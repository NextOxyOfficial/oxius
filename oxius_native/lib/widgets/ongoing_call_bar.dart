import 'dart:async';
import 'package:flutter/material.dart';
import '../services/agora_call_service.dart';
import '../services/fcm_service.dart';
import '../screens/call_screen.dart';

class OngoingCallBar extends StatefulWidget {
  const OngoingCallBar({super.key});

  @override
  State<OngoingCallBar> createState() => _OngoingCallBarState();
}

class _OngoingCallBarState extends State<OngoingCallBar> {
  StreamSubscription<bool>? _callStateSub;
  bool _isInCall = false;
  bool _isAccepted = false;
  DateTime? _callStartedAt;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _isInCall = AgoraCallService.isInCall;
    _syncFromActiveCallInfo();
    _callStateSub = AgoraCallService.callStateStream.listen((inCall) {
      if (!mounted) return;
      setState(() {
        _isInCall = inCall;
      });
      if (inCall) {
        _syncFromActiveCallInfo();
      } else {
        _stopTimer();
      }
    });
  }

  void _syncFromActiveCallInfo() {
    final info = AgoraCallService.activeCallInfo;
    _isAccepted = AgoraCallService.activeCallAccepted;
    final connectedAtMs = AgoraCallService.activeCallConnectedAtMs;
    if (info == null || connectedAtMs == null) {
      _stopTimer(resetCallState: false);
      return;
    }
    _startTimer(DateTime.fromMillisecondsSinceEpoch(connectedAtMs));
  }

  void _startTimer(DateTime startedAt) {
    _callStartedAt = startedAt;
    _callDuration = DateTime.now().difference(startedAt);
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartedAt == null) return;
      setState(() {
        _callDuration = DateTime.now().difference(_callStartedAt!);
      });
    });
  }

  void _stopTimer({bool resetCallState = true}) {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callStartedAt = null;
    _callDuration = Duration.zero;
    if (resetCallState) {
      _isAccepted = false;
    }
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(minutes)}:${two(seconds)}';
  }

  void _returnToCall() {
    final info = AgoraCallService.activeCallInfo;
    if (info == null) return;

    // Use the global navigator key to ensure navigation works from the app builder context
    final navigator = FCMService.navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: info['channelName'] ?? '',
          calleeId: info['peerId'] ?? '',
          calleeName: info['peerName'] ?? 'Unknown',
          calleeAvatar: info['peerAvatar'],
          callId: info['callId']?.toString(),
          isIncoming: info['isIncoming'] ?? false,
          callType: info['callType'] ?? 'video',
          isReturning: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _callStateSub?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide if not in call or if call screen is currently visible
    if (!_isInCall || AgoraCallService.isCallScreenVisible) return const SizedBox.shrink();

    final info = AgoraCallService.activeCallInfo;
    final peerName = info?['peerName'] ?? 'Ongoing call';
    final callType = info?['callType'] ?? 'video';
    final peerAvatar = info?['peerAvatar']?.toString();
    final subtitle = _callStartedAt != null
        ? '${_formatDuration(_callDuration)} • Tap to return'
        : (_isAccepted ? 'Connecting… tap to return' : 'Ringing… tap to return');

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _returnToCall,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF06223B), Color(0xFF0F3A63)],
                ),
                border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: peerAvatar != null && peerAvatar.isNotEmpty
                        ? Image.network(
                            peerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              callType == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : Icon(
                            callType == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _callStartedAt != null ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                peerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.76),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Back to call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
