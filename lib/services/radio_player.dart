import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/resolved_stream.dart';
import '../models/station.dart';
import 'app_settings.dart';
import 'radio_audio_handler.dart';
import 'station_repository.dart';

class RadioPlayer extends ChangeNotifier {
  RadioPlayer(this._handler, this._stations, this._settings) {
    _handler.playbackState.listen(_onPlaybackState);
    _handler.mediaItem.listen(_onMediaItem);
  }

  static const _errorLinger = Duration(seconds: 8);
  static const _statusLinger = Duration(seconds: 4);

  final AudioHandler _handler;
  final StationRepository _stations;
  final AppSettings _settings;

  Station? _current;
  bool _playing = false;
  bool _loading = false;

  /// True while this class is driving a play request, so the playback state
  /// listener does not report an error it is already handling.
  bool _busy = false;

  String? _error;
  String? _statusMessage;
  int _errorToken = 0;
  int _statusToken = 0;
  bool _reportedStreamError = false;
  bool _disposed = false;

  String? _nowPlaying;
  String? _nowPlayingArtist;
  String? _nowPlayingTitle;
  int? _icyBitrate;
  String? _icyGenre;
  String? _icyStationName;
  String? _icyUrl;

  AudioProcessingState _processingState = AudioProcessingState.idle;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;

  bool _didAutoPlayAttempt = false;

  Station? get current => _current;
  bool get isPlaying => _playing;
  bool get loading => _loading;
  String? get error => _error;
  String? get statusMessage => _statusMessage;

  /// Cached directory entry backing the current station, if any.
  ResolvedStream? get currentStream =>
      _current == null ? null : _stations.cachedStreamFor(_current!.id);

  /// Raw ICY text when the stream provides it.
  String? get nowPlaying => _nowPlaying;
  String? get nowPlayingArtist => _nowPlayingArtist;
  String? get nowPlayingTitle => _nowPlayingTitle;

  int? get icyBitrate => _icyBitrate;
  String? get icyGenre => _icyGenre;
  String? get icyStationName => _icyStationName;
  String? get icyUrl => _icyUrl;

  Duration get position => _position;
  Duration get bufferedPosition => _bufferedPosition;

  /// How far ahead of playback the buffer reaches.
  Duration get bufferAhead {
    final ahead = _bufferedPosition - _position;
    return ahead.isNegative ? Duration.zero : ahead;
  }

  AppLocalizations get _l10n => appL10n();

  String stateLabel(AppLocalizations l10n) => switch (_processingState) {
        AudioProcessingState.idle => l10n.stateStopped,
        AudioProcessingState.loading => l10n.stateConnecting,
        AudioProcessingState.buffering => l10n.stateBuffering,
        AudioProcessingState.ready =>
          _playing ? l10n.statePlaying : l10n.statePaused,
        AudioProcessingState.completed => l10n.stateEnded,
        AudioProcessingState.error => l10n.stateError,
      };

  /// Friendly subtitle for the now-playing bar.
  String nowPlayingSubtitle(AppLocalizations l10n) {
    if (_loading) return l10n.connectingEllipsis;
    if (_nowPlayingArtist != null &&
        _nowPlayingTitle != null &&
        _nowPlayingArtist != _nowPlayingTitle) {
      return '$_nowPlayingArtist – $_nowPlayingTitle';
    }
    if (_nowPlaying != null) return _nowPlaying!;
    if (_playing) return l10n.live;
    return l10n.statePaused;
  }

  RadioAudioHandler get _radio => _handler as RadioAudioHandler;

  void _onPlaybackState(PlaybackState state) {
    final playing = state.playing;
    final processingState = state.processingState;
    final loading = processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;

    final playingChanged = playing != _playing;
    final processingChanged = processingState != _processingState;
    final loadingChanged = loading != _loading;
    final hadError = _error != null;

    _playing = playing;
    _processingState = processingState;
    _loading = loading;
    _position = state.position;
    _bufferedPosition = state.bufferedPosition;

    if (playing || processingState == AudioProcessingState.ready) {
      _clearError(notify: false);
    }

    var reportedNewError = false;
    if (processingState == AudioProcessingState.error) {
      if (!_busy && !_reportedStreamError) {
        _reportedStreamError = true;
        reportedNewError = true;
        final name = _current?.name;
        _setError(
          name == null
              ? _l10n.playbackStoppedUnexpectedly
              : _l10n.playbackOfStationStopped(name),
          notify: false,
        );
      }
    } else {
      _reportedStreamError = false;
    }

    final errorCleared = hadError && _error == null;
    if (playingChanged ||
        processingChanged ||
        loadingChanged ||
        reportedNewError ||
        errorCleared) {
      notifyListeners();
    }
  }

  void _onMediaItem(MediaItem? item) {
    if (item == null) {
      _current = null;
      _clearNowPlaying();
    } else {
      final previousId = _current?.id;
      _current = _stations.byId(item.id) ?? _current;
      // Station changed: drop prior On Air fields before reading extras so a
      // clean MediaItem (no ICY yet) cannot leave the old track on screen.
      if (previousId != null && previousId != item.id) {
        _clearNowPlaying();
      }
      final extras = item.extras;
      _nowPlaying = _text(extras?['nowPlaying']);
      _nowPlayingArtist = _text(extras?['nowPlayingArtist']);
      _nowPlayingTitle = _text(extras?['nowPlayingTitle']);
      final bitrate = extras?['icyBitrate'];
      _icyBitrate = bitrate is int && bitrate > 0 ? bitrate : null;
      _icyGenre = _text(extras?['icyGenre']);
      _icyStationName = _text(extras?['icyStationName']);
      _icyUrl = _text(extras?['icyUrl']);
    }
    notifyListeners();
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  Future<void> playStation(Station station) async {
    if (_busy) return;
    if (_current?.id == station.id && _playing) {
      await pause();
      return;
    }

    _busy = true;
    _current = station;
    _loading = true;
    _clearError(notify: false);
    _clearNowPlaying();
    // Resolving / failover is silent: the station tile already shows a spinner.
    _setStatus(null, notify: false);
    notifyListeners();

    final triedUrls = <String>{};
    var played = false;

    try {
      final cached = _stations.cachedStreamFor(station.id);
      if (cached != null) {
        if (await _tryPlay(station, cached)) {
          played = true;
          return;
        }
        triedUrls.add(_urlKey(cached.streamUrl));
        if (!_stillPlaying(station)) return;
      }

      List<ResolvedStream> candidates;
      try {
        candidates = await _stations.candidateStreams(station);
      } catch (e) {
        debugPrint('Could not list streams for ${station.id}: $e');
        if (!_stillPlaying(station)) return;
        _setError(_l10n.noStreamFound(station.name), notify: false);
        return;
      }

      if (!_stillPlaying(station)) return;

      if (candidates.isEmpty) {
        _setError(_l10n.noStreamFound(station.name), notify: false);
        return;
      }

      var attempts = 0;
      for (final candidate in candidates) {
        if (attempts >= StationRepository.maxPlayAttempts) break;
        if (!_stillPlaying(station)) return;

        final key = _urlKey(candidate.streamUrl);
        if (!triedUrls.add(key)) continue;
        attempts++;

        if (await _tryPlay(station, candidate)) {
          if (!_stillPlaying(station)) return;
          await _stations.rememberStream(station, candidate);
          played = true;
          return;
        }
      }

      if (!_stillPlaying(station)) return;
      await _stations.invalidate(station.id);
      _setError(_l10n.couldNotPlayStation(station.name), notify: false);
    } finally {
      if (!played && _stillPlaying(station)) {
        // Keep station selected so the tile can show idle/error, but clear busy.
      }
      _busy = false;
      _loading = false;
      notifyListeners();
    }
  }

  /// True while this play request still owns the selected station.
  bool _stillPlaying(Station station) =>
      !_disposed && _current?.id == station.id;

  static String _urlKey(String url) => url.trim().toLowerCase();

  Future<bool> _tryPlay(Station station, ResolvedStream stream) async {
    if (!_stillPlaying(station)) return false;
    try {
      await _radio.playStation(station, stream);
      if (!_stillPlaying(station)) return false;
      await _settings.setLastPlayedStationId(station.id);
      return true;
    } catch (e) {
      debugPrint('Playback failed for ${station.id} (${stream.streamUrl}): $e');
      return false;
    }
  }

  /// Discards the preferred stream and walks candidates again.
  Future<void> refreshCurrentStream() async {
    final station = _current;
    if (station == null || _busy) return;

    _busy = true;
    _loading = true;
    _clearError(notify: false);
    _setStatus(_l10n.refreshingStream, notify: false);
    notifyListeners();

    var played = false;
    try {
      await _stations.invalidate(station.id);
      if (!_stillPlaying(station)) return;

      final candidates = await _stations.candidateStreams(station);
      if (!_stillPlaying(station)) return;

      if (candidates.isEmpty) {
        _setStatus(null, notify: false);
        _setError(_l10n.couldNotRefreshStation(station.name), notify: false);
        return;
      }

      var attempts = 0;
      final triedUrls = <String>{};
      for (final candidate in candidates) {
        if (attempts >= StationRepository.maxPlayAttempts) break;
        if (!_stillPlaying(station)) return;

        final key = _urlKey(candidate.streamUrl);
        if (!triedUrls.add(key)) continue;
        attempts++;

        if (await _tryPlay(station, candidate)) {
          if (!_stillPlaying(station)) return;
          await _stations.rememberStream(station, candidate);
          _setStatus(_l10n.streamRefreshed, notify: false);
          played = true;
          return;
        }
      }

      if (!_stillPlaying(station)) return;
      _setStatus(null, notify: false);
      _setError(_l10n.couldNotPlayRefreshedStream, notify: false);
    } catch (e) {
      debugPrint('Refresh failed for ${station.id}: $e');
      if (!_stillPlaying(station)) return;
      _setStatus(null, notify: false);
      _setError(_l10n.couldNotRefreshStation(station.name), notify: false);
    } finally {
      _busy = false;
      _loading = false;
      if (!played) {
        // status/error already set above when still on this station
      }
      notifyListeners();
    }
  }

  Future<void> maybeAutoPlayLastStation() async {
    if (_didAutoPlayAttempt) return;
    _didAutoPlayAttempt = true;

    if (!_settings.autoPlayLastStation) return;
    final lastId = _settings.lastPlayedStationId;
    if (lastId == null) return;

    final station = _stations.byId(lastId);
    if (station == null) return;

    await playStation(station);
  }

  Future<void> togglePlayPause() async {
    final station = _current;
    if (station == null) return;
    if (_playing) {
      await pause();
      return;
    }
    if (_processingState == AudioProcessingState.idle ||
        _processingState == AudioProcessingState.error) {
      await playStation(station);
      return;
    }
    _clearError();
    try {
      await _handler.play();
    } catch (e) {
      debugPrint('Resume failed for ${station.id}: $e');
      _setError(_l10n.couldNotResumePlayback);
    }
  }

  Future<void> pause() => _handler.pause();

  Future<void> stop() async {
    await _handler.stop();
    _current = null;
    _clearNowPlaying();
    _clearError(notify: false);
    _setStatus(null, notify: false);
    notifyListeners();
  }

  /// Hides the current banner, whether it is an error or a status message.
  void dismissBanner() {
    _clearError(notify: false);
    _setStatus(null, notify: false);
    notifyListeners();
  }

  void _clearNowPlaying() {
    _nowPlaying = null;
    _nowPlayingArtist = null;
    _nowPlayingTitle = null;
    _icyBitrate = null;
    _icyGenre = null;
    _icyStationName = null;
    _icyUrl = null;
  }

  void _clearError({bool notify = true}) {
    _errorToken++;
    if (_error == null) return;
    _error = null;
    if (notify) notifyListeners();
  }

  void _setError(String message, {bool notify = true}) {
    _error = message;
    final token = ++_errorToken;
    Future<void>.delayed(_errorLinger, () {
      if (_disposed || _errorToken != token) return;
      _error = null;
      notifyListeners();
    });
    if (notify) notifyListeners();
  }

  void _setStatus(String? message, {bool notify = true}) {
    _statusMessage = message;
    final token = ++_statusToken;
    if (message != null) {
      Future<void>.delayed(_statusLinger, () {
        if (_disposed || _statusToken != token) return;
        _statusMessage = null;
        notifyListeners();
      });
    }
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
