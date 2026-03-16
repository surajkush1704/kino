import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../movie_detail_screen.dart'; // Import from root lib

class VibeCheckScreen extends StatefulWidget {
  const VibeCheckScreen({super.key});

  @override
  State<VibeCheckScreen> createState() => _VibeCheckScreenState();
}

class _VibeCheckScreenState extends State<VibeCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CardSwiperController _swiperController = CardSwiperController();
  
  bool _isLoading = false;
  bool _isResultView = false;
  List<dynamic> _searchResults = [];
  Map<String, dynamic> _vibeMetadata = {}; // New storage for AI insights
  List<String> _recentSearches = [];

  final List<String> _vibeSuggestions = [
    "I want to cry tonight",
    "I had a bad day cheer me up",
    "I'm very happy suggest action movies",
    "Date night movie suggestions",
    "I want something dark and intense",
    "Show me cult classic movies",
    "I want anime adventures",
    "Give me motivational films",
  ];

  final String _baseUrl = "http://127.0.0.1:8000";

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

  // Persistance Logic
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('recent_searches') ?? [];
    
    // Remove if exists to move to top, limit to 6
    history.remove(query);
    history.insert(0, query);
    if (history.length > 6) history = history.sublist(0, 6);
    
    await prefs.setStringList('recent_searches', history);
    setState(() => _recentSearches = history);
  }

  Future<void> _performVibeSearch(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    _saveSearch(query);

    setState(() {
      _isLoading = true;
      _isResultView = true;
      _searchResults = [];
    });

    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/api/v1/search/vibe?query=$query"))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // New structure: { "movies": [...], "metadata": {...} }
            if (data is Map) {
              _searchResults = data['movies'] ?? [];
              _vibeMetadata = data['metadata'] ?? {};
            } else {
              _searchResults = data; // Fallback
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isResultView = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Lost: $e")),
        );
      }
    }
  }

//   void _playTrailer(String? trailerKey) {
//     if (trailerKey == null || trailerKey.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Trailer not available for this movie.")),
//       );
//       return;
//     }
// 
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.black,
//         insetPadding: const EdgeInsets.all(10),
//         child: YoutubePlayer(
//           controller: YoutubePlayerController(
//             initialVideoId: trailerKey,
//             flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
//           ),
//           showVideoProgressIndicator: true,
//         ),
//       ),
//     );
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          if (!_isResultView) _buildLandingView() else _buildSwiperView(),
        ],
      ),
    );
  }

  // --- VIEW 1: LANDING VIEW ---
  Widget _buildLandingView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADING
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 28),
                SizedBox(width: 10),
                Text(
                  "Vibe Check",
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
              "Describe your mood or pick a vibe below",
              style: TextStyle(color: Colors.white30, fontSize: 14),
            ),
            
            const SizedBox(height: 25),

            // SEARCH BAR AT TOP
            TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _performVibeSearch,
              decoration: InputDecoration(
                hintText: "e.g. Rainy day in Tokyo...",
                hintStyle: const TextStyle(color: Colors.white12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_circle_right_rounded, color: Colors.purpleAccent, size: 30),
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

            // RECENT SEARCHES UNDER BAR
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 25),
              const Text(
                "Recent",
                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSearches.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => _buildHistoryBox(_recentSearches[index]),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // VIBE SUGGESTIONS
            const Text(
              "Suggested Vibes",
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vibeSuggestions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildSuggestionCard(_vibeSuggestions[index]),
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
            const Icon(Icons.auto_awesome_motion_rounded, color: Colors.purpleAccent, size: 20),
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
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
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

  // --- VIEW 2: SWIPER VIEW ---
  Widget _buildSwiperView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character animation (Dog)
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(
                "https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJtZndueHJ6ZndueHJ6ZndueHJ6ZndueHJ6ZndueHJ6ZndueHJ6JmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7WIYlXJ9RkM3fOms/giphy.gif",
                height: 150,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.pets, color: Colors.purpleAccent, size: 80),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sniffing out your vibe...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
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
            const Text("No movies found for that vibe.", style: TextStyle(color: Colors.white54)),
            TextButton(
              onPressed: () => setState(() => _isResultView = false),
              child: const Text("Try Again", style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // The Swiper - Repositioned with more top gap
        Positioned(
          top: 130, // Increased from 100 for more breathing room
          left: 0,
          right: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480), // Adjusted size
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _searchResults.length,
                    numberOfCardsDisplayed: 3,
                    isLoop: false,
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    onSwipe: (int prev, int? curr, CardSwiperDirection dir) {
                      if (dir == CardSwiperDirection.right) {
                        _showStatus("Saved to Watchlist 💚");
                      } else if (dir == CardSwiperDirection.left) {
                        _showStatus("Rejected 💔");
                      }
                      return true;
                    },
                    cardBuilder: (context, index, x, y) => _buildMovieCard(_searchResults[index]),
                  ),
                ),
              ),
            ),
          ),
        ),

        // NEW: Vibe Insight Panel at the bottom
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: _buildVibeInsight(),
        ),

        // UI Overlays
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isResultView = false;
                          _vibeSuggestions.shuffle(); // Shuffle on return
                        });
                      },
                    ),
                    IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white60),
                        onPressed: () => _swiperController.undo()),
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
    final keywords = (_vibeMetadata['keywords'] as List?)?.take(3).toList() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                "Vibe Insight",
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
              _buildInsightTag("Mood: $mood", Colors.blueAccent),
              _buildInsightTag("Tone: $tone", Colors.orangeAccent),
              for (var kw in keywords)
                _buildInsightTag(kw.toString(), Colors.purpleAccent.withOpacity(0.6)),
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Removed _buildTopSegments as requested

  Widget _buildMovieCard(dynamic movie) {
    final posterPath = movie['poster_path'];
    final imageUrl = posterPath != null
        ? "https://image.tmdb.org/t/p/w780$posterPath"
        : "https://via.placeholder.com/780x1170?text=No+Poster";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              // Gradient Overlay
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
              // Movie Info
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
                          (movie['vote_average'] as num?)?.toStringAsFixed(1) ?? 'N/A',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "${movie['runtime'] ?? '??'} min",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            movie['rating'] ?? 'PG',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // INTEGRATED ACTION BUTTONS INSIDE CARD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIntegratedButton(
                          Icons.close, 
                          Colors.redAccent, 
                          () => _swiperController.swipe(CardSwiperDirection.left)
                        ),
                        _buildIntegratedButton(
                          Icons.favorite, 
                          Colors.greenAccent, 
                          () => _swiperController.swipe(CardSwiperDirection.right)
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

  Widget _buildIntegratedButton(IconData icon, Color color, VoidCallback onTap) {
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

  // Removed old _buildBottomControls and _buildActionButton as they are now integrated

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
          colors: [
            Color(0xFF2A1639),
            Color(0xFF121212),
          ],
        ),
      ),
    );
  }
}
