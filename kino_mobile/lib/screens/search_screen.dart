import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CardSwiperController _swiperController = CardSwiperController();

  bool _isLoading = false;
  List<dynamic> _searchResults = [];

  final String _baseUrl = "http://127.0.0.1:8000";

  @override
  void dispose() {
    _searchController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _performMovieSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/api/v1/search/movie?query=$query"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data['results'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Search Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                if (_searchResults.isNotEmpty && !_isLoading)
                  _buildControlBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          ),
                        )
                      : _searchResults.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsDeck(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => _swiperController.undo(),
            icon: const Icon(Icons.undo, color: Colors.white70),
            tooltip: "Undo Swipe",
          ),
        ],
      ),
    );
  }

  Widget _buildResultsDeck() {
    // FIX: Use cardBuilder and cardsCount as required by your 7.x package version
    return CardSwiper(
      controller: _swiperController,
      cardsCount: _searchResults.length, // REQUIRED parameter
      numberOfCardsDisplayed: 3,
      padding: const EdgeInsets.all(24.0),
      onSwipe:
          (
            int previousIndex,
            int? currentIndex,
            CardSwiperDirection direction,
          ) {
            if (direction == CardSwiperDirection.right) {
              debugPrint(
                "Saved to Watchlist: ${_searchResults[previousIndex]['title']}",
              );
            }
            return true; // REQUIRED: Must return a bool to confirm the swipe
          },
      // REQUIRED parameter: Use cardBuilder instead of 'cards' list
      cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
        final movie = _searchResults[index];
        final posterPath = movie['poster_path'];
        final imageUrl = posterPath != null
            ? "https://image.tmdb.org/t/p/w500$posterPath"
            : "https://via.placeholder.com/500x750?text=No+Image";

        return ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            color: Colors.grey[900],
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(
                            242,
                          ), // Fixed: Use withAlpha to avoid deprecation
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie['title'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie['overview'] ?? '',
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
        );
      },
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.all(20),
    child: Text(
      "Kino Vibe",
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      onSubmitted: _performMovieSearch,
      decoration: const InputDecoration(
        hintText: "Search movies...",
        hintStyle: TextStyle(color: Colors.white30),
        prefixIcon: Icon(Icons.search, color: Colors.white70),
      ),
    ),
  );

  Widget _buildBackgroundGlow() => Positioned(
    top: -50,
    left: -50,
    child: Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.redAccent.withAlpha(38),
      ),
    ),
  );

  Widget _buildEmptyState() => const Center(
    child: Text(
      "Search for a vibe to start swiping",
      style: TextStyle(color: Colors.white24),
    ),
  );
}
