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
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

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
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📱 Packages response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'results': data['results'] ?? data,
          'count': data['count'] ?? (data is List ? data.length : 0),
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
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
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/mobile-recharge/operators/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
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
    required String operator,
    required double amount,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

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
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/mobile-recharge/recharges/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'results': data['results'] ?? data,
          'count': data['count'] ?? 0,
        };
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('❌ Error fetching history: $e');
      return {
        'success': false,
        'message': 'Failed to load history',
        'results': [],
      };
    }
  }
}
