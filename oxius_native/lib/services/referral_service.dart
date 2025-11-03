import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/referral_models.dart';

class ReferralService {
  static final String baseUrl = AppConfig.apiBaseUrl;

  /// Get platform referral statistics (public)
  static Future<PlatformStats> getPlatformStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/platform-referral-stats/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlatformStats.fromJson(data);
      } else {
        // Return default values
        return PlatformStats(
          activeReferrers: 500,
          topEarnerAmount: 10000,
          quickPayoutTime: '24hr',
          commissionRates: CommissionRates(
            gigCompletion: '5%',
            proSubscription: '20%',
            goldSponsor: '20%',
          ),
        );
      }
    } catch (e) {
      print('Error fetching platform stats: $e');
      return PlatformStats(
        activeReferrers: 500,
        topEarnerAmount: 10000,
        quickPayoutTime: '24hr',
        commissionRates: CommissionRates(
          gigCompletion: '5%',
          proSubscription: '20%',
          goldSponsor: '20%',
        ),
      );
    }
  }

  /// Get user's referral code and link
  static Future<Map<String, String>> getReferralInfo() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final user = AuthService.currentUser;
      if (user != null && user.referralCode != null) {
        return {
          'code': user.referralCode!,
          'link': 'https://adsyclub.com/auth/register/?ref=${user.referralCode}',
        };
      }

      throw Exception('No referral code found');
    } catch (e) {
      print('Error getting referral info: $e');
      rethrow;
    }
  }

  /// Get commission history
  static Future<CommissionData> getCommissionHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/commission-history/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommissionData.fromJson(data);
      } else {
        throw Exception('Failed to load commission history');
      }
    } catch (e) {
      print('Error fetching commission history: $e');
      rethrow;
    }
  }

  /// Get referred users
  static Future<List<ReferredUser>> getReferredUsers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/referred-users/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['referred_users'] != null) {
          return (data['referred_users'] as List)
              .map((user) => ReferredUser.fromJson(user))
              .toList();
        } else if (data is List) {
          return data.map((user) => ReferredUser.fromJson(user)).toList();
        }
        
        return [];
      } else {
        throw Exception('Failed to load referred users');
      }
    } catch (e) {
      print('Error fetching referred users: $e');
      rethrow;
    }
  }
}
