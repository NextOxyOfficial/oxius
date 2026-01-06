import 'dart:convert';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class AgoraCallService {
  static const String appId = '9eba1a50633041d08dbe75b0fde2ed8a';
  static const bool _useTokenServer = false;
  
  static RtcEngine? _engine;
  static bool _isInitialized = false;
  static String? _lastError;
  static String? get lastError => _lastError;

  static String? _lastNotificationError;
  static String? get lastNotificationError => _lastNotificationError;
  
  /// Initialize Agora RTC Engine
  static Future<RtcEngine> initEngine() async {
    if (_engine != null && _isInitialized) {
      return _engine!;
    }
    
    // Request permissions
    await [Permission.microphone, Permission.camera].request();
    
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 480),
        frameRate: 15,
        bitrate: 0,
      ),
    );
    
    _isInitialized = true;
    return _engine!;
  }
  
  /// Get the RTC Engine instance
  static RtcEngine? get engine => _engine;
  
  /// Generate a unique channel name for 1-on-1 call
  static String generateChannelName(String callerId, String calleeId) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(1 << 32).toRadixString(36);
    final pair = '$callerId|$calleeId';
    final pairHash = pair.hashCode.abs().toRadixString(36);
    return 'c_${pairHash}_$ts$rnd';
  }
  
  /// Generate RTC token for joining channel
  /// For production, this should be done on your backend server
  static Future<String?> generateToken(String channelName, int uid) async {
    if (!_useTokenServer) return null;
    try {
      // For testing, we'll use a temporary token approach
      // In production, call your backend to generate token
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/agora-token/'),
        headers: headers,
        body: json.encode({
          'channel_name': channelName,
          'uid': uid,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      }
      
      // If backend doesn't have token endpoint, return null (will use app ID only mode)
      print('Token generation failed, using app ID only mode');
      return null;
    } catch (e) {
      print('Error generating token: $e');
      return null;
    }
  }
  
  /// Join a video call channel
  static Future<bool> joinChannel({
    required String channelName,
    required int uid,
    String? token,
  }) async {
    try {
      _lastError = null;
      final nameOk = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(channelName);
      if (!nameOk || channelName.isEmpty || channelName.length > 64) {
        throw ArgumentError(
          'Invalid channel name. Must match ^[a-zA-Z0-9_]+\$, length 1..64. Got length=${channelName.length}, value=$channelName',
        );
      }

      print('Agora: Joining channel: $channelName with uid: $uid');
      print('Agora: Token: ${token != null ? "provided" : "null (using App ID only mode)"}');
      
      final engine = await initEngine();
      
      await engine.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      
      print('Agora: Join channel request sent successfully');
      return true;
    } catch (e) {
      _lastError = e.toString();
      print('Agora Error joining channel: $e');
      return false;
    }
  }
  
  /// Leave the current channel
  static Future<void> leaveChannel() async {
    try {
      await _engine?.leaveChannel();
    } catch (e) {
      print('Error leaving channel: $e');
    }
  }
  
  /// Toggle microphone mute
  static Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }
  
  /// Toggle camera on/off
  static Future<void> toggleCamera(bool enabled) async {
    await _engine?.enableLocalVideo(enabled);
  }
  
  /// Switch between front and back camera
  static Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }
  
  /// Toggle speaker/earpiece
  static Future<void> toggleSpeaker(bool speakerOn) async {
    await _engine?.setEnableSpeakerphone(speakerOn);
  }
  
  /// Dispose the engine
  static Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
  
  /// Send call notification to callee via FCM
  static Future<bool> sendCallNotification({
    required String calleeId,
    required String channelName,
    required String callType, // 'video' or 'audio'
  }) async {
    try {
      _lastNotificationError = null;
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return false;
      
      final headers = await ApiService.getHeaders();
      final callerName = [currentUser.firstName, currentUser.lastName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/send-call-notification/'),
        headers: headers,
        body: json.encode({
          'callee_id': calleeId,
          'channel_name': channelName,
          'call_type': callType,
          'caller_name': callerName.isNotEmpty ? callerName : currentUser.username,
          'caller_avatar': currentUser.profilePicture,
        }),
      );

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        _lastNotificationError = '${response.statusCode} ${response.body}';
        print('Call notification failed: ${response.statusCode} ${response.body}');
      }
      return ok;
    } catch (e) {
      _lastNotificationError = e.toString();
      print('Error sending call notification: $e');
      return false;
    }
  }
  
  /// Generate a random UID for Agora
  static int generateUid() {
    return Random().nextInt(100000) + 1;
  }
}
