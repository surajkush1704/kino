import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../movie_detail_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/kino_logo.dart';
import 'anime_screen.dart';
import 'classics_screen.dart';
import 'for_you_screen.dart';
import 'profile_screen.dart';
import 'vibe_check_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _genreOptions = <String>[
    'Action',
    'Comedy',
    'Drama',
    'Thriller',
    'Romance',
    'Horror',
    'Sci-Fi',
    'Fantasy',
    'Animation',
    'Crime',
    'Family',
    'Mystery',
  ];

  static const List<String> _languageOptions = <String>[
    'Hindi',
    'English',
    'Telugu',
    'Tamil',
    'Malayalam',
    'Kannada',
    'Punjabi',
    'Bhojpuri',
  ];

  static const List<String> _industryOptions = <String>[
    'Bollywood',
    'Hollywood',
    'Telugu Cinema',
    'Tamil Cinema',
    'Malayalam Cinema',
    'Kannada Cinema',
    'Punjabi Cinema',
    'Bhojpuri Cinema',
    'Regional Films',
  ];

  late Future<List<dynamic>> _trendingFuture;

  final PageController _pageController = PageController(viewportFraction: 0.85);
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  int _currentPage = 0;
  Timer? _timer;
  final Set<int> _likedMovies = <int>{};
  bool _isShowingPreferences = false;

  @override
  void initState() {
    super.initState();
    _trendingFuture = ApiService.getTrendingMovies();
    _loadLikedMovies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
      _maybeShowPreferencesDialog();
    });
  }

  Future<void> _maybeShowPreferencesDialog() async {
    final bool hasCompleted = await _storageService.hasCompletedPreferences();
    if (hasCompleted || !mounted || _isShowingPreferences) return;

    _isShowingPreferences = true;
    await _showPreferencesDialog();
    _isShowingPreferences = false;
  }

  Future<void> _showPreferencesDialog() async {
    final Set<String> selectedGenres = <String>{};
    final Set<String> selectedLanguages = <String>{};
    final Set<String> selectedIndustries = <String>{};

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChip(
              String label,
              Set<String> bucket,
            ) {
              final bool isSelected = bucket.contains(label);
              return FilterChip(
                selected: isSelected,
                label: Text(label),
                onSelected: (selected) {
                  setModalState(() {
                    if (selected) {
                      bucket.add(label);
                    } else {
                      bucket.remove(label);
                    }
                  });
                },
                selectedColor: Colors.purpleAccent.withOpacity(0.25),
                checkmarkColor: Colors.purpleAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.purpleAccent : Colors.white12,
                ),
                backgroundColor: const Color(0xFF1A1A1A),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white10),
              ),
              title: const Text(
                'Set Your Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tell Kino what you enjoy. You can change this later without affecting your saved movies.',
                      style: TextStyle(color: Colors.white60, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Preferred Genres',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _genreOptions
                          .map((option) => buildChip(option, selectedGenres))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Preferred Languages',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languageOptions
                          .map(
                            (option) => buildChip(option, selectedLanguages),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Cinema Industries',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _industryOptions
                          .map(
                            (option) => buildChip(option, selectedIndustries),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _storageService.saveUserPreferences(
                      genres: selectedGenres.toList(),
                      languages: selectedLanguages.toList(),
                      industries: selectedIndustries.toList(),
                    );
                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferences saved'),
                      ),
                    );
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= 7) {
          nextPage = 0;
          _pageController.jumpToPage(0);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
        }
        _currentPage = nextPage;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int? _movieIdFrom(dynamic movie) {
    final dynamic id = movie is Map ? movie['id'] : null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  Map<String, dynamic> _movieToStorageEntry(dynamic movie) {
    final Map<String, dynamic> safeMovie = Map<String, dynamic>.from(
      movie is Map ? movie : <String, dynamic>{},
    );
    return <String, dynamic>{
      'id': _movieIdFrom(safeMovie),
      'title': safeMovie['title'],
      'poster_path': safeMovie['poster_path'],
      'vote_average': safeMovie['vote_average'],
      'release_date': safeMovie['release_date'],
      'overview': safeMovie['overview'],
      'genres': safeMovie['genres'] ?? <dynamic>[],
    };
  }

  Future<void> _loadLikedMovies() async {
    try {
      final likedMovies = await _storageService.getLiked();
      if (!mounted) return;
      setState(() {
        _likedMovies
          ..clear()
          ..addAll(
            likedMovies.map((movie) => _movieIdFrom(movie)).whereType<int>(),
          );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _likedMovies.clear());
    }
  }

  Future<void> _toggleLike(dynamic movie) async {
    final int? movieId = _movieIdFrom(movie);
    if (movieId == null) return;

    final bool wasLiked = _likedMovies.contains(movieId);

    try {
      await _storageService.toggleLike(_movieToStorageEntry(movie));
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedMovies.remove(movieId);
        } else {
          _likedMovies.add(movieId);
        }
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked ? 'Removed from Liked Movies' : 'Added to Liked Movies',
          ),
          duration: const Duration(milliseconds: 700),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update liked movies')),
      );
    }
  }

  Widget _buildProfileButton() {
    final User? user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        alignment: Alignment.center,
        child: user == null
            ? const Icon(Icons.person, color: Colors.white, size: 24)
            : Text(
                _authService.getUserInitials(user),
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBody: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const KinoLogo(),
                  _buildProfileButton(),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'KinoTadka',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 480,
              child: FutureBuilder<List<dynamic>>(
                future: _trendingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7000FF),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Could not connect to the server.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No movies found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final movies = snapshot.data!.take(7).toList();

                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      return _buildHeroCard(movies[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse by Vibe',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 150,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildBentoCard(
                            title: 'Vibe Check',
                            subtitle: 'Mood Search',
                            color: Colors.purpleAccent,
                            icon: Icons.auto_awesome,
                            imageUrl: 'assets/images/vibe_check.png',
                            onTap: () async {
                              final tab = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VibeCheckScreen(),
                                ),
                              );
                              if (tab != null && mounted) {
                                widget.onNavigateToTab?.call(tab);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: _buildBentoCard(
                            title: 'Anime',
                            subtitle: 'Japan',
                            color: Colors.orangeAccent,
                            icon: Icons.local_fire_department,
                            imageUrl: 'assets/images/anime.png',
                            onTap: () async {
                              final tab = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AnimeScreen(),
                                ),
                              );
                              if (tab != null && mounted) {
                                widget.onNavigateToTab?.call(tab);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildBentoCard(
                            title: 'For You',
                            subtitle: 'History',
                            color: Colors.pinkAccent,
                            icon: Icons.favorite,
                            imageUrl: 'assets/images/for_you.png',
                            onTap: () async {
                              final tab = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForYouScreen(),
                                ),
                              );
                              if (tab != null && mounted) {
                                widget.onNavigateToTab?.call(tab);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildBentoCard(
                            title: 'Classics',
                            subtitle: 'Top Rated',
                            color: Colors.tealAccent,
                            icon: Icons.star,
                            imageUrl: 'assets/images/classics.png',
                            onTap: () async {
                              final tab = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ClassicsScreen(),
                                ),
                              );
                              if (tab != null && mounted) {
                                widget.onNavigateToTab?.call(tab);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(dynamic movie) {
    final posterUrl = 'https://image.tmdb.org/t/p/w500${movie['poster_path']}';
    final movieId = movie['id'];
    final isLiked = _likedMovies.contains(movieId);

    return GestureDetector(
      onTap: () async {
        final selectedTab = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
        );
        if (selectedTab != null && selectedTab is int && mounted) {
          widget.onNavigateToTab?.call(selectedTab);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(posterUrl),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: GestureDetector(
                onTap: () => _toggleLike(movie),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.redAccent : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
