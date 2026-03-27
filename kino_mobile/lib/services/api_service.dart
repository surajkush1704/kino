import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String _apiOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_apiOverride.isNotEmpty) {
      return _apiOverride;
    }

    // Default to localhost so Android emulator and USB-debugged devices
    // work with `adb reverse tcp:8000 tcp:8000`.
    return 'http://127.0.0.1:8000/api/v1';
  }

  static Future<List<dynamic>> getTrendingMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies/trending'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  static Future<List<dynamic>> getClassicMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies/classics'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load classics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading classics: $e');
    }
  }

  static Future<List<dynamic>> getForYouMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies/foryou'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading recommendations: $e');
    }
  }

  static Future<List<dynamic>> searchMovies(
    String query, {
    String sortBy = 'popularity',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/vibe?query=$query&sort=$sortBy'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching: $e');
    }
  }

  static Future<List<dynamic>> searchMovieCatalog(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/search/movie?query=${Uri.encodeQueryComponent(query)}',
        ),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return data is List ? data : <dynamic>[];
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching movies: $e');
    }
  }

  static Future<List<dynamic>> advancedSearch({
    required String contentType,
    double minRating = 0,
    List<int> genreIds = const <int>[],
    String? decade,
    String? keywords,
    List<String> languages = const <String>[],
    int page = 1,
  }) async {
    final Map<String, String> params = <String, String>{
      'content_type': contentType,
      'min_rating': minRating.toString(),
      'page': page.toString(),
    };

    if (genreIds.isNotEmpty) {
      params['genres'] = genreIds.join(',');
    }
    if (decade != null && decade.isNotEmpty) {
      params['decade'] = decade;
    }
    if (keywords != null && keywords.trim().isNotEmpty) {
      params['keywords'] = keywords.trim();
    }
    if (languages.isNotEmpty) {
      params['languages'] = languages.join(',');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/advanced').replace(queryParameters: params),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return data is List ? data : <dynamic>[];
      } else {
        throw Exception('Advanced search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error running advanced search: $e');
    }
  }

  static Future<List<dynamic>> getRecommendationsByGenres(
    List<int> genreIds,
  ) async {
    if (genreIds.isEmpty) {
      return advancedSearch(contentType: 'movie');
    }

    return advancedSearch(
      contentType: 'movie',
      genreIds: genreIds,
      minRating: 6.0,
    );
  }

  static Future<List<dynamic>> getAnimeMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/anime'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load anime: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading anime: $e');
    }
  }
}
