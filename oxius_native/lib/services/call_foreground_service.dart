import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the Android foreground service that keeps a call alive while
/// the app is not on screen.
///
/// iOS needs nothing here: the `audio` and `voip` background modes in
/// Info.plist already let a call keep the microphone once CallKit or the
/// audio session is active, so every method is a no-op there.
///
/// Everything is driven from one [sync] call so there is a single place that
/// decides whether a service should be running — call state changes arrive
/// from a lot of places (outgoing dial, in-app accept, CallKit accept, remote
/// hangup, screen dispose) and each of them would otherwise need its own
/// start/stop pair to keep straight.
class CallForegroundService {
  const CallForegroundService._();

  static const MethodChannel _channel =
      MethodChannel('com.oxius.app/call_service');

  static bool _running = false;

  /// What the notification currently says. Call state is emitted far more
  /// often than it meaningfully changes, and re-posting an identical
  /// notification just makes the shade flicker.
  static String? _signature;

  static void _log(String message) {
    if (kDebugMode) debugPrint('📞 CallForegroundService: $message');
  }

  static bool _handlerAttached = false;

  /// What to run when the user hangs up from the notification. Injected so
  /// this service does not have to know how a call is torn down — that lives
  /// with the call state, not with the notification that describes it.
  static Future<void> Function()? onHangUp;

  /// What to run when Android puts the app into, or takes it out of, a
  /// floating Picture-in-Picture window.
  ///
  /// Injected for the same reason as [onHangUp], and routed through here for
  /// a blunter one: a MethodChannel is keyed by name, so the LAST
  /// setMethodCallHandler for 'com.oxius.app/call_service' silently replaces
  /// every earlier one. Two services listening on this channel would mean
  /// one of them stops being called, with nothing to show for it. One
  /// handler, and it dispatches.
  static void Function(bool inPip)? onPipModeChanged;

  static void _ensureHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'hangup':
          await onHangUp?.call();
          break;
        case 'pipModeChanged':
          onPipModeChanged?.call(call.arguments == true);
          break;
      }
      return null;
    });
  }

  /// Attaches the channel handler before any call exists.
  ///
  /// [sync] does this too, but only once a call is running — and PiP can be
  /// entered on the very first one, before sync has ever been reached.
  static void ensureHandlerAttached() {
    if (!Platform.isAndroid) return;
    _ensureHandler();
  }

  /// Brings the service in line with the current call state.
  ///
  /// [info] is `AgoraCallService.activeCallInfo` — peer name, call type and
  /// the moment the media connected.
  static Future<void> sync({
    required bool inCall,
    Map<String, dynamic>? info,
  }) async {
    if (!Platform.isAndroid) return;
    _ensureHandler();

    if (!inCall) {
      if (!_running) return;
      _running = false;
      _signature = null;
      await _invoke('stop');
      return;
    }

    final peerName = info?['peerName']?.toString().trim() ?? '';
    final callType = info?['callType']?.toString() ?? 'audio';
    final isVideo = callType == 'video';
    final accepted = info?['accepted'] == true;
    final connectedAt = _toInt(info?['connectedAt']) ?? 0;

    final title = peerName.isEmpty ? 'AdsyClub' : peerName;
    final String text;
    if (connectedAt > 0) {
      text = isVideo ? 'Video call in progress' : 'Audio call in progress';
    } else if (accepted) {
      text = 'Connecting…';
    } else {
      text = 'Ringing…';
    }

    final signature = '$title|$text|$isVideo|$connectedAt';
    if (_running && signature == _signature) return;
    _signature = signature;
    _running = true;

    await _invoke('start', <String, dynamic>{
      'title': title,
      'text': text,
      'video': isVideo,
      'connectedAt': connectedAt,
    });
  }

  /// Unconditional teardown, for the paths that drop call state without going
  /// through the normal end-of-call bookkeeping.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    _running = false;
    _signature = null;
    await _invoke('stop');
  }

  static Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // The channel lives on MainActivity's engine. A call accepted from a
      // killed app can reach this before the activity exists; the next state
      // change re-runs sync() once it does, so this is not worth escalating.
      _running = false;
      _signature = null;
      _log('$method skipped — activity channel not up yet');
    } catch (error) {
      _log('$method failed: $error');
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
