import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/media_item_model.dart';
import '../services/audio_handler.dart';
import '../services/library_repository.dart';
import '../services/podcast_api.dart';

enum PlayerRepeatMode { none, repeatAll, repeatOne }

class PlayerProvider extends ChangeNotifier {
  final AppAudioPlayer    _audio;
  final LibraryRepository _repo = LibraryRepository.instance;

  PlayerProvider(this._audio) {
    _audio.playerStateStream.listen((_) => notifyListeners());
    _audio.positionStream.listen((pos) { _position = pos; notifyListeners(); });
    _audio.durationStream.listen((dur) { _duration = dur; notifyListeners(); });
    _audio.completionStream.listen((_) => _onTrackComplete());

    // When Firestore background sync brings new data, update in-memory state
    _repo.onSyncComplete((data) {
      _likedItems = List.of(data.likedItems);
      _savedShows = List.of(data.savedShows);
      notifyListeners();
    });

    // ⚠️ Do NOT call _loadLibrary() here.
    // FirebaseAuth.instance.currentUser is null at this point.
    // AuthGate calls loadLibrary() once Firebase confirms the session.
  }

  // ── Library state ──────────────────────────────────────────────────────────
  List<MediaItemModel> _likedItems    = [];
  List<PodcastShow>    _savedShows    = [];
  bool                 _libraryLoaded = false;

  List<MediaItemModel> get likedItems    => List.unmodifiable(_likedItems);
  List<PodcastShow>    get savedShows    => List.unmodifiable(_savedShows);
  bool                 get libraryLoaded => _libraryLoaded;

  bool isLiked(String id)     => _likedItems.any((e) => e.id == id);
  bool isShowSaved(String id) => _savedShows.any((s) => s.id == id);

  // Called by AuthGate after Firebase confirms the user is logged in
  Future<void> loadLibrary() async {
    if (_libraryLoaded) return; // already loaded — don't fetch twice
    _libraryLoaded = false;
    final data = await _repo.load();
    _likedItems    = List.of(data.likedItems);
    _savedShows    = List.of(data.savedShows);
    _libraryLoaded = true;
    notifyListeners();
  }

  // Called by AuthGate when user logs out — wipe in-memory library
  void clearLibrary() {
    _likedItems    = [];
    _savedShows    = [];
    _libraryLoaded = false;
    notifyListeners();
  }

  Future<void> _persistLibrary() => _repo.save(
    LibraryData(likedItems: _likedItems, savedShows: _savedShows),
  );

  void toggleLike(MediaItemModel item) {
    if (isLiked(item.id)) {
      _likedItems.removeWhere((e) => e.id == item.id);
      item.isLiked = false;
    } else {
      item.isLiked = true;
      _likedItems.add(item);
    }
    _persistLibrary();
    notifyListeners();
  }

  void toggleSaveShow(PodcastShow show) {
    if (isShowSaved(show.id)) {
      _savedShows.removeWhere((s) => s.id == show.id);
    } else {
      _savedShows.add(show);
    }
    _persistLibrary();
    notifyListeners();
  }

  // ── Playback state ─────────────────────────────────────────────────────────
  List<MediaItemModel> _queue        = [];
  int                  _currentIndex = -1;
  PlayerRepeatMode     _repeat       = PlayerRepeatMode.none;
  bool                 _shuffle      = false;
  Duration             _position     = Duration.zero;
  Duration             _duration     = Duration.zero;

  MediaItemModel? get currentItem =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex] : null;

  bool get hasSong     => currentItem != null;
  bool get isPlaying   => _audio.isPlaying;
  bool get isShuffle   => _shuffle;
  PlayerRepeatMode get repeatMode => _repeat;
  bool get isRepeatOne => _repeat == PlayerRepeatMode.repeatOne;
  bool get isRepeating => _repeat != PlayerRepeatMode.none;
  Duration get position => _position;
  Duration get duration => _duration;

  double get progress {
    final total = _duration.inMilliseconds;
    if (total == 0) return 0.0;
    return (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  bool get canSkipNext => _currentIndex < _queue.length - 1 || isRepeating;
  bool get canSkipPrev => _currentIndex > 0 || isRepeating;

  Future<void> playItem(MediaItemModel item, {List<MediaItemModel>? playlist}) async {
    _queue        = playlist ?? [item];
    _currentIndex = _queue.indexWhere((e) => e.id == item.id);
    if (_currentIndex == -1) { _queue.insert(0, item); _currentIndex = 0; }
    _position = Duration.zero;
    _duration = Duration.zero;
    await _audio.playUrl(_queue[_currentIndex].audioUrl);
    notifyListeners();
  }

  Future<void> togglePlayPause() async =>
      _audio.isPlaying ? await _audio.pause() : await _audio.play();

  Future<void> skipNext() async {
    if (_repeat == PlayerRepeatMode.repeatOne) {
      await _audio.seek(Duration.zero); await _audio.play(); return;
    }
    int next;
    if (_shuffle && _queue.length > 1) {
      do { next = DateTime.now().millisecondsSinceEpoch % _queue.length; }
      while (next == _currentIndex);
    } else if (_currentIndex < _queue.length - 1) {
      next = _currentIndex + 1;
    } else if (_repeat == PlayerRepeatMode.repeatAll) {
      next = 0;
    } else return;
    _currentIndex = next;
    _position = Duration.zero;
    await _audio.playUrl(_queue[_currentIndex].audioUrl);
    notifyListeners();
  }

  Future<void> skipPrev() async {
    if (_position.inSeconds > 3) { await _audio.seek(Duration.zero); return; }
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeat == PlayerRepeatMode.repeatAll) {
      _currentIndex = _queue.length - 1;
    } else { await _audio.seek(Duration.zero); return; }
    _position = Duration.zero;
    await _audio.playUrl(_queue[_currentIndex].audioUrl);
    notifyListeners();
  }

  Future<void> seekTo(double progress) async => _audio.seek(
      Duration(milliseconds: (progress * _duration.inMilliseconds).toInt()));

  void toggleShuffle() { _shuffle = !_shuffle; notifyListeners(); }

  void cycleRepeatMode() {
    switch (_repeat) {
      case PlayerRepeatMode.none:      _repeat = PlayerRepeatMode.repeatAll;  break;
      case PlayerRepeatMode.repeatAll: _repeat = PlayerRepeatMode.repeatOne;  break;
      case PlayerRepeatMode.repeatOne: _repeat = PlayerRepeatMode.none;       break;
    }
    notifyListeners();
  }

  void _onTrackComplete() => skipNext();

  @override
  void dispose() { _audio.dispose(); super.dispose(); }
}