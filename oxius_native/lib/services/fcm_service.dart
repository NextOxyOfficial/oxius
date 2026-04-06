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
import 'adsyconnect_realtime_service.dart';
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

const Set<String> _rideshareNotificationTypes = <String>{
  'rideshare_update',
  'new_ride_request',
  'targeted_ride_request',
  'ride_accepted',
  'ride_cancelled',
  'ride_completed',
  'ride_auto_cancelled',
};

const Set<String> _rideshareRideRequestTypes = <String>{
  'new_ride_request',
  'targeted_ride_request',
};

const Set<String> _rideshareStatusTypes = <String>{
  'searching_driver',
  'accepted',
  'driver_arriving',
  'in_progress',
  'awaiting_passenger_confirmation',
  'completed',
  'cancelled',
  'no_driver_available',
  'auto_cancelled',
};

bool _isRideshareNotification(
  Map<String, dynamic> data, {
  String? type,
  String? notificationType,
}) {
  final rideId = data['ride_id']?.toString();
  final status = data['status']?.toString();

  return _rideshareNotificationTypes.contains(type) ||
      _rideshareNotificationTypes.contains(notificationType) ||
      _rideshareStatusTypes.contains(notificationType) ||
      _rideshareStatusTypes.contains(status) ||
      (rideId != null && rideId.isNotEmpty);
}

bool _isRideshareRideRequestNotification(String? type) {
  return _rideshareRideRequestTypes.contains(type);
}

String _resolveRideshareMode(
  Map<String, dynamic> data, {
  String? type,
  String? notificationType,
}) {
  final modeHint = data['mode']?.toString() ??
      data['user_role']?.toString() ??
      data['recipient_role']?.toString() ??
      data['target_role']?.toString();

  if (modeHint == 'driver' || modeHint == 'passenger') {
    return modeHint!;
  }

  if (type == 'targeted_ride_request' ||
      type == 'new_ride_request' ||
      data['targeted_driver_id'] != null ||
      data['targeted_driver_user_id'] != null) {
    return 'driver';
  }

  if (notificationType == 'searching_driver' ||
      notificationType == 'accepted' ||
      notificationType == 'driver_arriving' ||
      notificationType == 'awaiting_passenger_confirmation' ||
      notificationType == 'no_driver_available' ||
      notificationType == 'auto_cancelled') {
    return 'passenger';
  }

  return 'passenger';
}

class _CallkitLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    FCMService._appLifecycleState = state;
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
  
  final type = message.data['type']?.toString();

  // Handle incoming call in background - show high priority notification
  if (type == 'incoming_call' || type == 'call') {
    await _showBackgroundCallNotification(message.data);
    return;
  }

  // Handle ride request in background - wake the driver
  if (_isRideshareRideRequestNotification(type)) {
    await _showBackgroundRideRequestNotification(message.data);
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

class _TrackingRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  String? currentRouteName;

  void _capture(Route<dynamic>? route) {
    currentRouteName = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _capture(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _capture(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _capture(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _capture(previousRoute);
  }
}

/// Show ride request notification when app is in background/killed
/// Uses a separate plugin instance since FCMService static members are unavailable
Future<void> _showBackgroundRideRequestNotification(Map<String, dynamic> data) async {
  final rideId = data['ride_id']?.toString() ?? '';
  final pickup = data['pickup_address']?.toString() ?? 'Pickup';
  final drop = data['drop_address']?.toString() ?? 'Drop';
  final fare = data['fare_estimate']?.toString() ?? '';
  final timeoutSec = int.tryParse(data['timeout_seconds']?.toString() ?? '') ?? 60;

  final title = '🚗 New Ride Request!';
  final body = '${pickup.length > 35 ? '${pickup.substring(0, 35)}…' : pickup} → ${drop.length > 35 ? '${drop.substring(0, 35)}…' : drop}${fare.isNotEmpty ? ' · ৳$fare' : ''}';

  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

  final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    'oxius_ride_requests',
    'Ride Requests',
    description: 'New ride request alerts for drivers',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  ));

  final details = AndroidNotificationDetails(
    'oxius_ride_requests',
    'Ride Requests',
    channelDescription: 'New ride request alerts for drivers',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    icon: '@mipmap/ic_launcher',
    timeoutAfter: timeoutSec * 1000,
    autoCancel: true,
  );

  await plugin.show(
    rideId.hashCode,
    title,
    body,
    NotificationDetails(android: details),
    payload: jsonEncode({
      ...data,
      'type': data['type']?.toString() ?? 'targeted_ride_request',
    }),
  );
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;
  static final _TrackingRouteObserver _routeObserver = _TrackingRouteObserver();
  static final StreamController<Map<String, dynamic>>
      _rideshareNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  static const int _callRecoveryMaxAgeMs = 30000;
  static bool _callRecoveryEnabled = false;
  
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
  static StreamSubscription<Map<String, dynamic>>? _adsyConnectRealtimeSubscription;
  static final Map<String, int> _recentCallSignalTimestamps = <String, int>{};

  static bool get _isAppInForeground => _appLifecycleState == AppLifecycleState.resumed;
  static RouteObserver<PageRoute<dynamic>> get routeObserver => _routeObserver;
  static String? get currentRouteName => _routeObserver.currentRouteName;

  static Stream<Map<String, dynamic>> get rideshareNotificationEvents =>
      _rideshareNotificationController.stream;

  static void _emitRideshareNotificationEvent(Map<String, dynamic> payload) {
    if (!_rideshareNotificationController.isClosed) {
      _rideshareNotificationController.add(payload);
    }
  }

  static String _buildCallId(String callerId, String channelName) {
    return '${callerId}_$channelName';
  }

  static int? _parseCallTimestamp(dynamic rawValue) {
    if (rawValue == null) return null;
    if (rawValue is int) return rawValue;
    return int.tryParse(rawValue.toString());
  }

  static bool _shouldProcessCallSignal(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type != 'incoming_call' && type != 'call' && type != 'call_status') {
      return true;
    }

    final channelName = data['channel_name']?.toString();
    if (channelName == null || channelName.isEmpty) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _recentCallSignalTimestamps.removeWhere(
      (_, timestamp) => now - timestamp > 4000,
    );

    final signalKey = [
      type,
      channelName,
      data['status']?.toString() ?? '',
      data['caller_id']?.toString() ?? data['sender_id']?.toString() ?? '',
    ].join('|');

    final previousTimestamp = _recentCallSignalTimestamps[signalKey];
    if (previousTimestamp != null && now - previousTimestamp <= 4000) {
      _log('📞 Skipping duplicate call signal: $signalKey');
      return false;
    }

    _recentCallSignalTimestamps[signalKey] = now;
    return true;
  }

  static void _attachAdsyConnectRealtimeBridge() {
    _adsyConnectRealtimeSubscription ??=
        AdsyConnectRealtimeService.instance.events.listen((event) {
      final type = event['type']?.toString();
      if (type != 'incoming_call' && type != 'call' && type != 'call_status') {
        return;
      }

      final payload = Map<String, dynamic>.from(event);
      if (!_shouldProcessCallSignal(payload)) {
        return;
      }

      _log('📞 Handling AdsyConnect realtime call event: $payload');
      _navigateBasedOnData(payload);
    });
  }

  static bool _isCallTimestampFresh(int? timestamp) {
    if (timestamp == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age >= 0 && age <= _callRecoveryMaxAgeMs;
  }

  static Future<bool> _hasRecoverableAuthenticatedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedOut = prefs.getBool('adsyclub_logged_out') ?? false;
    final token = prefs.getString('adsyclub_token');
    return !loggedOut && token != null && token.isNotEmpty;
  }

  static Future<void> handleAuthenticationState(bool isAuthenticated) async {
    _callRecoveryEnabled = isAuthenticated;

    if (isAuthenticated) {
      await _tryNavigateToActiveCallkitCall();
      return;
    }

    await _clearPersistedIncomingCallState();
  }

  static Future<void> preflightCallStateCleanup() async {
    final hasSession = await _hasRecoverableAuthenticatedSession();

    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List || calls.isEmpty) {
        if (!hasSession) {
          await _clearPersistedIncomingCallState();
        }
        return;
      }

      bool shouldClear = !hasSession;

      for (final call in calls) {
        if (call is! Map) {
          shouldClear = true;
          continue;
        }

        final map = Map<String, dynamic>.from(call);
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
            shouldClear = true;
          }
        }

        final timestamp = _parseCallTimestamp(extra?['timestamp']);
        if (!_isCallTimestampFresh(timestamp)) {
          shouldClear = true;
        }
      }

      if (shouldClear) {
        _log('📞 Preflight cleanup removed stale persisted CallKit state');
        await _clearPersistedIncomingCallState();
      }
    } catch (e) {
      _log('⚠️ Preflight CallKit cleanup failed, forcing reset: $e');
      await _clearPersistedIncomingCallState();
    }
  }

  static Future<void> _clearPersistedIncomingCallState() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      _log('⚠️ Failed to end persisted CallKit calls: $e');
    }

    try {
      await cancelCallNotification();
    } catch (e) {
      _log('⚠️ Failed to cancel stale call notification: $e');
    }

    _activeCallIds.clear();
    _callTimestamps.clear();
    _acceptedCallkitUuids.clear();
    _pendingNavigationData = null;
  }

  static bool _registerIncomingCall({
    required String callerId,
    required String channelName,
    required String callType,
    int? timestamp,
    required String source,
  }) {
    if (AgoraCallService.isInCall || AgoraCallService.isCallScreenVisible) {
      _log('🚫 Ignoring $source incoming call - already in call or CallScreen visible');
      AgoraCallService.sendCallStatus(
        receiverId: callerId,
        channelName: channelName,
        status: 'busy',
        callType: callType,
      );
      return false;
    }

    if (timestamp != null) {
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTimestamp - timestamp;
      if (timeDifference > 30000) {
        _log('🚫 Ignoring old $source call (${timeDifference}ms old)');
        return false;
      }
    }

    final callId = _buildCallId(callerId, channelName);
    if (_activeCallIds.contains(callId)) {
      _log('🚫 Ignoring duplicate $source call: $callId');
      return false;
    }

    _activeCallIds.add(callId);
    _callTimestamps[callId] = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return true;
  }

  static void releaseIncomingCallTracking({
    required String callerId,
    required String channelName,
  }) {
    final callId = _buildCallId(callerId, channelName);
    _activeCallIds.remove(callId);
    _callTimestamps.remove(callId);
  }

  static Map<String, dynamic>? _parseCallkitExtra(dynamic rawExtra) {
    if (rawExtra == null) return null;
    if (rawExtra is Map<String, dynamic>) {
      return rawExtra;
    }
    if (rawExtra is Map) {
      return Map<String, dynamic>.from(rawExtra);
    }
    if (rawExtra is String && rawExtra.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawExtra);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

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

      await _ensureAndroidCallPermissions();

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

      _attachAdsyConnectRealtimeBridge();

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

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

  static Future<void> _ensureAndroidCallPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await FlutterCallkitIncoming.requestNotificationPermission({
        'title': 'Notification permission',
        'rationaleMessagePermission': 'Call notifications are required to show incoming calls.',
        'postNotificationMessageRequired': 'Please allow notifications so incoming calls can ring properly.',
      });
    } catch (e) {
      _log('⚠️ Failed to request CallKit notification permission: $e');
    }

    try {
      final canUseFullScreenIntent = await FlutterCallkitIncoming.canUseFullScreenIntent();
      if (canUseFullScreenIntent != true) {
        await FlutterCallkitIncoming.requestFullIntentPermission();
      }
    } catch (e) {
      _log('⚠️ Failed to request full-screen intent permission: $e');
    }
  }

  static Future<void> _tryNavigateToActiveCallkitCall() async {
    if (AgoraCallService.isCallScreenVisible) return;

    if (!_callRecoveryEnabled) {
      _log('📞 Skipping active CallKit recovery - authentication not ready');
      return;
    }

    if (!await _hasRecoverableAuthenticatedSession()) {
      _log('📞 No authenticated session found. Clearing persisted CallKit state.');
      await _clearPersistedIncomingCallState();
      return;
    }
    
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
      final timestamp = _parseCallTimestamp(extra?['timestamp']);
      if (callerId == null || channelName == null) {
      _log('📞 CallKit actionCallAccept missing callerId/channelName: callerId=$callerId channelName=$channelName');
      return;
    }

      if (!_isCallTimestampFresh(timestamp)) {
        _log('📞 Clearing stale CallKit recovery entry for channel=$channelName');
        if (callkitUuid.isNotEmpty) {
          await FlutterCallkitIncoming.endCall(callkitUuid);
        } else {
          await _clearPersistedIncomingCallState();
        }
        releaseIncomingCallTracking(callerId: callerId, channelName: channelName);
        return;
      }

      final callData = {
        // If call was accepted, use 'accepted_call' type to go directly to CallScreen
        'type': wasAccepted ? 'accepted_call' : 'incoming_call',
        'caller_id': callerId,
        'channel_name': channelName,
        'timestamp': timestamp,
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

    // High-priority channel for ride requests (heads-up, sound, vibration)
    const AndroidNotificationChannel rideChannel = AndroidNotificationChannel(
      'oxius_ride_requests', // id
      'Ride Requests', // name
      description: 'New ride request alerts for drivers',
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
    await androidPlugin?.createNotificationChannel(rideChannel);
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

    final callData = _extractCallDataFromCallEvent(event);
    if (callData == null) return;

    if (!_isCallTimestampFresh(_parseCallTimestamp(callData['timestamp']))) {
      _log('📞 Ignoring stale actionCallIncoming event');
      final callkitUuid = event.body['id']?.toString() ?? '';
      if (callkitUuid.isNotEmpty) {
        unawaited(FlutterCallkitIncoming.endCall(callkitUuid));
      } else {
        unawaited(_clearPersistedIncomingCallState());
      }
      return;
    }

    if (!_callRecoveryEnabled) {
      _log('📞 Skipping _cacheCallIncoming - call recovery not enabled yet');
      return;
    }

    _pendingNavigationData ??= callData;
  }

  static Map<String, dynamic>? _extractCallDataFromCallEvent(CallEvent event) {
    final extra = _parseCallkitExtra(event.body['extra']);
    if (extra == null) return null;

    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    if (callerId == null || channelName == null) return null;

    return {
      'type': 'incoming_call',
      'caller_id': callerId,
      'channel_name': channelName,
      'timestamp': _parseCallTimestamp(extra['timestamp']),
      'call_type': extra['call_type']?.toString() ?? 'video',
      'caller_name': extra['caller_name']?.toString() ?? 'Unknown',
      'caller_avatar': extra['caller_avatar']?.toString() ?? '',
    };
  }

  /// Handle call accepted from CallKit
  static Future<void> _handleCallAccepted(CallEvent event) async {
    _log('📞 CallKit actionCallAccept body: ${event.body}');

    final extra = _parseCallkitExtra(event.body['extra']);
    if (extra == null) {
      _log('📞 CallKit actionCallAccept missing/invalid extra: ${event.body['extra']}');
      return;
    }
    
    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    final callType = extra['call_type']?.toString() ?? 'video';
    final callerName = extra['caller_name']?.toString() ?? 'Unknown';
    final callerAvatar = extra['caller_avatar']?.toString();
    final callkitUuid = event.body['id']?.toString() ?? '';
    final timestamp = _parseCallTimestamp(extra['timestamp']);
    
    if (callerId == null || channelName == null) return;

    if (!_isCallTimestampFresh(timestamp) || !await _hasRecoverableAuthenticatedSession()) {
      _log('📞 Ignoring accepted CallKit event for stale/unauthenticated call');
      releaseIncomingCallTracking(callerId: callerId, channelName: channelName);
      if (callkitUuid.isNotEmpty) {
        await FlutterCallkitIncoming.endCall(callkitUuid);
      }
      await _clearPersistedIncomingCallState();
      return;
    }
    
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
      'timestamp': timestamp,
      'call_type': callType,
      'caller_name': callerName,
      'caller_avatar': callerAvatar ?? '',
    };
    
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      _log('📞 Navigating to CallScreen immediately (accepted_call)');
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
    final extra = _parseCallkitExtra(event.body['extra']);
    if (extra == null) return;
    
    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    final callType = extra['call_type']?.toString() ?? 'video';
    
    if (callerId == null || channelName == null) return;

    releaseIncomingCallTracking(callerId: callerId, channelName: channelName);
    
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
    
    final extra = _parseCallkitExtra(event.body['extra']);
    if (extra != null) {
      final callerId = extra['caller_id']?.toString();
      final channelName = extra['channel_name']?.toString();
      final callType = extra['call_type']?.toString() ?? 'video';
      
      if (callerId != null && channelName != null) {
        releaseIncomingCallTracking(callerId: callerId, channelName: channelName);
        
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
    final extra = _parseCallkitExtra(event.body['extra']);
    if (extra == null) return;
    
    final callerId = extra['caller_id']?.toString();
    final channelName = extra['channel_name']?.toString();
    final callType = extra['call_type']?.toString() ?? 'video';
    
    if (callerId == null || channelName == null) return;

    releaseIncomingCallTracking(callerId: callerId, channelName: channelName);
    
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
    if (!_registerIncomingCall(
      callerId: callerId,
      channelName: channelName,
      callType: callType,
      timestamp: timestamp,
      source: 'CallKit',
    )) {
      return;
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
        'timestamp': (timestamp ?? DateTime.now().millisecondsSinceEpoch).toString(),
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

  static void _navigateToIncomingCallScreen(NavigatorState navigator, Map<String, dynamic> data) {
    final channelName = data['channel_name']?.toString();
    final callerId = data['caller_id']?.toString();
    final callerName = data['caller_name']?.toString() ?? 'Unknown';
    final callerAvatar = data['caller_avatar']?.toString();
    final callType = data['call_type']?.toString() ?? 'video';
    final timestamp = int.tryParse(data['timestamp']?.toString() ?? '');

    if (channelName == null || callerId == null) {
      _log('⚠️ Cannot navigate to incoming call screen: missing channelName or callerId');
      return;
    }

    if (!_registerIncomingCall(
      callerId: callerId,
      channelName: channelName,
      callType: callType,
      timestamp: timestamp,
      source: 'foreground',
    )) {
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          calleeId: callerId,
          calleeName: callerName,
          calleeAvatar: callerAvatar,
          isIncoming: true,
          callType: callType,
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
      final payload = Map<String, dynamic>.from(message.data);
      if (_shouldProcessCallSignal(payload)) {
        _navigateBasedOnData(payload);
      }
      return;
    }

    // Ride request for driver: show high-priority heads-up notification
    if (_isRideshareRideRequestNotification(type)) {
      _showRideRequestNotification(message.data);
      return;
    }

    // Show local notification
    _showLocalNotification(message);
  }

  /// Show high-priority ride request notification for drivers
  static Future<void> _showRideRequestNotification(Map<String, dynamic> data) async {
    final rideId = data['ride_id']?.toString() ?? '';
    final pickup = data['pickup_address']?.toString() ?? 'Pickup';
    final drop = data['drop_address']?.toString() ?? 'Drop';
    final fare = data['fare_estimate']?.toString() ?? '';
    final timeoutSec = int.tryParse(data['timeout_seconds']?.toString() ?? '') ?? 60;

    final title = '🚗 New Ride Request!';
    final body = '${pickup.length > 35 ? '${pickup.substring(0, 35)}…' : pickup} → ${drop.length > 35 ? '${drop.substring(0, 35)}…' : drop}${fare.isNotEmpty ? ' · ৳$fare' : ''} · ${timeoutSec}s';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'oxius_ride_requests',
      'Ride Requests',
      channelDescription: 'New ride request alerts for drivers',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
      timeoutAfter: timeoutSec * 1000,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Tap to view the request',
      ),
    );

    await _localNotifications.show(
      rideId.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        ...data,
        'type': data['type']?.toString() ?? 'targeted_ride_request',
      }),
    );
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
    // RIDESHARE NOTIFICATIONS
    // ============================================
    if (_isRideshareNotification(
      data,
      type: type,
      notificationType: notificationType,
    )) {
      final mode = _resolveRideshareMode(
        data,
        type: type,
        notificationType: notificationType,
      );
      final rideId = data['ride_id']?.toString();
      final payload = {
        'mode': mode,
        if (rideId != null && rideId.isNotEmpty) 'ride_id': rideId,
        if (type != null && type.isNotEmpty) 'type': type,
        if (notificationType != null && notificationType.isNotEmpty)
          'notification_type': notificationType,
      };

      _log('   → Navigating to rideshare ($mode) for ride: $rideId');
      _emitRideshareNotificationEvent(payload);

      if (currentRouteName == '/rideshare') {
        _log('   → Rideshare screen already open, refreshing in place');
        return;
      }

      navigator.pushNamed(
        '/rideshare',
        arguments: payload,
      );
      return;
    }

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
        if (_isAppInForeground) {
          _navigateToIncomingCallScreen(navigator, data);
        } else {
          showIncomingCall(
            callerId: callerId,
            callerName: callerName,
            callerAvatar: callerAvatar,
            channelName: channelName,
            callType: callType,
            timestamp: int.tryParse(data['timestamp']?.toString() ?? ''),
          );
        }
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
