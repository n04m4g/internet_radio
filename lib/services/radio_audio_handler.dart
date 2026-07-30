import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/resolved_stream.dart';
import '../models/station.dart';
import 'app_settings.dart';
import 'station_repository.dart';

Future<AudioHandler> initAudioService(
  StationRepository stations,
  AppSettings settings,
) {
  return AudioService.init(
    builder: () => RadioAudioHandler(stations, settings),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nrs.internet_radio.channel.audio',
      androidNotificationChannelName: 'Radio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
}

class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler(this._stations, this._settings) {
    _appliedBufferSize = _settings.streamBufferSize;
    _player = AudioPlayer(
      audioLoadConfiguration: _appliedBufferSize.audioLoadConfiguration,
    );
    _init();
    _settings.addListener(_onSettingsChanged);
  }

  static const _loadTimeout = Duration(seconds: 20);

  final StationRepository _stations;
  final AppSettings _settings;

  late AudioPlayer _player;
  StreamBufferSize _appliedBufferSize = StreamBufferSize.normal;
  Station? _current;
  ResolvedStream? _currentStream;
  bool _recreatingPlayer = false;

  /// Bumped on every [playStation]/stop so late ICY from a previous source is
  /// never written onto the newly selected station.
  int _sourceGeneration = 0;

  /// False while a new source is loading; ICY is ignored until load succeeds.
  bool _icyActive = false;

  /// User wants audio to be playing. Pause/stop clear this so a late
  /// [AudioPlayer.play] cannot keep sound going against the notification UI.
  bool _playWhenReady = false;

  /// Guards re-entrant pause/stop when enforcing intent against player events.
  bool _enforcingIntent = false;

  final List<StreamSubscription<dynamic>> _playerSubs = [];

  Station? get currentStation => _current;
  ResolvedStream? get currentStream => _currentStream;

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _bindPlayerStreams();
  }

  void _bindPlayerStreams() {
    for (final sub in _playerSubs) {
      sub.cancel();
    }
    _playerSubs
      ..clear()
      ..addAll([
        _player.playbackEventStream.listen(
          (_) => _onPlayerTransportEvent(),
          onError: _onPlaybackError,
        ),
        _player.playerStateStream.listen((_) => _onPlayerTransportEvent()),
        _player.icyMetadataStream.listen(_onIcyMetadata),
        _player.processingStateStream.listen((state) {
          if (state == ProcessingState.completed) {
            unawaited(stop());
          }
        }),
      ]);
  }

  void _onPlaybackError(Object error, StackTrace stackTrace) {
    debugPrint('RadioAudioHandler playback error: $error\n$stackTrace');
    _playWhenReady = false;
    _publishTransportState(
      processingOverride: AudioProcessingState.error,
    );
  }

  void _onSettingsChanged() {
    if (_settings.streamBufferSize == _appliedBufferSize) return;
    unawaited(_recreatePlayerForBuffer(_settings.streamBufferSize));
  }

  Future<void> _recreatePlayerForBuffer(StreamBufferSize size) async {
    if (_recreatingPlayer) return;
    _recreatingPlayer = true;
    final station = _current;
    final stream = _currentStream;
    final shouldResume = _playWhenReady && station != null && stream != null;
    final resumeStation = shouldResume ? station : null;
    final resumeStream = shouldResume ? stream : null;

    try {
      await _player.stop();
      await _player.dispose();

      _appliedBufferSize = size;
      _player = AudioPlayer(
        audioLoadConfiguration: size.audioLoadConfiguration,
      );
      _bindPlayerStreams();

      if (resumeStation != null && resumeStream != null) {
        await playStation(resumeStation, resumeStream);
      } else {
        _publishTransportState();
      }
    } catch (e, st) {
      debugPrint('Failed to apply buffer size $size: $e\n$st');
    } finally {
      _recreatingPlayer = false;
    }
  }

  void _onIcyMetadata(IcyMetadata? icy) {
    if (!_icyActive) return;
    final station = _current;
    final generation = _sourceGeneration;
    if (station == null || icy == null) return;

    final current = mediaItem.valueOrNull;
    if (current == null || current.id != station.id) return;

    final extras = <String, dynamic>{...?current.extras};
    var changed = false;

    void put(String key, Object? value) {
      final cleaned = value is String ? value.trim() : value;
      if (cleaned == null || (cleaned is String && cleaned.isEmpty)) return;
      if (extras[key] == cleaned) return;
      extras[key] = cleaned;
      changed = true;
    }

    final raw = icy.info?.title?.trim();
    if (raw != null && raw.isNotEmpty && extras['nowPlaying'] != raw) {
      final parsed = _parseIcyTitle(raw);
      extras['nowPlaying'] = raw;
      if (parsed.artist != null) {
        extras['nowPlayingArtist'] = parsed.artist;
      } else {
        extras.remove('nowPlayingArtist');
      }
      if (parsed.title != null) {
        extras['nowPlayingTitle'] = parsed.title;
      } else {
        extras.remove('nowPlayingTitle');
      }
      changed = true;
    }

    final headers = icy.headers;
    if (headers != null) {
      // ExoPlayer reports icy-br in bits per second; the UI wants kbps.
      final bitrate = headers.bitrate;
      if (bitrate != null && bitrate > 0) {
        put('icyBitrate', bitrate >= 1000 ? bitrate ~/ 1000 : bitrate);
      }
      put('icyGenre', headers.genre);
      put('icyStationName', headers.name);
      put('icyUrl', headers.url);
    }

    if (!changed) return;
    // Another play/stop started while we were parsing — drop this update.
    if (generation != _sourceGeneration || !_icyActive) return;
    if (_current?.id != station.id) return;

    final artist = extras['nowPlayingArtist'];
    final title = extras['nowPlayingTitle'];
    mediaItem.add(
      current.copyWith(
        artist: artist is String && artist.isNotEmpty ? artist : station.genre,
        displayTitle:
            title is String && title.isNotEmpty ? title : station.name,
        extras: extras,
      ),
    );
  }

  ({String? artist, String? title}) _parseIcyTitle(String raw) {
    const separators = [' - ', ' – ', ' — '];
    for (final sep in separators) {
      final index = raw.indexOf(sep);
      if (index > 0 && index < raw.length - sep.length) {
        final artist = raw.substring(0, index).trim();
        final title = raw.substring(index + sep.length).trim();
        if (artist.isNotEmpty && title.isNotEmpty) {
          return (artist: artist, title: title);
        }
      }
    }
    return (artist: null, title: raw);
  }

  Future<void> playStation(Station station, ResolvedStream stream) async {
    if (!ResolvedStream.isPlayableUrl(stream.streamUrl)) {
      _playWhenReady = false;
      _publishTransportState(
        processingOverride: AudioProcessingState.error,
      );
      throw ArgumentError.value(
        stream.streamUrl,
        'streamUrl',
        'Only http(s) stream URLs are allowed',
      );
    }

    final generation = ++_sourceGeneration;
    _icyActive = false;
    _playWhenReady = false;
    _current = station;
    _currentStream = stream;

    final item = MediaItem(
      id: station.id,
      title: station.name,
      album: station.subtitle ?? station.genre,
      artist: station.genre,
      extras: <String, dynamic>{'streamUrl': stream.streamUrl},
    );
    mediaItem.add(item);
    _publishTransportState(
      processingOverride: AudioProcessingState.loading,
    );

    try {
      await _player
          .setAudioSource(
            AudioSource.uri(Uri.parse(stream.streamUrl), tag: item),
          )
          .timeout(_loadTimeout);
    } catch (e, st) {
      debugPrint('RadioAudioHandler could not load ${stream.streamUrl}: '
          '$e\n$st');
      if (generation == _sourceGeneration) {
        _playWhenReady = false;
        _publishTransportState(
          processingOverride: AudioProcessingState.error,
        );
      }
      rethrow;
    }

    if (generation != _sourceGeneration) return;
    _icyActive = true;
    _playWhenReady = true;

    // Live streams: play() may never complete, so do not await it here.
    unawaited(_startPlayback());
    _publishTransportState();
  }

  /// Starts the player, then undoes itself if the user already paused/stopped.
  Future<void> _startPlayback() async {
    try {
      await _player.play();
    } catch (e, st) {
      _onPlaybackError(e, st);
      return;
    }
    if (!_playWhenReady) {
      await _enforceNotPlaying();
    }
    _publishTransportState();
  }

  Future<void> _enforceNotPlaying() async {
    if (_enforcingIntent) return;
    _enforcingIntent = true;
    try {
      if (_current == null) {
        await _player.stop();
      } else {
        await _player.pause();
      }
    } catch (e, st) {
      debugPrint('RadioAudioHandler enforceNotPlaying failed: $e\n$st');
    } finally {
      _enforcingIntent = false;
    }
  }

  void _onPlayerTransportEvent() {
    if (!_playWhenReady && _player.playing && !_enforcingIntent) {
      // Publish paused/stopped UI immediately; enforce player async.
      _publishTransportState();
      unawaited(() async {
        await _enforceNotPlaying();
        _publishTransportState();
      }());
      return;
    }
    _publishTransportState();
  }

  @override
  Future<void> play() async {
    if (_current == null || _currentStream == null) return;
    _playWhenReady = true;
    unawaited(_startPlayback());
    _publishTransportState();
  }

  @override
  Future<void> pause() async {
    _playWhenReady = false;
    try {
      await _player.pause();
    } catch (e, st) {
      debugPrint('RadioAudioHandler pause failed: $e\n$st');
    }
    _publishTransportState();
  }

  @override
  Future<void> stop() async {
    _playWhenReady = false;
    _sourceGeneration++;
    _icyActive = false;
    try {
      await _player.stop();
    } catch (e, st) {
      debugPrint('RadioAudioHandler stop failed: $e\n$st');
    }
    _current = null;
    _currentStream = null;
    mediaItem.add(null);
    _publishTransportState(
      processingOverride: AudioProcessingState.idle,
    );
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final station = _stations.byId(mediaItem.id);
    if (station == null) return;
    final stream = await _stations.resolveStream(station);
    await playStation(station, stream);
  }

  /// Pushes a definitive media-session state so notification/lock-screen
  /// controls always reflect user intent, not a stale player snapshot.
  void _publishTransportState({AudioProcessingState? processingOverride}) {
    final processing = processingOverride ??
        switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        };

    // After stop, or whenever the user cleared intent, never report playing.
    final playing = processingOverride == AudioProcessingState.idle
        ? false
        : (_playWhenReady && _player.playing);

    // While paused with intent off, avoid leaving the session stuck in
    // "loading" so Play/Pause controls stay tappable and the UI can flip.
    final resolvedProcessing =
        processingOverride == AudioProcessingState.idle
            ? AudioProcessingState.idle
            : (!_playWhenReady &&
                    (processing == AudioProcessingState.loading ||
                        processing == AudioProcessingState.buffering)
                ? AudioProcessingState.ready
                : processing);

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {},
        androidCompactActionIndices: const [0, 1],
        processingState: resolvedProcessing,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }
}
