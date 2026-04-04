import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:http/http.dart' as http;

import '../movie_detail_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class VibeCheckScreen extends StatefulWidget {
  const VibeCheckScreen({super.key});

  @override
  State<VibeCheckScreen> createState() => _VibeCheckScreenState();
}

class _VibeCheckScreenState extends State<VibeCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CardSwiperController _swiperController = CardSwiperController();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  bool _isResultView = false;
  List<dynamic> _searchResults = [];
  Map<String, dynamic> _vibeMetadata = {};
  List<String> _recentSearches = [];
  String _lastQuery = '';

  final List<String> _vibeSuggestions = [
    'I want to cry tonight',
    'I had a bad day cheer me up',
    "I'm very happy suggest action movies",
    'Date night movie suggestions',
    'I want something dark and intense',
    'Show me cult classic movies',
    'I want anime adventures',
    'Give me motivational films',
  ];

  @override
  void initState() {
    super.initState();
    _vibeSuggestions.shuffle();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _storageService.getRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

  Future<void> _saveSearch(String query) async {
    await _storageService.saveRecentSearch(query);
    await _loadRecentSearches();
  }

  Future<void> _performVibeSearch(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _saveSearch(trimmedQuery);

    setState(() {
      _isLoading = true;
      _isResultView = true;
      _searchResults = [];
      _vibeMetadata = {};
      _lastQuery = trimmedQuery;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiService.baseUrl}/search/vibe?query=${Uri.encodeQueryComponent(trimmedQuery)}',
            ),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }

      final dynamic data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        if (data is Map<String, dynamic>) {
          _searchResults = data['movies'] as List<dynamic>? ?? <dynamic>[];
          _vibeMetadata = data['metadata'] as Map<String, dynamic>? ?? {};
        } else if (data is List) {
          _searchResults = data;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isResultView = false;
      });
      final errorText = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorText.toLowerCase().contains('500')
                ? 'Server error. Please try again in a moment.'
                : errorText.toLowerCase().contains('timeout')
                    ? 'Request timed out. AI search may take a moment.'
                    : 'Connection lost: $errorText',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
        label: 'Library',
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
            selectedItemColor: Colors.purpleAccent,
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
      bottomNavigationBar: _isLoading ? null : _buildBottomNav(),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          if (!_isResultView) _buildLandingView() else _buildSwiperView(),
        ],
      ),
    );
  }

  Widget _buildLandingView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Vibe Check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe your mood or pick a vibe below',
              style: TextStyle(color: Colors.white30, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildMoodHeroPanel(),
            const SizedBox(height: 25),
            TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _performVibeSearch,
              decoration: InputDecoration(
                hintText: 'e.g. Rainy day in Tokyo...',
                hintStyle: const TextStyle(color: Colors.white12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.purpleAccent,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.arrow_circle_right_rounded,
                    color: Colors.purpleAccent,
                    size: 30,
                  ),
                  onPressed: () => _performVibeSearch(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 25),
              const Text(
                'Recent',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSearches.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _buildHistoryBox(_recentSearches[index]),
                ),
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              'Suggested Vibes',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vibeSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildSuggestionCard(_vibeSuggestions[index]),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String title) {
    return GestureDetector(
      onTap: () {
        _searchController.text = title;
        _performVibeSearch(title);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.01),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_motion_rounded,
              color: Colors.purpleAccent,
              size: 20,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHeroPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purpleAccent.withOpacity(0.18),
            Colors.redAccent.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'From moods to midnight obsessions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tell Kino how tonight feels and it will build a stack of movies that match the emotional energy.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _movieToStorageEntry(dynamic movie) {
    final Map<String, dynamic> safeMovie = Map<String, dynamic>.from(
      movie is Map ? movie : <String, dynamic>{},
    );
    return <String, dynamic>{
      'id': safeMovie['id'],
      'title': safeMovie['title'],
      'poster_path': safeMovie['poster_path'],
      'vote_average': safeMovie['vote_average'],
      'release_date': safeMovie['release_date'],
      'overview': safeMovie['overview'],
      'genres': safeMovie['genres'] ?? <dynamic>[],
      'rating': safeMovie['rating'],
    };
  }

  Widget _buildHistoryBox(String query) {
    return GestureDetector(
      onTap: () {
        _searchController.text = query;
        _performVibeSearch(query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
        ),
        child: Text(
          query,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSwiperView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.purpleAccent,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tuning into your vibe...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No movies found for that vibe.',
              style: TextStyle(color: Colors.white54),
            ),
            TextButton(
              onPressed: () => setState(() => _isResultView = false),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          top: 130,
          left: 0,
          right: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _searchResults.length,
                    numberOfCardsDisplayed: 3,
                    isLoop: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 0,
                    ),
                    onSwipe: (int prev, int? curr, CardSwiperDirection dir) {
                      if (dir == CardSwiperDirection.right) {
                        _storageService.addToWatchlist(
                          _movieToStorageEntry(_searchResults[prev]),
                        );
                        _showStatus('Saved to Watchlist');
                      } else if (dir == CardSwiperDirection.left) {
                        _showStatus('Rejected');
                      }
                      return true;
                    },
                    cardBuilder: (context, index, x, y) =>
                        _buildMovieCard(_searchResults[index]),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(bottom: 30, left: 20, right: 20, child: _buildVibeInsight()),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isResultView = false;
                              _vibeSuggestions.shuffle();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.undo, color: Colors.white60),
                          onPressed: () => _swiperController.undo(),
                        ),
                      ],
                    ),
                    if (_lastQuery.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            _lastQuery,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVibeInsight() {
    final mood = _vibeMetadata['mood'] ?? 'Tuned';
    final tone = _vibeMetadata['tone'] ?? 'Balanced';
    final keywords =
        (_vibeMetadata['keywords'] as List?)?.take(3).toList() ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: Colors.purpleAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vibe Insight',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInsightTag('Mood: $mood', Colors.blueAccent),
              _buildInsightTag('Tone: $tone', Colors.orangeAccent),
              for (final kw in keywords)
                _buildInsightTag(
                  kw.toString(),
                  Colors.purpleAccent.withOpacity(0.6),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMovieCard(dynamic movie) {
    final posterPath = movie['poster_path'];
    final imageUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w780$posterPath'
        : 'https://via.placeholder.com/780x1170?text=No+Poster';

    return GestureDetector(
      onTap: () async {
        final tab = await Navigator.push<int>(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        );
        if (tab != null && context.mounted) {
          Navigator.pop(context, tab);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 25,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['title'] ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          (movie['vote_average'] as num?)?.toStringAsFixed(1) ??
                              'N/A',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "${movie['runtime'] ?? '??'} min",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            movie['rating'] ?? 'PG',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIntegratedButton(
                          Icons.close,
                          Colors.redAccent,
                          () =>
                              _swiperController.swipe(CardSwiperDirection.left),
                        ),
                        _buildIntegratedButton(
                          Icons.favorite,
                          Colors.greenAccent,
                          () =>
                              _swiperController.swipe(CardSwiperDirection.right),
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

  Widget _buildIntegratedButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  void _showStatus(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.8),
          radius: 1.5,
          colors: [Color(0xFF3A1D52), Color(0xFF121212)],
        ),
      ),
    );
  }
}
