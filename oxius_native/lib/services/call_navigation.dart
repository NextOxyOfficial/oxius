import 'package:flutter/material.dart';

import '../screens/call_screen.dart';
import 'agora_call_service.dart';
import 'fcm_service.dart';

/// Re-opens the call screen for the call that is already running.
///
/// Three different surfaces need this — the in-app minimised bar, the floating
/// bubble over other apps, and the ongoing-call notification — and each one
/// rebuilding the CallScreen arguments from `activeCallInfo` by hand is three
/// chances to get the "returning" flag or the peer id subtly wrong.
class CallNavigation {
  const CallNavigation._();

  static bool openActiveCall() {
    final info = AgoraCallService.activeCallInfo;
    if (info == null) return false;

    final navigator = FCMService.navigatorKey.currentState;
    if (navigator == null) return false;

    // Already looking at it — a second push would stack a duplicate call
    // screen on top of the live one.
    if (AgoraCallService.isCallScreenVisible) return true;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: info['channelName']?.toString() ?? '',
          calleeId: info['peerId']?.toString() ?? '',
          calleeName: info['peerName']?.toString() ?? 'Unknown',
          calleeAvatar: info['peerAvatar']?.toString(),
          callId: info['callId']?.toString(),
          isIncoming: info['isIncoming'] == true,
          callType: info['callType']?.toString() ?? 'video',
          isReturning: true,
        ),
      ),
    );
    return true;
  }
}
