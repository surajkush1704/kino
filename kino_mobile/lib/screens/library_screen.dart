import 'package:flutter/material.dart';

import '../movie_detail_screen.dart';
import '../services/storage_service.dart';

class LibraryScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final VoidCallback? onBackToPrevious;
  final int initialTabIndex;

  const LibraryScreen({
    super.key,
    this.onNavigateToTab,
    this.onBackToPrevious,
    this.initialTabIndex = 0,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();

  late final TabController _tabController;
  List<Map<String, dynamic>> _watchlist = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _watched = <Map<String, dynamic>>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadLibrary();
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _storageService.getWatchlist(),
        _storageService.getWatched(),
      ]);

      if (!mounted) return;
      setState(() {
        _watchlist = results[0];
        _watched = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _watchlist = <Map<String, dynamic>>[];
        _watched = <Map<String, dynamic>>[];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your library')),
      );
    }
  }

  Future<void> _removeMovie({
    required bool isWatchlist,
    required Map<String, dynamic> movie,
  }) async {
    final dynamic idValue = movie['id'];
    final int? movieId = idValue is int ? idValue : int.tryParse('$idValue');
    if (movieId == null) return;

    try {
      if (isWatchlist) {
        await _storageService.removeFromWatchlist(movieId);
      } else {
        await _storageService.removeFromWatched(movieId);
      }

      if (!mounted) return;
      setState(() {
        final target = isWatchlist ? _watchlist : _watched;
        target.removeWhere((item) => item['id'] == movieId);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isWatchlist ? 'Removed from Watchlist' : 'Removed from Watched',
          ),
          duration: const Duration(milliseconds: 700),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove movie')),
      );
    }
  }

  String _releaseYear(Map<String, dynamic> movie) {
    final String releaseDate = (movie['release_date'] ?? '').toString();
    if (releaseDate.length >= 4) return releaseDate.substring(0, 4);
    return 'Unknown';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white24, size: 48),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard({
    required Map<String, dynamic> movie,
    required bool isWatchlist,
  }) {
    final posterPath = movie['poster_path'];
    final String imageUrl = posterPath != null && '$posterPath'.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://via.placeholder.com/300x450?text=No+Image';
    final List<dynamic> genres = (movie['genres'] as List<dynamic>? ?? []);
    final double rating = movie['vote_average'] is num
        ? (movie['vote_average'] as num).toDouble()
        : double.tryParse('${movie['vote_average'] ?? 0}') ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final selectedTab = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(
                  movie: movie,
                  initialTabIndex: 2,
                ),
              ),
            );
            if (selectedTab != null && mounted) {
              widget.onNavigateToTab?.call(selectedTab);
            }
            await _loadLibrary();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    width: 90,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 130,
                      color: const Color(0xFF242424),
                      child: const Icon(
                        Icons.movie_outlined,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              (movie['title'] ?? 'Unknown').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeMovie(
                              isWatchlist: isWatchlist,
                              movie: movie,
                            ),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white60,
                            ),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _releaseYear(movie),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: genres.take(3).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              genre.toString(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabView({
    required List<Map<String, dynamic>> movies,
    required bool isWatchlist,
  }) {
    final Widget child = movies.isEmpty
        ? _buildEmptyState(
            icon: isWatchlist ? Icons.movie_outlined : Icons.check_circle,
            title: 'Nothing here yet',
            subtitle: isWatchlist
                ? 'Add movies to watch later'
                : 'Mark movies as watched',
          )
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return _buildMovieCard(
                movie: movies[index],
                isWatchlist: isWatchlist,
              );
            },
          );

    return RefreshIndicator(
      onRefresh: _loadLibrary,
      color: Colors.purpleAccent,
      backgroundColor: const Color(0xFF1E1E1E),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(
            '${isWatchlist ? 'watchlist' : 'watched'}-${movies.length}',
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBackToPrevious,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
        ),
        title: const Text(
          'My Library',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Watchlist'),
            Tab(text: 'Watched'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabView(movies: _watchlist, isWatchlist: true),
                _buildTabView(movies: _watched, isWatchlist: false),
              ],
            ),
    );
  }
}
