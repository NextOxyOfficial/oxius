import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/diamond_models.dart';
import 'api_service.dart';

class DiamondService {
  static String get _baseUrl => ApiService.baseUrl;

  // Get diamond packages
  static Future<List<DiamondPackage>> getPackages() async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/diamonds/packages/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => DiamondPackage.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading diamond packages: $e');
      return [];
    }
  }

  // Purchase diamonds
  static Future<Map<String, dynamic>?> purchaseDiamonds({
    required int amount,
    required double cost,
  }) async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/diamonds/purchase/'),
        headers: headers,
        body: json.encode({
          'amount': amount,
          'cost': cost,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to purchase diamonds');
      }
    } catch (e) {
      print('Error purchasing diamonds: $e');
      rethrow;
    }
  }

  // Get diamond transaction history
  static Future<DiamondTransactionsResponse?> getTransactions({
    int page = 1,
  }) async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/diamonds-transactions/?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DiamondTransactionsResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error loading transaction history: $e');
      return null;
    }
  }

  // Calculate price based on diamonds (10 diamonds = 1 BDT)
  static double calculatePrice(int diamonds) {
    return diamonds / 10.0;
  }

  // Calculate diamonds from price
  static int calculateDiamonds(double price) {
    return (price * 10).round();
  }

  // Send diamond gift to post author
  static Future<Map<String, dynamic>?> sendGift({
    required int amount,
    required String recipientId,
    required String postId,
    required String message,
  }) async {
    try {
      final headers = await ApiService.getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/diamonds/send-gift/'),
        headers: headers,
        body: json.encode({
          'amount': amount,
          'recipientId': recipientId,
          'postId': postId,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to send gift');
      }
    } catch (e) {
      print('Error sending gift: $e');
      rethrow;
    }
  }
}
