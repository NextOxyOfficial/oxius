import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/fcm_service.dart';
import '../models/adsy_call.dart';
import 'firestore_call_signaling_service.dart';
import '../screens/adsy_call_screen.dart';

class CallListenerService {
  CallListenerService._();

  static final CallListenerService instance = CallListenerService._();

  StreamSubscription? _sub;
  String? _activeCallId;
  Timer? _navTimer;
  int _navAttempts = 0;

  void start() {
    _sub ??= FirestoreCallSignalingService.instance.watchIncomingCalls().listen((snap) {
      for (final doc in snap.docs) {
        if (_activeCallId != null) return;

        final callId = doc.id;
        final call = AdsyCallDoc.fromSnapshot(doc);
        if (call == null) continue;

        _activeCallId = callId;
        _navigateToIncoming(call);
        break;
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _activeCallId = null;
    _navTimer?.cancel();
    _navTimer = null;
    _navAttempts = 0;
  }

  void _navigateToIncoming(AdsyCallDoc call) {
    _navTimer?.cancel();
    _navAttempts = 0;

    _navTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      final nav = FCMService.navigatorKey.currentState;
      if (nav == null) {
        _navAttempts += 1;
        if (_navAttempts >= 20) {
          t.cancel();
          _navTimer = null;
          _activeCallId = null;
        }
        return;
      }

      t.cancel();
      _navTimer = null;

      nav
          .push(
        MaterialPageRoute(
          builder: (context) => AdsyCallScreen(
            isCaller: false,
            callId: call.id,
            otherUserId: call.callerId,
            otherUserName: call.callerId,
            type: call.type,
          ),
        ),
      )
          .then((_) {
        _activeCallId = null;
      });
    });
  }
}
