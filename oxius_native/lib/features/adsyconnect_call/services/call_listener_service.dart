import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../../../services/fcm_service.dart';
import '../models/adsy_call.dart';
import 'firebase_call_auth_service.dart';
import 'firestore_call_signaling_service.dart';
import '../screens/adsy_call_screen.dart';

class CallListenerService {
  CallListenerService._();

  static final CallListenerService instance = CallListenerService._();

  StreamSubscription? _sub;
  String? _activeCallId;
  Timer? _navTimer;
  int _navAttempts = 0;

  bool _isStarting = false;

  int _retryCount = 0;
  static const int _maxRetries = 3;

  Future<void> start() async {
    if (_sub != null || _isStarting) {
      dev.log('[CallListener] Already started or starting');
      return;
    }
    
    _isStarting = true;
    dev.log('[CallListener] Starting incoming call listener...');
    
    // First ensure Firebase Auth is signed in with retry logic
    bool authOk = false;
    for (int i = 0; i <= _maxRetries; i++) {
      authOk = await FirebaseCallAuthService.instance.ensureSignedIn();
      if (authOk) break;
      if (i < _maxRetries) {
        dev.log('[CallListener] Firebase Auth failed, retrying in 2s... (attempt ${i + 1}/$_maxRetries)');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    if (!authOk) {
      dev.log('[CallListener] ERROR: Firebase Auth failed after $_maxRetries retries - ${FirebaseCallAuthService.instance.lastError}');
      _isStarting = false;
      _retryCount++;
      // Schedule a retry after 10 seconds if not too many retries
      if (_retryCount <= 3) {
        dev.log('[CallListener] Will retry start() in 10 seconds...');
        Future.delayed(const Duration(seconds: 10), () {
          if (_sub == null) start();
        });
      }
      return;
    }
    
    _retryCount = 0; // Reset on success
    final uid = FirebaseCallAuthService.instance.uid;
    dev.log('[CallListener] Firebase Auth OK, listening for calls where calleeId=$uid');
    dev.log('[CallListener] NOTE: Caller must send this exact uid as calleeId for recipient to receive the call');
    
    _sub = FirestoreCallSignalingService.instance.watchIncomingCalls().listen(
      (snap) {
        dev.log('[CallListener] Received snapshot with ${snap.docs.length} docs');
        for (final doc in snap.docs) {
          if (_activeCallId != null) {
            dev.log('[CallListener] Already handling call $_activeCallId, skipping');
            return;
          }

          final callId = doc.id;
          dev.log('[CallListener] Processing incoming call: $callId');
          final call = AdsyCallDoc.fromSnapshot(doc);
          if (call == null) {
            dev.log('[CallListener] Failed to parse call doc');
            continue;
          }

          dev.log('[CallListener] Incoming call from ${call.callerId}, type=${call.type}');
          _activeCallId = callId;
          _navigateToIncoming(call);
          break;
        }
      },
      onError: (e, st) {
        dev.log('[CallListener] Stream error: $e\n$st');
      },
      onDone: () {
        dev.log('[CallListener] Stream closed');
      },
    );
    
    _isStarting = false;
    dev.log('[CallListener] Listener started successfully');
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
    dev.log('[CallListener] _navigateToIncoming: callId=${call.id}, callerId=${call.callerId}');
    _navTimer?.cancel();
    _navAttempts = 0;

    _navTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      final nav = FCMService.navigatorKey.currentState;
      if (nav == null) {
        _navAttempts += 1;
        dev.log('[CallListener] Navigator not ready, attempt $_navAttempts/20');
        if (_navAttempts >= 20) {
          dev.log('[CallListener] Max nav attempts reached, giving up');
          t.cancel();
          _navTimer = null;
          _activeCallId = null;
        }
        return;
      }

      t.cancel();
      _navTimer = null;
      dev.log('[CallListener] Navigating to incoming call screen');

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
        dev.log('[CallListener] Call screen closed');
        _activeCallId = null;
      });
    });
  }
}
