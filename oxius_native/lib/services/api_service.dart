import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get mediaBaseUrl => AppConfig.mediaBaseUrl;
  static const String _tokenKey = 'adsyclub_token';

  // Helper method to get full API URL
  static String getApiUrl(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }

  // Helper method to get absolute media URL
  static String getAbsoluteUrl(String? url) {
    return AppConfig.getAbsoluteUrl(url);
  }

  // Get headers with authentication token if available
  static Future<Map<String, String>> getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    
    return headers;
  }

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
    print('DEBUG: fetchClassifiedCategories called, baseUrl: $baseUrl');
    // Use the non-paginated endpoint to get ALL categories
    final uri = Uri.parse('$baseUrl/classified-categories-all/');

    try {
      print('DEBUG: Making request to: $uri');
      final resp = await http.get(uri);
      print('DEBUG: Response status: ${resp.statusCode}');
      if (resp.statusCode != 200) {
        print('DEBUG: Non-200 response from ${uri.path} -> ${resp.statusCode}');
        log('fetchClassifiedCategories ${uri.path} -> ${resp.statusCode}');
        return [];
      }
      final data = json.decode(resp.body);
      print('DEBUG: Raw response data type: ${data.runtimeType}');
      if (data is Map) {
        print('DEBUG: Response is Map with keys: ${data.keys}');
      }
      final raw = (data is List) ? data : (data['results'] ?? []);
      print('DEBUG: Extracted ${raw.length} items from response');
      final result = raw
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      print('DEBUG: Returning ${result.length} processed categories');
      return result;
    } catch (e, st) {
      print('DEBUG: Exception in fetchClassifiedCategories: $e');
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