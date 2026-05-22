// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/media_item_model.dart';
import '../providers/player_provider.dart';
import '../services/quran_api.dart';
import '../services/podcast_api.dart';
import '../widgets/dynamic_profile_avatar.dart'; // Import Dynamic Avatar Widget
import 'player_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalKey to access and reload the state of the profile avatar dynamically
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

  void _play(MediaItemModel item, List<MediaItemModel> queue) {
    context.read<PlayerProvider>().playItem(item, playlist: queue);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            title: Text(_greeting, style: Theme.of(context).textTheme.headlineMedium),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    // 1. Wait for navigation pop
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                    // 2. Trigger dynamic avatar state reloading directly
                    _avatarKey.currentState?.loadData();
                  },
                  // Render the dynamic profile avatar instead of the hardcoded one
                  child: DynamicProfileAvatar(key: _avatarKey, radius: 14),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFF1DB954))))
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
          _QuickGrid(items: _quranSurahs.take(6).toList(), onTap: (item) => _play(item, _quranSurahs)),
          const SizedBox(height: 28),
        ],
        if (_quranSurahs.isNotEmpty) ...[
          _SectionHeader(title: 'Quran — All Surahs', onSeeAll: () {}),
          _MediaCarousel(items: _quranSurahs.take(10).toList(), onTap: (item) => _play(item, _quranSurahs)),
          const SizedBox(height: 28),
        ],
        if (_podcastShows.isNotEmpty) ...[
          _SectionHeader(title: 'Trending Podcasts', onSeeAll: () {}),
          _ShowCarousel(shows: _podcastShows, onTap: (show) => _loadAndPlayPodcast(show)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load episodes: $e'), backgroundColor: const Color(0xFF282828)),
        );
      }
    }
  }
}

// ... Keep the remaining static widgets (_QuickGrid, _SectionHeader, etc.) from home_screen.dart unchanged ...
class _QuickGrid extends StatelessWidget {
  final List<MediaItemModel> items;
  final void Function(MediaItemModel) onTap;
  const _QuickGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 3.8, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => onTap(item),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                    child: _Thumb(url: item.artworkUrl, size: 48),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.title,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _MediaCarousel extends StatelessWidget {
  final List<MediaItemModel> items;
  final void Function(MediaItemModel) onTap;
  const _MediaCarousel({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => onTap(item),
            child: Container(
              width: 140, margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: _Thumb(url: item.artworkUrl, size: 140)),
                  const SizedBox(height: 8),
                  Text(item.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShowCarousel extends StatelessWidget {
  final List<PodcastShow> shows;
  final void Function(PodcastShow) onTap;
  const _ShowCarousel({required this.shows, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: shows.length,
        itemBuilder: (_, i) {
          final show = shows[i];
          return GestureDetector(
            onTap: () => onTap(show),
            child: Container(
              width: 140, margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: _Thumb(url: show.artworkUrl, size: 140)),
                  const SizedBox(height: 8),
                  Text(show.name,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(show.author,
                      style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
        imageUrl: url, width: size, height: size, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback());
  }

  Widget _fallback() => Container(
      width: size, height: size, color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, color: Colors.white24));
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
            const Icon(Icons.wifi_off, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('Could not load content', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: Color(0xFF1DB954))),
            ),
          ],
        ),
      ),
    );
  }
}