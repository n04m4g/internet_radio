import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/resolved_stream.dart';

class RadioBrowserHit {
  const RadioBrowserHit({
    required this.uuid,
    required this.name,
    required this.streamUrl,
    required this.tags,
    required this.votes,
    required this.clickCount,
    required this.bitrate,
    required this.codec,
    required this.homepage,
    required this.countryCode,
    required this.language,
    required this.lastCheckOk,
    required this.hls,
  });

  final String uuid;
  final String name;
  final String streamUrl;
  final String tags;
  final int votes;
  final int clickCount;

  /// Nominal bitrate in kbps, 0 when the directory does not know it.
  final int bitrate;

  final String codec;
  final String homepage;
  final String countryCode;
  final String language;

  /// Radio Browser's own health check result for this stream.
  final bool lastCheckOk;

  /// HLS playlists carry no ICY metadata and usually report an unknown codec.
  final bool hls;

  factory RadioBrowserHit.fromJson(Map<String, dynamic> json) {
    final resolved = (json['url_resolved'] as String?)?.trim() ?? '';
    final fallback = (json['url'] as String?)?.trim() ?? '';
    return RadioBrowserHit(
      uuid: json['stationuuid'] as String? ?? '',
      name: (json['name'] as String? ?? '').trim(),
      streamUrl: resolved.isNotEmpty ? resolved : fallback,
      tags: json['tags'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      clickCount: (json['clickcount'] as num?)?.toInt() ?? 0,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      codec: (json['codec'] as String? ?? '').trim(),
      homepage: (json['homepage'] as String? ?? '').trim(),
      countryCode: (json['countrycode'] as String? ?? '').trim(),
      language: (json['language'] as String? ?? '').trim(),
      lastCheckOk: ((json['lastcheckok'] as num?)?.toInt() ?? 0) == 1,
      hls: ((json['hls'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  ResolvedStream toResolvedStream(DateTime resolvedAt) {
    String? nonEmpty(String value) => value.isEmpty ? null : value;

    return ResolvedStream(
      streamUrl: streamUrl,
      resolvedAt: resolvedAt,
      bitrate: bitrate > 0 ? bitrate : null,
      codec: nonEmpty(codec),
      homepage: nonEmpty(homepage),
      countryCode: nonEmpty(countryCode),
      language: nonEmpty(language),
      radioBrowserName: nonEmpty(name),
      radioBrowserUuid: nonEmpty(uuid),
    );
  }
}

/// Community station directory: https://www.radio-browser.info/
class RadioBrowserClient {
  RadioBrowserClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static const _userAgent = 'InternetRadioApp/1.0 (Flutter; personal use)';
  static const _fallbackHosts = <String>[
    'de1.api.radio-browser.info',
    'fi1.api.radio-browser.info',
    'nl1.api.radio-browser.info',
  ];

  final http.Client _http;
  String? _host;
  List<String>? _knownHosts;

  Future<List<RadioBrowserHit>> searchStations({
    String? name,
    String? countryCode,
    int limit = 30,
  }) async {
    final query = <String, String>{
      'hidebroken': 'true',
      'limit': '$limit',
      'order': 'clickcount',
      'reverse': 'true',
    };
    if (name != null && name.trim().isNotEmpty) {
      query['name'] = name.trim();
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      query['countrycode'] = countryCode;
    }

    final response = await _get('/json/stations/search', query: query);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((e) => RadioBrowserHit.fromJson(Map<String, dynamic>.from(e)))
        .where((hit) =>
            ResolvedStream.isPlayableUrl(hit.streamUrl) && hit.uuid.isNotEmpty)
        .toList(growable: false);
  }

  Future<RadioBrowserHit?> stationByUuid(String uuid) async {
    final response = await _get('/json/stations/byuuid/$uuid');
    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map) return null;
    final hit = RadioBrowserHit.fromJson(Map<String, dynamic>.from(first));
    if (!ResolvedStream.isPlayableUrl(hit.streamUrl)) return null;
    return hit;
  }

  Map<String, String> get _headers => {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      };

  /// GET against the current Radio Browser host, rotating once on failure.
  Future<http.Response> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final host = await _resolveHost();
    try {
      return await _getFromHost(host, path, query: query);
    } catch (_) {
      final retryHost = await _rotateHost(failedHost: host);
      return _getFromHost(retryHost, path, query: query);
    }
  }

  Future<http.Response> _getFromHost(
    String host,
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.https(host, path, query);
    final response = await _http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Radio Browser HTTP ${response.statusCode}');
    }
    return response;
  }

  Future<String> _rotateHost({required String failedHost}) async {
    _host = null;
    final hosts = await _candidateHosts();
    final alternatives =
        hosts.where((h) => h != failedHost).toList(growable: false);
    final pool = alternatives.isNotEmpty ? alternatives : hosts;
    _host = pool[Random().nextInt(pool.length)];
    return _host!;
  }

  Future<List<String>> _candidateHosts() async {
    if (_knownHosts != null && _knownHosts!.isNotEmpty) {
      return _knownHosts!;
    }
    await _resolveHost();
    if (_knownHosts != null && _knownHosts!.isNotEmpty) {
      return _knownHosts!;
    }
    return _fallbackHosts;
  }

  Future<String> _resolveHost() async {
    if (_host != null) return _host!;
    try {
      final uri = Uri.https('all.api.radio-browser.info', '/json/servers');
      final response = await _http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final hosts = decoded
              .whereType<Map>()
              .map((e) => e['name'] as String?)
              .whereType<String>()
              .where((h) => h.isNotEmpty)
              .toList();
          if (hosts.isNotEmpty) {
            _knownHosts = hosts;
            _host = hosts[Random().nextInt(hosts.length)];
            return _host!;
          }
        }
      }
    } catch (_) {
      // Fall through to static mirrors.
    }
    _knownHosts = List<String>.from(_fallbackHosts);
    _host = _fallbackHosts[Random().nextInt(_fallbackHosts.length)];
    return _host!;
  }
}
