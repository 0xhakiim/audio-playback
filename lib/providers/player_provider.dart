// lib/providers/player_provider.dart
// Manages the global playback state using Provider (ChangeNotifier)

import 'package:flutter/foundation.dart';
import '../models/song.dart';

enum PlayerRepeatMode { none, repeatAll, repeatOne }

class PlayerProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = -1;

  bool _isPlaying = false;
  bool _isShuffle = false;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.none;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // ── Getters ────────────────────────────────────────────────────────────────

  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  bool get isPlaying => _isPlaying;
  bool get isShuffle => _isShuffle;
  PlayerRepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasSong => _currentSong != null;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get canSkipNext => _currentIndex < _queue.length - 1 || _repeatMode != PlayerRepeatMode.none;
  bool get canSkipPrev => _currentIndex > 0 || _repeatMode != PlayerRepeatMode.none;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Play a song from a given queue (playlist or album)
  void playSong(Song song, {List<Song>? playlist}) {
    _queue = playlist ?? [song];
    _currentIndex = _queue.indexWhere((s) => s.id == song.id);
    if (_currentIndex == -1) {
      _queue.insert(0, song);
      _currentIndex = 0;
    }
    _currentSong = song;
    _isPlaying = true;
    _position = Duration.zero;
    _duration = song.duration;
    // TODO: Call just_audio player here (see player_screen.dart)
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void skipNext() {
    if (_queue.isEmpty) return;

    if (_repeatMode == PlayerRepeatMode.repeatOne) {
      _position = Duration.zero;
      notifyListeners();
      return;
    }

    if (_isShuffle) {
      _currentIndex = (_queue.length * (DateTime.now().millisecondsSinceEpoch % 1000) ~/ 1000)
          .clamp(0, _queue.length - 1);
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_repeatMode == PlayerRepeatMode.repeatAll) {
      _currentIndex = 0;
    } else {
      return;
    }

    _currentSong = _queue[_currentIndex];
    _position = Duration.zero;
    _duration = _currentSong!.duration;
    notifyListeners();
  }

  void skipPrev() {
    if (_queue.isEmpty) return;

    // If more than 3 seconds in, restart the song
    if (_position.inSeconds > 3) {
      _position = Duration.zero;
      notifyListeners();
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == PlayerRepeatMode.repeatAll) {
      _currentIndex = _queue.length - 1;
    } else {
      _position = Duration.zero;
      notifyListeners();
      return;
    }

    _currentSong = _queue[_currentIndex];
    _position = Duration.zero;
    _duration = _currentSong!.duration;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case PlayerRepeatMode.none:
        _repeatMode = PlayerRepeatMode.repeatAll;
        break;
      case PlayerRepeatMode.repeatAll:
        _repeatMode = PlayerRepeatMode.repeatOne;
        break;
      case PlayerRepeatMode.repeatOne:
        _repeatMode = PlayerRepeatMode.none;
        break;
    }
    notifyListeners();
  }

  void seekTo(double progress) {
    _position = Duration(
      milliseconds: (progress * _duration.inMilliseconds).toInt(),
    );
    notifyListeners();
  }

  void toggleLike(Song song) {
    song.isLiked = !song.isLiked;
    notifyListeners();
  }

  // Simulate playback progress (replace with just_audio stream in production)
  void updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }
}