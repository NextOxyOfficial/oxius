import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/mindforce_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class MindForceService {
  // Fetch all problems
  static Future<List<MindForceProblem>> getProblems() async {
    try {
      final token = await AuthService.getToken();
      final headers = token != null
          ? {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            }
          : {'Content-Type': 'application/json'};

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MindForceProblem.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching problems: $e');
      return [];
    }
  }

  // Fetch categories
  static Future<List<MindForceCategory>> getCategories() async {
    try {
      final token = await AuthService.getToken();
      final headers = token != null
          ? {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            }
          : {'Content-Type': 'application/json'};

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/categories/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MindForceCategory.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Create problem
  static Future<MindForceProblem?> createProblem({
    required String title,
    required String description,
    int? categoryId,
    String paymentOption = 'free',
    double? paymentAmount,
    List<String> images = const [],
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final body = {
        'title': title,
        'description': description,
        'payment_option': paymentOption,
        'images': images,
      };

      if (categoryId != null) {
        body['category'] = categoryId.toString();
      }

      if (paymentAmount != null) {
        body['payment_amount'] = paymentAmount.toString();
      }

      print('Creating problem with body: ${json.encode(body)}');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('Create problem response status: ${response.statusCode}');
      print('Create problem response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return MindForceProblem.fromJson(data);
      } else {
        print('Failed to create problem: ${response.statusCode}');
        print('Error response: ${response.body}');
      }

      return null;
    } catch (e) {
      print('Error creating problem: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update problem
  static Future<bool> updateProblem(int problemId, Map<String, dynamic> updates) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/$problemId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating problem: $e');
      return false;
    }
  }

  // Delete problem
  static Future<bool> deleteProblem(int problemId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/$problemId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting problem: $e');
      return false;
    }
  }

  // Fetch comments for a problem
  static Future<List<MindForceComment>> getComments(int problemId) async {
    try {
      final token = await AuthService.getToken();
      final headers = token != null
          ? {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            }
          : {'Content-Type': 'application/json'};

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/$problemId/comments/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MindForceComment.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  // Add comment
  static Future<MindForceComment?> addComment({
    required int problemId,
    required String content,
    List<String> images = const [],
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/$problemId/comments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'images': images,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return MindForceComment.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Mark comment as solution
  static Future<bool> markCommentAsSolution(int commentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/bn/mindforce/comments/$commentId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_solved': true}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking comment as solution: $e');
      return false;
    }
  }

  // Mark problem as solved
  static Future<bool> markProblemAsSolved(int problemId) async {
    return updateProblem(problemId, {'status': 'solved'});
  }

  // Increment view count
  static Future<void> incrementViews(int problemId, int currentViews) async {
    await updateProblem(problemId, {'views': currentViews + 1});
  }
}
