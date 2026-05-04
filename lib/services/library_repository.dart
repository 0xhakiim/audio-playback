// lib/services/library_repository.dart
//
// HOW IT WORKS:
//   - shared_preferences  →  instant read/write, survives app kills
//   - Firestore           →  syncs across devices, survives reinstalls
//
// On every like/save:
//   1. Update shared_preferences immediately  (UI feels instant)
//   2. Write to Firestore immediately         (real network request)
//
// On app start:
//   1. Load from shared_preferences           (instant, no network)
//   2. Fetch from Firestore                   (merge in any newer data)

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item_model.dart';
import '../services/podcast_api.dart';

const _kLikedKey = 'liked_items_v1';
const _kShowsKey = 'saved_shows_v1';

class LibraryRepository {
  LibraryRepository._();
  static final instance = LibraryRepository._();

  // Callback so PlayerProvider can react when Firestore sync finishes
  void Function(LibraryData)? _onSync;
  void onSyncComplete(void Function(LibraryData) cb) => _onSync = cb;

  // ── Single Firestore document for this user ────────────────────────────────
  // Path: users/{uid}/library/data
  DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugLog('⚠️  No logged-in user — Firestore skipped');
      return null;
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc('data');
  }

  // ── LOAD on startup ────────────────────────────────────────────────────────
  Future<LibraryData> load() async {
    // Step 1: local cache — instant
    final local = await _readLocal();
    debugLog('📦 Loaded from local: ${local.likedItems.length} liked, ${local.savedShows.length} shows');

    // Step 2: Firestore — runs in background, calls _onSync when done
    _fetchFromFirestore(local);

    return local;
  }

  // ── SAVE on every like / save-show action ─────────────────────────────────
  Future<void> save(LibraryData data) async {
    // Write local first — fast, never fails
    await _writeLocal(data);
    debugLog('💾 Saved to local: ${data.likedItems.length} liked, ${data.savedShows.length} shows');

    // Write to Firestore — real network call
    await _writeFirestore(data);
  }

  // ── Firestore fetch + merge ────────────────────────────────────────────────
  Future<void> _fetchFromFirestore(LibraryData local) async {
    final ref = _ref;
    if (ref == null) return;

    try {
      debugLog('🔥 Fetching from Firestore...');
      final snap = await ref.get();

      if (!snap.exists || snap.data() == null) {
        debugLog('🔥 No Firestore data yet — uploading local data');
        await _writeFirestore(local);
        return;
      }

      final d = snap.data()!;
      final remoteItems = (d['liked_items'] as List? ?? [])
          .map((e) => _itemFromMap(Map<String, dynamic>.from(e)))
          .toList();
      final remoteShows = (d['saved_shows'] as List? ?? [])
          .map((e) => _showFromMap(Map<String, dynamic>.from(e)))
          .toList();

      debugLog('🔥 Firestore returned: ${remoteItems.length} liked, ${remoteShows.length} shows');

      // Union merge — keep everything from both sources
      final merged = LibraryData(
        likedItems: _union(local.likedItems, remoteItems, (e) => e.id),
        savedShows: _union(local.savedShows, remoteShows, (s) => s.id),
      );

      // Persist merged result locally
      await _writeLocal(merged);
      debugLog('✅ Merge complete: ${merged.likedItems.length} liked, ${merged.savedShows.length} shows');

      // Tell PlayerProvider new data is available
      _onSync?.call(merged);
    } catch (e, stack) {
      debugLog('❌ Firestore fetch failed: $e\n$stack');
    }
  }

  // ── Firestore write ────────────────────────────────────────────────────────
  Future<void> _writeFirestore(LibraryData data) async {
    final ref = _ref;
    if (ref == null) return;

    try {
      debugLog('🔥 Writing to Firestore...');
      await ref.set({
        'liked_items': data.likedItems.map(_itemToMap).toList(),
        'saved_shows': data.savedShows.map(_showToMap).toList(),
        'updated_at':  FieldValue.serverTimestamp(),
        'uid':         FirebaseAuth.instance.currentUser?.uid,
      });
      debugLog('✅ Firestore write successful');
    } catch (e) {
      debugLog('❌ Firestore write failed: $e');
      rethrow;
    }
  }

  // ── shared_preferences ────────────────────────────────────────────────────
  Future<LibraryData> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final items = (prefs.getStringList(_kLikedKey) ?? [])
        .map((s) => _itemFromMap(jsonDecode(s)))
        .toList();
    final shows = (prefs.getStringList(_kShowsKey) ?? [])
        .map((s) => _showFromMap(jsonDecode(s)))
        .toList();
    return LibraryData(likedItems: items, savedShows: shows);
  }

  Future<void> _writeLocal(LibraryData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kLikedKey, data.likedItems.map((e) => jsonEncode(_itemToMap(e))).toList());
    await prefs.setStringList(
        _kShowsKey, data.savedShows.map((s) => jsonEncode(_showToMap(s))).toList());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<T> _union<T>(List<T> a, List<T> b, String Function(T) id) {
    final map = <String, T>{for (final x in [...a, ...b]) id(x): x};
    return map.values.toList();
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    print('[Library] $msg');
  }

  // MediaItemModel ↔ Map
  Map<String, dynamic> _itemToMap(MediaItemModel e) => {
    'id': e.id, 'title': e.title, 'subtitle': e.subtitle,
    'audioUrl': e.audioUrl, 'artworkUrl': e.artworkUrl,
    'category': e.category.name,
  };

  MediaItemModel _itemFromMap(Map<String, dynamic> j) => MediaItemModel(
    id: j['id'], title: j['title'], subtitle: j['subtitle'],
    audioUrl: j['audioUrl'], artworkUrl: j['artworkUrl'],
    category: j['category'] == 'quran' ? MediaCategory.quran : MediaCategory.podcast,
    isLiked: true,
  );

  // PodcastShow ↔ Map
  Map<String, dynamic> _showToMap(PodcastShow s) => {
    'id': s.id, 'name': s.name, 'author': s.author,
    'artworkUrl': s.artworkUrl, 'feedUrl': s.feedUrl,
    'genre': s.genre, 'episodeCount': s.episodeCount,
  };

  PodcastShow _showFromMap(Map<String, dynamic> j) => PodcastShow(
    id: j['id'], name: j['name'], author: j['author'],
    artworkUrl: j['artworkUrl'], feedUrl: j['feedUrl'] ?? '',
    genre: j['genre'] ?? '', episodeCount: j['episodeCount'] ?? 0,
  );
}

// ── Data holder ───────────────────────────────────────────────────────────────
class LibraryData {
  final List<MediaItemModel> likedItems;
  final List<PodcastShow>    savedShows;
  const LibraryData({required this.likedItems, required this.savedShows});
}