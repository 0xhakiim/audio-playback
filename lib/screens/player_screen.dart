// lib/screens/player_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────
// Background:   #0D0B08  (deep warm black)
// Surface:      #13100C
// Card:         #1C1710
// Border:       #2A241C
// Gold accent:  #C49A3C
// Cream text:   #F0EDE6
// Muted text:   #9B8A6A  /  #7A7060
// --------------------------------------------------------------------------

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/player_provider.dart';

// ── Brand palette constants ────────────────────────────────────────────────
const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kCard    = Color(0xFF1C1710);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double _dragOffset = 0;
  static const _kDismissThreshold = 120.0;

  void _onDragUpdate(DragUpdateDetails d) {
    if (d.delta.dy > 0) {
      setState(() => _dragOffset += d.delta.dy);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragOffset > _kDismissThreshold ||
        (d.primaryVelocity != null && d.primaryVelocity! > 800)) {
      Navigator.pop(context);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  // ── Queue bottom sheet ───────────────────────────────────────────────────
  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Row(
                    children: [
                      const Text('Up Next',
                          style: TextStyle(
                              color: _kCream,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Text('${queue.length} tracks',
                            style: const TextStyle(color: _kMuted, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Divider(color: _kBorder, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: queue.length,
                    itemBuilder: (_, i) {
                      final track = queue[i];
                      final isCurrent = i == player.currentIndex;
                      return ListTile(
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: isCurrent ? Border.all(color: _kGold, width: 1.5) : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: track.artworkUrl.isNotEmpty
                                ? CachedNetworkImage(
                                imageUrl: track.artworkUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _queueArtPlaceholder())
                                : _queueArtPlaceholder(),
                          ),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? _kGold : _kCream,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          track.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _kMuted, fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.equalizer, color: _kGold, size: 20)
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
      width: 46,
      height: 46,
      color: _kCard,
      child: const Icon(Icons.music_note, size: 20, color: _kDim));

  // ── Main build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final opacity = (1.0 - (_dragOffset / 300).clamp(0.0, 1.0));
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: AnimatedContainer(
        duration: _dragOffset == 0
            ? const Duration(milliseconds: 250)
            : Duration.zero,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Opacity(
          opacity: opacity,
          child: Scaffold(
            backgroundColor: _kBg,
            body: Consumer<PlayerProvider>(
              builder: (context, player, _) {
                final item = player.currentItem;
                if (item == null) return const SizedBox.shrink();

                return SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(context),

                      // ── Circular album art with rings ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _CircularArtwork(
                            imageUrl: item.artworkUrl,
                            isPlaying: player.isPlaying,
                          ),
                        ),
                      ),

                      // ── Track info ─────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: _kCream,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            // Arabic subtitle in gold (if present)
                            if (item.arabicTitle != null && item.arabicTitle!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  item.arabicTitle!,
                                  style: const TextStyle(color: _kGold, fontSize: 14),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: const TextStyle(color: _kMuted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // ── Progress slider ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _kGold,
                                inactiveTrackColor: _kBorder,
                                thumbColor: _kGold,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                overlayColor: _kGold.withOpacity(0.15),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: player.progress,
                                onChanged: player.seekTo,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_fmt(player.position),
                                      style: const TextStyle(color: _kDim, fontSize: 12, letterSpacing: 0.5)),
                                  Text(_fmt(player.duration),
                                      style: const TextStyle(color: _kDim, fontSize: 12, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Playback controls (flat rounded-rect buttons) ────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ControlButton(
                              icon: Icons.shuffle,
                              isActive: player.isShuffle,
                              onTap: player.toggleShuffle,
                            ),
                            _ControlButton(
                              icon: Icons.skip_previous,
                              isActive: false,
                              enabled: player.canSkipPrev,
                              onTap: player.canSkipPrev ? player.skipPrev : null,
                            ),
                            // Centre play/pause — slightly larger
                            _ControlButton(
                              icon: player.isPlaying ? Icons.pause : Icons.play_arrow,
                              isActive: false,
                              isLarge: true,
                              onTap: player.togglePlayPause,
                            ),
                            _ControlButton(
                              icon: Icons.skip_next,
                              isActive: false,
                              enabled: player.canSkipNext,
                              onTap: player.canSkipNext ? player.skipNext : null,
                            ),
                            _ControlButton(
                              icon: item.isLiked ? Icons.favorite : Icons.favorite_border,
                              isActive: item.isLiked,
                              onTap: () => player.toggleLike(item),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Inline "Up Next" queue ──────────────────────────────────
                      Expanded(
                        child: GestureDetector(
                          // Prevent the queue's scroll from triggering swipe-down-to-close
                          onVerticalDragUpdate: (_) {},
                          onVerticalDragEnd: (_) {},
                          child: Consumer<PlayerProvider>(
                            builder: (context, player, _) {
                              final queue = player.queue;
                              // Show at most the next few tracks after current
                              final startIndex = (player.currentIndex + 1).clamp(0, queue.length);
                              final nextTracks = queue.sublist(startIndex);

                              if (nextTracks.isEmpty) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: _kSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kBorder, width: 0.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Up Next',
                                            style: TextStyle(
                                              color: _kCream,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${nextTracks.length} tracks',
                                            style: const TextStyle(color: _kDim, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(color: _kBorder, height: 1),
                                    Expanded(
                                      child: ListView.separated(
                                        physics: const BouncingScrollPhysics(),
                                        shrinkWrap: false,
                                        itemCount: nextTracks.length,
                                        separatorBuilder: (_, __) => Divider(
                                            color: _kBorder, height: 1, indent: 16, endIndent: 16),
                                        itemBuilder: (_, i) {
                                          final track = nextTracks[i];
                                          return ListTile(
                                            dense: true,
                                            leading: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _kCard,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: _kBorder, width: 0.5),
                                              ),
                                              child: track.artworkUrl.isNotEmpty
                                                  ? ClipRRect(
                                                borderRadius: BorderRadius.circular(5),
                                                child: CachedNetworkImage(
                                                  imageUrl: track.artworkUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) =>
                                                  const Icon(Icons.music_note, size: 18, color: _kDim),
                                                ),
                                              )
                                                  : const Icon(Icons.music_note, size: 18, color: _kDim),
                                            ),
                                            title: Text(
                                              track.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: _kCream, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Text(
                                              track.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: _kMuted, fontSize: 11),
                                            ),
                                            trailing: Text(
                                              _fmt(track.duration),
                                              style: const TextStyle(color: _kDim, fontSize: 12),
                                            ),
                                            onTap: () => player.jumpTo(startIndex + i),
                                          );
                                        },
                                      ),
                                    ), // Expanded ListView
                                  ], // Column children
                                ), // Column
                              );
                            },
                          ),
                        ), // inner GestureDetector
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ), // Scaffold
        ), // Opacity
      ), // AnimatedContainer
    ); // GestureDetector
  }

  Widget _buildTopBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: _kCream),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'NOW PLAYING',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kDim,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: _kCream),
          onPressed: () {},
        ),
      ],
    ),
  );

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Flat rounded-rect control button ──────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool enabled;
  final bool isLarge;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.isActive,
    this.enabled = true,
    this.isLarge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isLarge ? 56 : 44;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _kGold.withOpacity(0.5) : _kBorder,
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Icon(
          icon,
          size: isLarge ? 28 : 22,
          color: isActive
              ? _kGold
              : (enabled ? _kCream : _kDim),
        ),
      ),
    );
  }
}

// ── Circular artwork with concentric rings ─────────────────────────────────
class _CircularArtwork extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  const _CircularArtwork({required this.imageUrl, required this.isPlaying});

  @override
  State<_CircularArtwork> createState() => _CircularArtworkState();
}

class _CircularArtworkState extends State<_CircularArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 20))
    ..repeat();

  @override
  void didUpdateWidget(_CircularArtwork old) {
    super.didUpdateWidget(old);
    widget.isPlaying ? _rotCtrl.repeat() : _rotCtrl.stop();
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final diameter = constraints.maxWidth;
      return AnimatedBuilder(
        animation: _rotCtrl,
        builder: (_, child) {
          return CustomPaint(
            painter: _RingsPainter(rotation: _rotCtrl.value * 2 * math.pi),
            child: child,
          );
        },
        child: Center(
          child: SizedBox(
            width: diameter * 0.62,
            height: diameter * 0.62,
            child: ClipOval(
              child: widget.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _artPlaceholder(diameter),
              )
                  : _artPlaceholder(diameter),
            ),
          ),
        ),
      );
    });
  }

  Widget _artPlaceholder(double diameter) => Container(
    color: _kCard,
    child: Center(
      child: Icon(Icons.graphic_eq, size: diameter * 0.22, color: _kGold),
    ),
  );
}

// ── Concentric rings painter ───────────────────────────────────────────────
class _RingsPainter extends CustomPainter {
  final double rotation;
  _RingsPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Draw 4 concentric dashed rings at different radii
    const ringRadii = [0.72, 0.82, 0.90, 0.97];
    const opacities = [0.35, 0.25, 0.18, 0.10];

    for (int r = 0; r < ringRadii.length; r++) {
      final radius = maxR * ringRadii[r];
      final paint = Paint()
        ..color = _kGold.withOpacity(opacities[r])
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Draw dashed circle
      const dashCount = 40;
      const dashAngle = 2 * math.pi / dashCount;
      const gapFraction = 0.35;
      for (int i = 0; i < dashCount; i++) {
        final startAngle = dashAngle * i + rotation * (r.isEven ? 0.15 : -0.1);
        final sweepAngle = dashAngle * (1 - gapFraction);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    }

    // Solid innermost boundary of image area
    canvas.drawCircle(
      center,
      maxR * 0.65,
      Paint()
        ..color = _kGold.withOpacity(0.45)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.rotation != rotation;
}