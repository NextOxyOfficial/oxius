import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import '../services/agora_call_service.dart';
import '../services/adsyconnect_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final bool isIncoming;
  final String callType; // 'video' or 'audio'
  final bool isReturning;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    this.isIncoming = false,
    this.callType = 'video',
    this.isReturning = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isConnecting = true;
  bool _callAccepted = false;
  late int _localUid;
  RtcEngine? _engine;

  StreamSubscription<Map<String, dynamic>>? _callStatusSub;
  Timer? _durationTimer;
  DateTime? _callStartedAt;
  Duration _callDuration = Duration.zero;
  String? _statusOverlay;
  bool _isClosing = false;
  bool _isMinimizing = false;

  @override
  void initState() {
    super.initState();
    _localUid = AgoraCallService.generateUid();
    
    if (widget.isReturning) {
      _localUserJoined = true;
      _callAccepted = true;
      _isConnecting = false;
      _engine = AgoraCallService.engine;
      _listenForCallStatus();
      _startCallTimer();
      return;
    }
    
    AgoraCallService.setInCall(true);
    AgoraCallService.setActiveCallInfo(
      channelName: widget.channelName,
      peerId: widget.calleeId,
      peerName: widget.calleeName,
      peerAvatar: widget.calleeAvatar,
      callType: widget.callType,
      isIncoming: widget.isIncoming,
    );
    _listenForCallStatus();
    if (widget.isIncoming) {
      _startIncomingAlert();
    }
    _initAgora();
  }

  void _listenForCallStatus() {
    _callStatusSub = AgoraCallService.callStatusStream.listen((data) {
      final type = data['type']?.toString();
      if (type != 'call_status') return;

      final channel = data['channel_name']?.toString();
      if (channel == null || channel != widget.channelName) return;

      final status = data['status']?.toString();
      if (status == null) return;

      if (!mounted) return;

      if (status == 'rejected') {
        _showOverlayAndClose('Call declined');
        _endCall(notifyPeer: false, allowLog: true, outcomeOverride: 'rejected');
      } else if (status == 'busy') {
        _showOverlayAndClose('User busy');
        _endCall(notifyPeer: false, allowLog: true, outcomeOverride: 'busy');
      } else if (status == 'cancelled') {
        _showOverlayAndClose('Call cancelled');
        _endCall(notifyPeer: false, allowLog: true, outcomeOverride: 'cancelled');
      } else if (status == 'ended') {
        _showOverlayAndClose('Call ended');
        _endCall(notifyPeer: false, allowLog: true, outcomeOverride: 'ended');
      }
    });
  }

  Future<void> _startIncomingAlert() async {
    try {
      FlutterRingtonePlayer().playRingtone(looping: true);
    } catch (_) {
      // Ignore
    }

    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 800, 600, 800], repeat: 0);
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _stopIncomingAlert() async {
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {
      // Ignore
    }

    try {
      Vibration.cancel();
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _initAgora() async {
    try {
      _engine = await AgoraCallService.initEngine();
      
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Local user joined: ${connection.localUid}');
            setState(() {
              _localUserJoined = true;
              _isConnecting = false;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user joined: $remoteUid');
            setState(() {
              _remoteUid = remoteUid;
              _callAccepted = true;
            });
            _startCallTimer();
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('Remote user left: $remoteUid');
            setState(() {
              _remoteUid = null;
            });
            // End call when remote user leaves
            _showOverlayAndClose('Call ended');
            _endCall(notifyPeer: false, allowLog: true);
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err - $msg');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_friendlyError(err)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );

      // If incoming call, wait for accept. If outgoing, join immediately
      if (widget.isIncoming) {
        setState(() {
          _isConnecting = false;
        });
      } else {
        await _joinChannel();
        // Send notification to callee
        final notified = await AgoraCallService.sendCallNotification(
          calleeId: widget.calleeId,
          channelName: widget.channelName,
          callType: widget.callType,
        );

        if (!notified && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not reach the recipient. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error initializing Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start call. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _joinChannel() async {
    setState(() => _isConnecting = true);

    print('CallScreen: join requested. channel=${widget.channelName} (len=${widget.channelName.length}), uid=$_localUid');

    final token = await AgoraCallService.generateToken(widget.channelName, _localUid);
    final success = await AgoraCallService.joinChannel(
      channelName: widget.channelName,
      uid: _localUid,
      token: token,
    );

    if (!success && mounted) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not join the call. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _acceptCall() {
    _stopIncomingAlert();
    setState(() => _callAccepted = true);
    _joinChannel();
  }

  void _rejectCall() {
    _stopIncomingAlert();
    AgoraCallService.sendCallStatus(
      receiverId: widget.calleeId,
      channelName: widget.channelName,
      status: 'rejected',
      callType: widget.callType,
    );
    _endCall(notifyPeer: false, allowLog: false);
  }

  Future<void> _endCall({required bool notifyPeer, required bool allowLog, String? outcomeOverride}) async {
    if (_isClosing) return;
    _isClosing = true;

    _durationTimer?.cancel();
    _durationTimer = null;

    await _stopIncomingAlert();

    final localOutcome = outcomeOverride ?? ((_callStartedAt != null) ? 'ended' : 'cancelled');

    if (notifyPeer) {
      AgoraCallService.sendCallStatus(
        receiverId: widget.calleeId,
        channelName: widget.channelName,
        status: localOutcome,
        callType: widget.callType,
      );
    }

    if (allowLog) {
      await _sendCallLog(localOutcome);
    }

    await AgoraCallService.leaveChannel();
    AgoraCallService.setInCall(false);
    if (mounted && _statusOverlay != null) {
      await Future.delayed(const Duration(milliseconds: 900));
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _startCallTimer() {
    if (_callStartedAt != null) return;
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

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  Future<void> _sendCallLog(String outcome) async {
    if (widget.isIncoming) return;

    final label = widget.callType == 'video' ? 'Video call' : 'Audio call';

    try {
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(widget.calleeId);
      final chatroomId = chatroom['id']?.toString();
      if (chatroomId == null || chatroomId.isEmpty) return;

      String text;
      if (outcome == 'ended' && _callStartedAt != null && _callDuration.inSeconds >= 1) {
        text = '📞 $label • ${_formatDuration(_callDuration)}';
      } else if (outcome == 'busy') {
        text = '📞 $label • Busy';
      } else if (outcome == 'rejected') {
        text = '📞 $label • Declined';
      } else if (outcome == 'cancelled') {
        text = '📞 $label • Cancelled';
      } else {
        text = '📞 $label • ${outcome[0].toUpperCase()}${outcome.substring(1)}';
      }

      await AdsyConnectService.sendTextMessage(
        chatroomId: chatroomId,
        receiverId: widget.calleeId,
        content: text,
      );
    } catch (_) {
      // Ignore
    }
  }

  void _showOverlayAndClose(String text) {
    if (!mounted) return;
    setState(() {
      _statusOverlay = text;
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    AgoraCallService.toggleMute(_isMuted);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    AgoraCallService.toggleCamera(!_isCameraOff);
  }

  void _switchCamera() {
    AgoraCallService.switchCamera();
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    AgoraCallService.toggleSpeaker(_isSpeakerOn);
  }

  String _friendlyError(ErrorCodeType err) {
    switch (err) {
      case ErrorCodeType.errNotInitialized:
        return 'Call service not ready. Please try again.';
      case ErrorCodeType.errInvalidToken:
      case ErrorCodeType.errTokenExpired:
        return 'Session expired. Please restart the app.';
      case ErrorCodeType.errConnectionLost:
      case ErrorCodeType.errConnectionInterrupted:
        return 'Connection lost. Please check your internet.';
      case ErrorCodeType.errJoinChannelRejected:
        return 'Could not join the call. Please try again.';
      case ErrorCodeType.errLeaveChannelRejected:
        return 'Could not leave the call properly.';
      case ErrorCodeType.errInvalidChannelName:
        return 'Invalid call session. Please try again.';
      case ErrorCodeType.errNoServerResources:
        return 'Server busy. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _callStatusSub?.cancel();
    _callStatusSub = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    if (!_isMinimizing) {
      _stopIncomingAlert();
      AgoraCallService.setInCall(false);
      AgoraCallService.leaveChannel();
    }
    super.dispose();
  }

  void _minimizeCall() {
    _isMinimizing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            if (_remoteUid != null && widget.callType == 'video')
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              )
            else
              _buildWaitingView(),

            // Local video (small preview)
            if (_localUserJoined && widget.callType == 'video' && !_isCameraOff)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),

            // Incoming call UI
            if (widget.isIncoming && !_callAccepted)
              _buildIncomingCallUI(),

            if (_callAccepted && _callStartedAt != null)
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),

            if (_statusOverlay != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          _statusOverlay!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Call controls
            if (_callAccepted || !widget.isIncoming)
              _buildCallControls(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
                border: Border.all(color: Colors.white24, width: 3),
              ),
              child: widget.calleeAvatar != null && widget.calleeAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.calleeAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white54,
                    ),
            ),
            const SizedBox(height: 24),
            // Name
            Text(
              widget.calleeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Status
            Text(
              _statusOverlay != null
                  ? _statusOverlay!
                  : _isConnecting
                      ? 'Connecting...'
                      : _remoteUid == null
                          ? 'Calling...'
                          : (_callStartedAt != null ? _formatDuration(_callDuration) : 'Connected'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            if (_isConnecting) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingCallUI() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: Column(
        children: [
          const Spacer(),
          // Avatar
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade800,
              border: Border.all(color: Colors.green.shade400, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: widget.calleeAvatar != null && widget.calleeAvatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.calleeAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 70,
                    color: Colors.white54,
                  ),
          ),
          const SizedBox(height: 32),
          // Name
          Text(
            widget.calleeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Incoming ${widget.callType} call...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const Spacer(),
          // Accept/Reject buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject
                GestureDetector(
                  onTap: _rejectCall,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                // Accept
                GestureDetector(
                  onTap: _acceptCall,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.callType == 'video' ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Secondary controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.callType == 'video') ...[
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  onTap: _toggleCamera,
                  isActive: !_isCameraOff,
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.cameraswitch,
                  onTap: _switchCamera,
                ),
                const SizedBox(width: 20),
              ],
              _buildControlButton(
                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                onTap: _toggleSpeaker,
                isActive: _isSpeakerOn,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mute
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                onTap: _toggleMute,
                isActive: !_isMuted,
                size: 60,
              ),
              const SizedBox(width: 40),
              // End call
              GestureDetector(
                onTap: () => _endCall(notifyPeer: true, allowLog: true),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = true,
    double size = 50,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isActive ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          size: size * 0.5,
        ),
      ),
    );
  }
}
