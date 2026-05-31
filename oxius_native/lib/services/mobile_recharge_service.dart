// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

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

      print('📱 Fetching packages: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📱 Packages response status: ${response.statusCode}');
      print('📱 Packages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📱 Decoded data type: ${data.runtimeType}');
        print(
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

        print('📱 Total results found: ${results.length}');
        if (results.isNotEmpty) {
          print('📱 Sample package: ${results.first}');
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
        print(
            '❌ API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load packages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching packages: $e');
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
      print('📱 Fetching operators from: $baseUrl/mobile-recharge/operators/');

      final response = await http.get(
        Uri.parse('$baseUrl/mobile-recharge/operators/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📱 Operators response status: ${response.statusCode}');
      print('📱 Operators response body: ${response.body}');

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

        print('📱 Total operators found: ${operators.length}');

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
              print(
                  '📱 Converted operator icon: ${operator['name']} -> ${operator['icon']}');
            }
          }

          return operator;
        }).toList();

        print(
            '📱 Processed operators: ${processedOperators.map((o) => '${o['name']} (${o['icon']})').join(', ')}');

        return List<Map<String, dynamic>>.from(processedOperators);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching operators: $e');
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

      print(
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

      print('📱 Recharge response: ${response.statusCode}');
      print('📱 Response body: ${response.body}');

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
      print('❌ Error submitting recharge: $e');
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
        print('❌ Recharge history: No auth token');
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('$baseUrl/mobile-recharge/recharges/?page=$page');
      print('📱 Fetching recharge history: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📱 Recharge history response status: ${response.statusCode}');
      print('📱 Recharge history response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📱 Recharge history data type: ${data.runtimeType}');

        // Handle both paginated and non-paginated responses
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map && data['results'] != null) {
          results = data['results'];
        } else {
          results = [];
        }

        print('📱 Total recharge records found: ${results.length}');

        return {
          'success': true,
          'results': results,
          'count':
              data is Map ? (data['count'] ?? results.length) : results.length,
        };
      } else {
        print(
            '❌ API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching recharge history: $e');
      return {
        'success': false,
        'message': 'Failed to load history: $e',
        'results': [],
      };
    }
  }
}
