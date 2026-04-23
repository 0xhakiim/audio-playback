// lib/screens/home_screen.dart
// Home tab — shows greeting, recently played, featured playlist, and "Made for you"

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/song.dart';
import '../data/dummy_data.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            title: Text(
              _greeting,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: [
              // Notification bell
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              // Settings / clock icon
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () {},
              ),
              // Profile avatar
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {},
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF1DB954),
                    child: Text('U', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quick Access Grid (recent playlists) ──────────────────
                _QuickAccessGrid(playlists: dummyPlaylists.take(6).toList()),
                const SizedBox(height: 28),

                // ── Featured Playlist ─────────────────────────────────────
                _SectionHeader(title: 'Featured today'),
                _FeaturedPlaylist(playlist: dummyPlaylists[1]),
                const SizedBox(height: 28),

                // ── Made For You (horizontal scroll) ─────────────────────
                _SectionHeader(title: 'Made for you'),
                _PlaylistCarousel(playlists: dummyPlaylists),
                const SizedBox(height: 28),

                // ── Recently Played songs ─────────────────────────────────
                _SectionHeader(title: 'Recently played'),
                _SongCarousel(songs: dummySongs),
                const SizedBox(height: 28),

                // ── New Releases ──────────────────────────────────────────
                _SectionHeader(title: 'New releases'),
                _PlaylistCarousel(playlists: dummyPlaylists.reversed.toList()),
                const SizedBox(height: 100), // bottom padding for mini player
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Access Grid ─────────────────────────────────────────────────────────
// Shows 2 columns of recently played items at the top

class _QuickAccessGrid extends StatelessWidget {
  final List<Playlist> playlists;
  const _QuickAccessGrid({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _QuickAccessCard(playlist: playlist);
        },
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final Playlist playlist;
  const _QuickAccessCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Play the first song in this playlist
        if (playlist.songs.isNotEmpty) {
          context.read<PlayerProvider>().playSong(
            playlist.songs.first,
            playlist: playlist.songs,
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Playlist cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: CachedNetworkImage(
                imageUrl: playlist.coverImage,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF535353),
                  child: const Icon(Icons.music_note, size: 20, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Playlist name
            Expanded(
              child: Text(
                playlist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          Text(
            'See all',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFB3B3B3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured Playlist Card ────────────────────────────────────────────────────

class _FeaturedPlaylist extends StatelessWidget {
  final Playlist playlist;
  const _FeaturedPlaylist({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (playlist.songs.isNotEmpty) {
          context.read<PlayerProvider>().playSong(
            playlist.songs.first,
            playlist: playlist.songs,
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: playlist.coverImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.music_note, size: 64, color: Colors.white30),
                ),
              ),
            ),
            // Gradient overlay for text readability
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
            // Text overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Play button
            Positioned(
              bottom: 12,
              right: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF1DB954),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Playlist Carousel (horizontal scroll) ────────────────────────────────────

class _PlaylistCarousel extends StatelessWidget {
  final List<Playlist> playlists;
  const _PlaylistCarousel({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return GestureDetector(
            onTap: () {
              if (playlist.songs.isNotEmpty) {
                context.read<PlayerProvider>().playSong(
                  playlist.songs.first,
                  playlist: playlist.songs,
                );
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
              }
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: playlist.coverImage,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 140,
                        height: 140,
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.music_note, size: 48, color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    playlist.description,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Song Carousel (horizontal scroll) ────────────────────────────────────────

class _SongCarousel extends StatelessWidget {
  final List<Song> songs;
  const _SongCarousel({required this.songs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () {
              context.read<PlayerProvider>().playSong(song, playlist: songs);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: song.albumArt,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 140,
                        height: 140,
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.music_note, size: 48, color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}