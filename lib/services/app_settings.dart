import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

enum StreamBufferSize {
  low,
  normal,
  high;

  String label(AppLocalizations l10n) => switch (this) {
        StreamBufferSize.low => l10n.bufferLow,
        StreamBufferSize.normal => l10n.bufferNormal,
        StreamBufferSize.high => l10n.bufferHigh,
      };

  String description(AppLocalizations l10n) => switch (this) {
        StreamBufferSize.low => l10n.bufferLowDescription,
        StreamBufferSize.normal => l10n.bufferNormalDescription,
        StreamBufferSize.high => l10n.bufferHighDescription,
      };

  /// ExoPlayer / just_audio load control for this preset.
  AudioLoadConfiguration get audioLoadConfiguration {
    final android = switch (this) {
      StreamBufferSize.low => AndroidLoadControl(
          minBufferDuration: const Duration(seconds: 5),
          maxBufferDuration: const Duration(seconds: 15),
          bufferForPlaybackDuration: const Duration(seconds: 1),
          bufferForPlaybackAfterRebufferDuration: const Duration(seconds: 2),
          prioritizeTimeOverSizeThresholds: true,
        ),
      StreamBufferSize.normal => AndroidLoadControl(
          minBufferDuration: const Duration(seconds: 15),
          maxBufferDuration: const Duration(seconds: 30),
          bufferForPlaybackDuration: const Duration(milliseconds: 2500),
          bufferForPlaybackAfterRebufferDuration: const Duration(seconds: 5),
          prioritizeTimeOverSizeThresholds: true,
        ),
      StreamBufferSize.high => AndroidLoadControl(
          minBufferDuration: const Duration(seconds: 30),
          maxBufferDuration: const Duration(seconds: 60),
          bufferForPlaybackDuration: const Duration(seconds: 5),
          bufferForPlaybackAfterRebufferDuration: const Duration(seconds: 10),
          prioritizeTimeOverSizeThresholds: true,
        ),
    };

    final darwin = switch (this) {
      StreamBufferSize.low => DarwinLoadControl(
          preferredForwardBufferDuration: const Duration(seconds: 8),
        ),
      StreamBufferSize.normal => DarwinLoadControl(
          preferredForwardBufferDuration: const Duration(seconds: 20),
        ),
      StreamBufferSize.high => DarwinLoadControl(
          preferredForwardBufferDuration: const Duration(seconds: 40),
        ),
    };

    return AudioLoadConfiguration(
      androidLoadControl: android,
      darwinLoadControl: darwin,
    );
  }
}

class AppSettings extends ChangeNotifier {
  static const _autoPlayKey = 'settings_auto_play_last_station';
  static const _lastStationKey = 'settings_last_played_station_id';
  static const _bufferKey = 'settings_stream_buffer_size';

  bool _autoPlayLastStation = false;
  String? _lastPlayedStationId;
  StreamBufferSize _streamBufferSize = StreamBufferSize.normal;
  bool _ready = false;

  bool get isReady => _ready;
  bool get autoPlayLastStation => _autoPlayLastStation;
  String? get lastPlayedStationId => _lastPlayedStationId;
  StreamBufferSize get streamBufferSize => _streamBufferSize;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoPlayLastStation = prefs.getBool(_autoPlayKey) ?? false;
    _lastPlayedStationId = prefs.getString(_lastStationKey);
    final bufferName = prefs.getString(_bufferKey);
    _streamBufferSize = StreamBufferSize.values.firstWhere(
      (v) => v.name == bufferName,
      orElse: () => StreamBufferSize.normal,
    );
    _ready = true;
    notifyListeners();
  }

  Future<void> setAutoPlayLastStation(bool value) async {
    if (_autoPlayLastStation == value) return;
    _autoPlayLastStation = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayKey, value);
  }

  Future<void> setLastPlayedStationId(String stationId) async {
    if (_lastPlayedStationId == stationId) return;
    _lastPlayedStationId = stationId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStationKey, stationId);
  }

  Future<void> setStreamBufferSize(StreamBufferSize value) async {
    if (_streamBufferSize == value) return;
    _streamBufferSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bufferKey, value.name);
  }
}
