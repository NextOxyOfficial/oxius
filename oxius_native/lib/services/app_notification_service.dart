import 'dart:convert';
import 'api_service.dart';

/// A saved push notification shown in the AdsyConnect "Updates" tab.
class AppNotification {
  final int id;
  final String title;
  final String body;
  final String image;
  final String deepLink;
  final bool hasVisit;
  final String notificationType;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.image,
    required this.deepLink,
    required this.hasVisit,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      image: (j['image'] ?? '').toString(),
      deepLink: (j['deep_link'] ?? '').toString(),
      hasVisit: j['has_visit'] == true,
      notificationType: (j['notification_type'] ?? 'general').toString(),
      isRead: j['is_read'] == true,
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    );
  }
}

class AppNotificationService {
  static String get _base => ApiService.baseUrl;

  /// Page of the current user's notifications (newest first) + broadcasts.
  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await ApiService.client.get(
        Uri.parse('$_base/notifications/?page=$page'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? const [];
        return {
          'items': results
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          'hasMore': data['next'] != null,
        };
      }
    } catch (_) {}
    return {'items': <AppNotification>[], 'hasMore': false};
  }

  static Future<int> unreadCount() async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await ApiService.client.get(
        Uri.parse('$_base/notifications/unread-count/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['unread'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  static Future<void> markRead(int id) async {
    try {
      final headers = await ApiService.getHeaders();
      await ApiService.client.post(
        Uri.parse('$_base/notifications/$id/read/'),
        headers: headers,
      );
    } catch (_) {}
  }

  static Future<void> markAllRead() async {
    try {
      final headers = await ApiService.getHeaders();
      await ApiService.client.post(
        Uri.parse('$_base/notifications/mark-all-read/'),
        headers: headers,
      );
    } catch (_) {}
  }
}
