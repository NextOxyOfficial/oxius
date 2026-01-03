import 'package:cloud_firestore/cloud_firestore.dart';

enum AdsyCallType { audio, video }

enum AdsyCallState { idle, calling, ringing, connected, ended }

class AdsyCallDoc {
  final String id;
  final String callerId;
  final String calleeId;
  final AdsyCallType type;
  final AdsyCallState state;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;

  AdsyCallDoc({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.state,
    required this.offer,
    required this.answer,
  });

  static AdsyCallType _parseType(String? value) {
    if (value == 'video') return AdsyCallType.video;
    return AdsyCallType.audio;
  }

  static AdsyCallState _parseState(String? value) {
    switch (value) {
      case 'calling':
        return AdsyCallState.calling;
      case 'ringing':
        return AdsyCallState.ringing;
      case 'connected':
        return AdsyCallState.connected;
      case 'ended':
        return AdsyCallState.ended;
      default:
        return AdsyCallState.idle;
    }
  }

  static String stateToString(AdsyCallState state) {
    switch (state) {
      case AdsyCallState.calling:
        return 'calling';
      case AdsyCallState.ringing:
        return 'ringing';
      case AdsyCallState.connected:
        return 'connected';
      case AdsyCallState.ended:
        return 'ended';
      case AdsyCallState.idle:
      default:
        return 'idle';
    }
  }

  static String typeToString(AdsyCallType type) {
    return type == AdsyCallType.video ? 'video' : 'audio';
  }

  static AdsyCallDoc? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;

    return AdsyCallDoc(
      id: snap.id,
      callerId: (data['callerId'] ?? '').toString(),
      calleeId: (data['calleeId'] ?? '').toString(),
      type: _parseType(data['type']?.toString()),
      state: _parseState(data['state']?.toString()),
      offer: data['offer'] is Map ? Map<String, dynamic>.from(data['offer'] as Map) : null,
      answer: data['answer'] is Map ? Map<String, dynamic>.from(data['answer'] as Map) : null,
    );
  }

  static DocumentReference<Map<String, dynamic>> callsRef(String callId) {
    return FirebaseFirestore.instance.collection('calls').doc(callId);
  }
}
