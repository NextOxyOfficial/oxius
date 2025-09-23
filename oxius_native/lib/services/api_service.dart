import 'dart:convert';
import 'package:http/http.dart' as http;

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
}