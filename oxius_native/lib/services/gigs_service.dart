import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GigsService {
  static String get baseUrl => ApiService.baseUrl;

  Future<Map<String, dynamic>> fetchMicroGigs({
    bool showSubmitted = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final url = '$baseUrl/micro-gigs/?show_submitted=$showSubmitted&page=$page&page_size=$pageSize';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is Map && data['results'] != null) {
          // Backend returns paginated response
          return {
            'results': List<Map<String, dynamic>>.from(data['results']),
            'count': data['count'] ?? 0,
            'next': data['next'],
            'previous': data['previous'],
          };
        } else if (data is List) {
          // Fallback for non-paginated response
          return {
            'results': List<Map<String, dynamic>>.from(data),
            'count': (data as List).length,
            'next': null,
            'previous': null,
          };
        }
        
        return {'results': [], 'count': 0, 'next': null, 'previous': null};
      } else {
        throw Exception('Failed to load micro gigs: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchMicroGigsByCategory(
    String categoryId, {
    bool showSubmitted = false,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final url = '$baseUrl/micro-gigs/?category=$categoryId&show_submitted=$showSubmitted&page=$page&page_size=$pageSize';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is Map && data['results'] != null) {
          // Backend returns paginated response
          return {
            'results': List<Map<String, dynamic>>.from(data['results']),
            'count': data['count'] ?? 0,
            'next': data['next'],
            'previous': data['previous'],
          };
        } else if (data is List) {
          // Fallback for non-paginated response
          return {
            'results': List<Map<String, dynamic>>.from(data),
            'count': (data as List).length,
            'next': null,
            'previous': null,
          };
        }
        
        return {'results': [], 'count': 0, 'next': null, 'previous': null};
      } else {
        throw Exception('Failed to load gigs by category: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMicroGigCategories() async {
    try {
      final headers = await ApiService.getHeaders();
      final url = '$baseUrl/micro-gigs-categories/';
      final response = await http.get(Uri.parse(url), headers: headers);

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

  Future<List<Map<String, dynamic>>> fetchTargetDevices() async {
    try {
      final url = '$baseUrl/target-device/';
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
        throw Exception('Failed to load target devices: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTargetNetworks() async {
    try {
      final url = '$baseUrl/target-network/';
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
        throw Exception('Failed to load target networks: ${response.statusCode}');
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
      final headers = await ApiService.getHeaders();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
        
        return [];
      } else {
        throw Exception('Failed to load user gigs: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Update gig status (pause/activate/stop)
  Future<bool> updateGigStatus(String gigId, String action, bool value) async {
    try {
      final url = '$baseUrl/update-user-micro-gig/$gigId/';
      final headers = await ApiService.getHeaders();
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
        headers: headers,
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
      final headers = await ApiService.getHeaders();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get gig details by ID (for user's own gigs)
  Future<Map<String, dynamic>?> getGigDetails(String gigId) async {
    try {
      final url = '$baseUrl/get-user-micro-gig/$gigId/';
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

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

  /// Fetch public gig details by slug (for order page)
  Future<Map<String, dynamic>> fetchGigDetails(String gigSlug) async {
    try {
      final url = '$baseUrl/micro-gigs/$gigSlug/';
      final headers = await ApiService.getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Failed to load gig details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Post a new micro gig
  Future<Map<String, dynamic>> postMicroGig(Map<String, dynamic> gigData) async {
    try {
      final url = '$baseUrl/post-micro-gigs/';
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(gigData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        final dynamic errorData = json.decode(response.body);
        String errorMessage = 'Failed to post gig';
        if (errorData is Map) {
          if (errorData['errors'] != null) {
            errorMessage = errorData['errors'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          }
        }
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
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
