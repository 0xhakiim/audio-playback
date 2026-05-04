// lib/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasSong) return const SizedBox.shrink();
        final item = player.currentItem!;

        return GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, a, __) => const PlayerScreen(),
            transitionsBuilder: (_, a, __, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: child,
            ),
          )),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Artwork
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.artworkUrl.isNotEmpty
                              ? CachedNetworkImage(imageUrl: item.artworkUrl, width: 44, height: 44, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _artFallback())
                              : _artFallback(),
                        ),
                        const SizedBox(width: 10),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(item.subtitle, style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // Like
                        IconButton(
                          icon: Icon(item.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: item.isLiked ? const Color(0xFF1DB954) : Colors.white, size: 20),
                          onPressed: () => player.toggleLike(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        // Play/Pause
                        IconButton(
                          icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                          onPressed: player.togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                        // Skip
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                          onPressed: player.skipNext,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                  ),
                ),
                // Progress bar
                ClipRRect(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                  child: LinearProgressIndicator(value: player.progress, backgroundColor: const Color(0xFF404040), color: Colors.white, minHeight: 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _artFallback() => Container(
      width: 44, height: 44, color: const Color(0xFF535353),
      child: const Icon(Icons.music_note, size: 18, color: Colors.white30));
}