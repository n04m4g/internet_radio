import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internet_radio/data/stations.dart';
import 'package:internet_radio/models/resolved_stream.dart';
import 'package:internet_radio/models/station.dart';
import 'package:internet_radio/services/radio_browser_client.dart';
import 'package:internet_radio/services/station_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> hit(
  String name,
  String url, {
  int clickCount = 0,
  int votes = 0,
  int bitrate = 128,
  bool hls = false,
  String uuid = '',
}) {
  return {
    'stationuuid': uuid.isEmpty ? 'uuid-$name-$url' : uuid,
    'name': name,
    'url': url,
    'url_resolved': url,
    'tags': '',
    'votes': votes,
    'clickcount': clickCount,
    'bitrate': bitrate,
    'hls': hls ? 1 : 0,
    'codec': 'MP3',
    'homepage': 'https://example.com',
    'countrycode': 'IL',
    'language': 'hebrew',
    'lastcheckok': 1,
  };
}

/// Serves [results] for station searches and [uuidResults] for byuuid lookups.
/// [uuidResultsById] maps a stationuuid path segment to that UUID's payload.
/// byuuid defaults to empty so a test exercises the name-search fallback
/// unless it explicitly wants the pinned-uuid path.
StationRepository repositoryServing(
  List<Map<String, dynamic>> results, {
  List<Map<String, dynamic>> uuidResults = const [],
  Map<String, List<Map<String, dynamic>>> uuidResultsById = const {},
  List<Uri>? requestLog,
}) {
  final client = MockClient((request) async {
    requestLog?.add(request.url);
    if (request.url.path.contains('/json/servers')) {
      return http.Response(
        jsonEncode([
          {'name': 'de1.api.radio-browser.info'},
        ]),
        200,
      );
    }
    if (request.url.path.contains('/json/stations/byuuid/')) {
      final uuid = request.url.pathSegments.last;
      final byId = uuidResultsById[uuid];
      if (byId != null) {
        return http.Response(jsonEncode(byId), 200);
      }
      return http.Response(jsonEncode(uuidResults), 200);
    }
    return http.Response(jsonEncode(results), 200);
  });

  return StationRepository(
    radioBrowser: RadioBrowserClient(httpClient: client),
  );
}

Station stationById(String id) =>
    stationCatalog.firstWhere((s) => s.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a pinned uuid resolves ahead of name-search hits', () async {
    final repo = repositoryServing(
      [hit('ECO99FM', 'https://example.com/from-search')],
      uuidResults: [hit('ECO99FM', 'https://example.com/from-uuid')],
    );
    await repo.load();

    final resolved = await repo.resolveStream(stationById('eco99'));

    expect(resolved.streamUrl, 'https://example.com/from-uuid');
  });

  test('a popular unrelated station never wins over a name match', () async {
    final repo = repositoryServing([
      hit('Radios 100FM', 'https://example.com/100fm',
          clickCount: 999999, votes: 9999),
      hit('Galgalatz', 'https://example.com/galgalatz', clickCount: 500000),
      hit('ECO99FM', 'https://example.com/eco99', clickCount: 12),
    ]);
    await repo.load();

    final resolved = await repo.resolveStream(stationById('eco99'));

    expect(resolved.streamUrl, 'https://example.com/eco99');
  });

  test('among equal names, the direct stream with the best bitrate wins',
      () async {
    final repo = repositoryServing([
      hit('ECO99FM', 'https://example.com/hls', bitrate: 320, hls: true),
      hit('ECO99FM', 'https://example.com/low', bitrate: 64, votes: 9999),
      hit('ECO99FM', 'https://example.com/high', bitrate: 192),
    ]);
    await repo.load();

    final resolved = await repo.resolveStream(stationById('eco99'));

    expect(resolved.streamUrl, 'https://example.com/high');
  });

  test('no name match fails instead of substituting a station', () async {
    final repo = repositoryServing([
      hit('Radios 100FM', 'https://example.com/100fm', clickCount: 999999),
      hit('Galgalatz', 'https://example.com/galgalatz', clickCount: 500000),
    ]);
    await repo.load();

    await expectLater(
      repo.resolveStream(stationById('eco99')),
      throwsA(isA<StreamResolveException>()),
    );
  });

  test('a fresh cache entry is reused without calling the directory',
      () async {
    final log = <Uri>[];
    final repo = repositoryServing(
      [hit('ECO99FM', 'https://example.com/eco99')],
      requestLog: log,
    );
    await repo.load();

    final station = stationById('eco99');
    await repo.resolveStream(station);
    final callsAfterFirst = log.length;
    final second = await repo.resolveStream(station);

    expect(log.length, callsAfterFirst);
    expect(second.streamUrl, 'https://example.com/eco99');
    expect(repo.isFresh(station.id), isTrue);
    expect(repo.cachedStreamCount, 1);
  });

  test('clearing the cache drops resolved streams', () async {
    final repo = repositoryServing([hit('Galgalatz', 'https://example.com/g')]);
    await repo.load();

    await repo.resolveStream(stationById('galgalatz'));
    expect(repo.cachedStreamCount, 1);

    await repo.clearCache();
    expect(repo.cachedStreamCount, 0);
    expect(repo.cachedStreamFor('galgalatz'), isNull);
  });

  test('a stale entry is kept when the directory has nothing to offer',
      () async {
    SharedPreferences.setMockInitialValues({
      'stream_cache_v2': jsonEncode({
        'eco99': {
          'streamUrl': 'https://example.com/old-eco99',
          'resolvedAt': DateTime.now()
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch,
        },
      }),
    });
    final repo = repositoryServing([
      hit('Radios 100FM', 'https://example.com/100fm', clickCount: 999999),
    ]);
    await repo.load();

    final station = stationById('eco99');
    expect(repo.isFresh(station.id), isFalse);

    final resolved = await repo.resolveStream(station);
    expect(resolved.streamUrl, 'https://example.com/old-eco99');
  });

  test('caches written by an older version are discarded', () async {
    SharedPreferences.setMockInitialValues({
      'stream_cache_v1': jsonEncode({
        'eco99': {
          'streamUrl': 'https://example.com/stale-v1',
          'resolvedAt': DateTime.now().millisecondsSinceEpoch,
        },
      }),
    });
    final repo = repositoryServing(const []);
    await repo.load();

    expect(repo.cachedStreamCount, 0);
    expect(repo.cachedStreamFor('eco99'), isNull);
  });

  test('only http(s) stream URLs are accepted as playable', () {
    expect(ResolvedStream.isPlayableUrl('https://example.com/stream'), isTrue);
    expect(ResolvedStream.isPlayableUrl('http://example.com/stream'), isTrue);
    expect(ResolvedStream.isPlayableUrl('file:///tmp/audio'), isFalse);
    expect(ResolvedStream.isPlayableUrl('javascript:alert(1)'), isFalse);
    expect(ResolvedStream.isPlayableUrl('not a url'), isFalse);
    expect(ResolvedStream.isPlayableUrl(''), isFalse);
    expect(ResolvedStream.isPlayableUrl('https://'), isFalse);
  });

  test('non-http(s) directory hits are ignored during resolve', () async {
    final repo = repositoryServing([
      hit('ECO99FM', 'file:///evil'),
      hit('ECO99FM', 'https://example.com/eco99'),
    ]);
    await repo.load();

    final resolved = await repo.resolveStream(stationById('eco99'));
    expect(resolved.streamUrl, 'https://example.com/eco99');
  });

  test('cache entries with non-http(s) URLs are discarded on load', () async {
    SharedPreferences.setMockInitialValues({
      'stream_cache_v2': jsonEncode({
        'eco99': {
          'streamUrl': 'file:///tmp/bad',
          'resolvedAt': DateTime.now().millisecondsSinceEpoch,
        },
      }),
    });
    final repo = repositoryServing(const []);
    await repo.load();

    expect(repo.cachedStreamCount, 0);
    expect(repo.cachedStreamFor('eco99'), isNull);
  });

  test('candidateStreams ranks name matches and dedupes URLs', () async {
    final station = stationById('eco99');
    final repo = repositoryServing(
      [
        hit('ECO99FM', 'https://example.com/dup', bitrate: 64, uuid: 'u-low'),
        hit('ECO99FM', 'https://example.com/dup/', bitrate: 320, uuid: 'u-dup'),
        hit('ECO99FM', 'https://example.com/high', bitrate: 192, uuid: 'u-high'),
        hit('ECO99FM', 'https://example.com/hls', bitrate: 320, hls: true,
            uuid: 'u-hls'),
      ],
      uuidResultsById: {
        station.radioBrowserUuid!: [
          hit('ECO99FM', 'https://example.com/pinned', uuid: station.radioBrowserUuid!),
        ],
      },
    );
    await repo.load();

    final candidates = await repo.candidateStreams(station);
    final urls = candidates.map((c) => c.streamUrl).toList();

    expect(urls.first, 'https://example.com/pinned');
    expect(urls.where((u) => u.contains('dup')).length, 1);
    expect(urls, contains('https://example.com/high'));
    // Non-HLS 192kbps outranks HLS 320 among search hits after the pin.
    final highIndex = urls.indexOf('https://example.com/high');
    final hlsIndex = urls.indexOf('https://example.com/hls');
    expect(highIndex, lessThan(hlsIndex));
  });

  test('stale remembered winner stays ahead of the catalog pin', () async {
    final station = stationById('kan-88');
    final catalogUuid = station.radioBrowserUuid!;
    const winnerUuid = 'winner-88-uuid';
    SharedPreferences.setMockInitialValues({
      'stream_cache_v2': jsonEncode({
        station.id: {
          'streamUrl': 'https://example.com/winner',
          'resolvedAt': DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
          'radioBrowserUuid': winnerUuid,
        },
      }),
    });
    final repo = repositoryServing(
      [
        hit('Kan 88', 'https://example.com/dead-search', uuid: 'dead-search'),
        hit('Kan 88', 'https://example.com/winner', bitrate: 128,
            uuid: winnerUuid),
      ],
      uuidResultsById: {
        catalogUuid: [
          hit('Kan 88', 'https://example.com/dead-pin', uuid: catalogUuid),
        ],
        winnerUuid: [
          hit('Kan 88', 'https://example.com/winner-refreshed',
              uuid: winnerUuid),
        ],
      },
    );
    await repo.load();
    expect(repo.isFresh(station.id), isFalse);

    final candidates = await repo.candidateStreams(station);
    final urls = candidates.map((c) => c.streamUrl).toList();

    expect(urls.first, 'https://example.com/winner');
    expect(urls, contains('https://example.com/winner-refreshed'));
    expect(
      urls.indexOf('https://example.com/winner'),
      lessThan(urls.indexOf('https://example.com/dead-pin')),
    );
  });

  test('rememberStream overwrites the preferred cache entry', () async {
    final station = stationById('eco99');
    final repo = repositoryServing(
      [hit('ECO99FM', 'https://example.com/eco99')],
      uuidResults: [
        hit('ECO99FM', 'https://example.com/from-uuid',
            uuid: station.radioBrowserUuid!),
      ],
    );
    await repo.load();
    await repo.resolveStream(station);
    expect(
      repo.cachedStreamFor(station.id)?.streamUrl,
      'https://example.com/from-uuid',
    );

    await repo.rememberStream(
      station,
      ResolvedStream(
        streamUrl: 'https://example.com/promoted',
        resolvedAt: DateTime.now(),
        radioBrowserUuid: 'promoted-uuid',
      ),
    );

    expect(
      repo.cachedStreamFor(station.id)?.streamUrl,
      'https://example.com/promoted',
    );
    expect(repo.cachedStreamFor(station.id)?.radioBrowserUuid, 'promoted-uuid');
    expect(repo.isFresh(station.id), isTrue);
  });

  test('candidateStreams returns more than the play attempt cap allows',
      () async {
    final station = stationById('eco99');
    final hits = <Map<String, dynamic>>[
      for (var i = 0; i < 8; i++)
        hit(
          'ECO99FM',
          'https://example.com/s$i',
          bitrate: 64 + i,
          uuid: 'u-$i',
        ),
    ];
    final repo = repositoryServing(
      hits,
      uuidResultsById: {
        station.radioBrowserUuid!: [
          hit('ECO99FM', 'https://example.com/pin',
              uuid: station.radioBrowserUuid!),
        ],
      },
    );
    await repo.load();

    final candidates = await repo.candidateStreams(station);
    expect(candidates.length, greaterThan(StationRepository.maxPlayAttempts));
  });
}
