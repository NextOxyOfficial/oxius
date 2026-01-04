import 'dart:developer' as dev;

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:uuid/uuid.dart';

import '../models/adsy_call.dart';

class NativeCallService {
  NativeCallService._();
  static final NativeCallService instance = NativeCallService._();

  final _uuid = const Uuid();

  /// Show native incoming call UI (works on lock screen, background, etc.)
  Future<void> showIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required AdsyCallType type,
    String? callerAvatar,
  }) async {
    try {
      dev.log('[NativeCall] Showing incoming call: callId=$callId, caller=$callerName, type=$type');
      
      final params = CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'Oxius',
        avatar: callerAvatar,
        handle: callerId,
        type: type == AdsyCallType.video ? 0 : 1, // 0 = video, 1 = audio
        duration: 45000, // 45 seconds ring timeout
        textAccept: 'Accept',
        textDecline: 'Decline',
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'Missed call',
          callbackText: 'Call back',
        ),
        extra: <String, dynamic>{
          'callId': callId,
          'callerId': callerId,
          'callerName': callerName,
          'callType': type == AdsyCallType.video ? 'video' : 'audio',
        },
        headers: <String, dynamic>{
          'platform': 'flutter',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          backgroundUrl: null,
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: 'Incoming Call',
          missedCallNotificationChannelName: 'Missed Call',
          isShowCallID: false,
          isShowFullLockedScreen: true,
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
          ringtonePath: 'system_ringtone_default',
        ),
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);
      dev.log('[NativeCall] Incoming call UI shown successfully');
    } catch (e, st) {
      dev.log('[NativeCall] Error showing incoming call: $e\n$st');
    }
  }

  /// Show outgoing call UI
  Future<void> showOutgoingCall({
    required String callId,
    required String calleeId,
    required String calleeName,
    required AdsyCallType type,
    String? calleeAvatar,
  }) async {
    try {
      dev.log('[NativeCall] Showing outgoing call: callId=$callId, callee=$calleeName');
      
      final params = CallKitParams(
        id: callId,
        nameCaller: calleeName,
        appName: 'Oxius',
        avatar: calleeAvatar,
        handle: calleeId,
        type: type == AdsyCallType.video ? 0 : 1,
        extra: <String, dynamic>{
          'callId': callId,
          'calleeId': calleeId,
          'calleeName': calleeName,
          'callType': type == AdsyCallType.video ? 'video' : 'audio',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: true,
        ),
      );

      await FlutterCallkitIncoming.startCall(params);
      dev.log('[NativeCall] Outgoing call UI shown successfully');
    } catch (e, st) {
      dev.log('[NativeCall] Error showing outgoing call: $e\n$st');
    }
  }

  /// End the current call
  Future<void> endCall(String callId) async {
    try {
      dev.log('[NativeCall] Ending call: $callId');
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e, st) {
      dev.log('[NativeCall] Error ending call: $e\n$st');
    }
  }

  /// End all calls
  Future<void> endAllCalls() async {
    try {
      dev.log('[NativeCall] Ending all calls');
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e, st) {
      dev.log('[NativeCall] Error ending all calls: $e\n$st');
    }
  }

  /// Get current active calls
  Future<List<dynamic>> getActiveCalls() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      dev.log('[NativeCall] Active calls: ${calls?.length ?? 0}');
      return calls ?? [];
    } catch (e, st) {
      dev.log('[NativeCall] Error getting active calls: $e\n$st');
      return [];
    }
  }

  /// Generate a unique call ID
  String generateCallId() {
    return _uuid.v4();
  }
}
