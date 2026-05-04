// lib/services/audio_handler.dart
// Audio player using audioplayers — Android's native MediaPlayer.
// No Google Play Services, no ExoPlayer, no audio_service required.

import 'package:audioplayers/audioplayers.dart';

class AppAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<PlayerState> get playerStateStream  => _player.onPlayerStateChanged;
  Stream<Duration>    get positionStream      => _player.onPositionChanged;
  Stream<Duration>    get durationStream      => _player.onDurationChanged;
  Stream<void>        get completionStream    => _player.onPlayerComplete;

  PlayerState get state => _player.state;
  bool get isPlaying    => _player.state == PlayerState.playing;

  // ── Load and play a URL ────────────────────────────────────────────────────
  Future<void> playUrl(String url) async {
    await _player.play(UrlSource(url));
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Future<void> play()             => _player.resume();
  Future<void> pause()            => _player.pause();
  Future<void> stop()             => _player.stop();
  Future<void> seek(Duration pos) => _player.seek(pos);

  Future<Duration?> getPosition() => _player.getCurrentPosition();
  Future<Duration?> getDuration() => _player.getDuration();

  // ── Release resources ──────────────────────────────────────────────────────
  Future<void> dispose() => _player.dispose();
}