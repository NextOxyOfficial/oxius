import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/elearning_models.dart';
import 'api_service.dart';

class ElearningService {
  // ApiService.baseUrl already includes '/api', so we use it directly
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Cache for storing fetched data
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Cache duration (1 hour for most data)
  static const Duration _cacheDuration = Duration(hours: 1);

  // Check if cache is valid
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  // Get from cache or null
  static T? _getFromCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key] as T?;
    }
    return null;
  }

  // Set cache
  static void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Clear specific cache
  static void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Fetch all batches
  static Future<List<Batch>> fetchBatches() async {
    const cacheKey = 'batches';

    // Check cache first
    final cached = _getFromCache<List<Batch>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/elearning/batches/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final batches = data.map((json) => Batch.fromJson(json)).toList();
        
        // Sort by display order
        batches.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        
        _setCache(cacheKey, batches);
        return batches;
      } else {
        throw Exception('Failed to load batches: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching batches: $e');
      throw Exception('Failed to load batches: $e');
    }
  }

  /// Fetch divisions for a specific batch
  static Future<List<Division>> fetchDivisionsForBatch(String batchCode) async {
    final cacheKey = 'divisions_$batchCode';

    // Check cache first
    final cached = _getFromCache<List<Division>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/elearning/batches/$batchCode/divisions/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final divisions = data.map((json) => Division.fromJson(json)).toList();
        
        // Sort by display order
        divisions.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        
        _setCache(cacheKey, divisions);
        return divisions;
      } else {
        throw Exception('Failed to load divisions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching divisions for batch $batchCode: $e');
      throw Exception('Failed to load divisions: $e');
    }
  }

  /// Fetch subjects for a specific division
  static Future<List<Subject>> fetchSubjectsForDivision(String divisionCode) async {
    final cacheKey = 'subjects_$divisionCode';

    // Check cache first
    final cached = _getFromCache<List<Subject>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/elearning/divisions/$divisionCode/subjects/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final subjects = data.map((json) => Subject.fromJson(json)).toList();
        
        // Sort by display order
        subjects.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        
        _setCache(cacheKey, subjects);
        return subjects;
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching subjects for division $divisionCode: $e');
      throw Exception('Failed to load subjects: $e');
    }
  }

  /// Fetch video lessons for a specific subject
  static Future<List<VideoLesson>> fetchVideoLessonsForSubject(String subjectCode) async {
    final cacheKey = 'videos_$subjectCode';

    // Check cache first (shorter cache for videos - 30 minutes)
    if (_isCacheValid(cacheKey)) {
      final cached = _cache[cacheKey] as List<VideoLesson>?;
      if (cached != null) return cached;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/elearning/subjects/$subjectCode/videos/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final videos = data.map((json) => VideoLesson.fromJson(json)).toList();
        
        // Sort by display order
        videos.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        
        _setCache(cacheKey, videos);
        return videos;
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching videos for subject $subjectCode: $e');
      throw Exception('Failed to load videos: $e');
    }
  }

  /// Increment video views
  static Future<bool> incrementVideoViews(String videoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/elearning/videos/$videoId/increment_views/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Invalidate cache for the video's subject
        _cache.keys
            .where((key) => key.startsWith('videos_'))
            .forEach((key) => clearCache(key));
        
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error incrementing video views: $e');
      return false;
    }
  }

  /// Fetch products for a specific batch
  static Future<List<Map<String, dynamic>>> fetchBatchProducts(
    String batchCode, {
    int limit = 50,
  }) async {
    final cacheKey = 'batch_products_${batchCode}_$limit';

    // Check cache first (30 minutes for products)
    if (_isCacheValid(cacheKey)) {
      final cached = _cache[cacheKey] as List<Map<String, dynamic>>?;
      if (cached != null) return cached;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/elearning/batches/$batchCode/products/?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((e) => e as Map<String, dynamic>).toList();
        
        _setCache(cacheKey, products);
        return products;
      } else {
        throw Exception('Failed to load batch products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching batch products: $e');
      return [];
    }
  }

  /// Fetch products for a specific division
  static Future<List<Map<String, dynamic>>> fetchDivisionProducts(
    String divisionCode, {
    int limit = 50,
  }) async {
    final cacheKey = 'division_products_${divisionCode}_$limit';

    // Check cache first (30 minutes for products)
    if (_isCacheValid(cacheKey)) {
      final cached = _cache[cacheKey] as List<Map<String, dynamic>>?;
      if (cached != null) return cached;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/elearning/divisions/$divisionCode/products/?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((e) => e as Map<String, dynamic>).toList();
        
        _setCache(cacheKey, products);
        return products;
      } else {
        throw Exception('Failed to load division products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching division products: $e');
      return [];
    }
  }
}
