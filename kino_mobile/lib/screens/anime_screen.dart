import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../movie_detail_screen.dart';

// ---------------------------------------------------------------------------
//  Genre chip definitions — client-side filter using TMDB genre IDs embedded
//  in the normalized movie objects (genre_ids list). Chip labels map to IDs.
// ---------------------------------------------------------------------------
const List<Map<String, dynamic>> _kAnimeGenres = [
  {'label': 'All',      'id': null},
  {'label': 'Action',   'id': 28},
  {'label': 'Adventure','id': 12},
  {'label': 'Fantasy',  'id': 14},
  {'label': 'Sci-Fi',   'id': 878},
  {'label': 'Romance',  'id': 10749},
  {'label': 'Thriller', 'id': 53},
  {'label': 'Drama',    'id': 18},
  {'label': 'Comedy',   'id': 35},
  {'label': 'Mystery',  'id': 9648},
];

// ---------------------------------------------------------------------------

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  late Future<List<dynamic>> _animeFuture;
  int? _selectedGenreId; // null == "All"

  @override
  void initState() {
    super.initState();
    _animeFuture = ApiService.getAnimeMovies();
  }

  Future<void> _refresh() async {
    setState(() {
      _animeFuture = ApiService.getAnimeMovies();
    });
  }

  List<dynamic> _filter(List<dynamic> movies) {
    if (_selectedGenreId == null) return movies;
    return movies.where((m) {
      final ids = m['genre_ids'];
      if (ids is List) return ids.contains(_selectedGenreId);
      return false;
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A1B9A), // deep violet
            Color(0xFFAD1457), // hot pink
            Color(0xFF1A237E), // indigo-dark
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative icon row
          Row(
            children: const [
              Text('🎌', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Text(
                'Anime',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Discover the world of Japanese animation',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _kAnimeGenres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final genre = _kAnimeGenres[i];
          final bool selected = genre['id'] == _selectedGenreId;
          return FilterChip(
            label: Text(genre['label'] as String),
            selected: selected,
            onSelected: (_) => setState(() => _selectedGenreId = genre['id'] as int?),
            backgroundColor: const Color(0xFF1E1E2E),
            selectedColor: const Color(0xFFAD1457),
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? const Color(0xFFAD1457) : Colors.white12,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          );
        },
      ),
    );
  }

  Widget _buildMovieGrid(List<dynamic> movies) {
    if (movies.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No anime found for this genre.\nTry another filter!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AnimeMovieCard(movie: movies[index]),
          childCount: movies.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.6,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFAD1457),
        backgroundColor: const Color(0xFF1E1E2E),
        child: FutureBuilder<List<dynamic>>(
          future: _animeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFAD1457),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.white30, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load anime.\nCheck your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 15,
                            height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAD1457),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final all = snapshot.data ?? [];
            final filtered = _filter(all);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 4),
                    child: _buildGenreChips(),
                  ),
                ),
                _buildMovieGrid(filtered),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  _AnimeMovieCard
// ---------------------------------------------------------------------------

class _AnimeMovieCard extends StatelessWidget {
  const _AnimeMovieCard({required this.movie});
  final dynamic movie;

  @override
  Widget build(BuildContext context) {
    final String? posterPath = movie['poster_path'] as String?;
    final String posterUrl = (posterPath != null && posterPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';
    final String title = (movie['title'] as String?) ?? 'Unknown';
    final double rating =
        ((movie['vote_average'] as num?) ?? 0).toDouble();
    final int movieId = (movie['id'] as int?) ?? 0;

    return GestureDetector(
      onTap: () {
        if (movieId == 0) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- Poster image ---
            posterUrl.isNotEmpty
                ? Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _posterPlaceholder(),
                  )
                : _posterPlaceholder(),

            // --- Bottom gradient + info ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xE6000000),
                      Colors.transparent,
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFC107)),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFFFFC107),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() => Container(
        color: const Color(0xFF1E1E2E),
        child: const Center(
          child: Icon(Icons.movie_filter_rounded,
              color: Colors.white12, size: 48),
        ),
      );
}
