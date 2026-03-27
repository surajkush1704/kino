import 'dart:ui';

import 'package:flutter/material.dart';

import '../movie_detail_screen.dart';
import '../services/api_service.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  late Future<List<dynamic>> _forYouFuture;

  @override
  void initState() {
    super.initState();
    _forYouFuture = ApiService.getForYouMovies();
  }

  Future<void> _refresh() async {
    final future = ApiService.getForYouMovies();
    setState(() => _forYouFuture = future);
    await future;
  }

  Widget _buildBottomNav() {
    const navItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_filled),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_rounded),
        label: 'Search',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: 'Watchlist',
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: const Color(0xFF121212).withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            currentIndex: 0,
            onTap: (i) => Navigator.pop(context, i),
            selectedItemColor: Colors.pinkAccent,
            unselectedItemColor: Colors.white30,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: navItems,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.pinkAccent,
        backgroundColor: const Color(0xFF1E1E1E),
        child: FutureBuilder<List<dynamic>>(
          future: _forYouFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              );
            }

            if (snapshot.hasError) {
              return _ForYouErrorState(onRetry: _refresh);
            }

            final movies = snapshot.data ?? [];
            if (movies.isEmpty) {
              return _ForYouErrorState(
                message: 'No recommendations are available right now.',
                buttonLabel: 'Refresh',
                onRetry: _refresh,
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: movies.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _ForYouHeader();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _ForYouMovieCard(movie: movies[index - 1]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ForYouHeader extends StatelessWidget {
  const _ForYouHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 56, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1020),
            Color(0xFF1B1B1B),
            Color(0xFF121212),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              const Text(
                '🎬 For You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Popular in India 🇮🇳',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Personalization coming soon',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForYouMovieCard extends StatelessWidget {
  final dynamic movie;

  const _ForYouMovieCard({required this.movie});

  String _languageLabel(String? code) {
    switch ((code ?? '').toLowerCase()) {
      case 'hi':
        return 'Hindi';
      case 'ta':
        return 'Tamil';
      case 'te':
        return 'Telugu';
      case 'ml':
        return 'Malayalam';
      case 'kn':
        return 'Kannada';
      default:
        return (code == null || code.isEmpty) ? 'Regional' : code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final posterPath = movie['poster_path'];
    final imageUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://via.placeholder.com/500x750?text=No+Image';
    final rating = ((movie['vote_average'] ?? 0.0) as num).toDouble();
    final overview = (movie['overview'] ?? 'No description available.')
        .toString()
        .trim();

    return GestureDetector(
      onTap: () async {
        final tab = await Navigator.push<int>(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
        if (tab != null && context.mounted) {
          Navigator.pop(context, tab);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(22),
              ),
              child: SizedBox(
                width: 110,
                height: 165,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF222222),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.movie_filter_outlined,
                      color: Colors.white38,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.pinkAccent.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            _languageLabel(movie['original_language'] as String?),
                            style: const TextStyle(
                              color: Colors.pinkAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade400,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      movie['title'] ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      overview.isEmpty
                          ? 'No description available.'
                          : overview,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.45,
                      ),
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
}

class _ForYouErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String message;
  final String buttonLabel;

  const _ForYouErrorState({
    required this.onRetry,
    this.message = 'Could not load your regional picks.',
    this.buttonLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_tethering_error_rounded,
                    color: Colors.white38,
                    size: 42,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: () => onRetry(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.pinkAccent,
                      side: const BorderSide(color: Colors.pinkAccent),
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
