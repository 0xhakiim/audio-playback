// lib/screens/player_screen.dart
// Full-screen Now Playing UI with album art, playback controls, and progress bar

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/player_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      body:
      GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child:Consumer<PlayerProvider>(

        builder: (context, player, _) {
          final song = player.currentSong;
          if (song == null) return const SizedBox.shrink();
          return SafeArea(
            child: Column(
              children: [
                // ── Top Bar ─────────────────────────────────────────────
                _buildTopBar(context),

                // ── Album Art ───────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: _AlbumArt(
                      imageUrl: song.albumArt,
                      isPlaying: player.isPlaying,
                    ),
                  ),
                ),

                // ── Song Info + Like ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Song title and artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 15,
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
                          size: 26,
                        ),
                        onPressed: () => player.toggleLike(song),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Progress Slider ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Slider(
                        value: player.progress,
                        onChanged: (v) => player.seekTo(v),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(player.position),
                              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                            ),
                            Text(
                              _formatDuration(player.duration),
                              style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Playback Controls ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: player.isShuffle ? const Color(0xFF1DB954) : Colors.white,
                          size: 22,
                        ),
                        onPressed: player.toggleShuffle,
                      ),
                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 38),
                        onPressed: player.canSkipPrev ? player.skipPrev : null,
                      ),
                      // Play / Pause (big button)
                      GestureDetector(
                        onTap: player.togglePlayPause,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 36,
                          ),
                        ),
                      ),
                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 38),
                        onPressed: player.canSkipNext ? player.skipNext : null,
                      ),
                      // Repeat
                      IconButton(
                        icon: Icon(
                          player.repeatMode == PlayerRepeatMode.repeatOne
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: player.repeatMode != PlayerRepeatMode.none
                              ? const Color(0xFF1DB954)
                              : Colors.white,
                          size: 22,
                        ),
                        onPressed: player.cycleRepeatMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Bottom Row (share, queue, device) ────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Color(0xFFB3B3B3), size: 20),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music, color: Color(0xFFB3B3B3), size: 20),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.devices, color: Color(0xFFB3B3B3), size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    ),);
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Chevron down to dismiss
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          // Currently playing label
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Now Playing',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Options menu
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ── Album Art Widget ──────────────────────────────────────────────────────────

class _AlbumArt extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  const _AlbumArt({required this.imageUrl, required this.isPlaying});

  @override
  State<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<_AlbumArt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.isPlaying) _controller.forward();
  }

  @override
  void didUpdateWidget(_AlbumArt old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFF282828),
            child: const Icon(Icons.music_note, size: 100, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}