import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'business_network_service.dart';
import 'agora_call_service.dart';
import '../firebase_options.dart';
import '../screens/business_network/profile_screen.dart';
import '../screens/business_network/post_detail_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/workspace/order_detail_screen.dart';
import '../screens/call_screen.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

class _CallkitLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When user taps the CallKit notification, Android may resume the app without
      // triggering FCM onMessageOpenedApp. Check active calls and navigate.
      FCMService._tryNavigateToActiveCallkitCall();
    }
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _log('📱 Background message received: ${message.messageId}');
  _log('📦 Data: ${message.data}');
  
  // Handle incoming call in background - show high priority notification
  final type = message.data['type']?.toString();
  if (type == 'incoming_call' || type == 'call') {
    await _showBackgroundCallNotification(message.data);
  }
}

/// Show native incoming call screen when app is in background/killed (WhatsApp-style)
Future<void> _showBackgroundCallNotification(Map<String, dynamic> data) async {
  // Check if call is too old (more than 30 seconds)
  final timestampStr = data['timestamp']?.toString();
  if (timestampStr != null) {
    try {
      final callTimestamp = int.parse(timestampStr);
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTimestamp - callTimestamp;
      
      // If call is older than 30 seconds, ignore it
      if (timeDifference > 30000) {
        _log('🚫 Ignoring old call notification (${timeDifference}ms old)');
        return;
      }
    } catch (e) {
      _log('⚠️ Error parsing call timestamp: $e');
    }
  }
  
  final callerName = data['caller_name']?.toString() ?? 'Unknown';
  final callerId = data['caller_id']?.toString() ?? '';
  final callerAvatar = data['caller_avatar']?.toString();
  final callType = data['call_type']?.toString() ?? 'video';
  final channelName = data['channel_name']?.toString() ?? '';
  
  final uuid = const Uuid().v4();
  
  final params = CallKitParams(
    id: uuid,
    nameCaller: callerName,
    appName: 'AdsyClub',
    avatar: callerAvatar,
    handle: callType == 'video' ? 'Video Call' : 'Voice Call',
    type: callType == 'video' ? 1 : 0, // 0 = audio, 1 = video
    duration: 60000, // 60 seconds ring timeout
    textAccept: 'Accept',
    textDecline: 'Decline',
    extra: {
      'caller_id': callerId,
      'channel_name': channelName,
      'call_type': callType,
      'caller_name': callerName,
      'caller_avatar': callerAvatar ?? '',
    },
    headers: <String, dynamic>{'platform': 'android'},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      backgroundUrl: '',
      actionColor: '#4CAF50',
      textColor: '#ffffff',
      incomingCallNotificationChannelName: 'Incoming Calls',
      isShowCallID: false,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'default',
    ),
  );
  
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  
  // Track active calls to prevent duplicates
  static final Set<String> _activeCallIds = <String>{};
  static final Map<String, int> _callTimestamps = <String, int>{};
  
  // Track accepted CallKit UUIDs to prevent actionCallEnded from sending 'ended' status
  static final Set<String> _acceptedCallkitUuids = <String>{};
  
  static const String _fcmTokenKey = 'adsyclub_fcm_token';
  static const String _lastUploadedKey = 'adsyclub_fcm_token_last_uploaded';
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Map<String, dynamic>? _pendingNavigationData;
  static Timer? _pendingNavigationTimer;
  static int _pendingNavigationAttempts = 0;
  static bool _lifecycleObserverInstalled = false;

  static Future<void> _persistFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
    } catch (e) {
      _log('⚠️ Failed to persist FCM token: $e');
    }
  }

  static Future<String?> _getPersistedFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fcmTokenKey);
      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      _log('⚠️ Failed to read persisted FCM token: $e');
      return null;
    }
  }

  /// Sync the current (or persisted) FCM token to the backend.
  /// Call this after login/session restore so the token upload doesn't get skipped.
  static Future<void> syncTokenWithBackend() async {
    try {
      final token = _fcmToken ?? await _getPersistedFcmToken() ?? await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) {
        _log('❌ Cannot sync token: FCM token is null/empty');
        return;
      }

      _fcmToken = token;
      await _persistFcmToken(token);
      await _sendTokenToBackend(token);
    } catch (e) {
      _log('❌ Error syncing FCM token: $e');
    }
  }

  /// Initialize FCM
  static Future<void> initialize() async {
    try {
      _log('🔥 Initializing FCM Service...');
      _log('=' * 60);

      if (!_lifecycleObserverInstalled) {
        WidgetsBinding.instance.addObserver(_CallkitLifecycleObserver());
        _lifecycleObserverInstalled = true;
      }

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
      
      // Initialize CallKit for incoming calls
      await _initializeCallKit();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      _log('\n📱 FCM TOKEN (DEBUG ONLY):');
      _log('=' * 60);
      _log(_fcmToken ?? 'null');
      _log('=' * 60);
      _log('');

      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _persistFcmToken(_fcmToken!);
      }

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
        _persistFcmToken(newToken);
        _sendTokenToBackend(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // If app was opened via CallKit notification shade tap, FCM callbacks may not fire.
      // Detect any active CallKit calls and navigate to the call screen.
      // Do this BEFORE processing FCM initial message to prioritize accepted calls
      await _tryNavigateToActiveCallkitCall();

      // Check if app was opened from a notification
      // Skip if we already have an accepted_call pending (from CallKit accept)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        final pendingType = _pendingNavigationData?['type']?.toString();
        if (pendingType == 'accepted_call') {
          _log('📞 Skipping FCM initial message - accepted_call pending');
        } else {
          _handleNotificationTap(initialMessage);
        }
      }

      _log('✅ FCM Service initialized successfully');
    } catch (e) {
      _log('❌ Error initializing FCM: $e');
    }
  }

  static Future<void> _tryNavigateToActiveCallkitCall() async {
    if (AgoraCallService.isCallScreenVisible) return;
    
    // Don't overwrite pending accepted_call navigation
    if (_pendingNavigationData != null && _pendingNavigationData!['type'] == 'accepted_call') {
      _log('📞 Skipping _tryNavigateToActiveCallkitCall - accepted_call pending');
      return;
    }

    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List || calls.isEmpty) return;

      final dynamic last = calls.last;
      if (last is! Map) return;

      final map = Map<String, dynamic>.from(last);
      
      // Check if this call was already accepted
      final callkitUuid = map['id']?.toString() ?? '';
      final wasAccepted = callkitUuid.isNotEmpty && _acceptedCallkitUuids.contains(callkitUuid);

      Map<String, dynamic>? extra;
      final rawExtra = map['extra'];
      if (rawExtra is Map) {
        extra = Map<String, dynamic>.from(rawExtra);
      } else if (rawExtra is String && rawExtra.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawExtra);
          if (decoded is Map) {
            extra = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Ignore
        }
      }

      final callerId = extra?['caller_id']?.toString();
      final channelName = extra?['channel_name']?.toString();
      if (callerId == null || channelName == null) return;

      final callData = {
        // If call was accepted, use 'accepted_call' type to go directly to CallScreen
        'type': wasAccepted ? 'accepted_call' : 'incoming_call',
        'caller_id': callerId,
        'channel_name': channelName,
        'call_type': extra?['call_type']?.toString() ?? 'video',
        'caller_name': extra?['caller_name']?.toString() ?? 'Unknown',
        'caller_avatar': extra?['caller_avatar']?.toString() ?? '',
      };

      _navigateBasedOnData(callData);
    } catch (e) {
      _log('⚠️ Failed to read CallKit active calls: $e');
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

    // Create high-priority call notification channel with ringtone
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'oxius_calls', // id
      'Incoming Calls', // name
      description: 'Notifications for incoming voice and video calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(callChannel);
  }

  /// Initialize CallKit for native incoming call UI
  static Future<void> _initializeCallKit() async {
    try {
      // Listen for CallKit events
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
        if (event == null) return;
        _log('📞 CallKit Event: ${event.event}');
        
        switch (event.event) {
          case Event.actionCallIncoming:
            _cacheCallIncoming(event);
            break;
          case Event.actionCallAccept:
            _handleCallAccepted(event);
            break;
          case Event.actionCallDecline:
            _handleCallDeclined(event);
            break;
          case Event.actionCallEnded:
            _handleCallEnded(event);
            break;
          case Event.actionCallTimeout:
            _handleCallTimeout(event);
            break;
          default:
            break;
        }
      });
      
      _log('✅ CallKit initialized');
    } catch (e) {
      _log('❌ Error initializing CallKit: $e');
    }
  }

  static void _cacheCallIncoming(CallEvent event) {
    // Do not auto-navigate here. This event can fire when the incoming CallKit UI is displayed.
    // Navigation should happen on accept or when the user taps the notification and app resumes.
    // Don't overwrite accepted_call with incoming_call
    if (_pendingNavigationData?['type'] == 'accepted_call') {
      _log('📞 Skipping _cacheCallIncoming - accepted_call already pending');
      return;
    }
    _pendingNavigationData ??= _extractCallDataFromCallEvent(event);
  }

  static Map<String, dynamic>? _extractCallDataFromCallEvent(CallEvent event) {
    final extra = event.body['extra'] as Map<String, dynamic>?;
    if (extra == null) return null;

    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    if (callerId == null || channelName == null) return null;

    return {
      'type': 'incoming_call',
      'caller_id': callerId,
      'channel_name': channelName,
      'call_type': extra['call_type']?.toString() ?? 'video',
      'caller_name': extra['caller_name']?.toString() ?? 'Unknown',
      'caller_avatar': extra['caller_avatar']?.toString() ?? '',
    };
  }

  /// Handle call accepted from CallKit
  static void _handleCallAccepted(CallEvent event) {
    final extra = event.body['extra'] as Map<String, dynamic>?;
    if (extra == null) return;
    
    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    final callType = extra['call_type']?.toString() ?? 'video';
    final callerName = extra['caller_name']?.toString() ?? 'Unknown';
    final callerAvatar = extra['caller_avatar']?.toString();
    final callkitUuid = event.body['id']?.toString() ?? '';
    
    if (callerId == null || channelName == null) return;
    
    // Mark this CallKit UUID as accepted so actionCallEnded won't send 'ended' status
    if (callkitUuid.isNotEmpty) {
      _acceptedCallkitUuids.add(callkitUuid);
    }
    
    // Use setCallConnected to mark call as connected (stops ringtone, updates call history on iOS)
    // Then end the CallKit UI - this is the correct flow for accepted calls
    FlutterCallkitIncoming.setCallConnected(callkitUuid);
    FlutterCallkitIncoming.endCall(callkitUuid);
    
    // Navigate to call screen - use pending navigation if navigator not ready (app cold start)
    // Use special type 'accepted_call' so _navigateBasedOnDataNow navigates directly to CallScreen
    final callData = {
      'type': 'accepted_call', // Special type to bypass showIncomingCall and go directly to CallScreen
      'caller_id': callerId,
      'channel_name': channelName,
      'call_type': callType,
      'caller_name': callerName,
      'caller_avatar': callerAvatar ?? '',
    };
    
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      _navigateToCallScreenDirectly(navigator, callData);
    } else {
      // App not fully initialized yet - store for pending navigation
      _log('📞 Navigator not ready, storing pending call navigation');
      _pendingNavigationData = callData;
      _schedulePendingNavigation();
    }
  }

  /// Handle call declined from CallKit
  static void _handleCallDeclined(CallEvent event) {
    final extra = event.body['extra'] as Map<String, dynamic>?;
    if (extra == null) return;
    
    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    final callType = extra['call_type']?.toString() ?? 'video';
    
    if (callerId == null || channelName == null) return;
    
    // Send rejected status to caller
    AgoraCallService.sendCallStatus(
      receiverId: callerId,
      channelName: channelName,
      status: 'rejected',
      callType: callType,
    );
    
    // End the CallKit UI
    FlutterCallkitIncoming.endCall(event.body['id'] ?? '');
  }

  /// Handle call ended from CallKit
  static void _handleCallEnded(CallEvent event) {
    final callkitUuid = event.body['id']?.toString() ?? '';
    
    // If this call was accepted, don't send 'ended' status - the CallScreen will handle it
    final wasAccepted = _acceptedCallkitUuids.remove(callkitUuid);
    
    final extra = event.body['extra'] as Map<String, dynamic>?;
    if (extra != null) {
      final callerId = extra['caller_id']?.toString();
      final channelName = extra['channel_name']?.toString();
      final callType = extra['call_type']?.toString() ?? 'video';
      
      if (callerId != null && channelName != null) {
        // Remove from active calls tracking
        final callId = '${callerId}_${channelName}';
        _activeCallIds.remove(callId);
        _callTimestamps.remove(callId);
        
        // Only send ended status if the call was NOT accepted
        // If accepted, the CallScreen handles sending the proper status when call ends
        if (!wasAccepted) {
          _log('📞 CallKit ended (not accepted) - sending ended status to caller');
          AgoraCallService.sendCallStatus(
            receiverId: callerId,
            channelName: channelName,
            status: 'ended',
            callType: callType,
          );
        } else {
          _log('📞 CallKit ended (was accepted) - CallScreen will handle status');
        }
      }
    }
    
    // Ensure CallKit UI is dismissed
    if (callkitUuid.isNotEmpty) {
      FlutterCallkitIncoming.endCall(callkitUuid);
    }
  }

  /// Handle call timeout from CallKit
  static void _handleCallTimeout(CallEvent event) {
    final extra = event.body['extra'] as Map<String, dynamic>?;
    if (extra == null) return;
    
    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    final callType = extra['call_type']?.toString() ?? 'video';
    
    if (callerId == null || channelName == null) return;
    
    // Remove from active calls tracking
    final callId = '${callerId}_${channelName}';
    _activeCallIds.remove(callId);
    _callTimestamps.remove(callId);
    
    // Send missed call status
    AgoraCallService.sendCallStatus(
      receiverId: callerId,
      channelName: channelName,
      status: 'cancelled',
      callType: callType,
    );
    
    FlutterCallkitIncoming.endCall(event.body['id'] ?? '');
  }

  /// Show native incoming call screen (for foreground calls too)
  static Future<void> showIncomingCall({
    required String callerId,
    required String callerName,
    String? callerAvatar,
    required String channelName,
    required String callType,
    int? timestamp,
  }) async {
    // Don't show CallKit if already in a call or CallScreen is visible
    if (AgoraCallService.isInCall || AgoraCallService.isCallScreenVisible) {
      _log('🚫 Ignoring incoming call - already in call or CallScreen visible');
      // Auto-reply busy
      AgoraCallService.sendCallStatus(
        receiverId: callerId,
        channelName: channelName,
        status: 'busy',
        callType: callType,
      );
      return;
    }
    
    // Check if call is too old (more than 30 seconds)
    if (timestamp != null) {
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTimestamp - timestamp;
      
      if (timeDifference > 30000) {
        _log('🚫 Ignoring old foreground call (${timeDifference}ms old)');
        return;
      }
    }
    
    // Create unique call identifier
    final callId = '${callerId}_${channelName}';
    
    // Check if this call is already active
    if (_activeCallIds.contains(callId)) {
      _log('🚫 Ignoring duplicate call: $callId');
      return;
    }
    
    // Add to active calls tracking
    _activeCallIds.add(callId);
    if (timestamp != null) {
      _callTimestamps[callId] = timestamp;
    }
    
    final uuid = const Uuid().v4();
    
    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'AdsyClub',
      avatar: callerAvatar,
      handle: callType == 'video' ? 'Video Call' : 'Voice Call',
      type: callType == 'video' ? 1 : 0,
      duration: 60000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: {
        'caller_id': callerId,
        'channel_name': channelName,
        'call_type': callType,
        'caller_name': callerName,
        'caller_avatar': callerAvatar ?? '',
      },
      headers: <String, dynamic>{'platform': 'android'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Calls',
        isShowCallID: false,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        ringtonePath: 'default',
      ),
    );
    
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// End all active calls
  static Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
    // Clear all tracking
    _activeCallIds.clear();
    _callTimestamps.clear();
    _acceptedCallkitUuids.clear();
  }

  /// Navigate directly to CallScreen for accepted calls (bypasses showIncomingCall)
  static void _navigateToCallScreenDirectly(NavigatorState navigator, Map<String, dynamic> data) {
    final channelName = data['channel_name']?.toString();
    final callerId = data['caller_id']?.toString();
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callerAvatar = data['caller_avatar']?.toString();
    final callType = data['call_type']?.toString() ?? 'video';
    
    if (channelName == null || callerId == null) {
      _log('⚠️ Cannot navigate to CallScreen: missing channelName or callerId');
      return;
    }
    
    // Prevent duplicate CallScreen pushes
    if (AgoraCallService.isCallScreenVisible) {
      _log('📞 CallScreen already visible, skipping navigation');
      return;
    }
    
    _log('📞 Navigating directly to CallScreen (accepted call)');
    navigator.push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          calleeId: callerId,
          calleeName: callerName,
          calleeAvatar: callerAvatar,
          isIncoming: true,
          callType: callType,
          autoAccept: true, // Already accepted from CallKit, skip accept UI
        ),
      ),
    );
  }

  /// Clean up old call timestamps (older than 2 minutes)
  static void cleanupOldCalls() {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final expiredCallIds = <String>[];
    
    _callTimestamps.forEach((callId, timestamp) {
      final timeDifference = currentTimestamp - timestamp;
      // Remove calls older than 2 minutes
      if (timeDifference > 120000) {
        expiredCallIds.add(callId);
      }
    });
    
    for (final callId in expiredCallIds) {
      _activeCallIds.remove(callId);
      _callTimestamps.remove(callId);
      _log('🧹 Cleaned up expired call: $callId');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    _log('📨 Foreground message received');
    _log('Title: ${message.notification?.title}');
    _log('Body: ${message.notification?.body}');
    _log('Data: ${message.data}');

    // Clean up old calls before processing new ones
    cleanupOldCalls();

    // Incoming call: open call screen immediately in foreground
    final type = message.data['type']?.toString();
    if (type == 'incoming_call' || type == 'call' || type == 'call_status') {
      _navigateBasedOnData(Map<String, dynamic>.from(message.data));
      return;
    }

    // Show local notification
    _showLocalNotification(message);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final type = data['type']?.toString();

    // Check if this is an incoming call notification
    if (type == 'incoming_call' || type == 'call') {
      await _showCallNotification(message);
      return;
    }

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

  /// Show native incoming call screen for foreground calls
  static Future<void> _showCallNotification(RemoteMessage message) async {
    final data = message.data;
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callerId = data['caller_id']?.toString() ?? '';
    final callerAvatar = data['caller_avatar']?.toString();
    final callType = data['call_type']?.toString() ?? 'video';
    final channelName = data['channel_name']?.toString() ?? '';
    
    // Parse timestamp if available
    int? timestamp;
    final timestampStr = data['timestamp']?.toString();
    if (timestampStr != null) {
      try {
        timestamp = int.parse(timestampStr);
      } catch (e) {
        _log('⚠️ Error parsing foreground call timestamp: $e');
      }
    }
    
    // Show native CallKit incoming call screen
    await showIncomingCall(
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      channelName: channelName,
      callType: callType,
      timestamp: timestamp,
    );
  }

  /// Legacy call notification (kept for fallback)
  static Future<void> _showLegacyCallNotification(RemoteMessage message) async {
    final data = message.data;
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callType = data['call_type']?.toString() ?? 'video';
    final callTypeLabel = callType == 'video' ? 'Video' : 'Voice';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'oxius_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming voice and video calls',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60000, // 60 seconds timeout
      styleInformation: BigTextStyleInformation(
        'Tap to answer the call',
        contentTitle: '$callTypeLabel call from $callerName',
        summaryText: 'Incoming $callTypeLabel Call',
      ),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      999, // Fixed ID for call notifications so we can cancel it
      'Incoming $callTypeLabel Call',
      '$callerName is calling...',
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  /// Cancel call notification
  static Future<void> cancelCallNotification() async {
    await _localNotifications.cancel(999);
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
      // Don't overwrite accepted_call with lower priority navigation
      final existingType = _pendingNavigationData?['type']?.toString();
      final newType = data['type']?.toString();
      if (existingType == 'accepted_call' && newType != 'accepted_call') {
        _log('📞 Keeping existing accepted_call pending, ignoring $newType');
        return;
      }
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
    // ACCEPTED CALL (from CallKit accept - navigate directly to CallScreen)
    // ============================================
    else if (type == 'accepted_call') {
      _navigateToCallScreenDirectly(navigator, data);
    }
    // ============================================
    // INCOMING CALL (Agora)
    // ============================================
    else if (type == 'incoming_call' || type == 'call') {
      final channelName = data['channel_name']?.toString();
      final callerId = data['caller_id']?.toString();
      final callerName = data['caller_name']?.toString() ?? 'Unknown';
      final callerAvatar = data['caller_avatar']?.toString();
      final callType = data['call_type']?.toString() ?? 'video';
      
      if (channelName != null && callerId != null) {
        if (AgoraCallService.isInCall) {
          _log('   → Already in call. Auto-reply busy to caller: $callerId');
          AgoraCallService.sendCallStatus(
            receiverId: callerId,
            channelName: channelName,
            status: 'busy',
            callType: callType,
          );
          return;
        }

        _log('   → Incoming call from: $callerName, channel: $channelName');
        // Show CallKit notification instead of opening CallScreen directly
        // This ensures proper ringtone and native call UI
        showIncomingCall(
          callerId: callerId,
          callerName: callerName,
          callerAvatar: callerAvatar,
          channelName: channelName,
          callType: callType,
        );
      }
    }
    // ============================================
    // CALL STATUS (busy/rejected/cancelled/ended)
    // ============================================
    else if (type == 'call_status') {
      AgoraCallService.emitCallStatus(data);
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
      final currentUserId = AuthService.currentUser?.id ?? '';
      final uploadKey = '$currentUserId:$token';

      _log('   Checking authentication...');
      final authToken = await AuthService.getValidToken();
      if (authToken == null) {
        _log('   ⚠️ No auth token, skipping FCM token upload');
        _log('   💡 User needs to login first');
        return;
      }

      // Avoid re-uploading the exact same token for the same logged-in user
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastUploaded = prefs.getString(_lastUploadedKey);
        if (lastUploaded == uploadKey) {
          _log('   ℹ️ FCM token already uploaded for this user, skipping');
          return;
        }
      } catch (_) {
        // Ignore
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
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastUploadedKey, uploadKey);
        } catch (_) {
          // Ignore
        }
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
