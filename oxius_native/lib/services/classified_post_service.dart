import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/classified_post.dart';
import '../models/geo_location.dart';

class ClassifiedPostService {
  final String baseUrl;
  final http.Client client;

  ClassifiedPostService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Fetch a single classified post by ID or slug
  Future<ClassifiedPost?> fetchPostById(String idOrSlug) async {
    try {
      final uri = Uri.parse('$baseUrl/classified-categories/post/$idOrSlug/');
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClassifiedPost.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching post by ID: $e');
      return null;
    }
  }

  /// Fetch classified posts with filters
  Future<ClassifiedPostsResponse> fetchPosts({
    String? categoryId,
    String? title,
    GeoLocation? location,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }

      if (title != null && title.isNotEmpty) {
        queryParams['title'] = title;
      }

      if (location != null) {
        queryParams['country'] = location.country;
        
        // Only add state, city, and upazila if not showing all over Bangladesh
        if (!location.allOverBangladesh) {
          if (location.state != null) queryParams['state'] = location.state!;
          if (location.city != null) queryParams['city'] = location.city!;
          if (location.upazila != null) queryParams['upazila'] = location.upazila!;
        }
      }

      final uri = Uri.parse('$baseUrl/classified-posts/filter/').replace(
        queryParameters: queryParams,
      );

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle both paginated and non-paginated responses
        if (data is Map && data.containsKey('results')) {
          final results = (data['results'] as List)
              .map((item) => ClassifiedPost.fromJson(item as Map<String, dynamic>))
              .where((post) => post.serviceStatus.toLowerCase() == 'approved' && post.activeService)
              .toList();
          
          return ClassifiedPostsResponse(
            results: results,
            count: data['count'] as int? ?? results.length,
            next: data['next']?.toString(),
            previous: data['previous']?.toString(),
          );
        } else if (data is List) {
          final results = data
              .map((item) => ClassifiedPost.fromJson(item as Map<String, dynamic>))
              .where((post) => post.serviceStatus.toLowerCase() == 'approved' && post.activeService)
              .toList();
          
          return ClassifiedPostsResponse(
            results: results,
            count: results.length,
          );
        }
      }
      
      return ClassifiedPostsResponse(results: [], count: 0);
    } catch (e) {
      print('Error fetching posts: $e');
      return ClassifiedPostsResponse(results: [], count: 0);
    }
  }

  /// Fetch nearby posts (same city or state)
  Future<List<ClassifiedPost>> fetchNearbyPosts({
    required String categoryId,
    required GeoLocation location,
    int pageSize = 20,
  }) async {
    try {
      // If showing all over Bangladesh, get a sample from across the country
      if (location.allOverBangladesh) {
        final response = await fetchPosts(
          categoryId: categoryId,
          location: GeoLocation(country: location.country, allOverBangladesh: true),
          pageSize: pageSize,
        );
        return response.results;
      }

      // Try same city first (any upazila)
      if (location.city != null) {
        final cityResponse = await fetchPosts(
          categoryId: categoryId,
          location: GeoLocation(
            country: location.country,
            state: location.state,
            city: location.city,
          ),
          pageSize: pageSize,
        );
        
        if (cityResponse.results.isNotEmpty) {
          return cityResponse.results;
        }
      }

      // Try same state (any city)
      if (location.state != null) {
        final stateResponse = await fetchPosts(
          categoryId: categoryId,
          location: GeoLocation(
            country: location.country,
            state: location.state,
          ),
          pageSize: pageSize,
        );
        
        return stateResponse.results;
      }

      return [];
    } catch (e) {
      print('Error fetching nearby posts: $e');
      return [];
    }
  }

  /// Fetch category details
  Future<CategoryDetails?> fetchCategoryDetails(String idOrSlug) async {
    try {
      final uri = Uri.parse('$baseUrl/details/classified-categories/$idOrSlug/');
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CategoryDetails.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching category details: $e');
      return null;
    }
  }
}

class ClassifiedPostsResponse {
  final List<ClassifiedPost> results;
  final int count;
  final String? next;
  final String? previous;

  ClassifiedPostsResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  bool get hasMore => next != null;
  int get totalPages => (count / results.length).ceil();
}
