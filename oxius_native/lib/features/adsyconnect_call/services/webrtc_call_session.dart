import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/adsy_call.dart';
import 'firestore_call_signaling_service.dart';

class WebRtcCallSession {
  final String callId;
  final bool isCaller;
  final AdsyCallType type;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  StreamSubscription? _callSub;
  StreamSubscription? _remoteCandidatesSub;

  final Set<String> _seenRemoteCandidateIds = <String>{};

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _speakerEnabled = false;

  WebRtcCallSession({
    required this.callId,
    required this.isCaller,
    required this.type,
  });

  bool get micEnabled => _micEnabled;
  bool get cameraEnabled => _cameraEnabled;
  bool get speakerEnabled => _speakerEnabled;

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    final configuration = {
      'sdpSemantics': 'unified-plan',
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(configuration);

    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };

    _pc!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null) return;
      FirestoreCallSignalingService.instance.addLocalCandidate(
        callId: callId,
        isCaller: isCaller,
        candidate: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': type == AdsyCallType.video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
            }
          : false,
    });

    localRenderer.srcObject = _localStream;

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _remoteCandidatesSub = FirestoreCallSignalingService.instance
        .watchRemoteCandidates(callId: callId, isCaller: isCaller)
        .listen((snap) {
      for (final doc in snap.docChanges) {
        final id = doc.doc.id;
        if (_seenRemoteCandidateIds.contains(id)) continue;
        _seenRemoteCandidateIds.add(id);

        final data = doc.doc.data();
        if (data == null) continue;
        final candidate = data['candidate']?.toString();
        final sdpMid = data['sdpMid']?.toString();
        final sdpMLineIndex = data['sdpMLineIndex'];

        if (candidate == null || candidate.isEmpty) continue;
        final int? lineIndex = (sdpMLineIndex is int)
            ? sdpMLineIndex
            : int.tryParse(sdpMLineIndex?.toString() ?? '');
        final cand = RTCIceCandidate(candidate, sdpMid, lineIndex);
        _pc?.addCandidate(cand);
      }
    });
  }

  Future<void> startAsCaller() async {
    if (_pc == null) throw StateError('PeerConnection not initialized');

    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': type == AdsyCallType.video ? 1 : 0,
    });

    await _pc!.setLocalDescription(offer);

    await FirestoreCallSignalingService.instance.setOffer(callId, offer.toMap());

    _callSub = FirestoreCallSignalingService.instance.watchCall(callId).listen((call) async {
      if (call == null) return;

      if (call.state == AdsyCallState.ended) {
        await dispose();
        return;
      }

      if (call.answer != null) {
        final currentRemote = await _pc!.getRemoteDescription();
        if (currentRemote == null) {
          final answer = RTCSessionDescription(
            call.answer!['sdp']?.toString(),
            call.answer!['type']?.toString(),
          );
          await _pc!.setRemoteDescription(answer);
          await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.connected);
        }
      }
    });
  }

  Future<void> startAsCallee() async {
    if (_pc == null) throw StateError('PeerConnection not initialized');

    AdsyCallDoc? call = await FirestoreCallSignalingService.instance.getCall(callId);
    if (call == null || call.offer == null) {
      call = await FirestoreCallSignalingService.instance
          .watchCall(callId)
          .where((c) => c != null && c.offer != null)
          .cast<AdsyCallDoc>()
          .timeout(const Duration(seconds: 15))
          .first;
    }

    if (call.offer == null) {
      throw StateError('Call offer not found');
    }

    await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.ringing);

    final offer = RTCSessionDescription(
      call.offer!['sdp']?.toString(),
      call.offer!['type']?.toString(),
    );
    await _pc!.setRemoteDescription(offer);

    final answer = await _pc!.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': type == AdsyCallType.video ? 1 : 0,
    });

    await _pc!.setLocalDescription(answer);
    await FirestoreCallSignalingService.instance.setAnswer(callId, answer.toMap());
    await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.connected);

    _callSub = FirestoreCallSignalingService.instance.watchCall(callId).listen((call) async {
      if (call == null) return;
      if (call.state == AdsyCallState.ended) {
        await dispose();
      }
    });
  }

  Future<void> setMicEnabled(bool enabled) async {
    _micEnabled = enabled;
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (final t in audioTracks) {
      t.enabled = enabled;
    }
  }

  Future<void> setCameraEnabled(bool enabled) async {
    _cameraEnabled = enabled;
    final videoTracks = _localStream?.getVideoTracks() ?? [];
    for (final t in videoTracks) {
      t.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? [];
    if (videoTracks.isEmpty) return;
    await Helper.switchCamera(videoTracks.first);
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    _speakerEnabled = enabled;
    await Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> endCall() async {
    await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.ended);
    await dispose();
  }

  Future<void> dispose() async {
    await _callSub?.cancel();
    await _remoteCandidatesSub?.cancel();

    try {
      await _pc?.close();
    } catch (_) {}

    try {
      await _localStream?.dispose();
    } catch (_) {}

    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (_) {}

    _pc = null;
    _localStream = null;
  }
}
