import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassifiedCategory {
  final String id; // Changed from int to String to support UUIDs
  final String title;
  final String? slug;
  final String? image; // fallback asset if null
  final bool isFeatured;

  ClassifiedCategory({
    required this.id,
    required this.title,
    this.slug,
    this.image,
    this.isFeatured = false,
  });

  factory ClassifiedCategory.fromJson(Map<String, dynamic> json) => ClassifiedCategory(
        id: json['id']?.toString() ?? '', // Handle UUID strings
        title: (json['title'] ?? '').toString(),
        slug: json['slug']?.toString(),
        image: json['image']?.toString(),
        isFeatured: json['is_featured'] == true,
      );

  /// Get the local asset path for category icons, with fallback to server image
  String getIconAsset() {
    if (image != null && image!.isNotEmpty) {
      return image!;
    }

    // Map category titles to local asset names
    final assetMap = <String, String>{
      'Services & Business': 'assets/images/icons/sign.png',
      'Jobs & Employment': 'assets/images/icons/mobileapp.png',
      'Real Estate & Property': 'assets/images/icons/premium.png',
      'Vehicles & Transportation': 'assets/images/icons/transaction.png',
      'Electronics & Technology': 'assets/images/icons/mobileapp.png',
      'Health & Wellness': 'assets/images/icons/medicalreport.png',
      'Sports & Recreation': 'assets/images/icons/onlineshopping.png',
      'Education & Learning': 'assets/images/icons/onlinelearning.png',
      'Home & Garden': 'assets/images/icons/premium.png',
      'Fashion & Beauty': 'assets/images/icons/onlineshopping.png',
    };

    // Try to find a match by title
    final localAsset = assetMap[title];
    if (localAsset != null) {
      return localAsset;
    }

    // Fallback: try to map based on keywords in title
    final titleLower = title.toLowerCase();
    if (titleLower.contains('service') || titleLower.contains('business')) {
      return 'assets/images/icons/sign.png';
    } else if (titleLower.contains('job') || titleLower.contains('employment')) {
      return 'assets/images/icons/mobileapp.png';
    } else if (titleLower.contains('real estate') || titleLower.contains('property')) {
      return 'assets/images/icons/premium.png';
    } else if (titleLower.contains('vehicle') || titleLower.contains('transport')) {
      return 'assets/images/icons/transaction.png';
    } else if (titleLower.contains('electronic') || titleLower.contains('technology')) {
      return 'assets/images/icons/mobileapp.png';
    } else if (titleLower.contains('health') || titleLower.contains('medical')) {
      return 'assets/images/icons/medicalreport.png';
    } else if (titleLower.contains('education') || titleLower.contains('learning')) {
      return 'assets/images/icons/onlinelearning.png';
    } else if (titleLower.contains('fashion') || titleLower.contains('beauty') || titleLower.contains('shopping')) {
      return 'assets/images/icons/onlineshopping.png';
    } else if (titleLower.contains('sport') || titleLower.contains('recreation')) {
      return 'assets/images/icons/onlineshopping.png';
    } else if (titleLower.contains('home') || titleLower.contains('garden')) {
      return 'assets/images/icons/premium.png';
    } else if (titleLower.contains('money') || titleLower.contains('payment')) {
      return 'assets/images/icons/money.png';
    } else if (titleLower.contains('news') || titleLower.contains('media')) {
      return 'assets/images/icons/news.png';
    }

    // Final fallback: use question icon or server image
    return 'assets/images/icons/question.png';
  }
}

class ClassifiedCategoryService {
  ClassifiedCategoryService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl; // e.g. https://api.example.com/api
  final http.Client _client;

  List<ClassifiedCategory>? _cache;
  DateTime? _lastFetch;
  final Duration cacheTtl = const Duration(minutes: 5);

  Future<List<ClassifiedCategory>> fetchCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < cacheTtl) return _cache!;
    }

    final uri = Uri.parse('$baseUrl/classified-categories/');
    final response = await _client.get(uri, headers: const {
      'Accept': 'application/json',
    });
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final List<ClassifiedCategory> list = _parseCategories(decoded);
      _cache = list;
      _lastFetch = DateTime.now();
      return list;
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  List<ClassifiedCategory> _parseCategories(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['results'] is List) {
        return (decoded['results'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ClassifiedCategory.fromJson)
            .toList();
      }
      // Some APIs might return an inline list w/o 'results'
      // but since this branch is Map, nothing to do
      return [];
    }
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ClassifiedCategory.fromJson)
          .toList();
    }
    return [];
  }

  void clearCache() {
    _cache = null;
    _lastFetch = null;
  }
}
