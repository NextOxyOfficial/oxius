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

  /// Get all micro gigs with optional filtering
  /// [category] - Filter by category ID
  /// [showSubmitted] - Show completed gigs (true) or available gigs (false)
  static Future<List<MicroGig>> getMicroGigs({
    int? category,
    bool? showSubmitted,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) {
        queryParams['category'] = category.toString();
      }
      if (showSubmitted != null) {
        queryParams['show_submitted'] = showSubmitted.toString();
      }

      final uri = Uri.parse('$baseUrl/micro-gigs/')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MicroGig.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load micro gigs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting micro gigs: $e');
      return [];
    }
  }

  /// Get micro gig categories with counts
  static Map<String, dynamic> getMicroGigCategories(List<MicroGig> gigs) {
    final categoryCounts = <String, Map<String, dynamic>>{};

    for (var gig in gigs) {
      if (gig.categoryDetails == null) continue;

      final category = gig.categoryDetails!.title;
      final id = gig.categoryDetails!.id;
      final isActiveAndApproved = gig.activeGig && 
          gig.gigStatus == 'approved' && 
          gig.user != null;

      if (!categoryCounts.containsKey(category)) {
        categoryCounts[category] = {
          'total': 0,
          'active': 0,
          'id': id,
        };
      }

      categoryCounts[category]!['total'] = 
          (categoryCounts[category]!['total'] as int) + 1;
      
      if (isActiveAndApproved) {
        categoryCounts[category]!['active'] = 
            (categoryCounts[category]!['active'] as int) + 1;
      }
    }

    return categoryCounts;
  }
}
