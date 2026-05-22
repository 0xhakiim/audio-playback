// lib/screens/library_screen.dart
// Shows ONLY what the user has explicitly liked or saved.
// No API calls here — reads directly from PlayerProvider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/media_item_model.dart';
import '../providers/player_provider.dart';
import '../services/podcast_api.dart';
import 'player_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Consumer<PlayerProvider>(
          builder: (context, player, _) {
            final liked  = player.likedItems;
            final shows  = player.savedShows;
            final isEmpty = liked.isEmpty && shows.isEmpty;

            return RefreshIndicator(
                onRefresh: () async {
                  // This triggers the repository to fetch from Firestore again
                  await player.loadLibrary();
                },
                color: const Color(0xFF1DB954), // Spotify Green
                backgroundColor: const Color(0xFF282828),
                child:CustomScrollView(
              slivers: [
                // ── App bar ──────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: const Color(0xFF121212),
                  floating: true,
                  elevation: 0,
                  title: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF1DB954),
                        child: Text('U', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Text('Your Library', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),

                // ── Empty state ──────────────────────────────────────────
                if (isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.library_music, size: 72, color: Colors.white12),
                          const SizedBox(height: 16),
                          const Text('Your library is empty',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Like surahs or save podcasts\nfrom Search or Home to add them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Find something to listen to'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Liked items section ──────────────────────────────────
                if (liked.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Liked',
                    count: liked.length,
                    icon: Icons.favorite,
                    iconColor: const Color(0xFF1DB954),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _MediaTile(
                        item: liked[i],
                        onTap: () {
                          player.playItem(liked[i], playlist: liked);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                        },
                        onLike: () => player.toggleLike(liked[i]),
                        isLiked: true,
                      ),
                      childCount: liked.length,
                    ),
                  ),
                ],

                // ── Saved podcast shows section ──────────────────────────
                if (shows.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Saved Podcasts',
                    count: shows.length,
                    icon: Icons.mic,
                    iconColor: const Color(0xFF9C27B0),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) => _ShowTile(
                        show: shows[i],
                        onTap: () => _playShow(context, player, shows[i]),
                        onUnsave: () => player.toggleSaveShow(shows[i]),
                      ),
                      childCount: shows.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ));
          },
        ),
      ),
    );
  }

  Future<void> _playShow(
      BuildContext context,
      PlayerProvider player,
      PodcastShow show,
      ) async {
    try {
      final episodes = await PodcastApiService.fetchEpisodes(show.id);
      if (episodes.isNotEmpty && context.mounted) {
        player.playItem(episodes.first, playlist: episodes);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load episodes: $e'),
          backgroundColor: const Color(0xFF282828),
        ));
      }
    }
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  const _SectionHeader({required this.title, required this.count, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('$count',
                style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Liked media tile ───────────────────────────────────────────────────────────

class _MediaTile extends StatelessWidget {
  final MediaItemModel item;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  const _MediaTile({required this.item, required this.onTap, required this.onLike, required this.isLiked});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: item.artworkUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: item.artworkUrl, width: 56, height: 56, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _fallback(Icons.music_note))
            : _fallback(Icons.music_note),
      ),
      title: Text(item.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(item.subtitle,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: Icon(Icons.favorite, color: const Color(0xFF1DB954), size: 20),
        onPressed: onLike,
        tooltip: 'Unlike',
      ),
      onTap: onTap,
    );
  }

  Widget _fallback(IconData icon) => Container(
      width: 56, height: 56, color: const Color(0xFF282828),
      child: Icon(icon, color: Colors.white30, size: 24));
}

// ── Saved podcast show tile ────────────────────────────────────────────────────

class _ShowTile extends StatelessWidget {
  final PodcastShow show;
  final VoidCallback onTap;
  final VoidCallback onUnsave;
  const _ShowTile({required this.show, required this.onTap, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: show.artworkUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: show.artworkUrl, width: 56, height: 56, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _fallback())
            : _fallback(),
      ),
      title: Text(show.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${show.author} • ${show.episodeCount} episodes',
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.bookmark_remove, color: Color(0xFF9C27B0), size: 20),
        onPressed: onUnsave,
        tooltip: 'Remove from library',
      ),
      onTap: onTap,
    );
  }

  Widget _fallback() => Container(
      width: 56, height: 56, color: const Color(0xFF282828),
      child: const Icon(Icons.mic, color: Colors.white30, size: 24));
}