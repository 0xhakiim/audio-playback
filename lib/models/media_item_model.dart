// lib/models/media_item_model.dart
// A unified model used by both the Quran and Podcast APIs.
// just_audio_background requires a MediaItem — we convert to it on the fly.

import 'package:just_audio_background/just_audio_background.dart' as jab;

enum MediaCategory { quran, podcast }

class MediaItemModel {
  final String        id;
  final String        title;
  final String        subtitle;   // artist / surah translation / podcast name
  final String        audioUrl;
  final String        artworkUrl;
  final MediaCategory category;
  final Duration      duration;
  bool                isLiked;
  final Map<String, dynamic> extra;

  String? arabicTitle; // category-specific fields

  MediaItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.audioUrl,
    required this.artworkUrl,
    required this.category,
    this.duration = Duration.zero,
    this.isLiked  = false,
    this.extra    = const {},
  });

  // Convert to just_audio_background MediaItem so the notification/lock screen
  // automatically show the correct title, artist, and artwork.
  jab.MediaItem toJabMediaItem() => jab.MediaItem(
    id:           audioUrl,   // just_audio uses the URL as the unique ID
    title:        title,
    artist:       subtitle,
    artUri:       artworkUrl.isNotEmpty ? Uri.parse(artworkUrl) : null,
    duration:     duration != Duration.zero ? duration : null,
    extras:       {'mediaId': id, 'category': category.name},
  );
  // In media_item_model.dart

  Map<String, dynamic> toJson() => {
    'id':         id,
    'title':      title,
    'subtitle':   subtitle,
    'audioUrl':   audioUrl,
    'artworkUrl': artworkUrl,
    'isLiked':    isLiked,
  };

  factory MediaItemModel.fromJson(Map<String, dynamic> json) => MediaItemModel(
    id:         json['id']         as String,
    title:      json['title']      as String,
    subtitle:   json['subtitle']   as String,
    audioUrl:   json['audioUrl']   as String,
    artworkUrl: json['artworkUrl'] as String,
    isLiked:    json['isLiked']    as bool? ?? false, category: MediaCategory.quran,
  );
}