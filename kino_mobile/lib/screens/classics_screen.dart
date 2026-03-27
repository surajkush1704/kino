import 'dart:ui';

import 'package:flutter/material.dart';

import '../movie_detail_screen.dart';
import '../services/api_service.dart';

class ClassicsScreen extends StatefulWidget {
  const ClassicsScreen({super.key});

  @override
  State<ClassicsScreen> createState() => _ClassicsScreenState();
}

class _ClassicsScreenState extends State<ClassicsScreen> {
  late Future<List<dynamic>> _classicsFuture;

  @override
  void initState() {
    super.initState();
    _classicsFuture = ApiService.getClassicMovies();
  }

  Future<void> _refresh() async {
    final future = ApiService.getClassicMovies();
    setState(() => _classicsFuture = future);
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
            selectedItemColor: const Color(0xFFD4AF37),
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
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1E1E1E),
        child: FutureBuilder<List<dynamic>>(
          future: _classicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              );
            }

            if (snapshot.hasError) {
              return _ClassicsErrorState(onRetry: _refresh);
            }

            final movies = snapshot.data ?? [];
            if (movies.isEmpty) {
              return _ClassicsErrorState(
                message: 'No classic movies found right now.',
                buttonLabel: 'Refresh',
                onRetry: _refresh,
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _ClassicsHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _ClassicMovieCard(movie: movies[index]),
                      childCount: movies.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClassicsHeader extends StatelessWidget {
  const _ClassicsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 56, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2112),
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
                '⭐ All Time Greats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'The greatest films ever made',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicMovieCard extends StatelessWidget {
  final dynamic movie;

  const _ClassicMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final posterPath = movie['poster_path'];
    final imageUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : 'https://via.placeholder.com/500x750?text=No+Image';
    final rating = ((movie['vote_average'] ?? 0.0) as num).toDouble();

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF222222),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.movie_creation_outlined,
                      color: Colors.white38,
                      size: 42,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.12),
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: Text(
                  movie['title'] ?? 'Unknown',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
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

class _ClassicsErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String message;
  final String buttonLabel;

  const _ClassicsErrorState({
    required this.onRetry,
    this.message = 'Could not load classic movies.',
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
                    Icons.auto_awesome_motion_outlined,
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
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
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
