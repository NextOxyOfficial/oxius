import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/store_review.dart';

/// Talks to the `reviews` app endpoints (mounted at `<api>/reviews/`).
class ReviewService {
  static String get baseUrl => ApiService.baseUrl;

  /// Public: reviews for a single product (paginated). Auth optional.
  /// Returns `{reviews: List<StoreReview>, hasMore: bool, total: int}`.
  static Future<Map<String, dynamic>> getProductReviews({
    required String productId,
    int page = 1,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      try {
        final token = await AuthService.getValidToken();
        if (token != null) headers['Authorization'] = 'Bearer $token';
      } catch (_) {}

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/products/$productId/reviews/?page=$page'),
        headers: headers,
      );

      debugPrint('⭐ Product reviews response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = (data is Map ? (data['results'] ?? []) : data) as List;
        final reviews = list
            .map((e) => StoreReview.fromJson(e as Map<String, dynamic>))
            .toList();
        final hasMore = data is Map && data['next'] != null;
        final total = data is Map ? (data['count'] ?? reviews.length) : reviews.length;
        return {
          'reviews': reviews,
          'hasMore': hasMore,
          'total': total is int ? total : int.tryParse('$total') ?? reviews.length,
        };
      }
      return {'reviews': <StoreReview>[], 'hasMore': false, 'total': 0};
    } catch (e) {
      debugPrint('❌ Error loading product reviews: $e');
      return {'reviews': <StoreReview>[], 'hasMore': false, 'total': 0};
    }
  }

  /// Public: aggregated rating stats for a product.
  /// Returns `{average: double, total: int}` (zeros when unavailable).
  static Future<Map<String, dynamic>> getProductRatingStats(
      String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/products/$productId/stats/'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final avg = double.tryParse('${data['average_rating']}') ?? 0;
        final total = data['total_reviews'];
        return {
          'average': avg,
          'total': total is int ? total : int.tryParse('$total') ?? 0,
        };
      }
      return {'average': 0.0, 'total': 0};
    } catch (e) {
      debugPrint('❌ Error loading rating stats: $e');
      return {'average': 0.0, 'total': 0};
    }
  }

  /// Submit a review on a product (auth required).
  /// Returns `{success, message}` — message carries the backend reason on failure.
  static Future<Map<String, dynamic>> submitReview({
    required String productId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        return {'success': false, 'message': null};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/reviews/products/$productId/reviews/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'rating': rating,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          'comment': comment,
        }),
      );

      debugPrint('⭐ Submit review: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      String? message;
      try {
        final err = json.decode(response.body);
        if (err is Map) {
          final raw = err['non_field_errors'] ??
              err['detail'] ??
              err['error'] ??
              err['message'];
          if (raw is List && raw.isNotEmpty) {
            message = raw.first.toString();
          } else if (raw != null) {
            message = raw.toString();
          }
        }
      } catch (_) {}
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('❌ Error submitting review: $e');
      return {'success': false, 'message': null};
    }
  }

  /// Reviews left on the current store owner's products (paginated).
  /// Returns `{reviews: List<StoreReview>, hasMore: bool, total: int}`.
  /// Public: reviews on ANY store's products (vendor page Reviews section).
  static Future<Map<String, dynamic>> getPublicStoreReviews(
      String storeUsername,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/reviews/store/$storeUsername/reviews/?page=$page'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = (data['results'] ?? data['data'] ?? []) as List;
        final reviews = list
            .map((e) => StoreReview.fromJson(e as Map<String, dynamic>))
            .toList();
        final total = data['total_count'] ?? data['count'] ?? reviews.length;
        return {
          'reviews': reviews,
          'hasMore': data['next'] != null,
          'total':
              total is int ? total : int.tryParse('$total') ?? reviews.length,
        };
      }
      return {'reviews': <StoreReview>[], 'hasMore': false, 'total': 0};
    } catch (e) {
      debugPrint('❌ Error loading public store reviews: $e');
      return {'reviews': <StoreReview>[], 'hasMore': false, 'total': 0};
    }
  }

  static Future<Map<String, dynamic>> getStoreReviews({int page = 1}) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/store-reviews/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('⭐ Store reviews response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = (data['results'] ?? data['data'] ?? []) as List;
        final reviews = list
            .map((e) => StoreReview.fromJson(e as Map<String, dynamic>))
            .toList();
        final hasMore = data['next'] != null;
        final total = data['total_count'] ?? data['count'] ?? reviews.length;
        return {
          'reviews': reviews,
          'hasMore': hasMore,
          'total': total is int ? total : int.tryParse('$total') ?? reviews.length,
        };
      }
      return {'reviews': <StoreReview>[], 'hasMore': false, 'total': 0};
    } catch (e) {
      debugPrint('❌ Error loading store reviews: $e');
      return {'reviews': <StoreReview>[], 'hasMore': false, 'total': 0};
    }
  }

  /// Total number of reviews on the store owner's products.
  static Future<int> getStoreReviewsCount() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/store-reviews/count/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final c = data['count'];
        return c is int ? c : int.tryParse('$c') ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error loading store reviews count: $e');
      return 0;
    }
  }

  /// Post (or update) the store owner's reply to a review.
  /// Returns `{success, data: StoreReview}` or `{success: false, message}`.
  static Future<Map<String, dynamic>> replyToReview({
    required String reviewId,
    required String text,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/reviews/reviews/$reviewId/reply/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'seller_response': text}),
      );

      debugPrint('⭐ Reply response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': StoreReview.fromJson(json.decode(response.body)),
        };
      }
      String? message;
      try {
        final err = json.decode(response.body);
        if (err is Map) {
          message = (err['error'] ?? err['detail'] ?? err['message'])?.toString();
        }
      } catch (_) {}
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('❌ Error replying to review: $e');
      return {'success': false, 'message': null};
    }
  }

  /// Remove the store owner's reply from a review.
  static Future<Map<String, dynamic>> deleteReply({
    required String reviewId,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/reviews/$reviewId/reply/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': StoreReview.fromJson(json.decode(response.body)),
        };
      }
      return {'success': false, 'message': null};
    } catch (e) {
      debugPrint('❌ Error deleting reply: $e');
      return {'success': false, 'message': null};
    }
  }
}
