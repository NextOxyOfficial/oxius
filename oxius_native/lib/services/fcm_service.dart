import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';
import 'business_network_service.dart';
import '../screens/business_network/profile_screen.dart';
import '../screens/business_network/post_detail_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/workspace/order_detail_screen.dart';

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

      // Request notification permissions with more aggressive settings
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,  // Request critical alert permission (iOS)
        announcement: true,   // Request announcement permission (iOS)
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Notification permission granted (provisional)');
      } else {
        print('❌ Notification permission denied');
        print('   Status: ${settings.authorizationStatus}');
        print('   Please enable notifications in device settings');
        // Continue anyway - user might enable later
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
    final notificationType = data['notification_type']?.toString();
    print('🔔 Navigating based on notification type: $type, notification_type: $notificationType');
    print('   Data: $data');

    // ============================================
    // WORKSPACE NOTIFICATIONS
    // ============================================
    if (type == 'workspace') {
      final orderId = data['order_id']?.toString();
      final gigId = data['gig_id']?.toString();
      
      // Handle different workspace notification types
      if (notificationType == 'new_order' || 
          notificationType == 'order_accept' ||
          notificationType == 'order_decline' ||
          notificationType == 'order_deliver' ||
          notificationType == 'order_complete' ||
          notificationType == 'order_cancel' ||
          notificationType == 'order_message' ||
          notificationType == 'payment_released' ||
          notificationType == 'order_cancelled' ||
          notificationType == 'order_refunded') {
        if (orderId != null) {
          print('   → Navigating to workspace order: $orderId');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            ),
          );
        } else {
          print('   ⚠️ Order ID is null, navigating to inbox updates tab');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InboxScreen(initialTab: 1),
            ),
          );
        }
      } else if (notificationType == 'new_review') {
        // Navigate to gig detail or my gigs
        print('   → Navigating to my gigs for review notification');
        Navigator.pushNamed(context, '/my-gigs');
      } else {
        // Default workspace - go to inbox updates tab
        print('   → Default workspace notification, navigating to inbox updates');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InboxScreen(initialTab: 1),
          ),
        );
      }
    }
    // ============================================
    // BUSINESS NETWORK NOTIFICATIONS
    // ============================================
    else if (type == 'follow') {
      // Navigate to user profile
      final userId = data['actor_id']?.toString() ?? data['user_id']?.toString();
      if (userId != null) {
        print('   → Navigating to profile: $userId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: userId),
          ),
        );
      }
    } else if (type == 'like_post' || type == 'comment' || type == 'mention') {
      // Navigate to post detail
      final postId = data['target_id']?.toString() ?? data['post_id']?.toString();
      if (postId != null) {
        print('   → Navigating to post: $postId');
        _navigateToPostDetail(context, int.tryParse(postId) ?? 0);
      }
    } else if (type == 'like_comment' || type == 'reply') {
      // Navigate to post detail using parent_id
      final postId = data['parent_id']?.toString() ?? data['post_id']?.toString();
      if (postId != null) {
        print('   → Navigating to post: $postId');
        _navigateToPostDetail(context, int.tryParse(postId) ?? 0);
      }
    } else if (type == 'solution') {
      // Navigate to MindForce
      print('   → Navigating to MindForce');
      Navigator.pushNamed(context, '/mindforce');
    } else if (type == 'gift_diamonds') {
      // Navigate to post detail
      final postId = data['target_id']?.toString() ?? data['post_id']?.toString();
      if (postId != null) {
        print('   → Navigating to post: $postId');
        _navigateToPostDetail(context, int.tryParse(postId) ?? 0);
      }
    }
    // ============================================
    // ADSYCONNECT MESSAGES
    // ============================================
    else if (type == 'message' || type == 'chat_message') {
      // Navigate to inbox AdsyConnect tab
      final chatId = data['chat_id']?.toString() ?? data['chatroom_id']?.toString();
      print('   → Navigating to AdsyConnect chat: $chatId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InboxScreen(
            initialTab: 0, // AdsyConnect tab is index 0
            initialChatId: chatId,
          ),
        ),
      );
    }
    // ============================================
    // SUPPORT TICKETS
    // ============================================
    else if (type == 'support_ticket' || type == 'ticket' || type == 'ticket_reply' || type == 'ticket_status_update') {
      final ticketId = data['ticket_id']?.toString();
      print('   → Navigating to support ticket: $ticketId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InboxScreen(
            initialTab: 2, // Support tab is index 2
            initialTicketId: ticketId,
          ),
        ),
      );
    }
    // ============================================
    // WALLET/TRANSACTIONS
    // ============================================
    else if (type == 'wallet' || type == 'withdraw_successful' || type == 'mobile_recharge_successful' || 
             type == 'deposit' || type == 'deposit_successful' || type == 'transfer_sent' || 
             type == 'transfer_received') {
      print('   → Navigating to wallet for: $type');
      Navigator.pushNamed(context, '/deposit-withdraw');
    }
    // ============================================
    // ORDERS (Legacy)
    // ============================================
    else if (type == 'order' || type == 'order_received' || type == 'order_status' || type == 'order_placed') {
      final orderId = data['order_id']?.toString();
      if (orderId != null) {
        print('   → Navigating to order: $orderId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: orderId),
          ),
        );
      } else {
        print('   → Navigating to inbox updates tab');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InboxScreen(initialTab: 1),
          ),
        );
      }
    }
    // ============================================
    // PRO SUBSCRIPTION
    // ============================================
    else if (type == 'pro_subscribed' || type == 'pro_expiring' || type == 'pro_expired') {
      print('   → Navigating to upgrade to pro for: $type');
      Navigator.pushNamed(context, '/upgrade-to-pro');
    }
    // ============================================
    // GIG UPDATES
    // ============================================
    else if (type == 'gig_posted' || type == 'gig_approved' || type == 'gig_rejected') {
      print('   → Navigating to my gigs for: $type');
      Navigator.pushNamed(context, '/my-gigs');
    }
    // ============================================
    // CLASSIFIED POSTS
    // ============================================
    else if (type == 'classified_post' || type == 'classified') {
      final postId = data['post_id']?.toString() ?? data['classified_id']?.toString();
      if (postId != null) {
        print('   → Navigating to classified post: $postId');
        Navigator.pushNamed(
          context,
          '/classified-post-details',
          arguments: {'postId': postId},
        );
      }
    }
    // ============================================
    // GENERAL/ADMIN NOTICES
    // ============================================
    else if (type == 'general' || type == 'admin_notice' || type == 'system' || type == 'announcement') {
      print('   → General notification, navigating to inbox updates tab');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InboxScreen(initialTab: 0),
        ),
      );
    }
    // ============================================
    // ACCOUNT UPDATES
    // ============================================
    else if (type == 'kyc_approved' || type == 'kyc_rejected' || type == 'account_warning' || 
             type == 'account_suspended' || type == 'account_activated') {
      print('   → Account notification, navigating to inbox updates tab');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InboxScreen(initialTab: 0),
        ),
      );
    }
    // ============================================
    // DEFAULT
    // ============================================
    else {
      print('   ⚠️ Unknown notification type: $type');
      // Default to inbox
      Navigator.pushNamed(context, '/inbox');
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

  /// Helper method to navigate to post detail by fetching the post first
  static Future<void> _navigateToPostDetail(BuildContext context, int postId) async {
    if (postId <= 0) {
      print('   ⚠️ Invalid post ID: $postId');
      return;
    }
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Fetch the post
      final post = await BusinessNetworkService.getPost(postId);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (post != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      } else {
        print('   ⚠️ Post not found: $postId');
      }
    } catch (e) {
      print('   ⚠️ Error fetching post: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    }
  }
}
