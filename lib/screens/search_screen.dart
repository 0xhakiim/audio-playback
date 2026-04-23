// lib/screens/search_screen.dart
// Search tab — search bar at top + browsable genre categories grid

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/dummy_data.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = [];
        _isSearching = false;
      } else {
        _isSearching = true;
        // Simple in-memory search — filter by title or artist
        _results = dummySongs
            .where((s) =>
        s.title.toLowerCase().contains(query.toLowerCase()) ||
            s.artist.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Title ───────────────────────────────────────────────────
              Text('Search', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),

              // ── Search Bar ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'What do you want to listen to?',
                    hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.black, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Results or Categories ───────────────────────────────────
              Expanded(
                child: _isSearching ? _buildResults() : _buildCategories(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Results List ───────────────────────────────────────────────────

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No results for "${_searchController.text}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final song = _results[index];
        return _SongListTile(song: song, allSongs: _results);
      },
    );
  }

  // ── Category Grid ─────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse all',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: searchCategories.length,
            itemBuilder: (context, index) {
              final category = searchCategories[index];
              return _CategoryCard(category: category);
            },
          ),
        ),
      ],
    );
  }
}

// ── Song list tile (used in search results) ───────────────────────────────────

class _SongListTile extends StatelessWidget {
  final Song song;
  final List<Song> allSongs;
  const _SongListTile({required this.song, required this.allSongs});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: song.albumArt,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 52,
            height: 52,
            color: const Color(0xFF282828),
            child: const Icon(Icons.music_note, size: 24, color: Colors.white30),
          ),
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
        onPressed: () {},
      ),
      onTap: () {
        context.read<PlayerProvider>().playSong(song, playlist: allSongs);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      },
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final SearchCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to a genre playlist screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Browsing ${category.name}'),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF282828),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background color
            Container(color: Color(category.color)),
            // Background image (bottom-right, rotated like Spotify)
            Positioned(
              bottom: -8,
              right: -8,
              child: Transform.rotate(
                angle: 0.4,
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
            // Category name
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}