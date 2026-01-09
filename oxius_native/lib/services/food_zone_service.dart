import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/classified_post.dart';
import '../models/geo_location.dart';

class FoodZoneCategory {
  final String id;
  final String title;
  final String? slug;
  final String? image;
  final bool isFoodZone;

  FoodZoneCategory({
    required this.id,
    required this.title,
    this.slug,
    this.image,
    this.isFoodZone = true,
  });

  factory FoodZoneCategory.fromJson(Map<String, dynamic> json) {
    return FoodZoneCategory(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      image: json['image']?.toString(),
      isFoodZone: json['is_food_zone'] as bool? ?? true,
    );
  }
}

class FoodZoneService {
  final String baseUrl;
  final http.Client client;

  FoodZoneService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Fetch Food Zone posts (classified posts from categories marked as food zone)
  Future<List<ClassifiedPost>> fetchFoodZonePosts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    GeoLocation? location,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }

      if (location != null) {
        queryParams['country'] = location.country;

        if (!location.allOverBangladesh) {
          if (location.state != null && location.state!.isNotEmpty) {
            queryParams['state'] = location.state!;
          }
          if (location.city != null && location.city!.isNotEmpty) {
            queryParams['city'] = location.city!;
          }
          if (location.upazila != null && location.upazila!.isNotEmpty) {
            queryParams['upazila'] = location.upazila!;
          }
        }
      }

      final uri = Uri.parse('$baseUrl/food-zone/posts/').replace(
        queryParameters: queryParams,
      );

      print('🍔 Fetching Food Zone posts from: $uri');

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> results;
        if (data is Map && data.containsKey('results')) {
          results = data['results'] as List<dynamic>;
        } else if (data is List) {
          results = data;
        } else {
          results = [];
        }

        return results
            .map((item) => ClassifiedPost.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching Food Zone posts: $e');
      return [];
    }
  }

  /// Fetch Food Zone categories (categories marked as food zone)
  Future<List<FoodZoneCategory>> fetchFoodZoneCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/food-zone/categories/');

      print('🍔 Fetching Food Zone categories from: $uri');

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map && data.containsKey('results')) {
          results = data['results'] as List<dynamic>;
        } else {
          results = [];
        }

        return results
            .map((item) => FoodZoneCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching Food Zone categories: $e');
      return [];
    }
  }
}
