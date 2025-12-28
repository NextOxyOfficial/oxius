import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';
import 'business_network_service.dart';
import '../screens/business_network/profile_screen.dart';
import '../screens/business_network/post_detail_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/workspace/order_detail_screen.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log('📱 Background message received: ${message.messageId}');
  _log('📦 Data: ${message.data}');
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Map<String, dynamic>? _pendingNavigationData;
  static Timer? _pendingNavigationTimer;
  static int _pendingNavigationAttempts = 0;

  /// Initialize FCM
  static Future<void> initialize() async {
    try {
      _log('🔥 Initializing FCM Service...');
      _log('=' * 60);

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
        _log('✅ Notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _log('⚠️ Notification permission granted (provisional)');
      } else {
        _log('❌ Notification permission denied');
        _log('   Status: ${settings.authorizationStatus}');
        _log('   Please enable notifications in device settings');
        // Continue anyway - user might enable later
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      _log('\n📱 FCM TOKEN (DEBUG ONLY):');
      _log('=' * 60);
      _log(_fcmToken ?? 'null');
      _log('=' * 60);
      _log('');

      // Send token to backend
      if (_fcmToken != null) {
        _log('📤 Sending FCM token to backend...');
        await _sendTokenToBackend(_fcmToken!);
      } else {
        _log('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _log('🔄 FCM Token refreshed: $newToken');
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

      _log('✅ FCM Service initialized successfully');
    } catch (e) {
      _log('❌ Error initializing FCM: $e');
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
    _log('📨 Foreground message received');
    _log('Title: ${message.notification?.title}');
    _log('Body: ${message.notification?.body}');
    _log('Data: ${message.data}');

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
    _log('🔔 Notification tapped');
    _log('Data: ${message.data}');

    final data = Map<String, dynamic>.from(message.data);
    _navigateBasedOnData(data);
  }

  /// Handle local notification tap
  static void _handleLocalNotificationTap(String payload) {
    _log('🔔 Local notification tapped');
    _log('Payload: $payload');

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _navigateBasedOnData(Map<String, dynamic>.from(decoded));
      } else {
        _log('⚠️ Local notification payload is not a Map');
      }
    } catch (e) {
      _log('Error parsing payload: $e');
    }
  }

  /// Navigate based on notification data
  static void _navigateBasedOnData(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _log('⚠️ Navigator is not ready yet. Queuing navigation.');
      _pendingNavigationData = Map<String, dynamic>.from(data);
      _schedulePendingNavigation();
      return;
    }

    _navigateBasedOnDataNow(navigator, data);
  }

  static void _schedulePendingNavigation() {
    if (_pendingNavigationTimer != null) return;

    _pendingNavigationAttempts = 0;
    _pendingNavigationTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      final navigator = navigatorKey.currentState;
      if (navigator != null && _pendingNavigationData != null) {
        final data = _pendingNavigationData!;
        _pendingNavigationData = null;
        timer.cancel();
        _pendingNavigationTimer = null;
        _navigateBasedOnDataNow(navigator, data);
        return;
      }

      _pendingNavigationAttempts += 1;
      if (_pendingNavigationAttempts >= 25) {
        _log('⚠️ Navigator not ready after waiting. Dropping pending navigation.');
        _pendingNavigationData = null;
        timer.cancel();
        _pendingNavigationTimer = null;
      }
    });
  }

  static Map<String, dynamic> _normalizeNotificationData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    for (final key in ['data', 'payload', 'extra']) {
      final value = normalized[key];
      if (value is String && value.isNotEmpty) {
        final trimmed = value.trim();
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          try {
            final decoded = jsonDecode(trimmed);
            if (decoded is Map) {
              normalized.addAll(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {
            // Ignore
          }
        }
      }
    }

    return normalized;
  }

  static void _navigateBasedOnDataNow(NavigatorState navigator, Map<String, dynamic> rawData) {
    final context = navigator.context;
    final data = _normalizeNotificationData(rawData);

    final rawType = data['type']?.toString();
    final rawNotificationType = data['notification_type']?.toString();

    String? type = rawType;
    final notificationType = rawNotificationType;

    if ((type == null || type.isEmpty) && notificationType != null && notificationType.isNotEmpty) {
      type = notificationType;
    }

    if (type == 'business_network' && notificationType != null && notificationType.isNotEmpty) {
      type = notificationType;
    }

    final directRoute = data['route']?.toString() ?? data['screen']?.toString();
    if (directRoute != null && directRoute.startsWith('/')) {
      _log('   → Navigating to direct route: $directRoute');
      navigator.pushNamed(directRoute);
      return;
    }

    _log('🔔 Navigating based on notification type: $type, notification_type: $notificationType');
    _log('   Data: $data');

    // ============================================
    // WORKSPACE NOTIFICATIONS
    // ============================================
    if (type == 'workspace') {
      final orderId = data['order_id']?.toString();
      
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
          _log('   → Navigating to workspace order: $orderId');
          navigator.push(
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            ),
          );
        } else {
          _log('   ⚠️ Order ID is null, navigating to inbox updates tab');
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const InboxScreen(initialTab: 1),
            ),
          );
        }
      } else if (notificationType == 'new_review') {
        // Navigate to gig detail or my gigs
        _log('   → Navigating to my gigs for review notification');
        navigator.pushNamed('/my-gigs');
      } else {
        // Default workspace - go to inbox updates tab
        _log('   → Default workspace notification, navigating to inbox updates');
        navigator.push(
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
        _log('   → Navigating to profile: $userId');
        navigator.push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: userId),
          ),
        );
      }
    } else if (type == 'like_post' || type == 'comment' || type == 'mention') {
      // Navigate to post detail
      final postId = data['target_id']?.toString() ?? data['post_id']?.toString();
      if (postId != null) {
        _log('   → Navigating to post: $postId');
        _navigateToPostDetail(context, int.tryParse(postId) ?? 0);
      }
    } else if (type == 'like_comment' || type == 'reply') {
      // Navigate to post detail using parent_id
      final postId = data['parent_id']?.toString() ?? data['post_id']?.toString();
      if (postId != null) {
        _log('   → Navigating to post: $postId');
        _navigateToPostDetail(context, int.tryParse(postId) ?? 0);
      }
    } else if (type == 'solution') {
      // Navigate to MindForce
      _log('   → Navigating to MindForce');
      navigator.pushNamed('/mindforce');
    } else if (type == 'gift_diamonds') {
      // Navigate to post detail
      final postId = data['target_id']?.toString() ?? data['post_id']?.toString();
      if (postId != null) {
        _log('   → Navigating to post: $postId');
        _navigateToPostDetail(context, int.tryParse(postId) ?? 0);
      }
    }
    // ============================================
    // ADSYCONNECT MESSAGES
    // ============================================
    else if (type == 'message' || type == 'chat_message') {
      // Navigate to inbox AdsyConnect tab
      final chatId = data['chat_id']?.toString() ?? data['chatroom_id']?.toString();
      _log('   → Navigating to AdsyConnect chat: $chatId');
      navigator.push(
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
      _log('   → Navigating to support ticket: $ticketId');
      navigator.push(
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
      _log('   → Navigating to wallet for: $type');
      navigator.pushNamed('/deposit-withdraw');
    }
    // ============================================
    // ORDERS (Legacy)
    // ============================================
    else if (type == 'order' || type == 'order_received' || type == 'order_status' || type == 'order_placed') {
      final orderId = data['order_id']?.toString();
      if (orderId != null) {
        _log('   → Navigating to order: $orderId');
        navigator.push(
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: orderId),
          ),
        );
      } else {
        _log('   → Navigating to inbox updates tab');
        navigator.push(
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
      _log('   → Navigating to upgrade to pro for: $type');
      navigator.pushNamed('/upgrade-to-pro');
    }
    // ============================================
    // GIG UPDATES
    // ============================================
    else if (type == 'gig_posted' || type == 'gig_approved' || type == 'gig_rejected') {
      _log('   → Navigating to my gigs for: $type');
      navigator.pushNamed('/my-gigs');
    }
    // ============================================
    // CLASSIFIED POSTS
    // ============================================
    else if (type == 'classified_post' || type == 'classified') {
      final postId = data['post_id']?.toString() ?? data['classified_id']?.toString();
      if (postId != null) {
        _log('   → Navigating to classified post: $postId');
        navigator.pushNamed(
          '/classified-post-details',
          arguments: {'postId': postId},
        );
      }
    }
    // ============================================
    // GENERAL/ADMIN NOTICES
    // ============================================
    else if (type == 'general' || type == 'admin_notice' || type == 'system' || type == 'announcement') {
      _log('   → General notification, navigating to inbox updates tab');
      navigator.push(
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
      _log('   → Account notification, navigating to inbox updates tab');
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const InboxScreen(initialTab: 0),
        ),
      );
    }
    // ============================================
    // DEFAULT
    // ============================================
    else {
      _log('   ⚠️ Unknown notification type: $type');
      // Default to inbox
      navigator.pushNamed('/inbox');
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      _log('   Checking authentication...');
      final authToken = await AuthService.getValidToken();
      if (authToken == null) {
        _log('   ⚠️ No auth token, skipping FCM token upload');
        _log('   💡 User needs to login first');
        return;
      }

      _log('   ✅ User is authenticated');
      _log('   📡 Sending to: ${ApiService.baseUrl}/save-fcm-token/');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/save-fcm-token/'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token, 'device_type': 'android'}),
      );

      _log('   Response status: ${response.statusCode}');
      _log('   Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('   ✅ FCM token sent to backend successfully!');
      } else {
        _log('   ❌ Failed to send FCM token: ${response.statusCode}');
        _log('   Response: ${response.body}');
      }
    } catch (e) {
      _log('   ❌ Error sending FCM token: $e');
      _log('   💡 Check if backend server is running');
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
      _log('Error refreshing FCM token: $e');
    }
  }

  /// Helper method to navigate to post detail by fetching the post first
  static Future<void> _navigateToPostDetail(BuildContext context, int postId) async {
    if (postId <= 0) {
      _log('   ⚠️ Invalid post ID: $postId');
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
        _log('   ⚠️ Post not found: $postId');
      }
    } catch (e) {
      _log('   ⚠️ Error fetching post: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    }
  }
}
