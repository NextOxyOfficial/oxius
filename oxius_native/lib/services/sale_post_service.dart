import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sale_post.dart';
import '../utils/api_error.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class SalePostService {
  final String baseUrl;
  final http.Client client;

  SalePostService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Get authentication token (auto-refreshes if expired)
  Future<String?> _getAuthToken() async {
    try {
      return await AuthService.getValidToken();
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  /// Get headers
  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (needsAuth) {
      final token = await _getAuthToken();
      debugPrint('Auth token retrieved: ${token != null ? "Yes (${token.substring(0, 20)}...)" : "No"}');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint('WARNING: Auth required but no token found!');
      }
    }

    return headers;
  }

  /// Fetch sale categories
  Future<List<SaleCategory>> fetchCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/sale/categories/');
      final response = await client.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((e) => SaleCategory.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching sale categories: $e');
      return [];
    }
  }

  /// Fetch sale posts with filters
  Future<SalePostsResponse> fetchPosts({
    String? categoryId,
    String? subcategoryId,
    String? title,
    String? state,
    String? city,
    String? upazila,
    String? division,
    String? district,
    String? area,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sortBy, // newest, price_low, price_high, most_viewed
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (categoryId != null) queryParams['category'] = categoryId;
      if (subcategoryId != null) queryParams['subcategory'] = subcategoryId;
      if (title != null && title.isNotEmpty) queryParams['title'] = title;
      if (state != null) queryParams['state'] = state;
      if (city != null) queryParams['city'] = city;
      if (upazila != null) queryParams['upazila'] = upazila;
      if (division != null) queryParams['division'] = division;
      if (district != null) queryParams['district'] = district;
      if (area != null) queryParams['area'] = area;
      if (condition != null) queryParams['condition'] = condition;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'newest':
            queryParams['ordering'] = '-created_at';
            break;
          case 'price_low':
            queryParams['ordering'] = 'price';
            break;
          case 'price_high':
            queryParams['ordering'] = '-price';
            break;
          case 'most_viewed':
            queryParams['ordering'] = '-views_count';
            break;
        }
      }

      final uri =
          Uri.parse('$baseUrl/sale/posts/').replace(queryParameters: queryParams);
      
      debugPrint('🛒 Fetching sale posts from: $uri');
      
      final response = await client.get(uri, headers: await _getHeaders());

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePostsResponse.fromJson(data);
      }

      return SalePostsResponse(results: [], count: 0);
    } catch (e) {
      debugPrint('❌ Error fetching sale posts: $e');
      return SalePostsResponse(results: [], count: 0);
    }
  }

  /// Fetch single sale post by slug
  Future<SalePost?> fetchPostBySlug(String slug) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/');
      // Send auth when available so an owner can open their own sold/pending
      // post (guests simply get no Authorization header).
      final response =
          await client.get(uri, headers: await _getHeaders(needsAuth: true));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePost.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching sale post by slug: $e');
      return null;
    }
  }

  /// Fetch user's sale posts
  Future<SalePostsResponse> fetchMyPosts({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/sale/posts/my_posts/')
          .replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: await _getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePostsResponse.fromJson(data);
      }

      return SalePostsResponse(results: [], count: 0);
    } catch (e) {
      debugPrint('Error fetching my sale posts: $e');
      return SalePostsResponse(results: [], count: 0);
    }
  }

  /// Create sale post
  Future<SalePost?> createPost(Map<String, dynamic> postData) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/');
      final response = await client.post(
        uri,
        headers: await _getHeaders(needsAuth: true),
        body: json.encode(postData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SalePost.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating sale post: $e');
      return null;
    }
  }

  /// Update sale post
  /// [slug] - The slug of the post to update (backend uses slug as lookup field)
  Future<SalePost?> updatePost(String slug, Map<String, dynamic> postData) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/');
      final response = await client.patch(
        uri,
        headers: await _getHeaders(needsAuth: true),
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePost.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating sale post: $e');
      return null;
    }
  }

  /// Delete sale post
  /// [slug] - The slug of the post to delete (backend uses slug as lookup field)
  Future<bool> deletePost(String slug) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/');
      final response = await client.delete(
        uri,
        headers: await _getHeaders(needsAuth: true),
      );

      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting sale post: $e');
      return false;
    }
  }

  /// Mark post as sold
  Future<SalePost?> markAsSold(String slug) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/mark_as_sold/');
      debugPrint('Marking as sold URL: $uri');
      
      final response = await client.post(
        uri,
        headers: await _getHeaders(needsAuth: true),
      );

      debugPrint('Mark as sold response status: ${response.statusCode}');
      debugPrint('Mark as sold response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePost.fromJson(data);
      } else {
        debugPrint('Failed to mark as sold. Status: ${response.statusCode}, Body: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Error marking post as sold: $e');
      rethrow; // Rethrow to show actual error in UI
    }
  }

  /// Switch a post between 'active' and 'sold' (owner only).
  Future<SalePost?> changeStatus(String slug, String newStatus) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/change_status/');
      final response = await client.post(
        uri,
        headers: await _getHeaders(needsAuth: true),
        body: json.encode({'status': newStatus}),
      );

      debugPrint('Change status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return SalePost.fromJson(json.decode(response.body));
      }
      debugPrint('Change status failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error changing post status: $e');
      return null;
    }
  }

  /// Fetch categories for post creation (raw JSON)
  Future<List<Map<String, dynamic>>> fetchCategoriesForForm() async {
    try {
      final uri = Uri.parse('$baseUrl/sale/categories/');
      final response = await client.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories for form: $e');
      return [];
    }
  }

  /// Fetch child categories
  Future<List<Map<String, dynamic>>> fetchChildCategories(int parentId) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/child-categories/?parent_id=$parentId');
      final response = await client.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching child categories: $e');
      return [];
    }
  }

  /// Fetch divisions (regions)
  /// Drop rows sharing the same name_eng so DropdownButton never sees two items
  /// with the same value (the geo data can return duplicate "Dhaka" rows).
  static List<Map<String, dynamic>> _dedupeGeo(List list) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final name = (item['name_eng'] ?? '').toString().trim();
      if (name.isEmpty || !seen.add(name)) continue;
      out.add(item);
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> fetchDivisions() async {
    try {
      final uri = Uri.parse('$baseUrl/geo/regions/?country_name_eng=Bangladesh');
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return _dedupeGeo(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching divisions: $e');
      return [];
    }
  }

  /// Fetch districts (cities)
  Future<List<Map<String, dynamic>>> fetchDistricts(String division) async {
    try {
      final uri = Uri.parse('$baseUrl/geo/cities/?region_name_eng=$division');
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return _dedupeGeo(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      return [];
    }
  }

  /// Fetch areas (upazilas)
  Future<List<Map<String, dynamic>>> fetchAreas(String district) async {
    try {
      final uri = Uri.parse('$baseUrl/geo/upazila/?city_name_eng=$district');
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return _dedupeGeo(data);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching areas: $e');
      return [];
    }
  }

  /// Create a new sale post
  Future<Map<String, dynamic>?> createSalePost(Map<String, dynamic> postData) async {
    try {
      debugPrint('Creating sale post with data: ${json.encode(postData)}');
      
      final uri = Uri.parse('$baseUrl/sale/posts/');
      final response = await client.post(
        uri,
        headers: await _getHeaders(needsAuth: true),
        body: json.encode(postData),
      );

      debugPrint('Create post response status: ${response.statusCode}');
      debugPrint('Create post response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> ? data : null;
      } else if (response.statusCode == 401) {
        debugPrint('❌ UNAUTHORIZED: User is not authenticated or token is invalid');
        throw Exception('You must be logged in to create a post. Please login and try again.');
      } else if (response.statusCode == 400) {
        // Check if it's actually a success (known backend issue)
        try {
          final data = json.decode(response.body);
          if (data is Map && (data.containsKey('id') || data.containsKey('message'))) {
            debugPrint('Detected success response with 400 status');
            return data as Map<String, dynamic>;
          }
        } catch (e) {
          // Parse failed, treat as error
        }
        debugPrint('Failed to create post. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiError.fromResponse(response.statusCode, response.body);
      } else {
        debugPrint('Failed to create post. Status: ${response.statusCode}, Body: ${response.body}');
        throw ApiError.fromResponse(response.statusCode, response.body);
      }
    } catch (e) {
      debugPrint('Error creating sale post: $e');
      rethrow;
    }
  }

  /// Report a sale post
  Future<bool> reportPost(String slug, String reason, {String? details}) async {
    try {
      debugPrint('Reporting sale post: $slug with reason: $reason');
      
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/report/');
      
      final body = {
        'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      };
      
      final response = await client.post(
        uri,
        headers: await _getHeaders(needsAuth: true),
        body: json.encode(body),
      );

      debugPrint('Report post response status: ${response.statusCode}');
      debugPrint('Report post response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Sale post reported successfully');
        return true;
      }
      
      debugPrint('❌ Failed to report post. Status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error reporting sale post: $e');
      return false;
    }
  }
}
