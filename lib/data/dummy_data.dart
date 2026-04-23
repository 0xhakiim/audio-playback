// lib/data/dummy_data.dart
// Mock data for development. Replace with real API or local files later.

import '../models/song.dart';

// Using placeholder image service for album art
const _imgBase = 'https://picsum.photos/seed';

// ── Songs ────────────────────────────────────────────────────────────────────

final List<Song> dummySongs = [
  Song(
    id: '1',
    title: 'Midnight City',
    artist: 'M83',
    albumArt: '$_imgBase/m83/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    duration: const Duration(minutes: 4, seconds: 3),
  ),
  Song(
    id: '2',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    albumArt: '$_imgBase/weeknd/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    duration: const Duration(minutes: 3, seconds: 22),
  ),
  Song(
    id: '3',
    title: 'Levitating',
    artist: 'Dua Lipa',
    albumArt: '$_imgBase/dualipa/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    duration: const Duration(minutes: 3, seconds: 41),
    isLiked: true,
  ),
  Song(
    id: '4',
    title: 'Watermelon Sugar',
    artist: 'Harry Styles',
    albumArt: '$_imgBase/harry/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    duration: const Duration(minutes: 2, seconds: 54),
  ),
  Song(
    id: '5',
    title: 'Stay',
    artist: 'The Kid LAROI',
    albumArt: '$_imgBase/laroi/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    duration: const Duration(minutes: 2, seconds: 21),
    isLiked: true,
  ),
  Song(
    id: '6',
    title: 'Peaches',
    artist: 'Justin Bieber',
    albumArt: '$_imgBase/bieber/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    duration: const Duration(minutes: 3, seconds: 18),
  ),
  Song(
    id: '7',
    title: 'Good 4 U',
    artist: 'Olivia Rodrigo',
    albumArt: '$_imgBase/olivia/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    duration: const Duration(minutes: 2, seconds: 58),
  ),
  Song(
    id: '8',
    title: 'Montero',
    artist: 'Lil Nas X',
    albumArt: '$_imgBase/lilnas/300/300',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    duration: const Duration(minutes: 2, seconds: 17),
  ),
];

// ── Playlists ─────────────────────────────────────────────────────────────────

final List<Playlist> dummyPlaylists = [
  Playlist(
    id: 'p1',
    name: 'Chill Vibes',
    description: 'Relaxed beats for any time of day',
    coverImage: '$_imgBase/chill/300/300',
    songs: [dummySongs[0], dummySongs[2], dummySongs[4], dummySongs[6]],
  ),
  Playlist(
    id: 'p2',
    name: 'Top Hits 2024',
    description: 'The biggest songs right now',
    coverImage: '$_imgBase/hits/300/300',
    songs: dummySongs,
  ),
  Playlist(
    id: 'p3',
    name: 'Workout Mix',
    description: 'High energy tracks to keep you moving',
    coverImage: '$_imgBase/workout/300/300',
    songs: [dummySongs[1], dummySongs[3], dummySongs[5], dummySongs[7]],
  ),
  Playlist(
    id: 'p4',
    name: 'Late Night Drive',
    description: 'Atmospheric tunes for the road',
    coverImage: '$_imgBase/drive/300/300',
    songs: [dummySongs[0], dummySongs[1], dummySongs[6]],
  ),
  Playlist(
    id: 'p5',
    name: 'Morning Coffee',
    description: 'Ease into the day',
    coverImage: '$_imgBase/coffee/300/300',
    songs: [dummySongs[2], dummySongs[4], dummySongs[7]],
  ),
];

// ── Search Categories ─────────────────────────────────────────────────────────

class SearchCategory {
  final String name;
  final int color; // ARGB int for Color()
  final String imageUrl;

  const SearchCategory({
    required this.name,
    required this.color,
    required this.imageUrl,
  });
}

final List<SearchCategory> searchCategories = [
  SearchCategory(name: 'Pop', color: 0xFF1DB954, imageUrl: '$_imgBase/pop/120/120'),
  SearchCategory(name: 'Hip-Hop', color: 0xFFFF6B35, imageUrl: '$_imgBase/hiphop/120/120'),
  SearchCategory(name: 'Rock', color: 0xFFE91E63, imageUrl: '$_imgBase/rock/120/120'),
  SearchCategory(name: 'Electronic', color: 0xFF9C27B0, imageUrl: '$_imgBase/edm/120/120'),
  SearchCategory(name: 'R&B', color: 0xFFFF9800, imageUrl: '$_imgBase/rnb/120/120'),
  SearchCategory(name: 'Jazz', color: 0xFF00BCD4, imageUrl: '$_imgBase/jazz/120/120'),
  SearchCategory(name: 'Latin', color: 0xFFF44336, imageUrl: '$_imgBase/latin/120/120'),
  SearchCategory(name: 'Classical', color: 0xFF607D8B, imageUrl: '$_imgBase/classical/120/120'),
  SearchCategory(name: 'Podcasts', color: 0xFF795548, imageUrl: '$_imgBase/podcast/120/120'),
  SearchCategory(name: 'Mood', color: 0xFF3F51B5, imageUrl: '$_imgBase/mood/120/120'),
];