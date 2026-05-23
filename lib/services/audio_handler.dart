// lib/services/audio_handler.dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Call this once in main() before runApp.
Future<AppAudioHandler> initAudioService() {
  return AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yourapp.audio',
      androidNotificationChannelName: 'Now Playing',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,

    ),
  );
}

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  AppAudioHandler() {
    // Forward just_audio state → audio_service state (drives the notification)
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Forward duration changes into the current MediaItem
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  // ── Public API (called by PlayerProvider) ──────────────────────────────────

  Future<void> playUrl(MediaItem item) async {
    mediaItem.add(item);                        // updates notification artwork/title
    await _player.setUrl(item.id);              // item.id == the audio URL
    await _player.play();
  }

  @override Future<void> play()               => _player.play();
  @override Future<void> pause()              => _player.pause();
  @override Future<void> stop()               => _player.stop();
  @override Future<void> seek(Duration pos)   => _player.seek(pos);
  @override Future<void> skipToNext()         async {} // handled by PlayerProvider
  @override Future<void> skipToPrevious()     async {} // handled by PlayerProvider

  // ── Streams (PlayerProvider subscribes to these) ───────────────────────────

  Stream<PlayerState>  get playerStateStream  => _player.playerStateStream;
  Stream<Duration>     get positionStream      => _player.positionStream;
  Stream<Duration?>    get durationStream      => _player.durationStream;
  Stream<void>         get completionStream    =>
      _player.playerStateStream
          .where((s) => s.processingState == ProcessingState.completed)
          .map((_) {});

  bool get isPlaying => _player.playing;


  Future<void> dispose() async {
    await _player.dispose();

  }

  // ── Private: translate just_audio state → audio_service PlaybackState ──────

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // all 3 show in compact view
      processingState: {
        ProcessingState.idle:       AudioProcessingState.idle,
        ProcessingState.loading:    AudioProcessingState.loading,
        ProcessingState.buffering:  AudioProcessingState.buffering,
        ProcessingState.ready:      AudioProcessingState.ready,
        ProcessingState.completed:  AudioProcessingState.completed,
      }[_player.processingState]!,
      playing:  playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed:    _player.speed,
      queueIndex: 0,
    );
  }
}