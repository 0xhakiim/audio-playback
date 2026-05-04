// lib/services/podcast_api.dart
// Search podcasts and fetch episodes using the iTunes Search API.
// 100% free — no API key required.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item_model.dart';

class PodcastApiService {
  static const _itunesSearch  = 'https://itunes.apple.com/search';
  static const _itunesLookup  = 'https://itunes.apple.com/lookup';

  // ── Search podcasts by keyword ─────────────────────────────────────────────
  // Returns a list of podcast shows (not episodes yet).
  static Future<List<PodcastShow>> searchPodcasts(String query, {int limit = 20}) async {
    final url = Uri.parse(
      '$_itunesSearch?media=podcast&term=${Uri.encodeQueryComponent(query)}&limit=$limit',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('iTunes search failed: ${response.statusCode}');
    }

    final data     = jsonDecode(response.body);
    final List results = data['results'];

    return results.map((r) => PodcastShow(
      id:          r['collectionId'].toString(),
      name:        r['collectionName'] as String? ?? '',
      author:      r['artistName'] as String? ?? '',
      artworkUrl:  r['artworkUrl600'] as String? ?? r['artworkUrl100'] as String? ?? '',
      feedUrl:     r['feedUrl'] as String? ?? '',
      genre:       (r['genres'] as List?)?.first as String? ?? '',
      episodeCount: r['trackCount'] as int? ?? 0,
    )).toList();
  }

  // ── Fetch episodes for a podcast using its iTunes collection ID ──────────
  // Uses the iTunes lookup endpoint which returns episodes as tracks.
  static Future<List<MediaItemModel>> fetchEpisodes(String collectionId, {int limit = 30}) async {
    final url = Uri.parse(
      '$_itunesLookup?id=$collectionId&media=podcast&entity=podcastEpisode&limit=$limit',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('iTunes lookup failed: ${response.statusCode}');
    }

    final data    = jsonDecode(response.body);
    final List results = data['results'];

    // First result is the show itself — skip it
    final episodes = results.skip(1).toList();

    return episodes.map((e) {
      final millis    = e['trackTimeMillis'] as int? ?? 0;
      final duration  = Duration(milliseconds: millis);

      return MediaItemModel(
        id:          'ep_${e['trackId']}',
        title:       e['trackName'] as String? ?? 'Untitled Episode',
        subtitle:    e['collectionName'] as String? ?? '',
        audioUrl:    e['episodeUrl'] as String? ?? '',
        artworkUrl:  e['artworkUrl600'] as String? ??
            e['artworkUrl160'] as String? ?? '',
        category:    MediaCategory.podcast,
        duration:    duration,
        extra: {
          'description':   e['description'] as String? ?? '',
          'releaseDate':   e['releaseDate'] as String? ?? '',
          'episodeNumber': e['episodeNumber'] ?? 0,
        },
      );
    }).where((e) => e.audioUrl.isNotEmpty).toList();
  }

  // ── Get curated popular podcasts (no search) ─────────────────────────────
  // Uses iTunes top charts — returns well-known podcasts across categories.
  static Future<List<PodcastShow>> fetchTopPodcasts({String genre = 'news'}) async {
    // Predefined popular search terms as a fallback for "browse" tabs
    const popularTerms = ['technology', 'true crime', 'comedy', 'history', 'science'];
    final term = popularTerms[DateTime.now().second % popularTerms.length];
    return searchPodcasts(term, limit: 15);
  }
}

// ── PodcastShow model ─────────────────────────────────────────────────────────
// Represents a podcast show (not an episode).

class PodcastShow {
  final String id;
  final String name;
  final String author;
  final String artworkUrl;
  final String feedUrl;
  final String genre;
  final int    episodeCount;

  const PodcastShow({
    required this.id,
    required this.name,
    required this.author,
    required this.artworkUrl,
    required this.feedUrl,
    required this.genre,
    required this.episodeCount,
  });
}