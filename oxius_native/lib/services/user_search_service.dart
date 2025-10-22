import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user_model.dart' as UserModel;

class UserSearchService {
  static String get _baseUrl => '${ApiService.baseUrl}/bn';

  /// Search users for mentions
  static Future<List<UserModel.User>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user-search/?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<dynamic> users = [];
        if (data is Map && data['results'] != null) {
          users = data['results'];
        } else if (data is List) {
          users = data;
        }

        return users.map((json) => UserModel.User.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
