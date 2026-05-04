// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/media_item_model.dart';
import '../providers/player_provider.dart';
import '../services/quran_api.dart';
import '../services/podcast_api.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  // Search state
  List<PodcastShow>    _podcastResults = [];
  List<MediaItemModel> _quranResults   = [];
  bool  _searching  = false;
  bool  _loading    = false;
  String? _error;

  // All surahs cached for local filtering
  List<MediaItemModel> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    _prefetchSurahs();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _prefetchSurahs() async {
    try {
      _allSurahs = await QuranApiService.fetchSurahs();
    } catch (_) {}
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() { _searching = false; _podcastResults = []; _quranResults = []; });
      return;
    }

    setState(() { _searching = true; _loading = true; _error = null; });

    try {
      // Quran: local filter (no extra network call)
      final q = query.toLowerCase();
      final quranHits = _allSurahs
          .where((s) => s.title.toLowerCase().contains(q) || s.subtitle.toLowerCase().contains(q))
          .toList();

      // Podcasts: iTunes search
      final podcastHits = await PodcastApiService.searchPodcasts(query);

      if (mounted) {
        setState(() { _quranResults = quranHits; _podcastResults = podcastHits; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _play(MediaItemModel item, List<MediaItemModel> queue) {
    context.read<PlayerProvider>().playItem(item, playlist: queue);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  Future<void> _playPodcastShow(PodcastShow show) async {
    setState(() => _loading = true);
    try {
      final episodes = await PodcastApiService.fetchEpisodes(show.id);
      if (episodes.isNotEmpty && mounted) _play(episodes.first, episodes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load: $e'), backgroundColor: const Color(0xFF282828)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Search', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),

              // Search bar
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearch,
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Surahs, podcasts, topics…',
                    hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.black, size: 22),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                        onPressed: () { _controller.clear(); _onSearch(''); })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                    : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                    : _searching
                    ? _buildResults()
                    : _buildCategories(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search results ─────────────────────────────────────────────────────────

  Widget _buildResults() {
    final hasQuran   = _quranResults.isNotEmpty;
    final hasPodcast = _podcastResults.isNotEmpty;

    if (!hasQuran && !hasPodcast) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off, size: 64, color: Colors.white24),
          const SizedBox(height: 12),
          Text('No results for "${_controller.text}"',
              style: const TextStyle(color: Colors.white54)),
        ]),
      );
    }

    return ListView(
      children: [
        if (hasQuran) ...[
          _ResultHeader(title: 'Quran'),
          ..._quranResults.map((item) => _MediaTile(
            item: item,
            onTap: () => _play(item, _quranResults),
          )),
          const SizedBox(height: 16),
        ],
        if (hasPodcast) ...[
          _ResultHeader(title: 'Podcasts'),
          ..._podcastResults.map((show) {
            final saved = context.watch<PlayerProvider>().isShowSaved(show.id);
            return _ShowTile(
              show: show,
              isSaved: saved,
              onTap: () => _playPodcastShow(show),
              onSave: () => context.read<PlayerProvider>().toggleSaveShow(show),
            );
          }),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Browse categories ──────────────────────────────────────────────────────

  Widget _buildCategories() {
    const categories = [
      _Category('Quran',       0xFF1DB954, Icons.menu_book),
      _Category('Podcasts',    0xFF9C27B0, Icons.mic),
      _Category('Technology',  0xFF2196F3, Icons.computer),
      _Category('Science',     0xFF00BCD4, Icons.science),
      _Category('History',     0xFFFF9800, Icons.history_edu),
      _Category('Health',      0xFFE91E63, Icons.favorite),
      _Category('Business',    0xFF607D8B, Icons.business),
      _Category('Comedy',      0xFFFFEB3B, Icons.sentiment_very_satisfied),
      _Category('True Crime',  0xFF795548, Icons.policy),
      _Category('Sports',      0xFF4CAF50, Icons.sports),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Browse all', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.7, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return GestureDetector(
                onTap: () {
                  _controller.text = cat.name;
                  _onSearch(cat.name);
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(cat.color),
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(cat.icon, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(cat.name,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Category {
  final String name;
  final int color;
  final IconData icon;
  const _Category(this.name, this.color, this.icon);
}

// ── Result section header ──────────────────────────────────────────────────────

class _ResultHeader extends StatelessWidget {
  final String title;
  const _ResultHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
  );
}

// ── MediaItem list tile ────────────────────────────────────────────────────────

class _MediaTile extends StatelessWidget {
  final MediaItemModel item;
  final VoidCallback onTap;
  const _MediaTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: item.artworkUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: item.artworkUrl, width: 52, height: 52, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _fallback())
            : _fallback(),
      ),
      title: Text(item.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(item.subtitle,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.more_vert, color: Color(0xFFB3B3B3), size: 20),
      onTap: onTap,
    );
  }

  Widget _fallback() => Container(
      width: 52, height: 52, color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, size: 24, color: Colors.white30));
}

// ── PodcastShow list tile ──────────────────────────────────────────────────────

class _ShowTile extends StatelessWidget {
  final PodcastShow show;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isSaved;
  const _ShowTile({required this.show, required this.onTap, required this.onSave, required this.isSaved});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: show.artworkUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: show.artworkUrl, width: 52, height: 52, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _fallback())
            : _fallback(),
      ),
      title: Text(show.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${show.author} • ${show.episodeCount} episodes',
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: isSaved ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
          size: 22,
        ),
        onPressed: onSave,
        tooltip: isSaved ? 'Remove from library' : 'Save to library',
      ),
      onTap: onTap,
    );
  }

  Widget _fallback() => Container(
      width: 52, height: 52, color: const Color(0xFF282828),
      child: const Icon(Icons.mic, size: 24, color: Colors.white30));
}