import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  // Load banner images from API
  static Future<List<dynamic>> loadBannerImages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/banners/'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'] ?? [];
      } else {
        throw Exception('Failed to load banner images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading banner images: $e');
      rethrow;
    }
  }

  // Load other API data can be added here
  static Future<Map<String, dynamic>> loadHomeData() async {
    try {
      // Simulate loading multiple data sources
      final banners = await loadBannerImages();
      
      return {
        'banners': banners,
        'success': true,
      };
    } catch (e) {
      print('Error loading home data: $e');
      return {
        'banners': [],
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ================= Classified (Stub) =================
  // These endpoints are assumptions based on common REST patterns.
  // Adjust the path strings to match the backend once confirmed.

  static Future<List<Map<String, dynamic>>> fetchClassifiedCategories() async {
    // Primary DRF paginated endpoint
    final primary = Uri.parse('$baseUrl/classified-categories/');
    // Non-paginated ("all") fallback if needed
    final fallback = Uri.parse('$baseUrl/classified-categories-all/');

    Future<List<Map<String, dynamic>>> _hit(Uri uri) async {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        log('fetchClassifiedCategories ${uri.path} -> ${resp.statusCode}');
        return [];
      }
      final data = json.decode(resp.body);
      final raw = (data is List) ? data : (data['results'] ?? []);
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    try {
      var cats = await _hit(primary);
      if (cats.isEmpty) {
        cats = await _hit(fallback);
      }
      return cats;
    } catch (e, st) {
      log('fetchClassifiedCategories error: $e', stackTrace: st);
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchClassifiedPosts({
    String? query,
    String? categoryId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };
    if (query != null && query.trim().isNotEmpty) qp['search'] = query.trim();
    if (categoryId != null && categoryId.isNotEmpty) qp['category'] = categoryId;
    // Correct endpoint per backend urls.py: "classified-posts/"
    final uri = Uri.parse('$baseUrl/classified-posts/').replace(queryParameters: qp);
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = (data is List) ? data : (data['results'] ?? []);
        return results
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      log('fetchClassifiedPosts non-200: ${resp.statusCode}');
      return [];
    } catch (e, st) {
      log('fetchClassifiedPosts error: $e', stackTrace: st);
      return [];
    }
  }
}