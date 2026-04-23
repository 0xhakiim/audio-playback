// lib/widgets/mini_player.dart
// Compact player bar shown above the BottomNavigationBar when a song is loaded

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/player_provider.dart';
import '../../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  void _openPlayer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const PlayerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        // Only render if there's a song loaded
        if (!player.hasSong) return const SizedBox.shrink();

        final song = player.currentSong!;

        return GestureDetector(

          onTap: () {
            // Tap → open full player
            _openPlayer(context);
          },

          // Swipe down to dismiss
          onVerticalDragEnd: (details) {

            if (details.primaryVelocity != null ) {
              if(details.primaryVelocity! > 200){
              // Swipe down — stop playback
              // player.stop(); // TODO: implement in PlayerProvider
              }
              if (details.primaryVelocity! < -200){
                _openPlayer(context);
              }
            }
          },
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [Container(
                width: 30,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
                // ── Main Row ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Album art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: song.albumArt,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFF535353),
                              child: const Icon(Icons.music_note, size: 18, color: Colors.white30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Song info (scrolling title if too long)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                style: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Like button
                        IconButton(
                          icon: Icon(
                            song.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: song.isLiked ? const Color(0xFF1DB954) : Colors.white,
                            size: 20,
                          ),
                          onPressed: () => player.toggleLike(song),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),

                        // Play / Pause button
                        IconButton(
                          icon: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: player.togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),

                        // Skip next button
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

                // ── Progress Line ────────────────────────────────────────
                // Thin progress indicator at the very bottom of the mini player
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: LinearProgressIndicator(
                    value: player.progress,
                    backgroundColor: const Color(0xFF404040),
                    color: Colors.white,
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
}