import 'package:flutter_test/flutter_test.dart';
import 'package:internet_radio/data/stations.dart';
import 'package:internet_radio/models/station.dart';

void main() {
  test('Israel stations are in the catalog', () {
    final israel =
        stationCatalog.where((s) => s.region == StationRegion.israel);
    expect(israel, isNotEmpty);
    expect(israel.any((s) => s.id == 'galgalatz'), isTrue);
  });

  test('Station ids are unique', () {
    final ids = stationCatalog.map((s) => s.id).toSet();
    expect(ids.length, stationCatalog.length);
  });

  test('Every station pins a Radio Browser uuid', () {
    for (final station in stationCatalog) {
      expect(
        station.radioBrowserUuid,
        isNotNull,
        reason: '${station.id} has no pinned uuid',
      );
      expect(station.radioBrowserUuid, isNotEmpty, reason: station.id);
    }
  });

  test('No two stations point at the same directory record', () {
    final uuids = stationCatalog.map((s) => s.radioBrowserUuid).toSet();
    expect(
      uuids.length,
      stationCatalog.length,
      reason: 'a duplicated uuid means the same station is listed twice',
    );
  });

  test('Every station has search terms and names to match against', () {
    for (final station in stationCatalog) {
      expect(station.searchTerms, isNotEmpty, reason: station.id);
      expect(station.matchNames, isNotEmpty, reason: station.id);
    }
  });

  test('Israel stations are scoped to the Israeli country code', () {
    for (final station in stationCatalog) {
      if (station.region != StationRegion.israel) continue;
      expect(station.countryCode, 'IL', reason: station.id);
    }
  });
}
