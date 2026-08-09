import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'agora_call_service.dart';
import 'call_foreground_service.dart';
import 'call_navigation.dart';

/// Keeping a live call reachable after the user leaves the app.
///
/// Two mechanisms, and which one runs is decided by what the user has
/// already agreed to — never by interrupting them:
///
///  * **Picture-in-Picture** is the default. Leaving the app during a call
///    shrinks it into a small floating window that sits over whatever they
///    open next, drags anywhere, and taps back to full screen. It needs no
///    permission at all, which is the entire reason it is the default.
///  * **The overlay bubble** (CallBubbleOverlay.kt) is richer, but it needs
///    SYSTEM_ALERT_WINDOW — a "special app access" that Android only grants
///    from its own Settings screen. There is no in-app dialog for it and no
///    library can make one, so this app never asks: the bubble is used only
///    when the permission already happens to be there, and the one place to
///    turn it on is a switch the user goes looking for in Settings.
///
/// Android only. iOS has neither, and there the CallKit call in the status
/// bar already does this job.
class CallBubbleService with WidgetsBindingObserver {
  CallBubbleService._();

  static final CallBubbleService instance = CallBubbleService._();

  static const MethodChannel _channel =
      MethodChannel('com.oxius.app/call_service');

  bool _started = false;
  bool _appInForeground = true;
  bool _visible = false;

  /// True while Android is showing the app as a floating PiP window.
  final ValueNotifier<bool> inPictureInPicture = ValueNotifier<bool>(false);

  static void _log(String message) {
    if (kDebugMode) debugPrint('🫧 CallBubble: $message');
  }

  void start() {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    // The channel has one handler and CallForegroundService owns it; this
    // side just registers what it wants dispatched. Attaching a second
    // handler here would quietly unhook the notification's hang-up button.
    CallForegroundService.ensureHandlerAttached();
    CallForegroundService.onPipModeChanged = _handlePipModeChanged;
    // A call can start, connect or end while the app is already in the
    // background, and each of those changes what the bubble should say. The
    // singleton outlives every call, so there is nothing to unsubscribe.
    AgoraCallService.callStateStream.listen((_) {
      unawaited(_publishCallState());
      unawaited(_sync());
    });
    unawaited(_publishCallState());
  }

  /// Native has to know, before the user has finished leaving, whether this
  /// exit should shrink the app into a floating window. Asking Dart at that
  /// moment is too late — onUserLeaveHint cannot wait for a round trip — so
  /// the answer is pushed ahead of time on every call state change.
  Future<void> _publishCallState() async {
    if (!Platform.isAndroid) return;
    final info = AgoraCallService.activeCallInfo;
    await _invoke('setCallActive', <String, dynamic>{
      'active': AgoraCallService.isInCall && info != null,
      'video': info?['callType']?.toString() == 'video',
    });
  }

  void _handlePipModeChanged(bool entering) {
    inPictureInPicture.value = entering;

    // A PiP window and an overlay bubble are the same idea twice over. The
    // bubble is the one that goes, because PiP is what the user is looking
    // at. Leaving PiP hands the decision back to _sync.
    if (entering) {
      if (_visible) {
        _visible = false;
        unawaited(_invoke('bubbleHide'));
      }
      return;
    }

    unawaited(_sync());

    // Coming out of PiP means the user tapped the floating call to get back
    // to it — the same intent as tapping the in-app bubble, so it lands in
    // the same place. Without this they would be dropped on whatever route
    // happened to be underneath, having asked for the call.
    if (AgoraCallService.isInCall && !AgoraCallService.isCallScreenVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!CallNavigation.openActiveCall()) {
          _log('left PiP with no active call to return to');
        }
      });
    }
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
    // Three reasons not to draw the bubble, and only one of them is "no
    // call": PiP is already showing a floating window, and the permission
    // the bubble needs may simply never have been granted — which is the
    // normal case now that nothing ever asks for it.
    final shouldShow = !_appInForeground &&
        !inPictureInPicture.value &&
        AgoraCallService.isInCall &&
        info != null &&
        await canDrawOverlays();

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

  /// Whether this device can host a floating Picture-in-Picture window.
  Future<bool> pipSupported() async {
    if (!Platform.isAndroid) return false;
    return (await _invoke('pipSupported')) == true;
  }

  /// Shrinks the app into a floating window right now.
  ///
  /// Leaving the app during a call does this on its own via
  /// onUserLeaveHint; this is for the call screen's own minimise button, so
  /// that control does the same visible thing as pressing Home.
  Future<bool> enterPictureInPicture() async {
    if (!Platform.isAndroid) return false;
    return (await _invoke('enterPip')) == true;
  }

  /// Opens the system page for "display over other apps".
  ///
  /// Reached ONLY from the switch in Settings, where the user went looking
  /// for it. Android grants SYSTEM_ALERT_WINDOW from that page and nowhere
  /// else — unlike camera or microphone, there is no in-app Allow dialog the
  /// app could show instead, for any app, including the ones that seem to
  /// manage it. They use Picture-in-Picture, which is what this app now does
  /// by default.
  Future<void> openOverlaySettings() async {
    if (!Platform.isAndroid) return;
    await _invoke('requestOverlayPermission');
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
