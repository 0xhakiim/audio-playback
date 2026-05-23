// lib/screens/player_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/player_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  Widget _buildResumeBanner(BuildContext context, PlayerProvider player) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withOpacity(0.15),
        border: Border.all(color: const Color(0xFF1DB954), width: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFF1DB954), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resume where you left off  •  ${_fmt(player.position)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: player.resumeSession,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1DB954),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: player.dismissRestoredSession,
            child: const Icon(Icons.close, color: Colors.white38, size: 16),
          ),
        ],
      ),
    );
  }
  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => Consumer<PlayerProvider>(
        builder: (context, player, _) {
          final queue = player.queue;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            builder: (_, scrollController) => Column(
              children: [
                // Handle + title
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    children: [
                      const Text('Up Next',
                          style: TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${queue.length} tracks',
                          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13)),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF333333)),
                // Track list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: queue.length,
                    itemBuilder: (_, i) {
                      final track = queue[i];
                      final isCurrent = i == player.currentIndex;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: track.artworkUrl.isNotEmpty
                              ? CachedNetworkImage(
                              imageUrl: track.artworkUrl,
                              width: 46, height: 46, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _queueArtPlaceholder())
                              : _queueArtPlaceholder(),
                        ),
                        title: Text(track.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF1DB954)
                                    : Colors.white,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14)),
                        subtitle: Text(track.subtitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFB3B3B3), fontSize: 12)),
                        trailing: isCurrent
                            ? const Icon(Icons.equalizer,
                            color: Color(0xFF1DB954), size: 20)
                            : null,
                        onTap: () {
                          player.jumpTo(i);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _queueArtPlaceholder() => Container(
      width: 46, height: 46,
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, size: 20, color: Colors.white24));
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
                if (player.sessionRestored) _buildResumeBanner(context, player),
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
                      IconButton(icon: const Icon(Icons.queue_music, color: Color(0xFFB3B3B3), size: 20), onPressed: () => _showQueueSheet(context)),
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