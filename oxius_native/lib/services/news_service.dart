import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_models.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class NewsService {
  static String get baseUrl => AppConfig.mediaBaseUrl;

  // Cache for storing fetched data
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Check if cache is valid
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  // Get all news posts with pagination
  static Future<PaginatedNewsResponse> getPosts({int page = 1}) async {
    final cacheKey = 'posts_page_$page';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as PaginatedNewsResponse;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/posts/?page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paginatedResponse = PaginatedNewsResponse.fromJson(data);

        _cache[cacheKey] = paginatedResponse;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return paginatedResponse;
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  // Get single post by slug
  static Future<NewsPost> getPostBySlug(String slug) async {
    final cacheKey = 'post_$slug';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as NewsPost;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/posts/$slug/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final post = NewsPost.fromJson(data);

        _cache[cacheKey] = post;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return post;
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching post: $e');
    }
  }

  // Get categories
  static Future<List<NewsCategory>> getCategories() async {
    const cacheKey = 'categories';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<NewsCategory>;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/categories/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<NewsCategory> categories;

        if (data is Map && data.containsKey('results')) {
          categories = (data['results'] as List)
              .map((c) => NewsCategory.fromJson(c))
              .toList();
        } else if (data is List) {
          categories = data.map((c) => NewsCategory.fromJson(c)).toList();
        } else {
          categories = [];
        }

        _cache[cacheKey] = categories;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return categories;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get posts by category
  static Future<List<NewsPost>> getPostsByCategory(String categorySlug,
      {int page = 1}) async {
    final cacheKey = 'category_${categorySlug}_page_$page';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<NewsPost>;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/categories/$categorySlug/?page=$page'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<NewsPost> posts;

        if (data is Map && data.containsKey('results')) {
          posts = (data['results'] as List)
              .map((p) => NewsPost.fromJson(p))
              .toList();
        } else if (data is List) {
          posts = data.map((p) => NewsPost.fromJson(p)).toList();
        } else {
          posts = [];
        }

        _cache[cacheKey] = posts;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return posts;
      } else {
        throw Exception(
            'Failed to load category posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category posts: $e');
    }
  }

  // Get tips and suggestions
  static Future<List<TipSuggestion>> getTipsAndSuggestions() async {
    const cacheKey = 'tips_suggestions';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<TipSuggestion>;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/tips-suggestions/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<TipSuggestion> tips;

        if (data is Map && data.containsKey('results')) {
          tips = (data['results'] as List)
              .map((t) => TipSuggestion.fromJson(t))
              .toList();
        } else if (data is List) {
          tips = data.map((t) => TipSuggestion.fromJson(t)).toList();
        } else {
          tips = [];
        }

        _cache[cacheKey] = tips;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return tips;
      } else {
        throw Exception(
            'Failed to load tips and suggestions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tips and suggestions: $e');
    }
  }

  static Future<List<BreakingNewsItem>> getBreakingNews() async {
    const cacheKey = 'breaking_news';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<BreakingNewsItem>;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/breaking-news/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawItems = data is Map && data.containsKey('results')
            ? data['results'] as List
            : data is List
                ? data
                : <dynamic>[];
        final items = rawItems
            .whereType<Map>()
            .map((item) =>
                BreakingNewsItem.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.displayTitle.isNotEmpty)
            .toList();

        if (items.isNotEmpty) {
          _cache[cacheKey] = items;
          _cacheTimestamps[cacheKey] = DateTime.now();
        } else {
          _cache.remove(cacheKey);
          _cacheTimestamps.remove(cacheKey);
        }
        return items;
      }
      throw Exception('Failed to load breaking news: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching breaking news: $e');
      return [];
    }
  }

  // Clear cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Clear specific cache entry
  static void clearCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  // Get AdsyNews logo
  static Future<String?> getNewsLogo() async {
    const cacheKey = 'news_logo';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as String?;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news-logo/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logoUrl = data['image'] as String?;

        if (logoUrl != null && logoUrl.isNotEmpty) {
          final absoluteUrl = AppConfig.getAbsoluteUrl(logoUrl);
          _cache[cacheKey] = absoluteUrl;
          _cacheTimestamps[cacheKey] = DateTime.now();
          return absoluteUrl;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching news logo: $e');
      return null;
    }
  }

  // ---- Comments -------------------------------------------------------------
  // Backed by the existing news comment API. Routes key off the NewsPost *id*
  // (not the slug), and comments are flat — no replies.

  /// List a story's comments, newest first (the API orders by -created_at).
  static Future<List<NewsComment>> getComments(String newsId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news/posts/$newsId/comments/'),
        headers: await ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Paginated responses wrap the rows in `results`.
        final rows = (data is Map ? data['results'] : data) as List? ?? [];
        return rows
            .whereType<Map>()
            .map((e) => NewsComment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      debugPrint('getComments -> ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error fetching news comments: $e');
      return [];
    }
  }

  /// Post a comment on a story. Returns the created comment, or null on failure.
  static Future<NewsComment?> addComment(String newsId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/news/posts/$newsId/comments/'),
        headers: await ApiService.getHeaders(),
        body: json.encode({'content': content}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        // The story's cached detail payload now has a stale comment list.
        _cache.removeWhere((k, _) => k.startsWith('post_'));
        return NewsComment.fromJson(
            Map<String, dynamic>.from(json.decode(response.body)));
      }
      debugPrint('addComment -> ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error posting news comment: $e');
      return null;
    }
  }
}
