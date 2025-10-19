import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final token = AuthService.getToken();
      if (token == null) {
        return {'notifications': [], 'hasMore': false, 'unreadCount': 0};
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/notifications/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<NotificationModel> notifications = [];
        
        if (data['results'] != null && data['results'] is List) {
          for (var item in data['results']) {
            notifications.add(NotificationModel.fromJson(item));
          }
        }

        return {
          'notifications': notifications,
          'hasMore': data['next'] != null,
          'unreadCount': data['unread_count'] ?? 0,
        };
      }

      return {'notifications': [], 'hasMore': false, 'unreadCount': 0};
    } catch (e) {
      print('Error fetching notifications: $e');
      return {'notifications': [], 'hasMore': false, 'unreadCount': 0};
    }
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final token = AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/bn/notifications/$notificationId/read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'read': true}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<bool> markAllAsRead() async {
    try {
      final token = AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/bn/notifications/mark-all-read/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final token = AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bn/notifications/?page=1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      }

      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }
}
