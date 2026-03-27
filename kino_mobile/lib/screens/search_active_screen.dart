import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../movie_detail_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class SearchGenreOption {
  final String name;
  final String emoji;
  final Color color;
  final int genreId;

  const SearchGenreOption({
    required this.name,
    required this.emoji,
    required this.color,
    required this.genreId,
  });
}

const List<SearchGenreOption> searchGenreOptions = <SearchGenreOption>[
  SearchGenreOption(name: 'Action', emoji: '🔥', color: Color(0xFFFF6B6B), genreId: 28),
  SearchGenreOption(name: 'Comedy', emoji: '😂', color: Color(0xFFFFD166), genreId: 35),
  SearchGenreOption(name: 'Drama', emoji: '💔', color: Color(0xFF74B9FF), genreId: 18),
  SearchGenreOption(name: 'Thriller', emoji: '😱', color: Color(0xFF636E72), genreId: 53),
  SearchGenreOption(name: 'Horror', emoji: '👻', color: Color(0xFF2D3436), genreId: 27),
  SearchGenreOption(name: 'Romance', emoji: '💕', color: Color(0xFFFF7AA2), genreId: 10749),
  SearchGenreOption(name: 'Sci-Fi', emoji: '🚀', color: Color(0xFF9B5DE5), genreId: 878),
  SearchGenreOption(name: 'Animation', emoji: '🎨', color: Color(0xFFFF9F43), genreId: 16),
  SearchGenreOption(name: 'Documentary', emoji: '📽', color: Color(0xFF95A5A6), genreId: 99),
  SearchGenreOption(name: 'Mystery', emoji: '🔍', color: Color(0xFF4ECDC4), genreId: 9648),
  SearchGenreOption(name: 'Fantasy', emoji: '⚔️', color: Color(0xFFECCC68), genreId: 14),
  SearchGenreOption(name: 'Crime', emoji: '🦹', color: Color(0xFFC44536), genreId: 80),
  SearchGenreOption(name: 'Adventure', emoji: '🌍', color: Color(0xFF2ECC71), genreId: 12),
];

const Map<String, int> _genreNameToId = <String, int>{
  'Action': 28,
  'Comedy': 35,
  'Drama': 18,
  'Thriller': 53,
  'Horror': 27,
  'Romance': 10749,
  'Sci-Fi': 878,
  'Animation': 16,
  'Documentary': 99,
  'Mystery': 9648,
  'Fantasy': 14,
  'Crime': 80,
  'Adventure': 12,
  'History': 36,
  'Music': 10402,
  'War': 10752,
  'Western': 37,
  'Family': 10751,
};

int? genreIdFromName(String name) => _genreNameToId[name];

const List<String> _advancedGenres = <String>[
  'Action',
  'Comedy',
  'Drama',
  'Thriller',
  'Horror',
  'Romance',
  'Sci-Fi',
  'Animation',
  'Documentary',
  'Mystery',
  'Fantasy',
  'Crime',
  'Adventure',
  'History',
  'Music',
  'War',
  'Western',
  'Family',
];

const List<String> _decades = <String>[
  'Classic',
  '70s',
  '80s',
  '90s',
  '2000s',
  '2010s',
  '2020s',
  'Latest',
];

const Map<String, String> _languageMap = <String, String>{
  'Hindi': 'hi',
  'English': 'en',
  'Tamil': 'ta',
  'Telugu': 'te',
  'Malayalam': 'ml',
  'Kannada': 'kn',
  'Korean': 'ko',
  'Japanese': 'ja',
  'Spanish': 'es',
  'French': 'fr',
  'Any': 'any',
};

const List<Map<String, String>> _languageOptions = <Map<String, String>>[
  {'label': '🇮🇳 Hindi', 'value': 'Hindi'},
  {'label': '🇬🇧 English', 'value': 'English'},
  {'label': '🇮🇳 Tamil', 'value': 'Tamil'},
  {'label': '🇮🇳 Telugu', 'value': 'Telugu'},
  {'label': '🇮🇳 Malayalam', 'value': 'Malayalam'},
  {'label': '🇮🇳 Kannada', 'value': 'Kannada'},
  {'label': '🇰🇷 Korean', 'value': 'Korean'},
  {'label': '🇯🇵 Japanese', 'value': 'Japanese'},
  {'label': '🇪🇸 Spanish', 'value': 'Spanish'},
  {'label': '🇫🇷 French', 'value': 'French'},
  {'label': '🌐 Any', 'value': 'Any'},
];

class SearchActiveScreen extends StatefulWidget {
  final String initialQuery;
  final String? preselectedGenre;
  final bool startInAdvancedTab;
  final ValueChanged<int>? onNavigateToTab;

  const SearchActiveScreen({
    super.key,
    this.initialQuery = '',
    this.preselectedGenre,
    this.startInAdvancedTab = false,
    this.onNavigateToTab,
  });

  @override
  State<SearchActiveScreen> createState() => _SearchActiveScreenState();
}

class _SearchActiveScreenState extends State<SearchActiveScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CardSwiperController _swiperController = CardSwiperController();
  final StorageService _storageService = StorageService();

  late final TabController _tabController;
  Timer? _debounce;

  List<String> _recentSearches = <String>[];
  List<dynamic> _trendingMovies = <dynamic>[];
  List<dynamic> _results = <dynamic>[];

  bool _isLoadingTrending = true;
  bool _isLoadingResults = false;
  String? _errorMessage;
  bool _hasSearched = false;

  final Set<String> _selectedTypes = <String>{'movie'};
  final Set<String> _selectedGenres = <String>{};
  final Set<String> _selectedLanguages = <String>{'Any'};
  double _minimumRating = 0;
  String? _selectedDecade;

  bool get _showResults =>
      _hasSearched || _results.isNotEmpty || _isLoadingResults || _errorMessage != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startInAdvancedTab ? 1 : 0,
    );
    _searchController.text = widget.initialQuery;
    if (widget.preselectedGenre != null) {
      _selectedGenres.add(widget.preselectedGenre!);
    }
    _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (widget.initialQuery.trim().isNotEmpty) {
        _performLiveSearch(widget.initialQuery.trim(), saveSearch: false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _keywordController.dispose();
    _focusNode.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait<void>([
      _loadRecentSearches(),
      _loadTrendingMovies(),
    ]);
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _storageService.getRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

  Future<void> _loadTrendingMovies() async {
    try {
      final movies = await ApiService.getTrendingMovies();
      if (!mounted) return;
      setState(() {
        _trendingMovies = movies.take(10).toList();
        _isLoadingTrending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _performLiveSearch(
    String query, {
    bool saveSearch = false,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = <dynamic>[];
        _isLoadingResults = false;
        _errorMessage = null;
        _hasSearched = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingResults = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.searchMovieCatalog(trimmed);
      if (saveSearch) {
        await _storageService.saveRecentSearch(trimmed);
        await _loadRecentSearches();
      }
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoadingResults = false;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = <dynamic>[];
        _isLoadingResults = false;
        _errorMessage = 'Could not load search results.';
        _hasSearched = true;
      });
    }
  }

  Future<void> _runAdvancedSearch() async {
    setState(() {
      _isLoadingResults = true;
      _errorMessage = null;
      _results = <dynamic>[];
      _hasSearched = true;
    });

    String contentType = 'movie';
    if (_selectedTypes.length == 1 && _selectedTypes.contains('tv')) {
      contentType = 'tv';
    } else if (_selectedTypes.length == 1 && _selectedTypes.contains('anime')) {
      contentType = 'anime';
    }

    final List<int> genreIds = _selectedGenres
        .map((genre) => genreIdFromName(genre))
        .whereType<int>()
        .toList();

    if (_selectedTypes.contains('documentary') && !genreIds.contains(99)) {
      genreIds.add(99);
    }

    final String keywords = [
      if (_selectedTypes.contains('short')) 'short film',
      _keywordController.text.trim(),
    ].where((value) => value.isNotEmpty).join(', ');

    final List<String> languages = _selectedLanguages
        .map((label) => _languageMap[label] ?? 'any')
        .where((value) => value.isNotEmpty)
        .toList();

    try {
      final results = await ApiService.advancedSearch(
        contentType: contentType,
        minRating: _minimumRating,
        genreIds: genreIds,
        decade: _selectedDecade?.toLowerCase(),
        keywords: keywords,
        languages: languages,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoadingResults = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = <dynamic>[];
        _isLoadingResults = false;
        _errorMessage = 'Advanced search failed.';
        _hasSearched = true;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (mounted) {
      setState(() {});
    }
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = <dynamic>[];
        _errorMessage = null;
        _isLoadingResults = false;
        _hasSearched = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performLiveSearch(value);
    });
  }

  Future<void> _onRecentTap(String term) async {
    _searchController.text = term;
    await _performLiveSearch(term, saveSearch: true);
  }

  Future<void> _openMovie(dynamic movie) async {
    final String mediaType = (movie['media_type'] ?? 'movie').toString();
    if (mediaType != 'movie') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Detailed pages are currently available for movie results only.',
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
      Navigator.pop(context);
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) => _performLiveSearch(value, saveSearch: true),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search movies, series, anime...',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
                setState(() {});
              },
              icon: const Icon(Icons.close, color: Colors.white38),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentChips() {
    if (_recentSearches.isEmpty) {
      return const Text(
        'Recent searches will appear here.',
        style: TextStyle(color: Colors.white38),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _recentSearches.map((term) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              backgroundColor: const Color(0xFF1B1B1B),
              side: const BorderSide(color: Colors.white12),
              label: Text(
                term,
                style: const TextStyle(color: Colors.white70),
              ),
              onPressed: () => _onRecentTap(term),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendingCards() {
    if (_isLoadingTrending) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _trendingMovies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = _trendingMovies[index];
          final String imageUrl =
              'https://image.tmdb.org/t/p/w500${movie['poster_path'] ?? ''}';
          return GestureDetector(
            onTap: () => _openMovie(movie),
            child: SizedBox(
              width: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF222222),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.movie_filter_outlined,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (movie['title'] ?? 'Unknown').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      side: BorderSide(
        color: selected ? Colors.purpleAccent : Colors.white12,
      ),
      selectedColor: Colors.purpleAccent.withOpacity(0.2),
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildResultsDeck() {
    if (_isLoadingResults) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No results found.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _swiperController.undo(),
                  icon: const Icon(Icons.undo, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _results.length,
              numberOfCardsDisplayed: 3,
              padding: const EdgeInsets.all(24),
              onSwipe: (_, __, ___) => true,
              cardBuilder:
                  (context, index, horizontalThreshold, verticalThreshold) {
                final item = _results[index];
                final dynamic posterPath = item['poster_path'];
                final String imageUrl =
                    (posterPath ?? '').toString().startsWith('http')
                        ? posterPath.toString()
                        : 'https://image.tmdb.org/t/p/w500${posterPath ?? ''}';
                return GestureDetector(
                  onTap: () => _openMovie(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: const Color(0xFF1A1A1A),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF222222),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.88),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (item['title'] ?? 'Unknown').toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (item['overview'] ?? '').toString(),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAndTrendingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecentChips(),
        const SizedBox(height: 28),
        const Text(
          'Trending Now 🔥',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        _buildTrendingCards(),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    final bool isEnabled = _selectedTypes.isNotEmpty ||
        _minimumRating > 0 ||
        _selectedGenres.isNotEmpty ||
        _selectedDecade != null ||
        _keywordController.text.trim().isNotEmpty ||
        (_selectedLanguages.isNotEmpty && !_selectedLanguages.contains('Any'));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const Text(
          'Type',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ('🎬 Movie', 'movie'),
            ('📺 TV Series', 'tv'),
            ('🎌 Anime', 'anime'),
            ('📱 Short Film', 'short'),
            ('🎭 Documentary', 'documentary'),
          ].map((item) {
            final selected = _selectedTypes.contains(item.$2);
            return _buildFilterChip(
              label: item.$1,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedTypes.remove(item.$2);
                  } else {
                    _selectedTypes.add(item.$2);
                  }
                  if (_selectedTypes.isEmpty) {
                    _selectedTypes.add('movie');
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Minimum Rating ⭐  ${_minimumRating.toStringAsFixed(1)}+',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        Slider(
          value: _minimumRating,
          min: 0,
          max: 10,
          divisions: 20,
          activeColor: Colors.purpleAccent,
          inactiveColor: Colors.white12,
          label: '${_minimumRating.toStringAsFixed(1)}+',
          onChanged: (value) => setState(() => _minimumRating = value),
        ),
        const SizedBox(height: 16),
        const Text(
          'Genres 🎬',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _advancedGenres.map((genre) {
            return _buildFilterChip(
              label: genre,
              selected: _selectedGenres.contains(genre),
              onTap: () {
                setState(() {
                  if (_selectedGenres.contains(genre)) {
                    _selectedGenres.remove(genre);
                  } else {
                    _selectedGenres.add(genre);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Era 📅',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _decades.map((decade) {
            return _buildFilterChip(
              label: decade,
              selected: _selectedDecade == decade,
              onTap: () {
                setState(() {
                  _selectedDecade = _selectedDecade == decade ? null : decade;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Keywords 🔑',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _keywordController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'time travel, heist, based on book',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Language 🌍',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _languageOptions.map((option) {
            final value = option['value']!;
            final selected = _selectedLanguages.contains(value);
            return _buildFilterChip(
              label: option['label']!,
              selected: selected,
              onTap: () {
                setState(() {
                  if (value == 'Any') {
                    _selectedLanguages
                      ..clear()
                      ..add('Any');
                  } else {
                    _selectedLanguages.remove('Any');
                    if (selected) {
                      _selectedLanguages.remove(value);
                    } else {
                      _selectedLanguages.add(value);
                    }
                    if (_selectedLanguages.isEmpty) {
                      _selectedLanguages.add('Any');
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: isEnabled ? _runAdvancedSearch : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Search 🔍',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: _buildSearchBar(),
              ),
              if (!_showResults)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF191919),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      tabs: const [
                        Tab(text: 'Recent & Trending'),
                        Tab(text: 'Advanced Search 🔍'),
                      ],
                    ),
                  ),
                ),
              if (_showResults)
                _buildResultsDeck()
              else
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecentAndTrendingTab(),
                      _buildAdvancedTab(),
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
