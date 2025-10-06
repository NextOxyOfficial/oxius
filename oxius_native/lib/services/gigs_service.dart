import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserGigs(String userId) async {
    try {
      final url = '$baseUrl/user-micro-gigs/$userId/';
      print('DEBUG API: Calling URL: $url');
      
      // Get auth headers from ApiService
      final headers = await ApiService.getHeaders();
      print('DEBUG API: Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('DEBUG API: Status code: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('DEBUG API: Parsed data type: ${data.runtimeType}');
        
        if (data is List) {
          print('DEBUG API: Got list with ${data.length} items');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] != null) {
          print('DEBUG API: Got paginated response with ${data['results'].length} items');
          return List<Map<String, dynamic>>.from(data['results']);
        }
        
        print('DEBUG API: No gigs in response');
        return [];
      } else {
        print('DEBUG API: Failed with status ${response.statusCode}');
        throw Exception('Failed to load user gigs: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG API: Exception: $e');
      return [];
    }
  }

  /// Update gig status (pause/activate/stop)
  Future<bool> updateGigStatus(String gigId, String action, bool value) async {
    try {
      final url = '$baseUrl/update-user-micro-gig/$gigId/';
      Map<String, dynamic> requestBody;
      
      if (action == "completed") {
        // Stop the gig
        requestBody = {
          'stop_gig': true,
          'active_gig': false,
        };
      } else {
        // Pause/Activate the gig
        requestBody = {
          'active_gig': value,
        };
      }
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Delete a gig
  Future<bool> deleteGig(String gigId) async {
    try {
      final url = '$baseUrl/delete-user-micro-gig/$gigId/';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get gig details by ID
  Future<Map<String, dynamic>?> getGigDetails(String gigId) async {
    try {
      final url = '$baseUrl/get-user-micro-gig/$gigId/';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
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
