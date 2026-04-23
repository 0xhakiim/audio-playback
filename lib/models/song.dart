// lib/models/song.dart
// Data models for the app

class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArt; // URL or local asset path
  final String audioUrl; // URL or local file path
  final Duration duration;
  bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.audioUrl,
    required this.duration,
    this.isLiked = false,
  });
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final String coverImage; // URL or local asset path
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImage,
    required this.songs,
  });

  int get totalDuration =>
      songs.fold(0, (sum, s) => sum + s.duration.inSeconds);
}