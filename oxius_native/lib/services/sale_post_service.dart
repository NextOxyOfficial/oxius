import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale_post.dart';

class SalePostService {
  final String baseUrl;
  final http.Client client;

  static const String _tokenKey = 'adsyclub_token';

  SalePostService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Get authentication token
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting auth token: $e');
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
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
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
      print('Error fetching sale categories: $e');
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
      
      print('🛒 Fetching sale posts from: $uri');
      
      final response = await client.get(uri, headers: await _getHeaders());

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePostsResponse.fromJson(data);
      }

      return SalePostsResponse(results: [], count: 0);
    } catch (e) {
      print('❌ Error fetching sale posts: $e');
      return SalePostsResponse(results: [], count: 0);
    }
  }

  /// Fetch single sale post by slug
  Future<SalePost?> fetchPostBySlug(String slug) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$slug/');
      final response = await client.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SalePost.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching sale post by slug: $e');
      return null;
    }
  }

  /// Fetch user's sale posts
  Future<SalePostsResponse> fetchMyPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'my_posts': 'true',
      };

      final uri = Uri.parse('$baseUrl/sale/posts/')
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
      print('Error fetching my sale posts: $e');
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
      print('Error creating sale post: $e');
      return null;
    }
  }

  /// Update sale post
  Future<SalePost?> updatePost(String id, Map<String, dynamic> postData) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$id/');
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
      print('Error updating sale post: $e');
      return null;
    }
  }

  /// Delete sale post
  Future<bool> deletePost(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/sale/posts/$id/');
      final response = await client.delete(
        uri,
        headers: await _getHeaders(needsAuth: true),
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting sale post: $e');
      return false;
    }
  }
}
