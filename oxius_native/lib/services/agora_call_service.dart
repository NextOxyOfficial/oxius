import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'call_foreground_service.dart';
import 'livekit_call_service.dart';
import 'package:flutter/foundation.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint('🎤 AgoraCallService: $message');
  }
}

class AgoraCallService {
  /// True while rejoinChannel() is deliberately leaving and re-entering the
  /// channel. Engine events during that window describe our own teardown, not
  /// a broken call, and must not reach the error stream.

  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Duration _restorableCallAge = Duration(hours: 8);
  static const String _prefsInCallKey = 'adsyconnect_active_call_in_call';
  static const String _prefsCallInfoKey = 'adsyconnect_active_call_info';
  static const String _prefsUpdatedAtKey = 'adsyconnect_active_call_updated_at';

  static bool _isInCall = false;
  static bool _isCallScreenVisible = false;
  static String? _lastError;
  static String? get lastError => _lastError;
  static String? _lastNotificationError;
  static String? get lastNotificationError => _lastNotificationError;
  static bool get isCallScreenVisible => _isCallScreenVisible;

  static void setCallScreenVisible(bool value) {
    final changed = _isCallScreenVisible != value;
    _isCallScreenVisible = value;
    // Notify the call bubble so it shows/hides as the CallScreen appears and goes.
    if (changed) _emitCallState();
  }

  static Map<String, dynamic>? _activeCallInfo;
  static Map<String, dynamic>? get activeCallInfo => _activeCallInfo == null
      ? null
      : Map<String, dynamic>.from(_activeCallInfo!);
  static bool get activeCallAccepted => _activeCallInfo?['accepted'] == true;
  static int? get activeCallConnectedAtMs {
    return _toInt(_activeCallInfo?['connectedAt']);
  }

  static final StreamController<bool> _callStateController =
      StreamController<bool>.broadcast();
  static Stream<bool> get callStateStream => _callStateController.stream;

  static final StreamController<Map<String, dynamic>> _callStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get callStatusStream =>
      _callStatusController.stream;

  static final StreamController<int> _localUserJoinedController =
      StreamController<int>.broadcast();
  static final StreamController<int> _remoteUserJoinedController =
      StreamController<int>.broadcast();
  static final StreamController<int> _remoteUserLeftController =
      StreamController<int>.broadcast();
  static final StreamController<String> _engineErrorController =
      StreamController<String>.broadcast();

  static Stream<int> get localUserJoinedStream =>
      _localUserJoinedController.stream;
  static Stream<int> get remoteUserJoinedStream =>
      _remoteUserJoinedController.stream;
  static Stream<int> get remoteUserLeftStream =>
      _remoteUserLeftController.stream;
  static Stream<String> get engineErrorStream => _engineErrorController.stream;

  static bool get isInCall => _isInCall;

  /// True only for a call this process is actually running. Restored state
  /// (see [restorePersistedCallState]) rebuilds the ongoing-call bar from
  /// disk after the app was killed, and that call's media is long gone — it
  /// must not raise a foreground service for a call nobody is on.
  static bool _callLiveInProcess = false;

  /// Ends the running call from outside the call screen — today, the "End call"
  /// action on the ongoing-call notification.
  ///
  /// The screen may not be mounted at all (the call was minimised, or the user
  /// is in another app entirely), so this does the whole teardown itself
  /// rather than asking the UI to: leave the room, tell the other side, drop
  /// the call state. The screen, if it is up, closes on the state change.
  static Future<void> hangUpActiveCall() async {
    final info = _activeCallInfo;
    if (!_isInCall && info == null) return;

    try {
      await LiveKitCallService.leaveChannel();
    } catch (_) {
      // The room is going away regardless.
    }

    final peerId = info?['peerId']?.toString();
    final channelName = info?['channelName']?.toString();
    if (peerId != null &&
        peerId.isNotEmpty &&
        channelName != null &&
        channelName.isNotEmpty) {
      unawaited(sendCallStatus(
        receiverId: peerId,
        channelName: channelName,
        status: 'ended',
        callType: info?['callType']?.toString() ?? 'audio',
        callId: info?['callId']?.toString(),
      ));
    }

    setInCall(false);
  }

  static void setInCall(bool value) {
    _isInCall = value;
    _callLiveInProcess = value;
    if (!value) {
      _activeCallInfo = null;
    }
    _schedulePersistedCallStateSync();
    _emitCallState();
  }

  static void setActiveCallInfo({
    required String channelName,
    required String peerId,
    required String peerName,
    String? peerAvatar,
    required String callType,
    required bool isIncoming,
    String? callId,
  }) {
    _activeCallInfo = {
      'callId': callId ?? _activeCallInfo?['callId'],
      'channelName': channelName,
      'peerId': peerId,
      'peerName': peerName,
      'peerAvatar': peerAvatar,
      'callType': callType,
      'isIncoming': isIncoming,
      'accepted': _activeCallInfo?['accepted'] == true,
      'connectedAt': _activeCallInfo?['connectedAt'],
      'remoteUid': _activeCallInfo?['remoteUid'],
    };
    _schedulePersistedCallStateSync();
    _emitCallState();
  }

  static void markCallAccepted() {
    _ensureActiveInfo();
    _activeCallInfo!['accepted'] = true;
    _schedulePersistedCallStateSync();
    _emitCallState();
  }

  static void markCallConnected([DateTime? connectedAt]) {
    _ensureActiveInfo();
    _activeCallInfo!['accepted'] = true;
    _activeCallInfo!['connectedAt'] =
        (connectedAt ?? DateTime.now()).millisecondsSinceEpoch;
    _schedulePersistedCallStateSync();
    _emitCallState();
  }

  static Future<void> restorePersistedCallState() async {
    if (_isInCall && _activeCallInfo != null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final inCall = prefs.getBool(_prefsInCallKey) ?? false;
      final rawInfo = prefs.getString(_prefsCallInfoKey);
      final updatedAt = prefs.getInt(_prefsUpdatedAtKey);

      if (!inCall || rawInfo == null || rawInfo.isEmpty || updatedAt == null) {
        await clearPersistedCallState();
        return;
      }

      final ageMs = DateTime.now().millisecondsSinceEpoch - updatedAt;
      if (ageMs < 0 || ageMs > _restorableCallAge.inMilliseconds) {
        await clearPersistedCallState();
        return;
      }

      final decoded = jsonDecode(rawInfo);
      if (decoded is! Map) {
        await clearPersistedCallState();
        return;
      }

      final info = Map<String, dynamic>.from(decoded);
      final channelName = info['channelName']?.toString().trim();
      final peerId = info['peerId']?.toString().trim();
      if (channelName == null ||
          channelName.isEmpty ||
          peerId == null ||
          peerId.isEmpty) {
        await clearPersistedCallState();
        return;
      }

      _isInCall = true;
      _isCallScreenVisible = false;
      _activeCallInfo = info;
      _emitCallState();
    } catch (error) {
      _log('⚠️ Failed to restore persisted call state: $error');
      await clearPersistedCallState();
    }
  }

  static Future<void> clearPersistedCallState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsInCallKey);
      await prefs.remove(_prefsCallInfoKey);
      await prefs.remove(_prefsUpdatedAtKey);
    } catch (error) {
      _log('⚠️ Failed to clear persisted call state: $error');
    }
  }

  static void emitCallStatus(Map<String, dynamic> data) {
    try {
      _callStatusController.add(Map<String, dynamic>.from(data));
    } catch (_) {
      // Ignore stream delivery issues.
    }
  }

  static Future<void> handleRemoteCallStatus(Map<String, dynamic> data) async {
    emitCallStatus(data);

    final channelName = data['channel_name']?.toString();
    final status = data['status']?.toString().toLowerCase();
    final callId = data['call_id']?.toString();
    final activeChannelName = _activeCallInfo?['channelName']?.toString();

    if (status == null ||
        channelName == null ||
        activeChannelName != channelName) {
      return;
    }

    if (callId != null && callId.isNotEmpty) {
      _ensureActiveInfo();
      _activeCallInfo!['callId'] = callId;
      _schedulePersistedCallStateSync();
    }

    if (status == 'accepted') {
      markCallAccepted();
      return;
    }

    const terminalStatuses = {
      'rejected',
      'declined',
      'busy',
      'cancelled',
      'ended',
      'missed',
      'failed',
    };

    if (!terminalStatuses.contains(status)) {
      return;
    }

    if (_isCallScreenVisible) {
      return;
    }

    // Media teardown belongs to the engine that owns it.
    await LiveKitCallService.leaveChannel();
    setInCall(false);
  }

  static String generateChannelName(String callerId, String calleeId) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(1 << 32).toRadixString(36);
    final pair = '$callerId|$calleeId';
    final pairHash = pair.hashCode.abs().toRadixString(36);
    return 'c_${pairHash}_$ts$rnd';
  }

  static Future<void> dispose() async {
    try {
      await LiveKitCallService.leaveChannel();
    } catch (_) {
      // Ignore teardown failures.
    } finally {
      _activeCallInfo = null;
      _isInCall = false;
      _callLiveInProcess = false;
      unawaited(clearPersistedCallState());
      _emitCallState();
    }
  }

  static Future<bool> sendCallNotification({
    required String calleeId,
    required String channelName,
    required String callType,
  }) async {
    try {
      _lastNotificationError = null;
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        _lastNotificationError = 'Your session expired. Please sign in again.';
        return false;
      }

      final headers = await ApiService.getHeaders();
      // A fresh call starts optimistic — the previous call's verdict must
      // not paint this one's UI.
      lastCallReachable = true;
      lastRingChannel = '';
      final callerName = [currentUser.firstName, currentUser.lastName]
          .where((value) => value != null && value.isNotEmpty)
          .join(' ');
      final fallbackName = currentUser.username.contains('@')
          ? currentUser.username.split('@').first
          : currentUser.username;

      final response = await http
          .post(
            Uri.parse(
                '${ApiService.baseUrl}/adsyconnect/send-call-notification/'),
            headers: headers,
            body: json.encode({
              'callee_id': calleeId,
              'channel_name': channelName,
              'call_type': callType,
              'call_id': _activeCallInfo?['callId'],
              'caller_name': callerName.isNotEmpty ? callerName : fallbackName,
              'caller_avatar': currentUser.profilePicture,
            }),
          )
          .timeout(_requestTimeout);

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        _lastNotificationError = _friendlyHttpError(response);
        return false;
      }

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final callId = decoded['call_id']?.toString();
        if (callId != null && callId.isNotEmpty) {
          _ensureActiveInfo();
          _activeCallInfo!['callId'] = callId;
          _schedulePersistedCallStateSync();
          _emitCallState();
        }
        // The server says whether the ring had anywhere to go. A callee with
        // no delivery route (no push token registered on any device) can
        // never see this call, and playing a ringback at the caller for
        // thirty seconds only teaches them the app is broken.
        lastCallReachable = decoded['reachable'] != false;
        lastRingChannel = decoded['ring_channel']?.toString() ?? '';
      }
      return ok;
    } on TimeoutException {
      _lastNotificationError = 'Call request timed out. Please try again.';
      return false;
    } catch (error) {
      _lastNotificationError = error.toString();
      return false;
    }
  }

  /// False when the last outgoing call could not be delivered to any of the
  /// callee's devices — the call screen shows this instead of ringing on.
  static bool lastCallReachable = true;

  /// How the last call was rung: 'voip' (CallKit), 'push' (alert only) or
  /// 'none'. Useful when a call is reported as never arriving.
  static String lastRingChannel = '';

  /// Tell the server that Agora media actually started flowing.
  ///
  /// Fire-and-forget diagnostics: without it, "accepted but never connected"
  /// and "connected then hung up" are indistinguishable in the server log,
  /// which is exactly the ambiguity that made this class of bug so slow to
  /// find. Never blocks or surfaces anything to the user.
  static Future<void> reportMediaConnected({
    required String channelName,
    String? callId,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      await http
          .post(
            Uri.parse(
                '${ApiService.baseUrl}/adsyconnect/call-media-connected/'),
            headers: headers,
            body: json.encode({
              'channel_name': channelName,
              'call_id': callId ?? _activeCallInfo?['callId'],
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Diagnostics must never affect a live call.
    }
  }

  static Future<bool> sendCallStatus({
    required String receiverId,
    required String channelName,
    required String status,
    required String callType,
    String? callId,
  }) async {
    try {
      _lastNotificationError = null;
      final headers = await ApiService.getHeaders();

      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/adsyconnect/send-call-status/'),
            headers: headers,
            body: json.encode({
              'receiver_id': receiverId,
              'channel_name': channelName,
              'status': status,
              'call_type': callType,
              'call_id': callId ?? _activeCallInfo?['callId'],
            }),
          )
          .timeout(_requestTimeout);

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        _lastNotificationError = _friendlyHttpError(response);
      }
      return ok;
    } on TimeoutException {
      _lastNotificationError =
          'Call status update timed out. Please try again.';
      return false;
    } catch (error) {
      _lastNotificationError = error.toString();
      return false;
    }
  }

  /// iOS only: proactively request microphone and camera so the app appears
  /// under Settings > Privacy & Security > Microphone / Camera on first launch,
  /// even before the user makes their first call.  On Android this is a no-op
  /// because runtime permissions are requested at call time (no pre-declaration
  /// needed for these permissions to appear in Settings on Android).
  /// Call this once from main.dart after FCMService.initialize().
  static Future<void> preRegisterIOSPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      await Permission.microphone.request();
    }
    final camStatus = await Permission.camera.status;
    if (!camStatus.isGranted) {
      await Permission.camera.request();
    }
  }

  static Future<void> ensurePermissions({required String callType}) async {
    // Check status first to avoid showing a redundant in-app prompt when the
    // OS already remembers the user's decision (especially on iOS where the
    // system dialog is one-shot and subsequent .request() returns the cached
    // status without showing UI — which previously looked like a "fake popup").
    PermissionStatus micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted && !micStatus.isPermanentlyDenied) {
      micStatus = await Permission.microphone.request();
    }
    if (micStatus.isPermanentlyDenied) {
      throw StateError('permission_permanently_denied:microphone');
    }
    if (!micStatus.isGranted) {
      throw StateError('permission_denied:microphone');
    }

    if (callType == 'video') {
      PermissionStatus camStatus = await Permission.camera.status;
      if (!camStatus.isGranted && !camStatus.isPermanentlyDenied) {
        camStatus = await Permission.camera.request();
      }
      if (camStatus.isPermanentlyDenied) {
        throw StateError('permission_permanently_denied:camera');
      }
      if (!camStatus.isGranted) {
        throw StateError('permission_denied:camera');
      }
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static void _ensureActiveInfo() {
    _activeCallInfo ??= <String, dynamic>{};
  }

  static void _schedulePersistedCallStateSync() {
    unawaited(_persistCallState());
  }

  static Future<void> _persistCallState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!_isInCall || _activeCallInfo == null) {
        await clearPersistedCallState();
        return;
      }

      await prefs.setBool(_prefsInCallKey, true);
      await prefs.setString(_prefsCallInfoKey, jsonEncode(_activeCallInfo));
      await prefs.setInt(
        _prefsUpdatedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (error) {
      _log('⚠️ Failed to persist call state: $error');
    }
  }

  static void _emitCallState() {
    // Every path that changes call state ends up here, which makes it the one
    // place that can keep the Android foreground service honest — without it
    // the microphone is cut the moment the app leaves the screen.
    unawaited(CallForegroundService.sync(
      inCall: _isInCall && _callLiveInProcess,
      info: _activeCallInfo,
    ));
    try {
      _callStateController.add(_isInCall);
    } catch (_) {
      // Ignore stream delivery issues.
    }
  }

  static String _friendlyHttpError(http.Response response) {
    // The server explains a refusal in words meant for this user — blocked,
    // privacy-restricted, ringing too often. Its own sentence beats anything
    // guessed from a status code, and a 403 in particular is no longer only
    // ever an expired session.
    final serverMessage = _serverErrorMessage(response.body);
    if (serverMessage != null) return serverMessage;

    switch (response.statusCode) {
      case 400:
        return 'Invalid call request. Please try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'This user cannot be called right now.';
      case 404:
        return 'User is unavailable right now.';
      case 409:
        return 'User is already on another call.';
      case 429:
        return 'Too many attempts. Please try again in a moment.';
      default:
        if (response.statusCode >= 500) {
          return 'The call service is unavailable. Please try again shortly.';
        }
        return 'The call request could not be completed.';
    }
  }

  /// The backend's own `error` / `detail` string, when it sent one that is
  /// safe to show. Anything HTML-shaped, empty or overlong is a stack trace or
  /// a proxy page, not a message for a user.
  static String? _serverErrorMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('{')) return null;
    try {
      final decoded = json.decode(trimmed);
      if (decoded is! Map) return null;
      final raw = decoded['error'] ?? decoded['detail'];
      if (raw is! String) return null;
      final message = raw.trim();
      if (message.isEmpty || message.length > 160) return null;
      return message;
    } catch (_) {
      return null;
    }
  }
}
