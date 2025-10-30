import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final token = await AuthService.getToken();
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

      print('🔔 Notification API Status: ${response.statusCode}');
      print('🔔 Notification API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔔 Decoded data type: ${data.runtimeType}');
        print('🔔 Has results key: ${data.containsKey('results')}');
        
        final List<NotificationModel> notifications = [];
        
        if (data['results'] != null && data['results'] is List) {
          print('🔔 Results list length: ${data['results'].length}');
          for (var item in data['results']) {
            try {
              notifications.add(NotificationModel.fromJson(item));
              print('✅ Parsed notification: ${item['type']} from ${item['actor']?['name']}');
            } catch (e) {
              print('❌ Error parsing notification: $e');
              print('❌ Notification data: $item');
            }
          }
        } else {
          print('❌ No results in response or results is not a list');
          print('❌ Response data: $data');
        }

        // Count unread notifications
        int unreadCount = 0;
        if (data['results'] != null && data['results'] is List) {
          for (var item in data['results']) {
            if (item['read'] == false) unreadCount++;
          }
        }

        print('🔔 Parsed ${notifications.length} notifications, $unreadCount unread');
        print('🔔 Returning: notifications list type = ${notifications.runtimeType}');
        
        final result = {
          'notifications': notifications,
          'hasMore': data['next'] != null,
          'unreadCount': unreadCount,
        };
        
        print('🔔 Result map: $result');
        return result;
      } else {
        print('❌ Notification API Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }

      return {'notifications': [], 'hasMore': false, 'unreadCount': 0};
    } catch (e) {
      print('Error fetching notifications: $e');
      print('Stack trace: ${StackTrace.current}');
      return {'notifications': [], 'hasMore': false, 'unreadCount': 0};
    }
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await AuthService.getToken();
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
      final token = await AuthService.getToken();
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
      final token = await AuthService.getToken();
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
