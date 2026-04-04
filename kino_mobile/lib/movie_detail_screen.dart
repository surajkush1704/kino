import 'package:flutter/material.dart';
import 'dart:ui'; // Required for Blur and ImageFilter
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'services/api_service.dart'; // To get baseUrl
import 'services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this to your pubspec.yaml

class MovieDetailScreen extends StatefulWidget {
  final dynamic movie;
  final int initialTabIndex;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.initialTabIndex = 0,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Map<String, dynamic>? _fullDetails;
  bool _isLoading = true;
  bool _isRestrictedContent = false;
  late final int _selectedIndex;
  final StorageService _storageService = StorageService();

  // --- STATE VARIABLES FOR BUTTONS ---
  bool _isInWatchlist = false;
  bool _isWatched = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _loadSavedStatuses();
    _fetchFullDetails();
  }

  int? _movieIdFrom(dynamic movie) {
    final dynamic id = movie is Map ? movie['id'] : null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  Map<String, dynamic> _movieToStorageEntry() {
    final Map<String, dynamic> baseMovie = Map<String, dynamic>.from(
      (widget.movie is Map) ? widget.movie as Map : <String, dynamic>{},
    );
    final Map<String, dynamic> fullDetails =
        _fullDetails == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(_fullDetails!);

    return <String, dynamic>{
      ...baseMovie,
      ...fullDetails,
      'id': _movieIdFrom(widget.movie) ?? baseMovie['id'],
      'title': fullDetails['title'] ?? baseMovie['title'],
      'poster_path': fullDetails['poster_path'] ?? baseMovie['poster_path'],
      'overview': fullDetails['overview'] ?? baseMovie['overview'],
      'release_date': fullDetails['release_date'] ?? baseMovie['release_date'],
      'vote_average': fullDetails['vote_average'] ?? baseMovie['vote_average'],
      'genres': fullDetails['genres'] ?? baseMovie['genres'] ?? <dynamic>[],
    };
  }

  Future<void> _loadSavedStatuses() async {
    final int? movieId = _movieIdFrom(widget.movie);
    if (movieId == null) return;

    try {
      final results = await Future.wait<bool>([
        _storageService.isInWatchlist(movieId),
        _storageService.isWatched(movieId),
      ]);

      if (!mounted) return;
      setState(() {
        _isInWatchlist = results[0];
        _isWatched = results[1];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInWatchlist = false;
        _isWatched = false;
      });
    }
  }

  bool _isMatureRating(String? rating) {
    final String normalized = (rating ?? '').trim().toUpperCase();
    return normalized == 'R' ||
        normalized == 'NC-17' ||
        normalized == 'A' ||
        normalized == '18+' ||
        normalized == 'TV-MA' ||
        normalized == 'X';
  }

  Future<void> _syncRecentlyBrowsedAndAccess() async {
    final Map<String, dynamic> entry = _movieToStorageEntry();
    await _storageService.addToRecentlyBrowsed(entry);

    final bool canAccessMature = await _storageService.canAccessMatureContent();
    final bool restricted = _isMatureRating(entry['rating']?.toString()) &&
        !canAccessMature;

    if (!mounted) return;
    setState(() => _isRestrictedContent = restricted);
  }

  Future<void> _toggleWatchlist() async {
    final int? movieId = _movieIdFrom(widget.movie);
    if (movieId == null) return;

    if (_isInWatchlist) {
      await _storageService.removeFromWatchlist(movieId);
    } else {
      await _storageService.addToWatchlist(_movieToStorageEntry());
    }

    if (!mounted) return;
    setState(() => _isInWatchlist = !_isInWatchlist);
  }

  Future<void> _toggleWatched() async {
    final int? movieId = _movieIdFrom(widget.movie);
    if (movieId == null) return;

    if (_isWatched) {
      await _storageService.removeFromWatched(movieId);
    } else {
      await _storageService.addToWatched(_movieToStorageEntry());
    }

    if (!mounted) return;
    setState(() => _isWatched = !_isWatched);
  }

  Future<void> _fetchFullDetails() async {
    try {
      final movieId = widget.movie['id'];
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/movie/$movieId/details'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _fullDetails = json.decode(response.body);
          _isLoading = false;
        });
        await _syncRecentlyBrowsedAndAccess();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading details: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- STABLE YOUTUBE TRAILER LOGIC WITH FULLSCREEN & EXTERNAL LINK ---
  void _playTrailer(String? youtubeKey) {
    if (youtubeKey == null || youtubeKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Trailer not available")));
      return;
    }

    final YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: youtubeKey,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        useHybridComposition: false,
        disableDragSeek: false,
        // 👇 This helps the app know it should fill the screen 👇
        forceHD: false,
        enableCaption: true,
      ),
    );

    showDialog(
      context: context,
      useSafeArea: false, // Allows the dialog to go behind the notch/status bar
      builder: (context) => YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          // AspectRatio 16/9 is standard, but the Builder will handle the stretch
          aspectRatio: 16 / 9,
          onEnded: (meta) => Navigator.pop(context),
        ),
        builder: (context, player) {
          return Scaffold(
            // Use Scaffold instead of AlertDialog for true full-screen
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit
                        .contain, // Change to BoxFit.cover if you want NO black bars (crops slightly)
                    child: player,
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 30,
                    ),
                    onPressed: () {
                      controller.dispose();
                      Navigator.pop(context);
                    },
                  ),
                ),
                // Fallback button stays at the bottom
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(
                          "https://www.youtube.com/watch?v=$youtubeKey",
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      label: const Text(
                        "Watch on YouTube App",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper: Format Date
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "Unknown";
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    } catch (e) {
      /* ignore */
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final basicMovie = widget.movie;
    final posterPath =
        _fullDetails?['poster_path'] ?? basicMovie['poster_path'];
    final posterUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBody: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : CustomScrollView(
              slivers: [
                // 1. HEADER
                SliverAppBar(
                  expandedHeight: 550,
                  backgroundColor: const Color(0xFF121212),
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.black),
                          ),
                        ),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80, bottom: 20),
                            child: Container(
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black87,
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  posterUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. BODY
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _isRestrictedContent
                        ? _buildRestrictedNotice()
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullDetails?['title'] ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildTag(
                              Icons.calendar_today,
                              _formatDate(_fullDetails?['release_date']),
                              Colors.blueGrey,
                            ),
                            const SizedBox(width: 10),
                            _buildTag(
                              Icons.star,
                              "${_fullDetails?['vote_average']?.toStringAsFixed(1)}",
                              Colors.amber,
                            ),
                            const SizedBox(width: 10),
                            _buildTag(
                              Icons.timer,
                              "${_fullDetails?['runtime'] ?? '?'} min",
                              Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              (_fullDetails?['genres'] as List<dynamic>? ?? [])
                                  .map((g) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        g.toString(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _toggleWatchlist();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(
                                      context,
                                    ).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _isInWatchlist
                                            ? "Added to Watchlist ❤️"
                                            : "Removed from Watchlist",
                                      ),
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                    ),
                                  );
                                  } catch (_) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Could not update watchlist",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(
                                  _isInWatchlist ? Icons.remove : Icons.add,
                                ),
                                label: Text(
                                  _isInWatchlist
                                      ? "Remove from Watchlist"
                                      : "Add to Watchlist",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final bool wasWatched = _isWatched;
                                  try {
                                    await _toggleWatched();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(
                                      context,
                                    ).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          wasWatched
                                              ? "Marked as Unwatched"
                                              : "Marked as Watched",
                                        ),
                                        duration: const Duration(
                                          milliseconds: 700,
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Could not update watched list",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _isWatched
                                      ? Colors.green
                                      : Colors.transparent,
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: _isWatched
                                        ? Colors.green
                                        : Colors.white54,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: Icon(
                                  _isWatched ? Icons.check_circle : Icons.check,
                                ),
                                label: Text(
                                  _isWatched
                                      ? "Mark Unwatched"
                                      : "Mark Watched",
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "Overview",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fullDetails?['overview'] ?? "No description.",
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Media Box
                        const Text(
                          "Media & Trailers",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                (_fullDetails?['screenshots'] as List?)
                                    ?.length ??
                                1,
                            itemBuilder: (context, index) {
                              final screenshots =
                                  _fullDetails?['screenshots'] as List?;
                              final imgUrl =
                                  (screenshots != null &&
                                      screenshots.isNotEmpty)
                                  ? "https://image.tmdb.org/t/p/w500${screenshots[index]}"
                                  : posterUrl;

                              return GestureDetector(
                                onTap: () =>
                                    _playTrailer(_fullDetails?['trailer_key']),
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(imgUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: index == 0
                                      ? const Center(
                                          child: Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "Languages",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _buildLanguageChips(),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "Cast",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                (_fullDetails?['cast'] as List?)?.length ?? 0,
                            itemBuilder: (context, index) {
                              final actor = _fullDetails!['cast'][index];
                              return Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: actor['image'] != null
                                          ? NetworkImage(
                                              "https://image.tmdb.org/t/p/w200${actor['image']}",
                                            )
                                          : null,
                                      child: actor['image'] == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      actor['name'],
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "User Guide",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 20),
                              _buildGuideRow(
                                "Certificate",
                                _fullDetails?['rating'] ?? "Not Rated",
                              ),
                              _buildGuideRow(
                                "Violence & Gore",
                                (_fullDetails?['genres'] as List? ?? [])
                                        .contains("Horror")
                                    ? "Moderate"
                                    : "Mild",
                              ),
                              _buildGuideRow("Profanity", "Varies"),
                              _buildGuideRow(
                                "Frightening Scenes",
                                (_fullDetails?['genres'] as List? ?? [])
                                        .contains("Horror")
                                    ? "Severe"
                                    : "Mild",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "You Might Also Like",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                (_fullDetails?['similar_movies'] as List?)
                                    ?.length ??
                                0,
                            itemBuilder: (context, index) {
                              final sim =
                                  _fullDetails!['similar_movies'][index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MovieDetailScreen(movie: sim),
                                  ),
                                ),
                                child: Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          "https://image.tmdb.org/t/p/w200${sim['poster_path']}",
                                          height: 140,
                                          width: 110,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        sim['title'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
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
              onTap: (index) => Navigator.pop(context, index),
              selectedItemColor: const Color(0xFFD4AF37),
              unselectedItemColor: Colors.white30,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Library',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PRESERVED HELPER WIDGETS ---
  List<Widget> _buildLanguageChips() {
    final List<dynamic> languages = _fullDetails?['spoken_languages'] ?? [];
    if (languages.isEmpty && _fullDetails?['original_language'] != null) {
      languages.add({
        'name': _fullDetails!['original_language'].toString().toUpperCase(),
      });
    }
    if (languages.isEmpty) {
      return [const Text("English", style: TextStyle(color: Colors.white54))];
    }
    return languages.map((lang) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          lang['name']?.toString() ??
              lang['english_name']?.toString() ??
              "Unknown",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '18+ content locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'This title is rated for mature audiences. Sign in and enable 18+ access from your profile to view A-rated or R-rated movies.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_ios_new),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
