import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/microgig_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MicrogigService {
  static String get baseUrl => ApiService.baseUrl;

  /// Get pending tasks for current user with pagination and filtering
  /// [page] - Page number (starts from 1)
  /// [filter] - Filter type: 'all', 'pending', 'approved', 'rejected'
  static Future<Map<String, dynamic>> getPendingTasks({
    int page = 1,
    String filter = 'all',
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse('$baseUrl/user-pending-tasks/')
          .replace(queryParameters: {
        'page': page.toString(),
        'filter': filter,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle paginated response
        final List<dynamic> results = data['results'] ?? [];
        final tasks = results.map((json) => MicroGigTask.fromJson(json)).toList();
        
        return {
          'tasks': tasks,
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
          'hasMore': data['next'] != null,
        };
      } else {
        throw Exception('Failed to load pending tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting pending tasks: $e');
      return {
        'tasks': <MicroGigTask>[],
        'count': 0,
        'next': null,
        'previous': null,
        'hasMore': false,
      };
    }
  }

  /// Calculate total pending balance from pending tasks
  static double calculatePendingBalance(List<MicroGigTask> tasks) {
    return tasks
        .where((task) => !task.approved && !task.rejected)
        .fold(0.0, (sum, task) => sum + task.gigPrice);
  }
}
