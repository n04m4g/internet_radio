import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/stations.dart';
import '../models/resolved_stream.dart';
import '../models/station.dart';
import 'radio_browser_client.dart';

class StreamResolveException implements Exception {
  StreamResolveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns the station catalog and the cache of stream URLs resolved from Radio
/// Browser. Entries are reused for [cacheTtl] before being refreshed.
class StationRepository extends ChangeNotifier {
  StationRepository({RadioBrowserClient? radioBrowser})
      : _radioBrowser = radioBrowser ?? RadioBrowserClient();

  static const cacheTtl = Duration(days: 7);

  /// Max alternate streams [RadioPlayer] should try in one play attempt.
  static const maxPlayAttempts = 5;

  static const _cacheKey = 'stream_cache_v2';

  /// Written by earlier versions whose entries were resolved by name search
  /// alone, so they are deleted rather than migrated: the catalog now pins a
  /// stationuuid per station and should re-resolve against it immediately.
  static const _legacyKeys = <String>[
    'cached_stations_v1',
    'stream_cache_v1',
  ];

  /// A name match is worth more than any stream quality or popularity score
  /// can add, so a popular station can never be substituted for the right one.
  static const _nameWeight = 10000000;

  /// Latin, digits, Hebrew, Arabic and Cyrillic letters. Everything else is
  /// dropped so spacing, punctuation, Hebrew geresh and Arabic diacritics
  /// cannot break an otherwise identical name.
  static final _nonNameChars =
      RegExp(r'[^a-z0-9\u05d0-\u05ea\u0621-\u064a\u0430-\u044f\u0451]+');
  static final _arabicAlef = RegExp('[\u0622\u0623\u0625\u0671]');

  final RadioBrowserClient _radioBrowser;
  final Map<String, ResolvedStream> _cache = {};
  bool _ready = false;

  bool get isReady => _ready;

  List<Station> get stations => stationCatalog;

  int get cachedStreamCount => _cache.length;

  List<Station> forRegion(StationRegion region) => stationCatalog
      .where((s) => s.region == region)
      .toList(growable: false);

  Station? byId(String id) {
    for (final station in stationCatalog) {
      if (station.id == id) return station;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }

    final raw = prefs.getString(_cacheKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is! String || value is! Map) return;
            final entry =
                ResolvedStream.tryFromJson(Map<String, dynamic>.from(value));
            if (entry != null) _cache[key] = entry;
          });
        }
      } catch (e) {
        debugPrint('Stream cache parse failed: $e');
      }
    }

    _ready = true;
    notifyListeners();
  }

  ResolvedStream? cachedStreamFor(String stationId) => _cache[stationId];

  bool isFresh(String stationId) {
    final entry = _cache[stationId];
    return entry != null && entry.isFreshAt(DateTime.now(), cacheTtl);
  }

  /// Ranked playable streams for [station], preferred for failover.
  ///
  /// Order: last cached URL (even if stale), fresh lookup of that UUID, catalog
  /// pin, then name/country matches by score. Deduped by normalized URL.
  Future<List<ResolvedStream>> candidateStreams(Station station) async {
    final now = DateTime.now();
    final out = <ResolvedStream>[];
    final seenUrls = <String>{};

    void add(ResolvedStream? stream) {
      if (stream == null) return;
      if (!ResolvedStream.isPlayableUrl(stream.streamUrl)) return;
      final key = _normalizeUrl(stream.streamUrl);
      if (key.isEmpty || !seenUrls.add(key)) return;
      out.add(stream);
    }

    final cached = _cache[station.id];
    if (cached != null) {
      add(cached);
    }

    final rememberedUuid = cached?.radioBrowserUuid;
    if (rememberedUuid != null && rememberedUuid.isNotEmpty) {
      add(await _hitByUuid(rememberedUuid, now));
    }

    final catalogUuid = station.radioBrowserUuid;
    if (catalogUuid != null &&
        catalogUuid.isNotEmpty &&
        catalogUuid != rememberedUuid) {
      add(await _hitByUuid(catalogUuid, now));
    }

    final matches = await _scoredMatches(station);
    matches.sort((a, b) => b.score.compareTo(a.score));
    for (final match in matches) {
      add(match.hit.toResolvedStream(now));
    }

    return out;
  }

  /// Persists [stream] as the main cached entry for [station].
  Future<void> rememberStream(Station station, ResolvedStream stream) async {
    if (!ResolvedStream.isPlayableUrl(stream.streamUrl)) return;
    final stored = ResolvedStream(
      streamUrl: stream.streamUrl,
      resolvedAt: DateTime.now(),
      bitrate: stream.bitrate,
      codec: stream.codec,
      homepage: stream.homepage,
      countryCode: stream.countryCode,
      language: stream.language,
      radioBrowserName: stream.radioBrowserName,
      radioBrowserUuid: stream.radioBrowserUuid,
    );
    _cache[station.id] = stored;
    notifyListeners();
    await _persist();
  }

  /// Returns a playable stream for [station].
  ///
  /// A cached entry younger than [cacheTtl] is reused as is. Otherwise the
  /// first [candidateStreams] entry is preferred (last winner before a dead
  /// catalog pin).
  Future<ResolvedStream> resolveStream(
    Station station, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[station.id];
    if (!forceRefresh &&
        cached != null &&
        cached.isFreshAt(DateTime.now(), cacheTtl)) {
      return cached;
    }

    final candidates = await candidateStreams(station);
    if (candidates.isEmpty) {
      throw StreamResolveException(
        'No stream for ${station.name} was found on Radio Browser.',
      );
    }

    final best = candidates.first;
    final sameAsCache = cached != null &&
        _normalizeUrl(cached.streamUrl) == _normalizeUrl(best.streamUrl) &&
        cached.radioBrowserUuid == best.radioBrowserUuid;
    if (!sameAsCache || forceRefresh) {
      await rememberStream(station, best);
      return _cache[station.id]!;
    }
    return best;
  }

  Future<void> invalidate(String stationId) async {
    if (_cache.remove(stationId) == null) return;
    notifyListeners();
    await _persist();
  }

  Future<void> clearCache() async {
    if (_cache.isEmpty) return;
    _cache.clear();
    notifyListeners();
    await _persist();
  }

  Future<ResolvedStream?> _hitByUuid(String uuid, DateTime now) async {
    try {
      final hit = await _radioBrowser.stationByUuid(uuid);
      if (hit != null && ResolvedStream.isPlayableUrl(hit.streamUrl)) {
        return hit.toResolvedStream(now);
      }
    } catch (e) {
      debugPrint('Radio Browser uuid lookup failed for $uuid: $e');
    }
    return null;
  }

  Future<List<({RadioBrowserHit hit, int score})>> _scoredMatches(
    Station station,
  ) async {
    final seenUuids = <String>{};
    final matches = <({RadioBrowserHit hit, int score})>[];

    // Search the station's own country first, then worldwide in case the
    // directory files it under a different country.
    final scopes = <String?>{station.countryCode, null};

    for (final scope in scopes) {
      for (final term in station.searchTerms) {
        List<RadioBrowserHit> hits;
        try {
          hits = await _radioBrowser.searchStations(
            name: term,
            countryCode: scope,
            limit: 25,
          );
        } catch (e) {
          debugPrint('Radio Browser search "$term" failed: $e');
          continue;
        }

        for (final hit in hits) {
          if (!ResolvedStream.isPlayableUrl(hit.streamUrl)) continue;
          if (!seenUuids.add(hit.uuid)) continue;
          final score = _score(station, hit);
          if (score > 0) {
            matches.add((hit: hit, score: score));
          }
        }
      }
      if (matches.isNotEmpty) return matches;
    }

    return matches;
  }

  /// Name similarity is a hard gate: a hit whose name does not match returns
  /// zero and can never be selected, however popular it is.
  ///
  /// Below the gate the layers rank stream quality above popularity, so votes
  /// only break ties between otherwise equivalent streams.
  int _score(Station station, RadioBrowserHit hit) {
    final nameScore = _nameScore(station, hit.name);
    if (nameScore == 0) return 0;

    var score = nameScore * _nameWeight;
    if (hit.lastCheckOk) score += 1000000;
    if (!hit.hls) score += 100000;
    score += min(hit.bitrate, 999) * 100;
    if (hit.streamUrl.startsWith('https')) score += 50;
    score += min(hit.votes + hit.clickCount ~/ 100, 49);
    return score;
  }

  int _nameScore(Station station, String hitName) {
    final hit = _compact(hitName);
    if (hit.isEmpty) return 0;

    var best = 0;
    for (final candidate in station.matchNames) {
      final name = _compact(candidate);
      if (name.isEmpty) continue;
      if (name == hit) return 100;
      if (name.length >= 4 && hit.contains(name)) {
        best = max(best, 70);
      } else if (hit.length >= 4 && name.contains(hit)) {
        best = max(best, 55);
      }
    }
    return best;
  }

  String _compact(String value) => value
      .toLowerCase()
      .replaceAll(_arabicAlef, '\u0627')
      .replaceAll(_nonNameChars, '');

  String _normalizeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return url.trim().toLowerCase();
    }
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return uri
        .replace(
          scheme: uri.scheme.toLowerCase(),
          host: uri.host.toLowerCase(),
          path: path.isEmpty ? '/' : path,
        )
        .toString();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _cache.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_cacheKey, payload);
  }
}
