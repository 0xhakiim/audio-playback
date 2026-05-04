// lib/services/quran_api.dart
// Fetches Quran surahs and audio recitations from api.alquran.cloud
// 100% free — no API key required.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item_model.dart';

// Popular reciters and their edition identifiers on alquran.cloud
const Map<String, String> kReciters = {
  'Mishary Alafasy':   'ar.alafasy',
  'Abdul Basit':       'ar.abdulbasitmurattal',
  'Hudhaify':          'ar.hudhaify',
  'Minshawi':          'ar.minshawi',
};

class QuranApiService {
  static const _base = 'https://api.alquran.cloud/v1';

  // ── Fetch all 114 surahs as MediaItemModel list ───────────────────────────
  static Future<List<MediaItemModel>> fetchSurahs({
    String reciter = 'ar.alafasy',
  }) async {
    final url = Uri.parse('$_base/surah');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Quran surahs: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List surahs = data['data'];

    return surahs.map((s) {
      final number = s['number'] as int;
      return MediaItemModel(
        id:          'quran_$number',
        title:       '${s['englishName']} — ${s['name']}',
        subtitle:    '${s['englishNameTranslation']} • ${s['numberOfAyahs']} verses',
        // Audio URL pattern — each surah number maps to a direct mp3 stream
        audioUrl:    'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$number.mp3',
        // Artwork from the same CDN
        artworkUrl:  'https://api.alquran.cloud/v1/surah/$number/ar.alafasy',
        category:    MediaCategory.quran,
        extra: {
          'surahNumber':    number,
          'arabicName':     s['name'],
          'reciter':        reciter,
          'revelationType': s['revelationType'],
        },
      );
    }).toList();
  }

  // ── Fetch a single surah's ayahs with individual audio links ─────────────
  static Future<List<MediaItemModel>> fetchSurahAyahs(
      int surahNumber, {
        String reciter = 'ar.alafasy',
      }) async {
    final url = Uri.parse('$_base/surah/$surahNumber/$reciter');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load ayahs');
    }

    final data    = jsonDecode(response.body);
    final surah   = data['data'];
    final List ayahs = surah['ayahs'];
    final surahName  = surah['englishName'] as String;

    return ayahs.map((a) {
      return MediaItemModel(
        id:         'ayah_${a['number']}',
        title:      '$surahName — Ayah ${a['numberInSurah']}',
        subtitle:   a['text'] as String,
        audioUrl:   a['audio'] as String,
        artworkUrl: '',
        category:   MediaCategory.quran,
        extra: {
          'surahNumber': surahNumber,
          'ayahNumber':  a['numberInSurah'],
        },
      );
    }).toList();
  }
}