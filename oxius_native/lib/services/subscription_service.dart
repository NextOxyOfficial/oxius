import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class SubscriptionService {

  /// Create a new subscription
  Future<Map<String, dynamic>> createSubscription({
    required int months,
    required int total,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/subscribe/?months=$months&total=$total'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        return {
          'success': true,
          'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          'data': data,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create subscription');
      }
    } catch (e) {
      print('Error creating subscription: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Public Pro pricing (regular / discount / effective), admin-managed.
  Future<Map<String, dynamic>?> getProPricing() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/pro-pricing/'),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('getProPricing error: $e');
    }
    return null;
  }

  /// Read the auto-renew status of the active paid subscription.
  Future<Map<String, dynamic>?> getAutoRenew() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auto-renew/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('getAutoRenew error: $e');
    }
    return null;
  }

  /// Turn auto-renew on/off. Returns {auto_renew, message} or null on failure.
  Future<Map<String, dynamic>?> setAutoRenew(bool enabled) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) return null;
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auto-renew/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'auto_renew': enabled}),
      ).timeout(const Duration(seconds: 8));
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    } catch (e) {
      print('setAutoRenew error: $e');
      return null;
    }
  }

  /// Get current subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/subscription/details/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (e) {
      print('Error fetching subscription details: $e');
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/subscription/cancel/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling subscription: $e');
      return false;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      final details = await getSubscriptionDetails();
      return details != null && details['is_active'] == true;
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
    }
  }
}
