// lib/screens/search_screen.dart
// ── Sawtq brand theme ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/media_item_model.dart';
import '../providers/player_provider.dart';
import '../services/quran_api.dart';
import '../services/podcast_api.dart';
import 'player_screen.dart';

const _kBg      = Color(0xFF0D0B08);
const _kSurface = Color(0xFF13100C);
const _kCard    = Color(0xFF1C1710);
const _kBorder  = Color(0xFF2A241C);
const _kGold    = Color(0xFFC49A3C);
const _kCream   = Color(0xFFF0EDE6);
const _kMuted   = Color(0xFF9B8A6A);
const _kDim     = Color(0xFF7A7060);
const _kGreen   = Color(0xFF4A7C59);
const _kPurple  = Color(0xFF8B6B9A);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  List<PodcastShow>    _podcastResults = [];
  List<MediaItemModel> _quranResults   = [];
  bool    _searching = false;
  bool    _loading   = false;
  bool    _focused   = false;
  String? _error;

  List<MediaItemModel> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    _prefetchSurahs();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _prefetchSurahs() async {
    try { _allSurahs = await QuranApiService.fetchSurahs(); } catch (_) {}
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() { _searching = false; _podcastResults = []; _quranResults = []; });
      return;
    }

    setState(() { _searching = true; _loading = true; _error = null; });

    try {
      final q = query.toLowerCase();
      final quranHits = _allSurahs
          .where((s) =>
      s.title.toLowerCase().contains(q) ||
          s.subtitle.toLowerCase().contains(q))
          .toList();

      final podcastHits = await PodcastApiService.searchPodcasts(query);

      if (mounted) {
        setState(() {
          _quranResults   = quranHits;
          _podcastResults = podcastHits;
          _loading        = false;
        });
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load: $e',
              style: const TextStyle(color: _kCream)),
          backgroundColor: _kCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _kBorder),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Search',
                    style: TextStyle(
                      color: _kCream,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'بحث',
                    style: TextStyle(
                        color: _kGold, fontSize: 12, letterSpacing: 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focused ? _kGold.withOpacity(0.6) : _kBorder,
                    width: _focused ? 1.5 : 0.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onSearch,
                  style: const TextStyle(color: _kCream, fontSize: 15),
                  cursorColor: _kGold,
                  decoration: InputDecoration(
                    hintText: 'Surahs, podcasts, topics…',
                    hintStyle: const TextStyle(color: _kDim, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: _kDim, size: 22),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                        icon: const Icon(Icons.close, color: _kDim, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onSearch('');
                        })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: _kGold, strokeWidth: 2))
                  : _error != null
                  ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: _kMuted)))
                  : _searching
                  ? _buildResults()
                  : _buildCategories(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final hasQuran   = _quranResults.isNotEmpty;
    final hasPodcast = _podcastResults.isNotEmpty;

    if (!hasQuran && !hasPodcast) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 56, color: _kDim),
            const SizedBox(height: 14),
            Text(
              'No results for "${_controller.text}"',
              style: const TextStyle(color: _kMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (hasQuran) ...[
          _ResultHeader(title: 'Quran', arabic: 'القرآن', color: _kGreen),
          ..._quranResults.map((item) => _MediaTile(
            item: item,
            onTap: () => _play(item, _quranResults),
          )),
          const SizedBox(height: 20),
        ],
        if (hasPodcast) ...[
          _ResultHeader(title: 'Podcasts', arabic: 'بودكاست', color: _kPurple),
          ..._podcastResults.map((show) {
            final saved =
            context.watch<PlayerProvider>().isShowSaved(show.id);
            return _ShowTile(
              show: show,
              isSaved: saved,
              onTap: () => _playPodcastShow(show),
              onSave: () =>
                  context.read<PlayerProvider>().toggleSaveShow(show),
            );
          }),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Browse categories ──────────────────────────────────────────────────

  Widget _buildCategories() {
    const categories = [
      _Category('Quran',      'القرآن',    0xFF4A7C59, Icons.menu_book_rounded),
      _Category('Podcasts',   'بودكاست',   0xFF8B6B9A, Icons.mic_rounded),
      _Category('Technology', 'تكنولوجيا', 0xFF2A5F8B, Icons.computer_rounded),
      _Category('Science',    'علوم',      0xFF2A7A7A, Icons.science_rounded),
      _Category('History',    'تاريخ',     0xFF7A5A2A, Icons.history_edu_rounded),
      _Category('Health',     'صحة',       0xFF7A2A4A, Icons.favorite_rounded),
      _Category('Business',   'أعمال',     0xFF4A5A6A, Icons.business_rounded),
      _Category('Comedy',     'كوميديا',   0xFF7A6A2A, Icons.sentiment_very_satisfied_rounded),
      _Category('True Crime', 'جريمة',     0xFF5A4A3A, Icons.policy_rounded),
      _Category('Sports',     'رياضة',     0xFF3A6A3A, Icons.sports_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: const [
              Text('Browse',
                  style: TextStyle(
                    color: _kCream,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
              SizedBox(width: 8),
              Text('استكشف',
                  style: TextStyle(color: _kGold, fontSize: 12, letterSpacing: 1.5)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06), width: 0.5),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(cat.icon, color: Colors.white70, size: 22),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(cat.arabic,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                  letterSpacing: 0.8)),
                        ],
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

// ── Widgets ────────────────────────────────────────────────────────────────

class _Category {
  final String name;
  final String arabic;
  final int color;
  final IconData icon;
  const _Category(this.name, this.arabic, this.color, this.icon);
}

class _ResultHeader extends StatelessWidget {
  final String title;
  final String arabic;
  final Color color;
  const _ResultHeader(
      {required this.title, required this.arabic, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: _kCream,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text(arabic,
            style: TextStyle(
                color: color, fontSize: 11, letterSpacing: 1.2)),
      ],
    ),
  );
}

class _MediaTile extends StatelessWidget {
  final MediaItemModel item;
  final VoidCallback onTap;
  const _MediaTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: item.artworkUrl.isNotEmpty
              ? CachedNetworkImage(
              imageUrl: item.artworkUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback())
              : _fallback(),
        ),
      ),
      title: Text(item.title,
          style: const TextStyle(
              color: _kCream, fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(item.subtitle,
          style: const TextStyle(color: _kDim, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, color: _kDim, size: 20),
      onTap: onTap,
    );
  }

  Widget _fallback() => Container(
      width: 52, height: 52, color: _kCard,
      child: const Icon(Icons.music_note, size: 24, color: _kDim));
}

class _ShowTile extends StatelessWidget {
  final PodcastShow show;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isSaved;
  const _ShowTile(
      {required this.show,
        required this.onTap,
        required this.onSave,
        required this.isSaved});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: show.artworkUrl.isNotEmpty
              ? CachedNetworkImage(
              imageUrl: show.artworkUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback())
              : _fallback(),
        ),
      ),
      title: Text(show.name,
          style: const TextStyle(
              color: _kCream, fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text('${show.author} · ${show.episodeCount} episodes',
          style: const TextStyle(color: _kDim, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isSaved ? _kGold : _kDim,
          size: 22,
        ),
        onPressed: onSave,
        tooltip: isSaved ? 'Remove from library' : 'Save to library',
      ),
      onTap: onTap,
    );
  }

  Widget _fallback() => Container(
      width: 52, height: 52, color: _kCard,
      child: const Icon(Icons.mic_rounded, size: 24, color: _kDim));
}