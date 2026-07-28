import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station.dart';
import 'station_repository.dart';

class FavoritesService extends ChangeNotifier {
  FavoritesService(this._stations);

  static const _prefsKey = 'favorite_station_ids';

  final StationRepository _stations;
  final Set<String> _ids = {};
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? const <String>[];
    _ids
      ..clear()
      ..addAll(stored);
    _ready = true;
    notifyListeners();
  }

  bool isFavorite(String stationId) => _ids.contains(stationId);

  List<Station> get favorites => _stations.stations
      .where((station) => _ids.contains(station.id))
      .toList(growable: false);

  Future<void> toggle(String stationId) async {
    if (_ids.contains(stationId)) {
      _ids.remove(stationId);
    } else {
      _ids.add(stationId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ids.toList(growable: false));
  }
}
