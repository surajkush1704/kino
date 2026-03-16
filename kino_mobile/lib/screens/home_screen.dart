import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // Required for the Glass-morphism (ImageFilter)
import '../services/api_service.dart';
import '../movie_detail_screen.dart';
import '../widgets/kino_logo.dart';
import 'vibe_check_screen.dart'; // ADDED: Import for the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _trendingFuture;

  // --- Auto Slide Variables ---
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _timer;

  // --- Navigation Variables ---
  int _selectedIndex = 0;

  final Set<int> _likedMovies = {};

  @override
  void initState() {
    super.initState();
    _trendingFuture = ApiService.getTrendingMovies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleLike(int movieId) {
    setState(() {
      if (_likedMovies.contains(movieId)) {
        _likedMovies.remove(movieId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Removed from Watchlist"),
            duration: Duration(milliseconds: 500),
          ),
        );
      } else {
        _likedMovies.add(movieId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to Watchlist ❤️"),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBody: true,
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // 1. TOP BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const KinoLogo(),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 2. HERO CAROUSEL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      "KinoTadka 🔥",
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7000FF),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No movies found",
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

                  // 3. BENTO GRID
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Browse by Vibe",
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
                                  title: "Vibe Check",
                                  subtitle: "Mood Search",
                                  color: Colors.purpleAccent,
                                  icon: Icons.auto_awesome,
                                  // High-quality cinematic poster
                                  imageUrl: "assets/images/vibe_check.png",
                                  onTap: () {
                                    // UPDATED: Navigate to the Vibe Check Screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const VibeCheckScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: _buildBentoCard(
                                  title: "Anime",
                                  subtitle: "Japan",
                                  color: Colors.orangeAccent,
                                  icon: Icons.local_fire_department,
                                  // Fast-paced anime loop
                                  imageUrl: "assets/images/anime.png",
                                  onTap: () {},
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
                                  title: "For You",
                                  subtitle: "History",
                                  color: Colors.pinkAccent,
                                  icon: Icons.favorite,
                                  // Popcorn / Movie magic
                                  imageUrl: "assets/images/for_you.png",
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _buildBentoCard(
                                  title: "Classics",
                                  subtitle: "Top Rated",
                                  color: Colors.tealAccent,
                                  icon: Icons.star,
                                  // Vintage projector
                                  imageUrl: "assets/images/classics.png",
                                  onTap: () {},
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
            )
          : Center(
              child: Text(
                _selectedIndex == 1 ? "Search Page" : "Library Page",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),

      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: const Color(0xFF121212).withOpacity(0.7),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xFFD4AF37),
              unselectedItemColor: Colors.white30,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.video_library_rounded),
                  label: 'Library',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _buildHeroCard and _buildBentoCard remain identical to your previous version
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
        if (selectedTab != null && selectedTab is int) {
          setState(() {
            _selectedIndex = selectedTab;
          });
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
                onTap: () => _toggleLike(movieId),
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
              // 1. Static Cinematic Background Poster
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // 2. Dark Overlay for Text Readability
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
              // 3. Icon & Labels
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
                            color: Colors.white.withOpacity(0.8), // Boosted visibility
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
