// lib/services/quran_api.dart
//
// Uses the Quran Foundation API (api.quran.com/api/v4) — free, no key needed.
// Docs: https://api-docs.quran.foundation
//
// Surah-level audio (full MP3):
//   GET /chapter_recitations/{reciter_id}/{chapter_number}
//   → audio_file.audio_url
//
// Bulk audio list for all surahs:
//   GET /chapter_recitations/{reciter_id}
//   → audio_files[].{ chapter_id, audio_url }
//
// Ayah-level audio:
//   GET /recitations/{recitation_id}/by_chapter/{chapter_number}
//   → audio_files[].{ verse_key, url }
//
// Chapter metadata:
//   GET /chapters?language=en

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item_model.dart';

// ── Reciters for full-surah playback ─────────────────────────────────────────
const Map<int, String> kChapterReciters = {
  1: 'Mishary Alafasy',
  2: 'Abu Bakr al-Shatri',
  3: 'Nasser Al Qatami',
  4: 'Yasser Al Dosari',
  6: 'Abdul Basit (Murattal)',
  7: 'Abdul Basit (Mujawwad)',
};
const int kDefaultChapterReciterId = 1; // Mishary Alafasy

// ── Reciters for ayah-by-ayah playback ───────────────────────────────────────
const Map<int, String> kAyahReciters = {
  1: 'AbdulBaset Mujawwad',
  2: 'AbdulBaset Murattal',
  3: 'Mishary Alafasy',
  4: 'Hani Rifai',
  5: 'Mohamed Siddiq Minshawi',
  6: 'Mahmoud Khalil Husary',
  7: 'Mahmoud Khalil Husary (Muallem)',
};
const int kDefaultAyahReciterId = 3; // Mishary Alafasy

class QuranApiService {
  static const _base = 'https://api.quran.com/api/v4';

  // ── Internal GET helper ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http
        .get(
      Uri.parse('$_base$path'),
      headers: {'Accept': 'application/json'},
    )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('QuranAPI $path → HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Fetch a single surah's audio URL ─────────────────────────────────────
  //
  // Used by PlayerProvider.jumpTo() when a queue item has no audioUrl yet.
  // Endpoint: GET /chapter_recitations/{reciter_id}/{chapter_number}
  //
  static Future<String> fetchSurahAudioUrl(
      int surahNumber, {
        int reciterId = kDefaultChapterReciterId,
      }) async {
    final data = await _get('/chapter_recitations/$reciterId/$surahNumber');
    // Response shape: { "audio_file": { "audio_url": "https://..." } }
    final audioFile = data['audio_file'] as Map<String, dynamic>?;
    final url = audioFile?['audio_url'] as String? ?? '';
    if (url.isEmpty) {
      throw Exception(
          'No audio URL returned for surah $surahNumber, reciter $reciterId');
    }
    return url;
  }

  // ── Fetch all 114 surahs as MediaItemModel list ───────────────────────────
  //
  // Bulk-fetches chapter metadata and all audio URLs in 2 API calls.
  // audioUrl is pre-filled; no lazy-loading needed unless you switch reciter.
  //
  static Future<List<MediaItemModel>> fetchSurahs({
    int reciterId = kDefaultChapterReciterId,
  }) async {
    // 1. Chapter metadata
    final chapData = await _get('/chapters?language=en');
    final List chapters = chapData['chapters'] as List;

    // 2. All audio files for this reciter in one call
    final audioData = await _get('/chapter_recitations/$reciterId');
    final List audioFiles = audioData['audio_files'] as List;

    // Build map: chapter_id → audio_url
    final audioMap = <int, String>{
      for (final f in audioFiles)
        (f['chapter_id'] as int): (f['audio_url'] as String? ?? ''),
    };

    final reciterName = kChapterReciters[reciterId] ?? 'Reciter $reciterId';

    return chapters.map((c) {
      final id       = c['id'] as int;
      final audioUrl = audioMap[id] ?? '';
      return MediaItemModel(
        id:         'quran_$id',
        title:      '${c['name_simple']} — ${c['name_arabic']}',
        subtitle:   '${c['translated_name']['name']} • ${c['verses_count']} verses',
        audioUrl:   audioUrl,
        artworkUrl: '',
        category:   MediaCategory.quran,
        extra: {
          'surahNumber':     id,
          'arabicName':      c['name_arabic'],
          'reciterId':       reciterId,
          'reciterName':     reciterName,
          'revelationPlace': c['revelation_place'],
        },
      )..arabicTitle = c['name_arabic'] as String?;
    }).toList();
  }

  // ── Fetch a single surah's ayahs with individual audio links ─────────────
  static Future<List<MediaItemModel>> fetchSurahAyahs(
      int surahNumber, {
        int recitationId = kDefaultAyahReciterId,
      }) async {
    // 1. Ayah audio — paginated
    final allAudioFiles = <Map<String, dynamic>>[];
    int page = 1;
    while (true) {
      final data = await _get(
        '/recitations/$recitationId/by_chapter/$surahNumber'
            '?page=$page&per_page=50',
      );
      final List files = data['audio_files'] as List;
      allAudioFiles.addAll(files.cast<Map<String, dynamic>>());
      final meta = data['meta'] as Map<String, dynamic>;
      if ((meta['current_page'] as int) >= (meta['total_pages'] as int)) break;
      page++;
    }

    // 2. Verse text for subtitles
    final verseData = await _get(
      '/verses/by_chapter/$surahNumber'
          '?language=en&fields=text_uthmani&per_page=300',
    );
    final List verses = verseData['verses'] as List;
    final textMap = <String, String>{
      for (final v in verses)
        v['verse_key'] as String: (v['text_uthmani'] as String? ?? ''),
    };

    // 3. Surah name for titles
    final chapData = await _get('/chapters/$surahNumber?language=en');
    final surahName = chapData['chapter']['name_simple'] as String;

    return allAudioFiles.map((f) {
      final verseKey = f['verse_key'] as String; // e.g. "2:5"
      final parts    = verseKey.split(':');
      final ayahNum  = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return MediaItemModel(
        id:         'ayah_${verseKey.replaceAll(':', '_')}',
        title:      '$surahName — Ayah $ayahNum',
        subtitle:   textMap[verseKey] ?? '',
        audioUrl:   f['url'] as String,
        artworkUrl: '',
        category:   MediaCategory.quran,
        extra: {
          'surahNumber': surahNumber,
          'ayahNumber':  ayahNum,
          'verseKey':    verseKey,
        },
      );
    }).toList();
  }

  // ── Fetch available chapter reciters from the API ─────────────────────────
  static Future<List<Map<String, dynamic>>> fetchChapterReciters() async {
    final data = await _get('/resources/chapter_reciters?language=en');
    return (data['reciters'] as List).cast<Map<String, dynamic>>();
  }
}