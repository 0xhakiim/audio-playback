// lib/screens/library_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/media_item_model.dart';
import '../providers/player_provider.dart';
import '../services/podcast_api.dart';
import '../widgets/dynamic_profile_avatar.dart';
import 'player_screen.dart';
import 'profile_screen.dart';

const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kCard    = Color(0xFF1C1710);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);
const _kGreen   = Color(0xFF4A7C59);
const _kPurple  = Color(0xFF8B6B9A);

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GlobalKey<DynamicProfileAvatarState> _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Consumer<PlayerProvider>(
          builder: (context, player, _) {
            final liked   = player.likedItems;
            final shows   = player.savedShows;
            final isEmpty = liked.isEmpty && shows.isEmpty;

            return RefreshIndicator(
              onRefresh: () async => player.loadLibrary(),
              color: _kGold,
              backgroundColor: _kSurface,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: _kBg,
                    floating: true,
                    elevation: 0,
                    title: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            );
                            _avatarKey.currentState?.loadData();
                          },
                          child:
                          DynamicProfileAvatar(key: _avatarKey, radius: 16),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Your Library',
                              style: TextStyle(
                                color: _kCream,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'مكتبتك',
                              style: TextStyle(
                                  color: _kGold, fontSize: 11, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: _kSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: _kBorder),
                              ),
                              child: const Icon(Icons.library_music,
                                  size: 40, color: _kDim),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Your library is empty',
                              style: TextStyle(
                                  color: _kCream,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Like surahs or save podcasts\nto build your collection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _kMuted, fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 28),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kGold,
                                side: const BorderSide(color: _kGold),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Explore content'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (liked.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Liked',
                      arabicTitle: 'المفضلة',
                      count: liked.length,
                      icon: Icons.favorite_rounded,
                      iconColor: _kGold,
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => _MediaTile(
                          item: liked[i],
                          onTap: () {
                            player.playItem(liked[i], playlist: liked);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PlayerScreen()));
                          },
                          onLike: () => player.toggleLike(liked[i]),
                          isLiked: true,
                        ),
                        childCount: liked.length,
                      ),
                    ),
                  ],

                  if (shows.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Saved Podcasts',
                      arabicTitle: 'بودكاست',
                      count: shows.length,
                      icon: Icons.mic_rounded,
                      iconColor: _kPurple,
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
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _playShow(
      BuildContext context, PlayerProvider player, PodcastShow show) async {
    try {
      final episodes = await PodcastApiService.fetchEpisodes(show.id);
      if (episodes.isNotEmpty && context.mounted) {
        player.playItem(episodes.first, playlist: episodes);
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load episodes: $e',
              style: const TextStyle(color: _kCream)),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _kBorder),
          ),
        ));
      }
    }
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String arabicTitle;
  final int count;
  final IconData icon;
  final Color iconColor;
  const _SectionHeader({
    required this.title,
    required this.arabicTitle,
    required this.count,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _kCream,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Text(arabicTitle,
                    style: TextStyle(
                        color: iconColor, fontSize: 10, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Text('$count',
                  style: const TextStyle(color: _kDim, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Liked media tile ───────────────────────────────────────────────────────

class _MediaTile extends StatelessWidget {
  final MediaItemModel item;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final bool isLiked;
  const _MediaTile(
      {required this.item,
        required this.onTap,
        required this.onLike,
        required this.isLiked});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: item.artworkUrl.isNotEmpty
              ? CachedNetworkImage(
              imageUrl: item.artworkUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback(Icons.music_note))
              : _fallback(Icons.music_note),
        ),
      ),
      title: Text(item.title,
          style: const TextStyle(
              color: _kCream, fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(item.subtitle,
          style: const TextStyle(color: _kDim, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.favorite_rounded, color: _kGold, size: 20),
        onPressed: onLike,
        tooltip: 'Unlike',
      ),
      onTap: onTap,
    );
  }

  Widget _fallback(IconData icon) => Container(
      width: 56,
      height: 56,
      color: _kCard,
      child: Icon(icon, color: _kDim, size: 24));
}

// ── Saved show tile ────────────────────────────────────────────────────────

class _ShowTile extends StatelessWidget {
  final PodcastShow show;
  final VoidCallback onTap;
  final VoidCallback onUnsave;
  const _ShowTile(
      {required this.show, required this.onTap, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: show.artworkUrl.isNotEmpty
              ? CachedNetworkImage(
              imageUrl: show.artworkUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback())
              : _fallback(),
        ),
      ),
      title: Text(show.name,
          style: const TextStyle(
              color: _kCream, fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '${show.author} · ${show.episodeCount} episodes',
          style: const TextStyle(color: _kDim, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.bookmark_remove_rounded,
            color: _kPurple, size: 20),
        onPressed: onUnsave,
        tooltip: 'Remove from library',
      ),
      onTap: onTap,
    );
  }

  Widget _fallback() => Container(
      width: 56,
      height: 56,
      color: _kCard,
      child: const Icon(Icons.mic_rounded, color: _kDim, size: 24));
}