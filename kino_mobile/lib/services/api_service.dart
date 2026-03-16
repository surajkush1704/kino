import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 127.0.0.1 for real device via USB + 'adb reverse'
  // 10.0.2.2 if using Android Emulator
  static const String baseUrl = "http://127.0.0.1:8000/api/v1";

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

  // UPDATED: Now accepts 'sortBy' parameter
  static Future<List<dynamic>> searchMovies(
    String query, {
    String sortBy = "popularity",
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
