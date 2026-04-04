import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _watchlistKey = 'watchlist';
  static const String _watchedKey = 'watched';
  static const String _likedKey = 'liked_movies';
  static const String _recentBrowsedKey = 'recently_browsed';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _nsfwEnabledKey = 'nsfw_enabled';
  static const String _adultVerifiedKey = 'adult_verified';
  static const String _preferencesCompletedKey = 'preferences_completed';
  static const String _preferredGenresKey = 'preferred_genres';
  static const String _preferredLanguagesKey = 'preferred_languages';
  static const String _preferredIndustriesKey = 'preferred_industries';

  static const String _usersCollection = 'users';
  static const String _profileCollection = 'preferences';
  static const String _watchlistCollection = 'watchlist';
  static const String _watchedCollection = 'watched';
  static const String _likedCollection = 'liked_movies';
  static const String _recentBrowsedCollection = 'recently_browsed';

  static const int _recentlyBrowsedLimit = 20;

  int? _movieIdFrom(Map<String, dynamic> movie) {
    final dynamic id = movie['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  bool get _isSignedIn => _currentUser != null;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final User? user = _currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection(_usersCollection).doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>>? _collectionForStorageKey(
    String key,
  ) {
    final userDoc = _userDoc;
    if (userDoc == null) return null;

    final String? collectionName = <String, String>{
      _watchlistKey: _watchlistCollection,
      _watchedKey: _watchedCollection,
      _likedKey: _likedCollection,
      _recentBrowsedKey: _recentBrowsedCollection,
    }[key];

    if (collectionName == null) return null;
    return userDoc.collection(collectionName);
  }

  List<String> _normalizeGenres(dynamic genres) {
    if (genres is List) {
      return genres
          .map((genre) {
            if (genre is Map) {
              return (genre['name'] ?? '').toString().trim();
            }
            return genre?.toString().trim() ?? '';
          })
          .where((genre) => genre.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Map<String, dynamic> _normalizeMovie(
    Map movie, {
    DateTime? viewedAt,
  }) {
    final Map<String, dynamic> safeMovie = Map<String, dynamic>.from(movie);
    final String? storedViewedAt =
        safeMovie['viewed_at']?.toString().trim().isEmpty ?? true
            ? null
            : safeMovie['viewed_at']?.toString();

    return <String, dynamic>{
      'id': _movieIdFrom(Map<String, dynamic>.from(safeMovie)),
      'title': (safeMovie['title'] ?? 'Unknown').toString(),
      'poster_path': safeMovie['poster_path']?.toString(),
      'vote_average': safeMovie['vote_average'] is num
          ? (safeMovie['vote_average'] as num).toDouble()
          : double.tryParse('${safeMovie['vote_average'] ?? 0}') ?? 0.0,
      'release_date': safeMovie['release_date']?.toString() ?? '',
      'overview': safeMovie['overview']?.toString() ?? '',
      'genres': _normalizeGenres(safeMovie['genres']),
      'original_language': safeMovie['original_language']?.toString(),
      'rating': safeMovie['rating']?.toString(),
      'viewed_at': (viewedAt ?? DateTime.tryParse(storedViewedAt ?? ''))
              ?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _mergeMovieLists(
    List<Map<String, dynamic>> primary,
    List<Map<String, dynamic>> secondary, {
    int? limit,
  }) {
    final List<Map<String, dynamic>> merged = <Map<String, dynamic>>[];
    final Set<int> seen = <int>{};

    void addMovies(List<Map<String, dynamic>> items) {
      for (final movie in items) {
        final int? movieId = _movieIdFrom(movie);
        if (movieId == null || seen.contains(movieId)) continue;
        seen.add(movieId);
        merged.add(movie);
        if (limit != null && merged.length >= limit) {
          return;
        }
      }
    }

    addMovies(primary);
    if (limit == null || merged.length < limit) {
      addMovies(secondary);
    }

    return merged;
  }

  Future<List<Map<String, dynamic>>> _readMoviesLocal(String key) async {
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

  Future<void> _writeMoviesLocal(
    String key,
    List<Map<String, dynamic>> movies,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(movies));
  }

  Future<List<Map<String, dynamic>>> _readMoviesRemote(String key) async {
    final collection = _collectionForStorageKey(key);
    if (collection == null) return <Map<String, dynamic>>[];

    try {
      Query<Map<String, dynamic>> query = collection.orderBy(
        'saved_at',
        descending: true,
      );
      if (key == _recentBrowsedKey) {
        query = query.limit(_recentlyBrowsedLimit);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data(),
            );
            final dynamic savedAt = data.remove('saved_at');
            if (savedAt is Timestamp && !data.containsKey('viewed_at')) {
              data['viewed_at'] = savedAt.toDate().toIso8601String();
            }
            return data;
          })
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _writeMovieRemote(String key, Map<String, dynamic> movie) async {
    final collection = _collectionForStorageKey(key);
    final int? movieId = _movieIdFrom(movie);
    if (collection == null || movieId == null) return;

    await collection.doc('$movieId').set(
      <String, dynamic>{
        ...movie,
        'saved_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _removeMovieRemote(String key, int movieId) async {
    final collection = _collectionForStorageKey(key);
    if (collection == null) return;
    await collection.doc('$movieId').delete();
  }

  Future<void> _seedRemoteIfNeeded(
    String key,
    List<Map<String, dynamic>> localMovies,
  ) async {
    if (!_isSignedIn || localMovies.isEmpty) return;

    final collection = _collectionForStorageKey(key);
    if (collection == null) return;

    final remoteExisting = await _readMoviesRemote(key);
    if (remoteExisting.isNotEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final movie in localMovies) {
      final int? movieId = _movieIdFrom(movie);
      if (movieId == null) continue;
      batch.set(
        collection.doc('$movieId'),
        <String, dynamic>{
          ...movie,
          'saved_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> _getMovies(String key) async {
    final List<Map<String, dynamic>> localMovies = await _readMoviesLocal(key);
    if (!_isSignedIn) return localMovies;

    try {
      await _seedRemoteIfNeeded(key, localMovies);
      final List<Map<String, dynamic>> remoteMovies =
          await _readMoviesRemote(key);
      final List<Map<String, dynamic>> merged = _mergeMovieLists(
        remoteMovies,
        localMovies,
        limit: key == _recentBrowsedKey ? _recentlyBrowsedLimit : null,
      );
      await _writeMoviesLocal(key, merged);
      return merged;
    } catch (_) {
      return localMovies;
    }
  }

  Future<void> _upsertMovie(String key, Map movie) async {
    final normalized = _normalizeMovie(movie);
    final int? movieId = _movieIdFrom(normalized);
    if (movieId == null) return;

    final movies = await _readMoviesLocal(key);
    final int existingIndex =
        movies.indexWhere((item) => _movieIdFrom(item) == movieId);

    if (existingIndex >= 0) {
      movies.removeAt(existingIndex);
    }
    movies.insert(0, normalized);

    if (key == _recentBrowsedKey && movies.length > _recentlyBrowsedLimit) {
      movies.removeRange(_recentlyBrowsedLimit, movies.length);
    }

    await _writeMoviesLocal(key, movies);

    if (_isSignedIn) {
      await _writeMovieRemote(key, normalized);
    }
  }

  Future<void> _removeMovie(String key, int movieId) async {
    final movies = await _readMoviesLocal(key);
    movies.removeWhere((movie) => _movieIdFrom(movie) == movieId);
    await _writeMoviesLocal(key, movies);

    if (_isSignedIn) {
      await _removeMovieRemote(key, movieId);
    }
  }

  Future<bool> _containsMovie(String key, int movieId) async {
    final movies = await _getMovies(key);
    return movies.any((movie) => _movieIdFrom(movie) == movieId);
  }

  Future<void> _writeStringListLocal(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values);
  }

  Future<List<String>> _readStringListLocal(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? <String>[];
  }

  Future<Map<String, dynamic>> _readRemotePreferences() async {
    final userDoc = _userDoc;
    if (userDoc == null) return <String, dynamic>{};

    try {
      final snapshot = await userDoc.collection(_profileCollection).doc('prefs').get();
      return snapshot.data() ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeRemotePreferences(Map<String, dynamic> data) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;

    await userDoc.collection(_profileCollection).doc('prefs').set(
      <String, dynamic>{
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addToWatchlist(Map movie) async {
    await _upsertMovie(_watchlistKey, movie);
  }

  Future<void> removeFromWatchlist(int movieId) async {
    await _removeMovie(_watchlistKey, movieId);
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    return _getMovies(_watchlistKey);
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
    return _getMovies(_watchedKey);
  }

  Future<bool> isWatched(int movieId) async {
    return _containsMovie(_watchedKey, movieId);
  }

  Future<void> addToLiked(Map movie) async {
    await _upsertMovie(_likedKey, movie);
  }

  Future<void> removeFromLiked(int movieId) async {
    await _removeMovie(_likedKey, movieId);
  }

  Future<void> toggleLike(Map movie) async {
    final normalized = _normalizeMovie(movie);
    final int? movieId = _movieIdFrom(normalized);
    if (movieId == null) return;

    final bool alreadyLiked = await isLiked(movieId);
    if (alreadyLiked) {
      await removeFromLiked(movieId);
    } else {
      await addToLiked(normalized);
    }
  }

  Future<List<Map<String, dynamic>>> getLiked() async {
    return _getMovies(_likedKey);
  }

  Future<bool> isLiked(int movieId) async {
    return _containsMovie(_likedKey, movieId);
  }

  Future<void> addToRecentlyBrowsed(Map movie) async {
    await _upsertMovie(_recentBrowsedKey, movie);
  }

  Future<List<Map<String, dynamic>>> getRecentlyBrowsed() async {
    return _getMovies(_recentBrowsedKey);
  }

  Future<void> removeFromRecentlyBrowsed(int movieId) async {
    await _removeMovie(_recentBrowsedKey, movieId);
  }

  Future<bool> getNsfwEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final bool local = prefs.getBool(_nsfwEnabledKey) ?? false;
    if (!_isSignedIn) return local;

    final remote = await _readRemotePreferences();
    if (remote.containsKey(_nsfwEnabledKey)) {
      final bool value = remote[_nsfwEnabledKey] == true;
      await prefs.setBool(_nsfwEnabledKey, value);
      return value;
    }

    await _writeRemotePreferences(<String, dynamic>{_nsfwEnabledKey: local});
    return local;
  }

  Future<void> setNsfwEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nsfwEnabledKey, value);
    if (_isSignedIn) {
      await _writeRemotePreferences(<String, dynamic>{_nsfwEnabledKey: value});
    }
  }

  Future<bool> getAdultVerified() async {
    final prefs = await SharedPreferences.getInstance();
    final bool local = prefs.getBool(_adultVerifiedKey) ?? false;
    if (!_isSignedIn) return local;

    final remote = await _readRemotePreferences();
    if (remote.containsKey(_adultVerifiedKey)) {
      final bool value = remote[_adultVerifiedKey] == true;
      await prefs.setBool(_adultVerifiedKey, value);
      return value;
    }

    if (local) {
      await _writeRemotePreferences(<String, dynamic>{_adultVerifiedKey: true});
    }
    return local;
  }

  Future<void> setAdultVerified(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adultVerifiedKey, value);
    if (_isSignedIn) {
      await _writeRemotePreferences(<String, dynamic>{_adultVerifiedKey: value});
    }
  }

  Future<bool> canAccessMatureContent() async {
    final results = await Future.wait<bool>([
      getNsfwEnabled(),
      getAdultVerified(),
    ]);
    return results[0] && results[1];
  }

  Future<bool> hasCompletedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bool localCompleted = prefs.getBool(_preferencesCompletedKey) ?? false;
    if (!_isSignedIn) return localCompleted;

    final remote = await _readRemotePreferences();
    if (remote.containsKey(_preferencesCompletedKey)) {
      final bool value = remote[_preferencesCompletedKey] == true;
      await prefs.setBool(_preferencesCompletedKey, value);
      return value;
    }

    return localCompleted;
  }

  Future<void> saveUserPreferences({
    required List<String> genres,
    required List<String> languages,
    required List<String> industries,
  }) async {
    await _writeStringListLocal(_preferredGenresKey, genres);
    await _writeStringListLocal(_preferredLanguagesKey, languages);
    await _writeStringListLocal(_preferredIndustriesKey, industries);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferencesCompletedKey, true);

    if (_isSignedIn) {
      await _writeRemotePreferences(<String, dynamic>{
        _preferredGenresKey: genres,
        _preferredLanguagesKey: languages,
        _preferredIndustriesKey: industries,
        _preferencesCompletedKey: true,
      });
    }
  }

  Future<Map<String, List<String>>> getUserPreferences() async {
    final Map<String, List<String>> local = <String, List<String>>{
      'genres': await _readStringListLocal(_preferredGenresKey),
      'languages': await _readStringListLocal(_preferredLanguagesKey),
      'industries': await _readStringListLocal(_preferredIndustriesKey),
    };

    if (!_isSignedIn) return local;

    final remote = await _readRemotePreferences();
    if (remote.isEmpty) {
      if (local.values.any((items) => items.isNotEmpty)) {
        await _writeRemotePreferences(<String, dynamic>{
          _preferredGenresKey: local['genres'],
          _preferredLanguagesKey: local['languages'],
          _preferredIndustriesKey: local['industries'],
          _preferencesCompletedKey: true,
        });
      }
      return local;
    }

    final List<String> genres = ((remote[_preferredGenresKey] as List?) ?? [])
        .map((item) => item.toString())
        .toList();
    final List<String> languages =
        ((remote[_preferredLanguagesKey] as List?) ?? [])
            .map((item) => item.toString())
            .toList();
    final List<String> industries =
        ((remote[_preferredIndustriesKey] as List?) ?? [])
            .map((item) => item.toString())
            .toList();

    await _writeStringListLocal(_preferredGenresKey, genres);
    await _writeStringListLocal(_preferredLanguagesKey, languages);
    await _writeStringListLocal(_preferredIndustriesKey, industries);

    return <String, List<String>>{
      'genres': genres.isNotEmpty ? genres : local['genres'] ?? <String>[],
      'languages': languages.isNotEmpty
          ? languages
          : local['languages'] ?? <String>[],
      'industries': industries.isNotEmpty
          ? industries
          : local['industries'] ?? <String>[],
    };
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchlistKey);
    await prefs.remove(_watchedKey);
    await prefs.remove(_likedKey);
    await prefs.remove(_recentBrowsedKey);
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
