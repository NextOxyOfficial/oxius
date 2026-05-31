import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'telemetry.dart';
import 'package:flutter/foundation.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint('🎤 AgoraCallService: $message');
  }
}

class AgoraCallService {
  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '9eba1a50633041d08dbe75b0fde2ed8a',
  );
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Duration _restorableCallAge = Duration(hours: 8);
  static const String _prefsInCallKey = 'adsyconnect_active_call_in_call';
  static const String _prefsCallInfoKey = 'adsyconnect_active_call_info';
  static const String _prefsUpdatedAtKey = 'adsyconnect_active_call_updated_at';

  static RtcEngine? _engine;
  static bool _isInCall = false;
  static bool _isCallScreenVisible = false;
  static String? _joinedChannelName;
  static int? _joinedUid;
  static String? _joinedToken;
  static String? _lastError;
  static String? get lastError => _lastError;
  static String? _lastNotificationError;
  static String? get lastNotificationError => _lastNotificationError;
  static bool get isCallScreenVisible => _isCallScreenVisible;
  static RtcEngine? get engine => _engine;

  static void setCallScreenVisible(bool value) {
    final changed = _isCallScreenVisible != value;
    _isCallScreenVisible = value;
    // Notify OngoingCallBar so it shows/hides when the CallScreen appears/disappears.
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

  static void setInCall(bool value) {
    _isInCall = value;
    if (!value) {
      _joinedChannelName = null;
      _joinedUid = null;
      _joinedToken = null;
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
      _joinedChannelName = channelName;
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

    await leaveChannel();
    setInCall(false);
  }

  static Future<RtcEngine> initEngine({required String callType}) async {
    final wantsVideo = callType == 'video';

    await _ensurePermissions(callType: callType);

    _lastError = null;

    if (_engine == null) {
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      // Enable audio - wrap in try-catch so initialization continues even if this fails
      try {
        await engine.enableAudio();
      } catch (e) {
        _log('⚠️ Warning: enableAudio failed: $e');
      }

      // Set client role - wrap in try-catch so initialization continues
      try {
        await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      } catch (e) {
        _log('⚠️ Warning: setClientRole failed: $e');
      }

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, _) {
            Telemetry.event('agora.joined', tags: {
              'channel': connection.channelId,
              'local_uid': connection.localUid,
            });
            try {
              final localUid = connection.localUid;
              if (localUid != null) {
                _localUserJoinedController.add(localUid);
              }
            } catch (_) {}
          },
          onUserJoined: (_, remoteUid, __) {
            Telemetry.event('agora.remote_joined',
                tags: {'remote_uid': remoteUid});
            _ensureActiveInfo();
            _activeCallInfo!['remoteUid'] = remoteUid;
            _schedulePersistedCallStateSync();
            markCallAccepted();
            try {
              _remoteUserJoinedController.add(remoteUid);
            } catch (_) {}
          },
          onUserOffline: (_, remoteUid, __) {
            // Only treat as "remote left" if this uid was actually our known peer.
            // Agora can fire onUserOffline for transient internal uids — ignoring
            // unknown uids prevents the call from ending before the peer even joined.
            final knownRemote = _activeCallInfo?['remoteUid'];
            if (knownRemote == null || knownRemote != remoteUid) {
              _log(
                  'ℹ️ Ignoring onUserOffline for unknown uid $remoteUid (known: $knownRemote)');
              return;
            }
            Telemetry.event('agora.remote_left',
                tags: {'remote_uid': remoteUid});
            _activeCallInfo!['remoteUid'] = null;
            _schedulePersistedCallStateSync();
            try {
              _remoteUserLeftController.add(remoteUid);
            } catch (_) {}
          },
          onConnectionStateChanged: (_, state, reason) {
            _log('🔗 Connection state: $state, reason: $reason');
            Telemetry.event('agora.connection_state', tags: {
              'state': state.toString().split('.').last,
              'reason': reason.toString().split('.').last,
            });
            if (state == ConnectionStateType.connectionStateFailed ||
                state == ConnectionStateType.connectionStateDisconnected) {
              _lastError = 'Connection lost. Please try again.';
              try {
                _engineErrorController.add(_lastError!);
              } catch (_) {}
            }
          },
          onTokenPrivilegeWillExpire: (connection, _) {
            final channelName = connection.channelId;
            final uid = connection.localUid ?? _joinedUid;
            if (channelName != null && uid != null) {
              unawaited(_renewAgoraToken(channelName: channelName, uid: uid));
            }
          },
          onError: (error, message) {
            _lastError = _friendlyAgoraError(error, message);
            Telemetry.event('agora.error',
                tags: {
                  'code': error.toString().split('.').last,
                  'message': message,
                },
                severity: TelemetrySeverity.error);
            try {
              _engineErrorController.add(_lastError!);
            } catch (_) {}
          },
        ),
      );
      _engine = engine;
    }

    await _runOptionalSetup(() => _configureVideoState(wantsVideo: wantsVideo));
    await _runOptionalSetup(() => toggleSpeaker(wantsVideo));
    return _engine!;
  }

  static String generateChannelName(String callerId, String calleeId) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(1 << 32).toRadixString(36);
    final pair = '$callerId|$calleeId';
    final pairHash = pair.hashCode.abs().toRadixString(36);
    return 'c_${pairHash}_$ts$rnd';
  }

  static Future<bool> joinChannel({
    required String channelName,
    required int uid,
    required String callType,
  }) async {
    try {
      _lastError = null;
      if (appId.trim().isEmpty) {
        throw StateError('missing_agora_app_id');
      }
      final channelNameOk = channelName.isNotEmpty &&
          channelName.length <= 64 &&
          RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(channelName);
      if (!channelNameOk) {
        throw ArgumentError('Invalid channel name');
      }

      final wantsVideo = callType == 'video';
      final engine = await initEngine(callType: callType);

      _log(
          '📱 Attempting to join channel: $channelName (uid: $uid, video: $wantsVideo)');

      if (_joinedChannelName != null && _joinedChannelName != channelName) {
        await engine.leaveChannel();
      }

      final agoraToken = await _fetchAgoraToken(
        channelName: channelName,
        uid: uid,
      );

      await engine.joinChannel(
        token: agoraToken,
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          autoSubscribeVideo: wantsVideo,
          autoSubscribeAudio: true,
          publishCameraTrack: wantsVideo,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _joinedChannelName = channelName;
      _joinedUid = uid;
      _joinedToken = agoraToken;
      _log('✅ Successfully joined channel: $channelName');
      return true;
    } catch (error) {
      _log('❌ Join channel failed for $channelName: $error');
      // Always store a user-friendly message — never expose raw SDK exceptions.
      final raw = error.toString().toLowerCase();
      if (raw.contains('permission')) {
        _lastError = 'Microphone permission is required to make calls.';
      } else if (raw.contains('invalid') && raw.contains('channel')) {
        _lastError = 'Invalid call session. Please try again.';
      } else if (raw.contains('token')) {
        _lastError = 'Call session expired. Please try again.';
      } else if (raw.contains('missing_agora_app_id')) {
        _lastError = 'Call service is not configured yet.';
      } else {
        _lastError = 'Could not join the call. Please try again.';
      }
      return false;
    }
  }

  static Future<void> leaveChannel() async {
    // Leave the channel first, then release the engine so the next call always
    // starts with a fresh Agora instance and correct audio routing.
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {
      // Ignore leave/release failures.
    } finally {
      _engine = null;
      _joinedChannelName = null;
      _joinedUid = null;
      _joinedToken = null;
      if (_activeCallInfo != null) {
        _activeCallInfo!['remoteUid'] = null;
        _schedulePersistedCallStateSync();
      }
    }
  }

  static Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  static Future<void> toggleCamera(bool enabled) async {
    await _engine?.enableLocalVideo(enabled);
  }

  static Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  static Future<void> toggleSpeaker(bool speakerOn) async {
    await _engine?.setEnableSpeakerphone(speakerOn);
  }

  static Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {
      // Ignore engine disposal failures.
    } finally {
      _engine = null;
      _joinedChannelName = null;
      _joinedUid = null;
      _joinedToken = null;
      _activeCallInfo = null;
      _isInCall = false;
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

  static Future<String> _fetchAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/adsyconnect/agora-token/'),
            headers: headers,
            body: json.encode({
              'channel_name': channelName,
              'uid': uid,
              'role': 'publisher',
              'call_id': _activeCallInfo?['callId'],
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 404) {
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.toLowerCase().contains('application/json')) {
          return '';
        }
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _lastError = _friendlyHttpError(response);
        throw StateError('agora_token_request_failed:${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('invalid_agora_token_response');
      }

      final tokenRequired = decoded['token_required'] == true ||
          decoded['token_required']?.toString().toLowerCase() == 'true';
      final tokenAppId = decoded['app_id']?.toString().trim();
      if (tokenAppId != null && tokenAppId.isNotEmpty && tokenAppId != appId) {
        _lastError =
            'Call configuration mismatch. Please update the app and try again.';
        throw StateError('agora_app_id_mismatch');
      }
      final token = decoded['token']?.toString() ?? '';
      if (tokenRequired && token.isEmpty) {
        throw StateError('empty_agora_token');
      }

      return token;
    } on TimeoutException {
      _lastError = 'Call token request timed out. Please try again.';
      rethrow;
    }
  }

  static Future<void> _renewAgoraToken({
    required String channelName,
    required int uid,
  }) async {
    try {
      final token = await _fetchAgoraToken(channelName: channelName, uid: uid);
      if (token.isEmpty || token == _joinedToken) {
        return;
      }
      await _engine?.renewToken(token);
      _joinedToken = token;
    } catch (error) {
      _lastError = 'Call session expired. Please reconnect.';
      try {
        _engineErrorController.add(_lastError!);
      } catch (_) {}
    }
  }

  static int generateUid() {
    // Use the full positive 31-bit range so two independently-generated UIDs in
    // the same channel practically never collide. A collision would make Agora
    // kick the first joiner when the second joins with the same UID, which looks
    // exactly like "the other party can't connect". 1..2147483646 is always a
    // valid Agora UID (0 is reserved for "let the SDK assign one").
    return Random().nextInt(2147483646) + 1;
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

  static Future<void> _ensurePermissions({required String callType}) async {
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

  static Future<void> _configureVideoState({required bool wantsVideo}) async {
    if (_engine == null) {
      return;
    }

    if (wantsVideo) {
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 0,
        ),
      );
    } else {
      await _engine!.disableVideo();
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

  static Future<void> _runOptionalSetup(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Ignore non-essential device-specific setup failures.
    }
  }

  static void _emitCallState() {
    try {
      _callStateController.add(_isInCall);
    } catch (_) {
      // Ignore stream delivery issues.
    }
  }

  static String _friendlyAgoraError(ErrorCodeType error, String message) {
    switch (error) {
      case ErrorCodeType.errNotInitialized:
        return 'Call service not ready. Please try again.';
      case ErrorCodeType.errInvalidToken:
      case ErrorCodeType.errTokenExpired:
        return 'Call session expired. Please try again.';
      case ErrorCodeType.errConnectionLost:
      case ErrorCodeType.errConnectionInterrupted:
        return 'Network connection lost during the call.';
      case ErrorCodeType.errInvalidChannelName:
        return 'Invalid call session. Please try again.';
      default:
        return 'Unable to continue the call right now.';
    }
  }

  static String _friendlyHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return 'Invalid call request. Please try again.';
      case 401:
      case 403:
        return 'Your session expired. Please sign in again.';
      case 404:
        return 'Recipient is unavailable right now.';
      case 409:
        return 'Recipient is already on another call.';
      default:
        if (response.statusCode >= 500) {
          return 'Call service is unavailable right now. Please try again.';
        }

        final body = response.body.trim();
        if (body.isEmpty || body.length > 160 || body.startsWith('<!DOCTYPE')) {
          return 'Unable to complete the call request right now.';
        }
        return body;
    }
  }
}
