import 'dart:convert';
import 'package:http/http.dart' as http;

class GigsService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<List<Map<String, dynamic>>> fetchMicroGigs({bool showSubmitted = false}) async {
    try {
      final url = '$baseUrl/micro-gigs/?show_submitted=$showSubmitted';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
        
        return [];
      } else {
        throw Exception('Failed to load micro gigs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching micro gigs: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMicroGigsByCategory(
    String categoryId, {
    bool showSubmitted = false,
  }) async {
    try {
      final url = '$baseUrl/micro-gigs/?category=$categoryId&show_submitted=$showSubmitted';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
        
        return [];
      } else {
        throw Exception('Failed to load gigs by category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching gigs by category: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchGigCategories() async {
    try {
      final url = '$baseUrl/gig-categories/';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
        
        return [];
      } else {
        throw Exception('Failed to load gig categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching gig categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMobileRechargeOperators() async {
    try {
      final url = '$baseUrl/mobile-recharge/operators/';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
        
        return [];
      } else {
        throw Exception('Failed to load operators: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mobile recharge operators: $e');
      return [];
    }
  }

  /// Transform relative URL to absolute URL
  String _abs(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return baseUrl.replaceAll('/api', '') + url;
    }
    return baseUrl.replaceAll('/api', '') + '/' + url;
  }
}
