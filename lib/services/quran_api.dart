// lib/services/quran_api.dart
// Fetches Quran surahs and audio recitations from the official Quran.com v4 API
// 100% free — no API key required for public endpoints.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item_model.dart';

// Popular Reciters from Quran.com: display name → v4 Reciter ID
const Map<String, int> kReciters = {
  'Mishary Alafasy': 7,
  'Abdul Basit (Murattal)': 1,
  'Hudhaify': 4,
  'Minshawi (Murattal)': 12,
};

const int kDefaultReciterId = 7; // Mishary Alafasy

class QuranApiService {
  static const String _base = 'https://api.quran.com/api/v4';

  // ── Fetch all 114 Surahs ───────────────────────────────────────────────────
  // Returns high-quality surah structural data with native fields mapped to MediaItemModel
  static Future<List<MediaItemModel>> fetchSurahs() async {
    final url = Uri.parse('$_base/chapters?language=en');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load surahs from Quran.com: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List chapters = data['chapters'] as List;

    return chapters.map((c) {
      final int number = c['id'] as int;
      // Format number cleanly with leading zeros for reliable caching/artwork referencing
      final String paddedNumber = number.toString().padLeft(3, '0');

      return MediaItemModel(
        id: 'surah_$number',
        title: '$paddedNumber. ${c['name_simple']}',
        subtitle: (c['translated_name'] as Map<String, dynamic>)['name'] as String? ?? '',
        audioUrl: '', // Will be dynamically selected or loaded full-surah via fetchSurahAudio
        artworkUrl: 'https://quran.com/images/quran-share-image.png', // Fallback brand image
        category: MediaCategory.quran,
        extra: {
          'number': number,
          'arabicName': c['name_arabic'] as String? ?? '',
          'revelationType': c['revelation_place'] as String? ?? '',
          'versesCount': c['verses_count'] as int? ?? 0,
        },
      )..arabicTitle = c['name_arabic'] as String?;
    }).toList();
  }

  // ── Fetch complete Surah audio file ───────────────────────────────────────
  // Resolves the high-fidelity streaming audio URL directly from Quran.com's CDN infrastructure
  static Future<String> fetchSurahAudioUrl(int surahNumber, {int reciterId = kDefaultReciterId}) async {
    final url = Uri.parse('$_base/chapter_recitations/$reciterId/$surahNumber');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve surah audio: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final audioFile = data['audio_file'] as Map<String, dynamic>?;

    if (audioFile == null || audioFile['audio_url'] == null) {
      throw Exception('Audio file metadata missing for surah $surahNumber');
    }

    return audioFile['audio_url'] as String;
  }

  // ── Fetch Surah with valid audio attachments attached on the fly ───────────
  static Future<List<MediaItemModel>> fetchSurahsWithAudio({int reciterId = kDefaultReciterId}) async {
    // 1. Get structural items
    final surahs = await fetchSurahs();

    // 2. Fetch bulk streaming paths for this specific reciter
    final audioUrl = Uri.parse('$_base/chapter_recitations/$reciterId');
    final response = await http.get(audioUrl).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List audioFiles = data['audio_files'] as List;

      // Match up arrays securely via structural chapter indexation
      for (var file in audioFiles) {
        final int chapterId = file['chapter_id'] as int;
        final String fileUrl = file['audio_url'] as String;

        final matchIndex = surahs.indexWhere((s) => s.extra['number'] == chapterId);
        if (matchIndex != -1) {
          surahs[matchIndex] = MediaItemModel(
            id: surahs[matchIndex].id,
            title: surahs[matchIndex].title,
            subtitle: surahs[matchIndex].subtitle,
            audioUrl: fileUrl,
            artworkUrl: surahs[matchIndex].artworkUrl,
            category: surahs[matchIndex].category,
            extra: surahs[matchIndex].extra,
          )..arabicTitle = surahs[matchIndex].arabicTitle;
        }
      }
    }

    return surahs;
  }
}