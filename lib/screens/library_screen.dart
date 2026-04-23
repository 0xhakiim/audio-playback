// lib/screens/library_screen.dart
// Library tab — user's playlists, liked songs, and albums

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/dummy_data.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';

enum LibraryFilter { all, playlists, artists, albums }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────
            _buildTopBar(context),

            // ── Filter Chips ─────────────────────────────────────────────
            _buildFilters(),

            // ── Library Content ──────────────────────────────────────────
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      // FAB to create a new playlist
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreatePlaylistDialog(context);
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF1DB954),
            child: Text('U', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text('Your Library', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          // Toggle grid/list view
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: LibraryFilter.values.map((f) {
          final label = {
            LibraryFilter.all: 'All',
            LibraryFilter.playlists: 'Playlists',
            LibraryFilter.artists: 'Artists',
            LibraryFilter.albums: 'Albums',
          }[f]!;

          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _filter = f),
              backgroundColor: const Color(0xFF282828),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    // Get liked songs
    final likedSongs = dummySongs.where((s) => s.isLiked).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        // ── Liked Songs ────────────────────────────────────────────────
        if (_filter == LibraryFilter.all || _filter == LibraryFilter.playlists)
          _LikedSongsCard(likedSongs: likedSongs),

        // ── Playlists ──────────────────────────────────────────────────
        if (_filter == LibraryFilter.all || _filter == LibraryFilter.playlists)
          ...dummyPlaylists.map((p) => _PlaylistListTile(playlist: p)),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Create playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }
}

// ── Liked Songs Card ──────────────────────────────────────────────────────────

class _LikedSongsCard extends StatelessWidget {
  final List<Song> likedSongs;
  const _LikedSongsCard({required this.likedSongs});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF450AF5), Color(0xFFC4EFD0)],
          ),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 28),
      ),
      title: const Text(
        'Liked Songs',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        'Playlist • ${likedSongs.length} songs',
        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
      ),
      onTap: () {
        if (likedSongs.isNotEmpty) {
          context.read<PlayerProvider>().playSong(likedSongs.first, playlist: likedSongs);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
        }
      },
    );
  }
}

// ── Playlist List Tile ────────────────────────────────────────────────────────

class _PlaylistListTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistListTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: playlist.coverImage,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: const Color(0xFF282828),
            child: const Icon(Icons.music_note, color: Colors.white30),
          ),
        ),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Playlist • ${playlist.songs.length} songs',
        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
        onPressed: () {},
      ),
      onTap: () {
        if (playlist.songs.isNotEmpty) {
          context.read<PlayerProvider>().playSong(
            playlist.songs.first,
            playlist: playlist.songs,
          );
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
        }
      },
    );
  }
}