// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class MobileRechargeService {
  static String get baseUrl => ApiService.baseUrl;

  /// Get all available recharge packages
  static Future<Map<String, dynamic>> getPackages({
    String? operator,
    String? type,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        if (operator != null && operator != 'all') 'operator': operator,
        if (type != null && type != 'all') 'type': type,
      };

      final uri = Uri.parse('$baseUrl/mobile-recharge/packages/').replace(
        queryParameters: queryParams,
      );

      debugPrint('📱 Fetching packages: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📱 Packages response status: ${response.statusCode}');
      debugPrint('📱 Packages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📱 Decoded data type: ${data.runtimeType}');
        debugPrint(
            '📱 Data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');

        // Handle both paginated and non-paginated responses
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map && data['results'] != null) {
          results = data['results'];
        } else {
          results = [];
        }

        debugPrint('📱 Total results found: ${results.length}');
        if (results.isNotEmpty) {
          debugPrint('📱 Sample package: ${results.first}');
        }

        return {
          'success': true,
          'results': results,
          'count':
              data is Map ? (data['count'] ?? results.length) : results.length,
          'next': data is Map ? data['next'] : null,
          'previous': data is Map ? data['previous'] : null,
        };
      } else {
        debugPrint(
            '❌ API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load packages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching packages: $e');
      return {
        'success': false,
        'message': 'Failed to load packages: $e',
        'results': [],
      };
    }
  }

  /// Get available operators
  static Future<List<Map<String, dynamic>>> getOperators() async {
    try {
      debugPrint('📱 Fetching operators from: $baseUrl/mobile-recharge/operators/');

      final response = await http.get(
        Uri.parse('$baseUrl/mobile-recharge/operators/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📱 Operators response status: ${response.statusCode}');
      debugPrint('📱 Operators response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> operators;

        if (data is List) {
          operators = data;
        } else if (data['results'] != null) {
          operators = data['results'];
        } else {
          operators = [];
        }

        debugPrint('📱 Total operators found: ${operators.length}');

        // Process operators to ensure icon URLs are absolute
        final processedOperators = operators.map((op) {
          final operator = Map<String, dynamic>.from(op);

          // Convert icon URL to absolute if it's relative
          if (operator['icon'] != null &&
              operator['icon'].toString().isNotEmpty) {
            final iconUrl = operator['icon'].toString();
            if (!iconUrl.startsWith('http')) {
              // Remove leading slash if present
              final cleanPath =
                  iconUrl.startsWith('/') ? iconUrl.substring(1) : iconUrl;
              operator['icon'] = '$baseUrl/$cleanPath';
              debugPrint(
                  '📱 Converted operator icon: ${operator['name']} -> ${operator['icon']}');
            }
          }

          return operator;
        }).toList();

        debugPrint(
            '📱 Processed operators: ${processedOperators.map((o) => '${o['name']} (${o['icon']})').join(', ')}');

        return List<Map<String, dynamic>>.from(processedOperators);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching operators: $e');
      return [];
    }
  }

  /// Submit a recharge request
  static Future<Map<String, dynamic>> submitRecharge({
    required int packageId,
    required String phoneNumber,
    required int operator,
    required double amount,
  }) async {
    try {
      final token = AuthService.isAuthenticated
          ? await AuthService.getValidToken()
          : null;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      debugPrint(
          '📱 Submitting recharge: packageId=$packageId, operator=$operator, phone=$phoneNumber, amount=$amount');

      final response = await http.post(
        Uri.parse('$baseUrl/mobile-recharge/recharges/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'package': packageId,
          'phone_number': phoneNumber,
          'operator': operator,
          'amount': amount,
        }),
      );

      debugPrint('📱 Recharge response: ${response.statusCode}');
      debugPrint('📱 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Recharge successful',
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Recharge failed',
          'errors': errorData['errors'] ?? {},
        };
      }
    } catch (e) {
      debugPrint('❌ Error submitting recharge: $e');
      return {
        'success': false,
        'message': 'Failed to process recharge: $e',
      };
    }
  }

  /// Get recharge history
  static Future<Map<String, dynamic>> getRechargeHistory({int page = 1}) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        debugPrint('❌ Recharge history: No auth token');
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('$baseUrl/mobile-recharge/recharges/?page=$page');
      debugPrint('📱 Fetching recharge history: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📱 Recharge history response status: ${response.statusCode}');
      debugPrint('📱 Recharge history response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📱 Recharge history data type: ${data.runtimeType}');

        // Handle both paginated and non-paginated responses
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map && data['results'] != null) {
          results = data['results'];
        } else {
          results = [];
        }

        debugPrint('📱 Total recharge records found: ${results.length}');

        return {
          'success': true,
          'results': results,
          'count':
              data is Map ? (data['count'] ?? results.length) : results.length,
        };
      } else {
        debugPrint(
            '❌ API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching recharge history: $e');
      return {
        'success': false,
        'message': 'Failed to load history: $e',
        'results': [],
      };
    }
  }
}
