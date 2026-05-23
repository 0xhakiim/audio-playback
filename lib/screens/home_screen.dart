// lib/screens/home_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/media_item_model.dart';
import '../providers/player_provider.dart';
import '../services/quran_api.dart';
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
const _kGreen   = Color(0xFF4A7C59); // Quran category
const _kPurple  = Color(0xFF8B6B9A); // Podcast category

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<DynamicProfileAvatarState> _avatarKey = GlobalKey();

  List<MediaItemModel> _quranSurahs  = [];
  List<PodcastShow>    _podcastShows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final results = await Future.wait([
        QuranApiService.fetchSurahs(),
        PodcastApiService.fetchTopPodcasts(),
      ]);
      if (mounted) {
        setState(() {
          _quranSurahs  = results[0] as List<MediaItemModel>;
          _podcastShows = results[1] as List<PodcastShow>;
          _loading      = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Arabic greeting mirroring the time-of-day
  String get _arabicGreeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'مساء النهار';
    return 'مساء الخير';
  }

  void _play(MediaItemModel item, List<MediaItemModel> queue) {
    context.read<PlayerProvider>().playItem(item, playlist: queue);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: _kBg,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: _kCream,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  _arabicGreeting,
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: _kMuted),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                    _avatarKey.currentState?.loadData();
                  },
                  child: DynamicProfileAvatar(key: _avatarKey, radius: 16),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const SizedBox(
                height: 300,
                child: Center(
                    child: CircularProgressIndicator(
                        color: _kGold, strokeWidth: 2)))
                : _error != null
                ? _ErrorView(message: _error!, onRetry: _loadContent)
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_quranSurahs.isNotEmpty) ...[
          _QuickGrid(
              items: _quranSurahs.take(6).toList(),
              onTap: (item) => _play(item, _quranSurahs)),
          const SizedBox(height: 32),
        ],
        if (_quranSurahs.isNotEmpty) ...[
          _SectionHeader(
            title: 'Quran — All Surahs',
            arabicTitle: 'القرآن الكريم',
            accentColor: _kGreen,
            onSeeAll: () {},
          ),
          _MediaCarousel(
              items: _quranSurahs.take(10).toList(),
              onTap: (item) => _play(item, _quranSurahs)),
          const SizedBox(height: 32),
        ],
        if (_podcastShows.isNotEmpty) ...[
          _SectionHeader(
            title: 'Trending Podcasts',
            arabicTitle: 'بودكاست',
            accentColor: _kPurple,
            onSeeAll: () {},
          ),
          _ShowCarousel(
              shows: _podcastShows,
              onTap: (show) => _loadAndPlayPodcast(show)),
          const SizedBox(height: 100),
        ],
      ],
    );
  }

  Future<void> _loadAndPlayPodcast(PodcastShow show) async {
    try {
      final episodes = await PodcastApiService.fetchEpisodes(show.id);
      if (episodes.isNotEmpty && mounted) _play(episodes.first, episodes);
    } catch (e) {
      if (mounted) {
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

// ── Quick grid (recently played) ──────────────────────────────────────────

class _QuickGrid extends StatelessWidget {
  final List<MediaItemModel> items;
  final void Function(MediaItemModel) onTap;
  const _QuickGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => onTap(item),
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      bottomLeft: Radius.circular(7),
                    ),
                    child: _Thumb(url: item.artworkUrl, size: 48),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: _kCream,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section header with Arabic subtitle ───────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String arabicTitle;
  final Color accentColor;
  final VoidCallback onSeeAll;
  const _SectionHeader({
    required this.title,
    required this.arabicTitle,
    required this.accentColor,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _kCream,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                arabicTitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(color: _kDim, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Media carousel ─────────────────────────────────────────────────────────

class _MediaCarousel extends StatelessWidget {
  final List<MediaItemModel> items;
  final void Function(MediaItemModel) onTap;
  const _MediaCarousel({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => onTap(item),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorder, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: _Thumb(url: item.artworkUrl, size: 140),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.title,
                      style: const TextStyle(
                          color: _kCream,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: const TextStyle(color: _kDim, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Show carousel ──────────────────────────────────────────────────────────

class _ShowCarousel extends StatelessWidget {
  final List<PodcastShow> shows;
  final void Function(PodcastShow) onTap;
  const _ShowCarousel({required this.shows, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: shows.length,
        itemBuilder: (_, i) {
          final show = shows[i];
          return GestureDetector(
            onTap: () => onTap(show),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorder, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: _Thumb(url: show.artworkUrl, size: 140),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(show.name,
                      style: const TextStyle(
                          color: _kCream,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(show.author,
                      style: const TextStyle(color: _kDim, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  final double size;
  const _Thumb({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback());
  }

  Widget _fallback() => Container(
      width: size,
      height: size,
      color: _kCard,
      child: const Icon(Icons.music_note, color: _kDim));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: _kDim),
            const SizedBox(height: 12),
            const Text('Could not load content',
                style: TextStyle(color: _kMuted, fontSize: 15)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kGold,
                side: const BorderSide(color: _kGold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}