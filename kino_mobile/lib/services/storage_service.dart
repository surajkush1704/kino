import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _watchlistKey = 'watchlist';
  static const String _watchedKey = 'watched';
  static const String _likedKey = 'liked_movies';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _nsfwEnabledKey = 'nsfw_enabled';
  static const String _preferencesCompletedKey = 'preferences_completed';
  static const String _preferredGenresKey = 'preferred_genres';
  static const String _preferredLanguagesKey = 'preferred_languages';
  static const String _preferredIndustriesKey = 'preferred_industries';

  int? _movieIdFrom(Map<String, dynamic> movie) {
    final dynamic id = movie['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  List<String> _normalizeGenres(dynamic genres) {
    if (genres is List) {
      return genres
          .map((genre) => genre?.toString().trim() ?? '')
          .where((genre) => genre.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Map<String, dynamic> _normalizeMovie(Map movie) {
    final Map<String, dynamic> safeMovie = Map<String, dynamic>.from(movie);
    return <String, dynamic>{
      'id': _movieIdFrom(safeMovie),
      'title': (safeMovie['title'] ?? 'Unknown').toString(),
      'poster_path': safeMovie['poster_path']?.toString(),
      'vote_average': safeMovie['vote_average'] is num
          ? (safeMovie['vote_average'] as num).toDouble()
          : double.tryParse('${safeMovie['vote_average'] ?? 0}') ?? 0.0,
      'release_date': safeMovie['release_date']?.toString() ?? '',
      'overview': safeMovie['overview']?.toString() ?? '',
      'genres': _normalizeGenres(safeMovie['genres']),
    };
  }

  Future<List<Map<String, dynamic>>> _readMovies(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];

      return decoded
          .whereType<Map>()
          .map((movie) => Map<String, dynamic>.from(movie))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _writeMovies(
    String key,
    List<Map<String, dynamic>> movies,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(movies));
  }

  Future<void> _upsertMovie(String key, Map movie) async {
    final normalized = _normalizeMovie(movie);
    final int? movieId = _movieIdFrom(normalized);
    if (movieId == null) return;

    final movies = await _readMovies(key);
    final int existingIndex =
        movies.indexWhere((item) => _movieIdFrom(item) == movieId);

    if (existingIndex >= 0) {
      movies[existingIndex] = normalized;
    } else {
      movies.insert(0, normalized);
    }

    await _writeMovies(key, movies);
  }

  Future<void> _removeMovie(String key, int movieId) async {
    final movies = await _readMovies(key);
    movies.removeWhere((movie) => _movieIdFrom(movie) == movieId);
    await _writeMovies(key, movies);
  }

  Future<bool> _containsMovie(String key, int movieId) async {
    final movies = await _readMovies(key);
    return movies.any((movie) => _movieIdFrom(movie) == movieId);
  }

  Future<void> _writeStringList(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values);
  }

  Future<List<String>> _readStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? <String>[];
  }

  Future<void> addToWatchlist(Map movie) async {
    await _upsertMovie(_watchlistKey, movie);
  }

  Future<void> removeFromWatchlist(int movieId) async {
    await _removeMovie(_watchlistKey, movieId);
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    return _readMovies(_watchlistKey);
  }

  Future<bool> isInWatchlist(int movieId) async {
    return _containsMovie(_watchlistKey, movieId);
  }

  Future<void> addToWatched(Map movie) async {
    await _upsertMovie(_watchedKey, movie);
  }

  Future<void> removeFromWatched(int movieId) async {
    await _removeMovie(_watchedKey, movieId);
  }

  Future<List<Map<String, dynamic>>> getWatched() async {
    return _readMovies(_watchedKey);
  }

  Future<bool> isWatched(int movieId) async {
    return _containsMovie(_watchedKey, movieId);
  }

  Future<void> toggleLike(Map movie) async {
    final normalized = _normalizeMovie(movie);
    final int? movieId = _movieIdFrom(normalized);
    if (movieId == null) return;

    final liked = await _readMovies(_likedKey);
    final bool alreadyLiked =
        liked.any((item) => _movieIdFrom(item) == movieId);

    if (alreadyLiked) {
      liked.removeWhere((item) => _movieIdFrom(item) == movieId);
    } else {
      liked.insert(0, normalized);
    }

    await _writeMovies(_likedKey, liked);
  }

  Future<List<Map<String, dynamic>>> getLiked() async {
    return _readMovies(_likedKey);
  }

  Future<bool> isLiked(int movieId) async {
    return _containsMovie(_likedKey, movieId);
  }

  Future<bool> getNsfwEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_nsfwEnabledKey) ?? false;
  }

  Future<void> setNsfwEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nsfwEnabledKey, value);
  }

  Future<bool> hasCompletedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preferencesCompletedKey) ?? false;
  }

  Future<void> saveUserPreferences({
    required List<String> genres,
    required List<String> languages,
    required List<String> industries,
  }) async {
    await _writeStringList(_preferredGenresKey, genres);
    await _writeStringList(_preferredLanguagesKey, languages);
    await _writeStringList(_preferredIndustriesKey, industries);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferencesCompletedKey, true);
  }

  Future<Map<String, List<String>>> getUserPreferences() async {
    return <String, List<String>>{
      'genres': await _readStringList(_preferredGenresKey),
      'languages': await _readStringList(_preferredLanguagesKey),
      'industries': await _readStringList(_preferredIndustriesKey),
    };
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchlistKey);
    await prefs.remove(_watchedKey);
    await prefs.remove(_likedKey);
    await prefs.remove(_recentSearchesKey);
  }

  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentSearchesKey) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveRecentSearch(String term) async {
    final String normalized = term.trim();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> searches =
        prefs.getStringList(_recentSearchesKey) ?? <String>[];

    searches.removeWhere(
      (search) => search.toLowerCase() == normalized.toLowerCase(),
    );
    searches.insert(0, normalized);

    if (searches.length > 6) {
      searches.removeRange(6, searches.length);
    }

    await prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> removeRecentSearch(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> searches =
        prefs.getStringList(_recentSearchesKey) ?? <String>[];
    searches.removeWhere(
      (search) => search.toLowerCase() == term.trim().toLowerCase(),
    );
    await prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
