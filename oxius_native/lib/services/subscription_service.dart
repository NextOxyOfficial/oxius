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
      final token = await AuthService.getToken();
      
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

  /// Get current subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final token = await AuthService.getToken();
      
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
      final token = await AuthService.getToken();
      
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
