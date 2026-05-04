// lib/screens/player_screen.dart
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
      body: Consumer<PlayerProvider>(
        builder: (context, player, _) {
          final item = player.currentItem;
          if (item == null) return const SizedBox.shrink();

          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),

                // Album Art
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: _AlbumArt(imageUrl: item.artworkUrl, isPlaying: player.isPlaying),
                  ),
                ),

                // Song Info + Like
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(item.subtitle,
                                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 15),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          item.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: item.isLiked ? const Color(0xFF1DB954) : Colors.white,
                          size: 26,
                        ),
                        onPressed: () => player.toggleLike(item),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Progress Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Slider(value: player.progress, onChanged: player.seekTo),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(player.position), style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                            Text(_fmt(player.duration), style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle, size: 22,
                            color: player.isShuffle ? const Color(0xFF1DB954) : Colors.white),
                        onPressed: player.toggleShuffle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 38),
                        onPressed: player.canSkipPrev ? player.skipPrev : null,
                      ),
                      GestureDetector(
                        onTap: player.togglePlayPause,
                        child: Container(
                          width: 68, height: 68,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black, size: 36),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 38),
                        onPressed: player.canSkipNext ? player.skipNext : null,
                      ),
                      IconButton(
                        icon: Icon(
                            player.isRepeatOne ? Icons.repeat_one : Icons.repeat,
                            size: 22,
                            color: player.isRepeating ? const Color(0xFF1DB954) : Colors.white),
                        onPressed: player.cycleRepeatMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.share_outlined, color: Color(0xFFB3B3B3), size: 20), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.queue_music, color: Color(0xFFB3B3B3), size: 20), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.devices, color: Color(0xFFB3B3B3), size: 20), onPressed: () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Row(
      children: [
        IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 30), onPressed: () => Navigator.pop(context)),
        const Expanded(
          child: Text('Now Playing', textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11, letterSpacing: 1.5)),
        ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    ),
  );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Album Art with scale animation ───────────────────────────────────────────

class _AlbumArt extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  const _AlbumArt({required this.imageUrl, required this.isPlaying});
  @override
  State<_AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<_AlbumArt> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _scale  = Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override void initState() { super.initState(); if (widget.isPlaying) _ctrl.forward(); }
  @override void didUpdateWidget(_AlbumArt old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) widget.isPlaying ? _ctrl.forward() : _ctrl.reverse();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: widget.imageUrl.isNotEmpty
          ? CachedNetworkImage(imageUrl: widget.imageUrl, fit: BoxFit.cover, width: double.infinity,
          errorWidget: (_, __, ___) => _placeholder())
          : _placeholder(),
    ),
  );

  Widget _placeholder() => Container(
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, size: 100, color: Colors.white24));
}