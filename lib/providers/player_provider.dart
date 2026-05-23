import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item_model.dart';
import '../services/audio_handler.dart';
import '../services/library_repository.dart';
import '../services/podcast_api.dart';

enum PlayerRepeatMode { none, repeatAll, repeatOne }

// Keys used by SharedPreferences
const _kQueue    = 'player_queue';
const _kIndex    = 'player_index';
const _kPosition = 'player_position_ms';

class PlayerProvider extends ChangeNotifier {
  final AppAudioPlayer    _audio;
  final LibraryRepository _repo = LibraryRepository.instance;
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    _position = Duration.zero;
    _duration = Duration.zero;
    await _audio.playUrl(_queue[_currentIndex].audioUrl);
    notifyListeners();
  }
  PlayerProvider(this._audio) {
    _audio.playerStateStream.listen((_) => notifyListeners());
    _audio.positionStream.listen((pos) {
      _position = pos;
      _throttledSaveSession(); // persist position as playback advances
      notifyListeners();
    });
    _audio.durationStream.listen((dur) { _duration = dur; notifyListeners(); });
    _audio.completionStream.listen((_) => _onTrackComplete());

    _repo.onSyncComplete((data) {
      _likedItems = List.of(data.likedItems);
      _savedShows = List.of(data.savedShows);
      notifyListeners();
    });
  }

  // ── Library state ──────────────────────────────────────────────────────────
  List<MediaItemModel> _likedItems    = [];
  List<PodcastShow>    _savedShows    = [];
  bool                 _libraryLoaded = false;

  List<MediaItemModel> get likedItems    => List.unmodifiable(_likedItems);
  List<PodcastShow>    get savedShows    => List.unmodifiable(_savedShows);
  bool                 get libraryLoaded => _libraryLoaded;
  List<MediaItemModel> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool isLiked(String id)     => _likedItems.any((e) => e.id == id);
  bool isShowSaved(String id) => _savedShows.any((s) => s.id == id);

  Future<void> loadLibrary() async {
    if (_libraryLoaded) return;
    _libraryLoaded = false;
    final data = await _repo.load();
    _likedItems    = List.of(data.likedItems);
    _savedShows    = List.of(data.savedShows);
    _libraryLoaded = true;
    notifyListeners();

    // Restore last session after library is ready
    await _restoreSession();
  }

  void clearLibrary() {
    _likedItems    = [];
    _savedShows    = [];
    _libraryLoaded = false;
    _clearSession();          // wipe saved session on logout
    _queue        = [];
    _currentIndex = -1;
    _position     = Duration.zero;
    _duration     = Duration.zero;
    _sessionRestored = false;
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

  /// True once a prior session has been loaded but not yet played by the user.
  /// Used to show a "Resume" prompt in the UI.
  bool _sessionRestored = false;
  bool get sessionRestored => _sessionRestored;

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

  // ── Session persistence ────────────────────────────────────────────────────

  // Throttle: only write to prefs at most once every 5 seconds while playing
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  void _throttledSaveSession() {
    final now = DateTime.now();
    if (now.difference(_lastSave).inSeconds >= 5) {
      _lastSave = now;
      _saveSession();
    }
  }

  Future<void> _saveSession() async {
    if (_queue.isEmpty || _currentIndex < 0) return;
    final prefs = await SharedPreferences.getInstance();
    final queueJson = jsonEncode(
      _queue.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_kQueue, queueJson);
    await prefs.setInt(_kIndex, _currentIndex);
    await prefs.setInt(_kPosition, _position.inMilliseconds);
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_kQueue);
    if (queueJson == null) return;

    try {
      final List<dynamic> decoded = jsonDecode(queueJson) as List;
      final queue = decoded
          .map((e) => MediaItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (queue.isEmpty) return;

      final index    = (prefs.getInt(_kIndex) ?? 0).clamp(0, queue.length - 1);
      final posMs    = prefs.getInt(_kPosition) ?? 0;

      _queue        = queue;
      _currentIndex = index;
      _position     = Duration(milliseconds: posMs);
      _sessionRestored = true;

      // Load the audio source and seek — but do NOT auto-play.
      await _audio.playUrl(_queue[_currentIndex].audioUrl);
      await _audio.pause();
      await _audio.seek(_position);

      notifyListeners();
    } catch (_) {
      // Corrupt data — ignore and start fresh
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kQueue);
    await prefs.remove(_kIndex);
    await prefs.remove(_kPosition);
  }

  /// Called from the UI "Resume" banner to actually start playback.
  Future<void> resumeSession() async {
    _sessionRestored = false;
    notifyListeners();
    await _audio.seek(_position);
    await _audio.play();
  }

  /// Called from the UI "Dismiss" action on the banner.
  void dismissRestoredSession() {
    _sessionRestored = false;
    _queue        = [];
    _currentIndex = -1;
    _position     = Duration.zero;
    _duration     = Duration.zero;
    _clearSession();
    notifyListeners();
  }

  // ── Playback actions ───────────────────────────────────────────────────────

  Future<void> playItem(MediaItemModel item, {List<MediaItemModel>? playlist}) async {
    _sessionRestored = false;
    _queue        = playlist ?? [item];
    _currentIndex = _queue.indexWhere((e) => e.id == item.id);
    if (_currentIndex == -1) { _queue.insert(0, item); _currentIndex = 0; }
    _position = Duration.zero;
    _duration = Duration.zero;
    await _audio.playUrl(_queue[_currentIndex].audioUrl);
    _saveSession();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_audio.isPlaying) {
      await _audio.pause();
      _saveSession(); // save exact position when user pauses
    } else {
      if (_sessionRestored) _sessionRestored = false;
      await _audio.play();
    }
    notifyListeners();
  }

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
    _saveSession();
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
    _saveSession();
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

  void _onTrackComplete() {
    _clearSession(); // completed naturally — don't resume this track next time
    skipNext();
  }

  @override
  void dispose() { _audio.dispose(); super.dispose(); }
}