import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora_call_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final bool isIncoming;
  final String callType; // 'video' or 'audio'

  const CallScreen({
    super.key,
    required this.channelName,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    this.isIncoming = false,
    this.callType = 'video',
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

  @override
  void initState() {
    super.initState();
    _localUid = AgoraCallService.generateUid();
    _initAgora();
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
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('Remote user left: $remoteUid');
            setState(() {
              _remoteUid = null;
            });
            // End call when remote user leaves
            _endCall();
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err - $msg');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Call error: $err - $msg'),
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
          final details = AgoraCallService.lastNotificationError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                details != null
                    ? 'Failed to notify recipient: $details'
                    : 'Failed to notify recipient',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error initializing Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize call: $e')),
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
      final details = AgoraCallService.lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(details != null ? 'Failed to join call: $details' : 'Failed to join call'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _acceptCall() {
    setState(() => _callAccepted = true);
    _joinChannel();
  }

  void _rejectCall() {
    Navigator.pop(context);
  }

  Future<void> _endCall() async {
    await AgoraCallService.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
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

  @override
  void dispose() {
    AgoraCallService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            // Call controls
            if (_callAccepted || !widget.isIncoming)
              _buildCallControls(),
          ],
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
              _isConnecting
                  ? 'Connecting...'
                  : _remoteUid == null
                      ? 'Calling...'
                      : 'Connected',
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
                onTap: _endCall,
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
