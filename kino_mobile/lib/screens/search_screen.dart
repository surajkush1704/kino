import 'package:flutter/material.dart';

import '../movie_detail_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'search_active_screen.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onBackToPrevious;

  const SearchScreen({
    super.key,
    this.onNavigateToTab,
    this.onBackToPrevious,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final StorageService _storageService = StorageService();

  List<String> _recentSearches = <String>[];
  List<dynamic> _recommendations = <dynamic>[];
  bool _isLoadingRecommendations = true;
  String _recommendationSubtitle = 'Based on your interests';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    await Future.wait<void>([
      _loadRecentSearches(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _storageService.getRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final liked = await _storageService.getLiked();
      final watched = await _storageService.getWatched();
      final combined = <Map<String, dynamic>>[...liked, ...watched];

      final Map<int, int> genreFrequency = <int, int>{};
      for (final movie in combined) {
        final genres = (movie['genres'] as List<dynamic>? ?? <dynamic>[]);
        for (final genre in genres) {
          final genreId = genreIdFromName(genre.toString());
          if (genreId == null) continue;
          genreFrequency[genreId] = (genreFrequency[genreId] ?? 0) + 1;
        }
      }

      final sortedGenres = genreFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topGenreIds = sortedGenres.take(3).map((entry) => entry.key).toList();

      final recommendations = await ApiService.getRecommendationsByGenres(
        topGenreIds,
      );

      if (!mounted) return;
      setState(() {
        _recommendations = recommendations.take(10).toList();
        _recommendationSubtitle = topGenreIds.isEmpty
            ? 'Start exploring'
            : 'Based on your interests';
        _isLoadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recommendations = <dynamic>[];
        _recommendationSubtitle = 'Start exploring';
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _removeRecentSearch(String term) async {
    await _storageService.removeRecentSearch(term);
    await _loadRecentSearches();
  }

  Future<void> _clearRecentSearches() async {
    await _storageService.clearRecentSearches();
    await _loadRecentSearches();
  }

  Future<void> _openActiveSearch({
    String initialQuery = '',
    String? preselectedGenre,
    bool startInAdvancedTab = false,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: SearchActiveScreen(
              initialQuery: initialQuery,
              preselectedGenre: preselectedGenre,
              startInAdvancedTab: startInAdvancedTab,
              onNavigateToTab: widget.onNavigateToTab,
            ),
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          final offsetTween = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          );
          return SlideTransition(
            position: offsetTween.animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
    await _loadContent();
  }

  Widget _buildSectionHeader(
    String title, {
    Widget? trailing,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        Container(height: 1, color: Colors.white10),
      ],
    );
  }

  Widget _buildSearchBarEntry() {
    return GestureDetector(
      onTap: () => _openActiveSearch(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: const [
            Icon(Icons.search_rounded, color: Colors.white70, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search movies, series, anime...',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Recent Searches',
          trailing: TextButton(
            onPressed: _recentSearches.isEmpty ? null : _clearRecentSearches,
            child: const Text('Clear all'),
          ),
        ),
        const SizedBox(height: 14),
        if (_recentSearches.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Your recent searches will show up here.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentSearches.map((term) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _openActiveSearch(initialQuery: term),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            term,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeRecentSearch(term),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white38,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(dynamic movie) {
    final dynamic posterPath = movie['poster_path'];
    final String imageUrl = (posterPath ?? '').toString().startsWith('http')
        ? posterPath.toString()
        : 'https://image.tmdb.org/t/p/w500${posterPath ?? ''}';
    final double rating =
        ((movie['vote_average'] ?? 0) as num?)?.toDouble() ?? 0.0;

    return SizedBox(
      width: 148,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 148,
              height: 206,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF222222),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_creation_outlined,
                    color: Colors.white30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Text(
              (movie['title'] ?? 'Unknown').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'You May Like',
          subtitle: _recommendationSubtitle,
        ),
        const SizedBox(height: 14),
        if (_isLoadingRecommendations)
          const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
          )
        else if (_recommendations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Recommendations will show up here once you start exploring.',
              style: TextStyle(color: Colors.white38),
            ),
          )
        else
          SizedBox(
            height: 266,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final movie = _recommendations[index];
                final String mediaType =
                    (movie['media_type'] ?? 'movie').toString();
                return GestureDetector(
                  onTap: () async {
                    if (mediaType != 'movie') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Detailed pages are available for movies right now.',
                          ),
                        ),
                      );
                      return;
                    }
                    final selectedTab = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(
                          movie: movie,
                          initialTabIndex: 1,
                        ),
                      ),
                    );
                    if (selectedTab != null && mounted) {
                      widget.onNavigateToTab?.call(selectedTab);
                    }
                  },
                  child: _buildRecommendationCard(movie),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGenreGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Browse by Genre'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: searchGenreOptions.map((genre) {
            return GestureDetector(
              onTap: () => _openActiveSearch(
                preselectedGenre: genre.name,
                startInAdvancedTab: true,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: genre.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: genre.color.withOpacity(0.45)),
                ),
                child: Text(
                  '${genre.emoji} ${genre.name}',
                  style: TextStyle(
                    color: genre.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: _loadContent,
        color: Colors.purpleAccent,
        backgroundColor: const Color(0xFF1E1E1E),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: widget.onBackToPrevious,
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Find movies, series, anime, and new obsessions.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 22),
                      _buildSearchBarEntry(),
                      const SizedBox(height: 28),
                      _buildRecentSearches(),
                      const SizedBox(height: 30),
                      _buildRecommendations(),
                      const SizedBox(height: 30),
                      _buildGenreGrid(),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
