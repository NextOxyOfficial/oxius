import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';
import 'auth_service.dart';

class AgoraCallService {
  static const String appId = '9eba1a50633041d08dbe75b0fde2ed8a';
  static const Duration _requestTimeout = Duration(seconds: 10);

  static RtcEngine? _engine;
  static bool _isInCall = false;
  static bool _isCallScreenVisible = false;
  static String? _joinedChannelName;
  static String? _lastError;
  static String? get lastError => _lastError;
  static String? _lastNotificationError;
  static String? get lastNotificationError => _lastNotificationError;
  static bool get isCallScreenVisible => _isCallScreenVisible;
  static RtcEngine? get engine => _engine;

  static void setCallScreenVisible(bool value) {
    _isCallScreenVisible = value;
  }

  static Map<String, dynamic>? _activeCallInfo;
  static Map<String, dynamic>? get activeCallInfo =>
      _activeCallInfo == null ? null : Map<String, dynamic>.from(_activeCallInfo!);
  static bool get activeCallAccepted => _activeCallInfo?['accepted'] == true;
  static int? get activeCallConnectedAtMs {
    return _toInt(_activeCallInfo?['connectedAt']);
  }

  static final StreamController<bool> _callStateController =
      StreamController<bool>.broadcast();
  static Stream<bool> get callStateStream => _callStateController.stream;

  static final StreamController<Map<String, dynamic>> _callStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get callStatusStream => _callStatusController.stream;

  static final StreamController<int> _localUserJoinedController =
      StreamController<int>.broadcast();
  static final StreamController<int> _remoteUserJoinedController =
      StreamController<int>.broadcast();
  static final StreamController<int> _remoteUserLeftController =
      StreamController<int>.broadcast();
  static final StreamController<String> _engineErrorController =
      StreamController<String>.broadcast();

  static Stream<int> get localUserJoinedStream => _localUserJoinedController.stream;
  static Stream<int> get remoteUserJoinedStream => _remoteUserJoinedController.stream;
  static Stream<int> get remoteUserLeftStream => _remoteUserLeftController.stream;
  static Stream<String> get engineErrorStream => _engineErrorController.stream;

  static bool get isInCall => _isInCall;

  static void setInCall(bool value) {
    _isInCall = value;
    if (!value) {
      _joinedChannelName = null;
      _activeCallInfo = null;
    }
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
    _emitCallState();
  }

  static void markCallAccepted() {
    _ensureActiveInfo();
    _activeCallInfo!['accepted'] = true;
    _emitCallState();
  }

  static void markCallConnected([DateTime? connectedAt]) {
    _ensureActiveInfo();
    _activeCallInfo!['accepted'] = true;
    _activeCallInfo!['connectedAt'] =
        (connectedAt ?? DateTime.now()).millisecondsSinceEpoch;
    _emitCallState();
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

    if (status == null || channelName == null || activeChannelName != channelName) {
      return;
    }

    if (callId != null && callId.isNotEmpty) {
      _ensureActiveInfo();
      _activeCallInfo!['callId'] = callId;
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
      await engine.enableAudio();
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, _) {
            try {
              final localUid = connection.localUid;
              if (localUid != null) {
                _localUserJoinedController.add(localUid);
              }
            } catch (_) {}
          },
          onUserJoined: (_, remoteUid, __) {
            _ensureActiveInfo();
            _activeCallInfo!['remoteUid'] = remoteUid;
            markCallAccepted();
            try {
              _remoteUserJoinedController.add(remoteUid);
            } catch (_) {}
          },
          onUserOffline: (_, remoteUid, __) {
            if (_activeCallInfo != null && _activeCallInfo!['remoteUid'] == remoteUid) {
              _activeCallInfo!['remoteUid'] = null;
            }
            try {
              _remoteUserLeftController.add(remoteUid);
            } catch (_) {}
          },
          onError: (error, message) {
            _lastError = _friendlyAgoraError(error, message);
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
      final channelNameOk = channelName.isNotEmpty &&
          channelName.length <= 64 &&
          RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(channelName);
      if (!channelNameOk) {
        throw ArgumentError('Invalid channel name');
      }

      final wantsVideo = callType == 'video';
      final engine = await initEngine(callType: callType);

      if (_joinedChannelName != null && _joinedChannelName != channelName) {
        await engine.leaveChannel();
      }

      await engine.joinChannel(
        token: '',
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
      return true;
    } catch (error) {
      _lastError = error.toString();
      return false;
    }
  }

  static Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
    } catch (_) {
      // Ignore leave failures.
    } finally {
      _joinedChannelName = null;
      if (_activeCallInfo != null) {
        _activeCallInfo!['remoteUid'] = null;
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
      _activeCallInfo = null;
      _isInCall = false;
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

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/send-call-notification/'),
        headers: headers,
        body: json.encode({
          'callee_id': calleeId,
          'channel_name': channelName,
          'call_type': callType,
          'call_id': _activeCallInfo?['callId'],
          'caller_name': callerName.isNotEmpty ? callerName : currentUser.username,
          'caller_avatar': currentUser.profilePicture,
        }),
      ).timeout(_requestTimeout);

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

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/send-call-status/'),
        headers: headers,
        body: json.encode({
          'receiver_id': receiverId,
          'channel_name': channelName,
          'status': status,
          'call_type': callType,
          'call_id': callId ?? _activeCallInfo?['callId'],
        }),
      ).timeout(_requestTimeout);

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        _lastNotificationError = _friendlyHttpError(response);
      }
      return ok;
    } on TimeoutException {
      _lastNotificationError = 'Call status update timed out. Please try again.';
      return false;
    } catch (error) {
      _lastNotificationError = error.toString();
      return false;
    }
  }

  static int generateUid() {
    return Random().nextInt(100000) + 1;
  }

  static Future<void> _ensurePermissions({required String callType}) async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw StateError('Microphone permission denied');
    }

    if (callType == 'video') {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        throw StateError('Camera permission denied');
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
        return message.isNotEmpty
            ? message
            : 'Unable to continue the call right now.';
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
