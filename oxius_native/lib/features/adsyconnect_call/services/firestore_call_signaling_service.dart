import 'dart:async';
import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/adsy_call.dart';
import 'firebase_call_auth_service.dart';

class FirestoreCallSignalingService {
  FirestoreCallSignalingService._();

  static final FirestoreCallSignalingService instance = FirestoreCallSignalingService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _calls => _db.collection('calls');

  Future<String?> createCall({
    required String calleeId,
    required AdsyCallType type,
  }) async {
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) return null;

    final callerId = FirebaseCallAuthService.instance.uid;
    if (callerId == null || callerId.isEmpty) return null;

    final now = FieldValue.serverTimestamp();
    final doc = await _calls.add({
      'callerId': callerId,
      'calleeId': calleeId,
      'type': AdsyCallDoc.typeToString(type),
      'state': AdsyCallDoc.stateToString(AdsyCallState.calling),
      'createdAt': now,
      'updatedAt': now,
    });

    return doc.id;
  }

  Future<void> updateCallState(String callId, AdsyCallState state) async {
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) return;

    await _calls.doc(callId).set({
      'state': AdsyCallDoc.stateToString(state),
      'updatedAt': FieldValue.serverTimestamp(),
      if (state == AdsyCallState.ended) 'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOffer(String callId, Map<String, dynamic> offer) async {
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) return;

    await _calls.doc(callId).set({
      'offer': offer,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setAnswer(String callId, Map<String, dynamic> answer) async {
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) return;

    await _calls.doc(callId).set({
      'answer': answer,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<AdsyCallDoc?> watchCall(String callId) {
    return _calls
        .doc(callId)
        .snapshots()
        .map((snap) => AdsyCallDoc.fromSnapshot(snap));
  }

  CollectionReference<Map<String, dynamic>> _candidatesCollection({
    required String callId,
    required bool isCaller,
  }) {
    return _calls
        .doc(callId)
        .collection(isCaller ? 'callerCandidates' : 'calleeCandidates');
  }

  CollectionReference<Map<String, dynamic>> _remoteCandidatesCollection({
    required String callId,
    required bool isCaller,
  }) {
    return _calls
        .doc(callId)
        .collection(isCaller ? 'calleeCandidates' : 'callerCandidates');
  }

  Future<void> addLocalCandidate({
    required String callId,
    required bool isCaller,
    required Map<String, dynamic> candidate,
  }) async {
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) return;

    await _candidatesCollection(callId: callId, isCaller: isCaller).add({
      ...candidate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRemoteCandidates({
    required String callId,
    required bool isCaller,
  }) {
    return _remoteCandidatesCollection(callId: callId, isCaller: isCaller)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchIncomingCalls() async* {
    dev.log('[FirestoreSignaling] watchIncomingCalls starting...');
    
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) {
      dev.log('[FirestoreSignaling] watchIncomingCalls: Firebase auth failed');
      yield* Stream.empty();
      return;
    }

    final uid = FirebaseCallAuthService.instance.uid;
    if (uid == null || uid.isEmpty) {
      dev.log('[FirestoreSignaling] watchIncomingCalls: UID is null or empty');
      yield* Stream.empty();
      return;
    }

    dev.log('[FirestoreSignaling] watchIncomingCalls: Listening for calls where calleeId=$uid and state=calling');
    yield* _calls
        .where('calleeId', isEqualTo: uid)
        .where('state', isEqualTo: AdsyCallDoc.stateToString(AdsyCallState.calling))
        .snapshots();
  }

  Future<AdsyCallDoc?> getCall(String callId) async {
    final ok = await FirebaseCallAuthService.instance.ensureSignedIn();
    if (!ok) return null;

    final snap = await _calls.doc(callId).get();
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return AdsyCallDoc.fromSnapshot(snap);
    }

    final raw = snap.data();
    if (raw != null && raw is Map) {
      final mapped = Map<String, dynamic>.from(raw as Map);
      return AdsyCallDoc(
        id: snap.id,
        callerId: mapped['callerId']?.toString() ?? '',
        calleeId: mapped['calleeId']?.toString() ?? '',
        type: (mapped['type']?.toString() == 'video') ? AdsyCallType.video : AdsyCallType.audio,
        state: AdsyCallState.idle,
        offer: mapped['offer'] is Map ? Map<String, dynamic>.from(mapped['offer'] as Map) : null,
        answer: mapped['answer'] is Map ? Map<String, dynamic>.from(mapped['answer'] as Map) : null,
      );
    }

    return null;
  }
}
