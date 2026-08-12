import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agora_call_service.dart';
import 'call_foreground_service.dart';
import 'call_navigation.dart';
import 'fcm_service.dart';
import 'livekit_call_service.dart';

/// Android-only, safely askable from anywhere — including web.
///
/// `Platform` lives in dart:io, which does not exist on web: merely READING
/// `Platform.isAndroid` there throws UnsupportedError. Every guard in this file
/// was written as `if (!Platform.isAndroid) return;` to make the whole service a
/// no-op off Android, but on web that guard threw instead of returning — and
/// because `start()` is called straight from `main()` with nothing around it,
/// the throw killed main() before it could run `_bootstrap`. The session was
/// never initialised, `isInitializing` never went false, and the app sat on the
/// splash screen forever having made no network calls at all.
///
/// `kIsWeb` is a compile-time constant and `||` short-circuits, so on Android
/// and iOS this compiles to exactly the old check and costs nothing.
bool get _isAndroid => !kIsWeb && Platform.isAndroid;

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

  /// Runs only while the overlay bubble is on screen. See [_watchForDeath].
  Timer? _livenessTimer;

  static void _log(String message) {
    if (kDebugMode) debugPrint('🫧 CallBubble: $message');
  }

  void start() {
    if (_started || !_isAndroid) return;
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
    if (!_isAndroid) return;
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
    if (!_isAndroid) return;
    _updateDeathWatch();

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

  /// Whether this isolate is currently deaf to call events.
  ///
  /// Away from the foreground, a terminal call_status lands in the FCM
  /// background isolate instead of this one — so both surfaces that can be
  /// on screen while the app is away (the overlay bubble and the PiP window)
  /// need watching, not just the bubble.
  bool get _needsDeathWatch =>
      AgoraCallService.isInCall &&
      (!_appInForeground || inPictureInPicture.value);

  void _updateDeathWatch() {
    if (_needsDeathWatch) {
      _livenessTimer ??= Timer.periodic(
          const Duration(seconds: 2), (_) => _checkStillAlive());
      return;
    }
    _livenessTimer?.cancel();
    _livenessTimer = null;
  }

  /// Notice a call that ended while the app was away.
  ///
  /// Away from the foreground, a terminal call_status arrives in the FCM
  /// *background* isolate, which cannot reach this one's state. So the app
  /// went on believing the call was live: the bubble stayed over the home
  /// screen after the other side hung up, and it only vanished once tapping
  /// it resumed the app and something finally reconciled.
  ///
  /// The background isolate does leave a marker naming the dead channel.
  /// Nothing was reading it while the app was away; now something does.
  Future<void> _checkStillAlive() async {
    if (!_needsDeathWatch) {
      _updateDeathWatch();
      // The call may have ended between ticks — let _sync take the surfaces
      // down rather than leaving whichever one is up.
      if (!AgoraCallService.isInCall) await _sync();
      return;
    }

    final channel = AgoraCallService.activeCallInfo?['channelName']?.toString();
    if (channel == null || channel.isEmpty) return;

    String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Reload: this value is written by the OTHER isolate, so the copy this
      // one cached at startup would never change.
      await prefs.reload();
      raw = prefs.getString(FCMService.bgRingTerminalPrefsKey);
    } catch (_) {
      return;
    }
    if (raw == null || raw.isEmpty) return;

    try {
      final marker = jsonDecode(raw);
      if (marker is! Map || marker['channel']?.toString() != channel) return;
    } catch (_) {
      return;
    }

    _log('peer ended the call while backgrounded — tearing down');
    // Same teardown handleRemoteCallStatus does for a call with no screen in
    // front of it. Media first, so the room is left before the state flips
    // and the UI stops asking about it.
    try {
      await LiveKitCallService.leaveChannel();
    } catch (_) {}
    AgoraCallService.setInCall(false);
    await _sync();
    // A PiP window is Android's, not ours to hide — ask for it to be left.
    if (inPictureInPicture.value) {
      await _invoke('exitPip');
    }
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
    if (!_isAndroid) return false;
    return (await _invoke('canDrawOverlays')) == true;
  }

  /// Whether this device can host a floating Picture-in-Picture window.
  Future<bool> pipSupported() async {
    if (!_isAndroid) return false;
    return (await _invoke('pipSupported')) == true;
  }

  /// Shrinks the app into a floating window right now.
  ///
  /// Leaving the app during a call does this on its own via
  /// onUserLeaveHint; this is for the call screen's own minimise button, so
  /// that control does the same visible thing as pressing Home.
  Future<bool> enterPictureInPicture() async {
    if (!_isAndroid) return false;
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
    if (!_isAndroid) return;
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
