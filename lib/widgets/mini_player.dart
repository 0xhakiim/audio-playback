// lib/widgets/mini_player.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kCard    = Color(0xFF1C1710);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasSong) return const SizedBox.shrink();
        final item = player.currentItem!;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const PlayerScreen(),
              transitionsBuilder: (_, a, __, child) => SlideTransition(
                position: Tween(
                    begin: const Offset(0, 1), end: Offset.zero)
                    .animate(
                    CurvedAnimation(parent: a, curve: Curves.easeOut)),
                child: child,
              ),
            ),
          ),
          child: Container(
            height: 68,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 0.5),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        // Artwork with gold ring when playing
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (player.isPlaying)
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: _kGold.withOpacity(0.4),
                                      width: 1.5),
                                ),
                              ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.artworkUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                  imageUrl: item.artworkUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _artFallback())
                                  : _artFallback(),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Track info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                    color: _kCream,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                    color: _kDim, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Like button
                        IconButton(
                          icon: Icon(
                            item.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: item.isLiked ? _kGold : _kDim,
                            size: 20,
                          ),
                          onPressed: () => player.toggleLike(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),

                        // Play/Pause — gold when playing
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: player.isPlaying
                                ? _kGold
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: player.isPlaying
                                ? null
                                : Border.all(color: _kBorder),
                          ),
                          child: IconButton(
                            icon: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: player.isPlaying ? _kBg : _kMuted,
                              size: 20,
                            ),
                            onPressed: player.togglePlayPause,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // Skip next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded,
                              color: _kMuted, size: 26),
                          onPressed: player.skipNext,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ),
                ),

                // Gold progress bar at bottom
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  child: LinearProgressIndicator(
                    value: player.progress,
                    backgroundColor: _kBorder,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(_kGold),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _artFallback() => Container(
      width: 44,
      height: 44,
      color: _kCard,
      child: const Icon(Icons.music_note_rounded, size: 18, color: _kDim));
}