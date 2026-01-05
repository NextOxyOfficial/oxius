import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/adsy_call.dart';
import '../services/firebase_call_auth_service.dart';
import '../services/firestore_call_signaling_service.dart';
import '../services/webrtc_call_session.dart';

class AdsyCallScreen extends StatefulWidget {
  final bool isCaller;
  final String? callId;
  final String? otherUserId;
  final String? otherUserName;
  final AdsyCallType type;

  const AdsyCallScreen({
    super.key,
    required this.isCaller,
    this.callId,
    this.otherUserId,
    this.otherUserName,
    required this.type,
  });

  @override
  State<AdsyCallScreen> createState() => _AdsyCallScreenState();
}

class _AdsyCallScreenState extends State<AdsyCallScreen> {
  WebRtcCallSession? _session;
  String? _callId;
  bool _isLoading = true;
  bool _accepted = false;
  bool _didAutoClose = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _callId = widget.callId;
    _bootstrap();
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      if (widget.isCaller) {
        dev.log('[AdsyCallScreen] Starting as CALLER to ${widget.otherUserId}');
        
        final permOk = await _ensurePermissions();
        if (!permOk) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = 'Microphone/Camera permission denied. Please allow permission and try again.';
          });
          return;
        }

        final callee = widget.otherUserId;
        if (callee == null || callee.isEmpty) {
          setState(() {
            _isLoading = false;
            _error = 'Invalid callee id';
          });
          return;
        }

        dev.log('[AdsyCallScreen] Creating call to calleeId=$callee');
        final existingCallId = _callId;
        final callId = existingCallId ??
            await FirestoreCallSignalingService.instance.createCall(
              calleeId: callee,
              type: widget.type,
            );
        dev.log('[AdsyCallScreen] Call created: callId=$callId');

        if (!mounted) return;
        if (callId == null) {
          setState(() {
            _isLoading = false;
            _error = FirebaseCallAuthService.instance.lastError ?? 'Failed to create call';
          });
          return;
        }

        _callId = callId;

        final session = WebRtcCallSession(
          callId: callId,
          isCaller: true,
          type: widget.type,
        );
        _session = session;
        try {
          await session.initialize();
          await session.startAsCaller();
        } catch (e, st) {
          dev.log('[AdsyCallScreen] WebRTC init/start error: $e\n$st');
          try {
            await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.ended);
          } catch (_) {}
          rethrow;
        }

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _accepted = true;
        });
      } else {
        final callId = _callId;
        if (callId == null || callId.isEmpty) {
          setState(() {
            _isLoading = false;
            _error = 'Missing call id';
          });
          return;
        }

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, st) {
      dev.log('[AdsyCallScreen] Bootstrap error: $e\n$st');
      final callId = _callId;
      if (widget.isCaller && callId != null && callId.isNotEmpty) {
        try {
          await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.ended);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _bootstrap();
  }

  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return true;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    if (widget.type == AdsyCallType.video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return false;
    }

    return true;
  }

  Future<void> _acceptIncoming() async {
    final callId = _callId;
    if (callId == null) return;

    final permOk = await _ensurePermissions();
    if (!permOk) return;

    final session = WebRtcCallSession(
      callId: callId,
      isCaller: false,
      type: widget.type,
    );

    _session = session;

    setState(() {
      _accepted = true;
    });

    await session.initialize();
    await session.startAsCallee();
  }

  Future<void> _rejectIncoming() async {
    final callId = _callId;
    if (callId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    await FirestoreCallSignalingService.instance.updateCallState(callId, AdsyCallState.ended);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _endCall() async {
    final session = _session;
    if (session == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    await session.endCall();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final name = widget.otherUserName ?? widget.otherUserId ?? 'User';
    final error = _error;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Call failed',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: _retry,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 120,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (mounted) Navigator.pop(context);
                                  },
                                  child: const Text('Close'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
            : StreamBuilder<AdsyCallDoc?>(
                stream: _callId == null
                    ? Stream.empty()
                    : FirestoreCallSignalingService.instance.watchCall(_callId!),
                builder: (context, snap) {
                  final call = snap.data;
                  final state = call?.state ?? (widget.isCaller ? AdsyCallState.calling : AdsyCallState.ringing);

                  if (!_didAutoClose && state == AdsyCallState.ended) {
                    _didAutoClose = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) Navigator.pop(context);
                    });
                  }

                  final isVideo = widget.type == AdsyCallType.video;

                  return Stack(
                    children: [
                      if (isVideo && session != null) ...[
                        Positioned.fill(
                          child: RTCVideoView(session.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          width: 120,
                          height: 170,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RTCVideoView(session.localRenderer, mirror: true),
                          ),
                        ),
                      ] else ...[
                        Positioned.fill(
                          child: Container(
                            color: Colors.black,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: Colors.white.withOpacity(0.12),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      Positioned(
                        left: 16,
                        top: 12,
                        child: Text(
                          _labelForState(state),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: _buildControls(state, session),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  String _labelForState(AdsyCallState state) {
    switch (state) {
      case AdsyCallState.calling:
        return 'Calling...';
      case AdsyCallState.ringing:
        return 'Ringing...';
      case AdsyCallState.connected:
        return 'Connected';
      case AdsyCallState.ended:
        return 'Ended';
      case AdsyCallState.idle:
      default:
        return 'Idle';
    }
  }

  Widget _buildControls(AdsyCallState state, WebRtcCallSession? session) {
    if (!widget.isCaller && !_accepted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleButton(
            color: const Color(0xFFEF4444),
            icon: Icons.call_end,
            onTap: _rejectIncoming,
          ),
          const SizedBox(width: 18),
          _circleButton(
            color: const Color(0xFF10B981),
            icon: widget.type == AdsyCallType.video ? Icons.videocam : Icons.call,
            onTap: _acceptIncoming,
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (session != null)
          _circleButton(
            color: Colors.white.withOpacity(0.14),
            icon: session.micEnabled ? Icons.mic : Icons.mic_off,
            onTap: () async {
              await session.setMicEnabled(!session.micEnabled);
              if (mounted) setState(() {});
            },
          ),
        if (session != null)
          _circleButton(
            color: Colors.white.withOpacity(0.14),
            icon: session.speakerEnabled ? Icons.volume_up : Icons.volume_off,
            onTap: () async {
              await session.setSpeakerEnabled(!session.speakerEnabled);
              if (mounted) setState(() {});
            },
          ),
        if (widget.type == AdsyCallType.video && session != null)
          _circleButton(
            color: Colors.white.withOpacity(0.14),
            icon: session.cameraEnabled ? Icons.videocam : Icons.videocam_off,
            onTap: () async {
              await session.setCameraEnabled(!session.cameraEnabled);
              if (mounted) setState(() {});
            },
          ),
        if (widget.type == AdsyCallType.video && session != null)
          _circleButton(
            color: Colors.white.withOpacity(0.14),
            icon: Icons.cameraswitch,
            onTap: () async {
              await session.switchCamera();
            },
          ),
        _circleButton(
          color: const Color(0xFFEF4444),
          icon: Icons.call_end,
          onTap: _endCall,
        ),
      ],
    );
  }

  Widget _circleButton({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
