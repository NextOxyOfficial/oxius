import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agora_call_service.dart';
import 'call_navigation.dart';

/// The floating call bubble that follows the user out of the app.
///
/// The native half (CallBubbleOverlay.kt) owns the window; this side decides
/// *when* it should exist — while a call is live and the app is not on screen —
/// and brings the user back to the call screen when the bubble is tapped.
///
/// Android only. iOS has no equivalent to a system-wide overlay window, and
/// there the CallKit call in the status bar already does this job.
class CallBubbleService with WidgetsBindingObserver {
  CallBubbleService._();

  static final CallBubbleService instance = CallBubbleService._();

  static const MethodChannel _channel =
      MethodChannel('com.oxius.app/call_service');

  /// Remembers that the user was already asked once. A "display over other
  /// apps" prompt is a trip to system Settings; asking on every minimise
  /// would be nagging.
  static const String _prefsAskedKey = 'call_bubble_overlay_asked';

  bool _started = false;
  bool _appInForeground = true;
  bool _visible = false;

  static void _log(String message) {
    if (kDebugMode) debugPrint('🫧 CallBubble: $message');
  }

  void start() {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    // A call can start, connect or end while the app is already in the
    // background, and each of those changes what the bubble should say. The
    // singleton outlives every call, so there is nothing to unsubscribe.
    AgoraCallService.callStateStream.listen((_) => _sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appInForeground = true;
        _sync();
        unawaited(_handlePendingCallOpen());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _appInForeground = false;
        _sync();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // `inactive` also fires for a permission dialog or the app switcher
        // preview, which are not "the user left" — reacting to it would flash
        // the bubble on top of our own app.
        break;
    }
  }

  Future<void> _sync() async {
    if (!Platform.isAndroid) return;

    final info = AgoraCallService.activeCallInfo;
    final shouldShow =
        !_appInForeground && AgoraCallService.isInCall && info != null;

    if (!shouldShow) {
      if (!_visible) return;
      _visible = false;
      await _invoke('bubbleHide');
      return;
    }

    final connectedAt = AgoraCallService.activeCallConnectedAtMs ?? 0;
    final shown = await _invoke('bubbleShow', <String, dynamic>{
      'video': info['callType']?.toString() == 'video',
      'connectedAt': connectedAt,
      'status': connectedAt > 0
          ? ''
          : (AgoraCallService.activeCallAccepted ? 'On call' : 'Ringing'),
    });
    _visible = shown == true;
  }

  Future<void> _handlePendingCallOpen() async {
    final pending = await _invoke('consumePendingCallOpen');
    if (pending != true) return;
    // The engine may still be building its first frame on a cold resume;
    // pushing after the frame keeps the navigator from being null.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!CallNavigation.openActiveCall()) {
        _log('bubble tap had no active call to return to');
      }
    });
  }

  Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return false;
    return (await _invoke('canDrawOverlays')) == true;
  }

  /// Asks — once — for the permission the bubble needs.
  ///
  /// Returns true when the bubble can already be drawn, so callers can skip
  /// the explanation entirely in the common case.
  Future<bool> ensurePermission(BuildContext context) async {
    if (!Platform.isAndroid) return false;
    if (await canDrawOverlays()) return true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsAskedKey) == true) return false;
    await prefs.setBool(_prefsAskedKey, true);

    if (!context.mounted) return false;
    final grant = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable the call bubble?'),
        content: const Text(
          'A small floating button stays on screen while you are in other '
          'apps, so one tap brings you back to the call.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (grant == true) {
      await _invoke('requestOverlayPermission');
    }
    return false;
  }

  Future<Object?> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, args);
    } on MissingPluginException {
      return null;
    } catch (error) {
      _log('$method failed: $error');
      return null;
    }
  }
}
