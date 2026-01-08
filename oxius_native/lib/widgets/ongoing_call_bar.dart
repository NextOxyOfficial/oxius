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
  DateTime? _callStartedAt;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _isInCall = AgoraCallService.isInCall;
    if (_isInCall) {
      _startTimer();
    }
    _callStateSub = AgoraCallService.callStateStream.listen((inCall) {
      if (!mounted) return;
      setState(() {
        _isInCall = inCall;
      });
      if (inCall && _callStartedAt == null) {
        _startTimer();
      } else if (!inCall) {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _callStartedAt = DateTime.now();
    _callDuration = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartedAt == null) return;
      setState(() {
        _callDuration = DateTime.now().difference(_callStartedAt!);
      });
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callStartedAt = null;
    _callDuration = Duration.zero;
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

    return GestureDetector(
      onTap: _returnToCall,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
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
                    Text(
                      peerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to return • ${_formatDuration(_callDuration)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Return',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
