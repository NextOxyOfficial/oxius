import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class UserSuggestionsService {
  /// Fetch user suggestions with social connectivity algorithm
  /// Returns users based on mutual connections, similar interests, location, etc.
  static Future<List<Map<String, dynamic>>> getUserSuggestions() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/user-suggestions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        debugPrint('Error fetching user suggestions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getUserSuggestions: $e');
      return [];
    }
  }

  /// Follow a user
  static Future<bool> followUser(String userId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/bn/users/$userId/follow/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String userId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/bn/users/$userId/unfollow/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  /// Fetch sponsored/featured products
  static Future<List<Map<String, dynamic>>> getSponsoredProducts({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/all-products/?limit=$limit&is_featured=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] is List) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
        return [];
      } else {
        debugPrint('Error fetching sponsored products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getSponsoredProducts: $e');
      return [];
    }
  }
}
