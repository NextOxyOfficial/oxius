import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('📦 Data: ${message.data}');
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize FCM
  static Future<void> initialize() async {
    try {
      print('🔥 Initializing FCM Service...');
      print('=' * 60);

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else {
        print('❌ Notification permission denied');
        print('   Please enable notifications in device settings');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('\n📱 FCM TOKEN (COPY THIS FOR TESTING):');
      print('=' * 60);
      print(_fcmToken);
      print('=' * 60);
      print('');

      // Send token to backend
      if (_fcmToken != null) {
        print('📤 Sending FCM token to backend...');
        await _sendTokenToBackend(_fcmToken!);
      } else {
        print('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleLocalNotificationTap(response.payload!);
        }
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'oxius_messages', // id
      'Oxius Messages', // name
      description: 'Notifications for messages and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Show local notification
    _showLocalNotification(message);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'oxius_messages',
        'Oxius Messages',
        channelDescription: 'Notifications for messages and updates',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped');
    print('Data: ${message.data}');

    final data = message.data;
    _navigateBasedOnData(data);
  }

  /// Handle local notification tap
  static void _handleLocalNotificationTap(String payload) {
    print('🔔 Local notification tapped');
    print('Payload: $payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateBasedOnData(data);
    } catch (e) {
      print('Error parsing payload: $e');
    }
  }

  /// Navigate based on notification data
  static void _navigateBasedOnData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ Navigator context is null, cannot navigate');
      return;
    }

    final type = data['type']?.toString();
    print('🔔 Navigating based on notification type: $type');
    print('   Data: $data');

    if (type == 'message') {
      // Navigate to chat screen
      final chatId = data['chat_id']?.toString();
      final senderId = data['sender_id']?.toString();
      final senderName = data['sender_name']?.toString();
      
      if (chatId != null) {
        print('   → Navigating to chat: $chatId');
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'userId': senderId,
            'userName': senderName,
          },
        );
      } else {
        print('   ⚠️ Chat ID is null, navigating to messages list');
        Navigator.pushNamed(context, '/messages');
      }
    } else if (type == 'support_ticket') {
      // Navigate to support ticket detail
      final ticketId = data['ticket_id']?.toString();
      
      if (ticketId != null) {
        print('   → Navigating to support ticket: $ticketId');
        Navigator.pushNamed(
          context,
          '/support-ticket-detail',
          arguments: {'ticketId': ticketId},
        );
      } else {
        print('   ⚠️ Ticket ID is null, navigating to support list');
        Navigator.pushNamed(context, '/support');
      }
    } else if (type == 'order') {
      // Navigate to orders
      final orderId = data['order_id']?.toString();
      
      if (orderId != null) {
        print('   → Navigating to order detail: $orderId');
        Navigator.pushNamed(
          context,
          '/order-detail',
          arguments: {'orderId': orderId},
        );
      } else {
        print('   → Navigating to orders list');
        Navigator.pushNamed(context, '/orders');
      }
    } else if (type == 'wallet') {
      // Navigate to wallet
      print('   → Navigating to wallet');
      Navigator.pushNamed(context, '/deposit-withdraw');
    } else if (type == 'general') {
      // General notification - go to home or notifications page
      print('   → General notification, navigating to home');
      Navigator.pushNamed(context, '/');
    } else {
      print('   ⚠️ Unknown notification type: $type');
      // Default to home
      Navigator.pushNamed(context, '/');
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      print('   Checking authentication...');
      final authToken = await AuthService.getValidToken();
      if (authToken == null) {
        print('   ⚠️ No auth token, skipping FCM token upload');
        print('   💡 User needs to login first');
        return;
      }

      print('   ✅ User is authenticated');
      print('   📡 Sending to: ${ApiService.baseUrl}/save-fcm-token/');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/save-fcm-token/'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token, 'device_type': 'android'}),
      );

      print('   Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('   ✅ FCM token sent to backend successfully!');
      } else {
        print('   ❌ Failed to send FCM token: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
    } catch (e) {
      print('   ❌ Error sending FCM token: $e');
      print('   💡 Check if backend server is running');
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Refresh FCM token
  static Future<void> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }
}
