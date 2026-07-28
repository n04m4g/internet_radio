// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Internet Radio';

  @override
  String get tabIsrael => 'Israel';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get tabWorld => 'World';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get dismissTooltip => 'Dismiss';

  @override
  String get emptyIsraelStations => 'No Israel stations configured.';

  @override
  String get emptyFavorites => 'Tap the heart on a station to save it here.';

  @override
  String get emptyWorldStations => 'No world stations configured.';

  @override
  String get notificationsBlocked =>
      'Notifications are blocked, so the player will not show up on the lock screen or in the notification area.';

  @override
  String get notNow => 'Not now';

  @override
  String get openSettings => 'Open settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get autoPlayLastStation => 'Auto-play last station';

  @override
  String get autoPlayLastStationHint =>
      'When enabled, start the station you played last time the app opened.';

  @override
  String autoPlayWillStartWith(String station) {
    return 'Will start with $station next launch.';
  }

  @override
  String get streamBuffer => 'Stream buffer';

  @override
  String get bufferLow => 'Low';

  @override
  String get bufferNormal => 'Normal';

  @override
  String get bufferHigh => 'High';

  @override
  String get bufferLowDescription =>
      'Faster start, may stutter on weak networks.';

  @override
  String get bufferNormalDescription => 'Balanced startup time and stability.';

  @override
  String get bufferHighDescription =>
      'More stable on mobile data, slower to start.';

  @override
  String get refreshStreamCache => 'Refresh stream cache';

  @override
  String get streamCacheEmpty =>
      'No streams cached yet. Streams are kept for a week after they are first played.';

  @override
  String streamCacheCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count streams cached. Clear them to look everything up again.',
      one: '1 stream cached. Clear it to look everything up again.',
    );
    return '$_temp0';
  }

  @override
  String get streamCacheCleared =>
      'Stream cache cleared. Streams reload on next play.';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutBody(String version) {
    return 'An internet radio app.\nVersion $version\nDeveloped by Noam Ran';
  }

  @override
  String get nowPlayingTitle => 'Now Playing';

  @override
  String get nothingPlaying => 'Nothing is playing right now.';

  @override
  String get addFavorite => 'Add favorite';

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get refreshStream => 'Refresh stream';

  @override
  String get quality => 'Quality';

  @override
  String get homepage => 'Homepage';

  @override
  String get onAir => 'On air';

  @override
  String copied(String label) {
    return '$label copied';
  }

  @override
  String get stateStopped => 'Stopped';

  @override
  String get stateConnecting => 'Connecting';

  @override
  String get stateBuffering => 'Buffering';

  @override
  String get statePlaying => 'Playing';

  @override
  String get statePaused => 'Paused';

  @override
  String get stateEnded => 'Ended';

  @override
  String get stateError => 'Error';

  @override
  String get connectingEllipsis => 'Connecting…';

  @override
  String get live => 'Live';

  @override
  String get playbackStoppedUnexpectedly => 'Playback stopped unexpectedly.';

  @override
  String playbackOfStationStopped(String station) {
    return 'Playback of $station stopped unexpectedly.';
  }

  @override
  String noStreamFound(String station) {
    return 'No stream found for $station. Check your connection and try again.';
  }

  @override
  String get streamFailedRefreshing =>
      'Stream failed. Refreshing from Radio Browser…';

  @override
  String get updatedStreamSaved => 'Updated stream saved for a week.';

  @override
  String couldNotPlayStation(String station) {
    return 'Could not play $station. The stream may be offline.';
  }

  @override
  String get refreshingStream => 'Refreshing stream from Radio Browser…';

  @override
  String get streamRefreshed => 'Stream refreshed.';

  @override
  String get couldNotPlayRefreshedStream =>
      'Could not play the refreshed stream.';

  @override
  String couldNotRefreshStation(String station) {
    return 'Could not refresh the stream for $station.';
  }

  @override
  String get couldNotResumePlayback => 'Could not resume playback.';
}
