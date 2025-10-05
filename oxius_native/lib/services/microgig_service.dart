import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/microgig_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MicrogigService {
  static String get baseUrl => ApiService.baseUrl;

  /// Get pending tasks for current user
  static Future<List<MicroGigTask>> getPendingTasks() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user-pending-tasks/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MicroGigTask.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pending tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting pending tasks: $e');
      return [];
    }
  }

  /// Calculate total pending balance from pending tasks
  static double calculatePendingBalance(List<MicroGigTask> tasks) {
    return tasks
        .where((task) => !task.approved && !task.rejected)
        .fold(0.0, (sum, task) => sum + task.gigPrice);
  }
}
