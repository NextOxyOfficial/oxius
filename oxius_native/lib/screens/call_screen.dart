import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import '../services/agora_call_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/fcm_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final bool isIncoming;
  final String callType; // 'video' or 'audio'
  final bool isReturning;
  final bool autoAccept; // When true, skip accept UI and join immediately

  const CallScreen({
    super.key,
    required this.channelName,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    this.isIncoming = false,
    this.callType = 'video',
    this.isReturning = false,
    this.autoAccept = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with RouteAware, SingleTickerProviderStateMixin {
  ModalRoute<dynamic>? _route;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
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
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  bool _incomingAlertActive = false;
  bool _acceptanceSent = false;
  late final AnimationController _pulseController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      if (_route != null) {
        FCMService.routeObserver.unsubscribe(this);
      }
      _route = route;
      FCMService.routeObserver.subscribe(this, route);
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _localUid = AgoraCallService.generateUid();
    AgoraCallService.setCallScreenVisible(true);
    
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
    
    // If autoAccept is true (accepted from CallKit), skip ringtone and accept UI
    if (widget.autoAccept) {
      _callAccepted = true;
    } else if (widget.isIncoming) {
      // Only play ringtone if NOT auto-accepted (user needs to accept manually)
      _startIncomingAlert();
    }
    _initAgora();
  }

  @override
  void didPush() {
    AgoraCallService.setCallScreenVisible(true);
  }

  @override
  void didPopNext() {
    AgoraCallService.setCallScreenVisible(true);
  }

  @override
  void didPushNext() {
    AgoraCallService.setCallScreenVisible(false);
  }

  @override
  void didPop() {
    AgoraCallService.setCallScreenVisible(false);
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

  // Ringtone and vibration are now handled by CallKit natively
  Future<void> _startIncomingAlert() async {
    if (_incomingAlertActive || widget.autoAccept || !widget.isIncoming) {
      return;
    }

    _incomingAlertActive = true;

    try {
      await _ringtonePlayer.playRingtone(looping: true, asAlarm: false);
    } catch (_) {
      // Ignore ringtone failures and still try vibration.
    }

    try {
      if (await Vibration.hasVibrator()) {
        if (await Vibration.hasCustomVibrationsSupport()) {
          await Vibration.vibrate(pattern: const [0, 1200, 800], repeat: 0);
        } else {
          await Vibration.vibrate(duration: 1200);
        }
      }
    } catch (_) {
      // Ignore vibration failures.
    }
  }

  Future<void> _stopIncomingAlert() async {
    if (!_incomingAlertActive) {
      return;
    }

    _incomingAlertActive = false;

    try {
      await _ringtonePlayer.stop();
    } catch (_) {
      // Ignore ringtone stop failures.
    }

    try {
      await Vibration.cancel();
    } catch (_) {
      // Ignore vibration stop failures.
    }
  }

  Future<void> _initAgora() async {
    try {
      _engine = await AgoraCallService.initEngine(callType: widget.callType);
      
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

      // If incoming call, wait for accept (unless autoAccept). If outgoing, join immediately
      if (widget.isIncoming && !widget.autoAccept) {
        setState(() {
          _isConnecting = false;
        });
      } else if (widget.isIncoming && widget.autoAccept) {
        // Auto-accepted from CallKit - join channel immediately
        _notifyCallAccepted();
        await _joinChannel();
      } else {
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

        await _joinChannel();
      }
    } catch (e) {
      print('Error initializing Agora: $e');
      if (mounted) {
        final msg = e.toString().toLowerCase().contains('permission')
            ? 'Please allow microphone${widget.callType == 'video' ? ' and camera' : ''} permission to start the call.'
            : 'Unable to start call. Please check your connection.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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
      callType: widget.callType,
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
    _notifyCallAccepted();
    _stopIncomingAlert();
    FCMService.cancelCallNotification(); // Cancel the notification
    setState(() => _callAccepted = true);
    _joinChannel();
  }

  void _notifyCallAccepted() {
    if (!widget.isIncoming || _acceptanceSent) {
      return;
    }

    _acceptanceSent = true;
    AgoraCallService.sendCallStatus(
      receiverId: widget.calleeId,
      channelName: widget.channelName,
      status: 'accepted',
      callType: widget.callType,
    );
  }

  void _rejectCall() {
    _stopIncomingAlert();
    FCMService.cancelCallNotification(); // Cancel the notification
    // For incoming calls, calleeId is actually the caller who should be notified
    AgoraCallService.sendCallStatus(
      receiverId: widget.calleeId, // This is the caller for incoming calls
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
      // For incoming calls, notify the caller (calleeId is actually the caller)
      // For outgoing calls, notify the callee (calleeId is the actual callee)
      final receiverId = widget.isIncoming ? widget.calleeId : widget.calleeId;
      AgoraCallService.sendCallStatus(
        receiverId: receiverId,
        channelName: widget.channelName,
        status: localOutcome,
        callType: widget.callType,
      );
    }

    if (allowLog) {
      await _sendCallLog(localOutcome);
    }

    if (widget.isIncoming) {
      FCMService.releaseIncomingCallTracking(
        callerId: widget.calleeId,
        channelName: widget.channelName,
      );
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
    _isClosing = true;

    try {
      FCMService.routeObserver.unsubscribe(this);
    } catch (_) {
      // Ignore
    }

    _callStatusSub?.cancel();
    _callStatusSub = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    AgoraCallService.setCallScreenVisible(false);
    if (!_isMinimizing) {
      _stopIncomingAlert();
      if (widget.isIncoming) {
        FCMService.releaseIncomingCallTracking(
          callerId: widget.calleeId,
          channelName: widget.channelName,
        );
      }
      // If call was active and we're disposing without proper end, notify peer
      if (AgoraCallService.isInCall && _callStartedAt != null) {
        AgoraCallService.sendCallStatus(
          receiverId: widget.calleeId,
          channelName: widget.channelName,
          status: 'ended',
          callType: widget.callType,
        );
      }
      AgoraCallService.setInCall(false);
      AgoraCallService.leaveChannel();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _minimizeCall() {
    _isMinimizing = true;
    AgoraCallService.setCallScreenVisible(false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasRemoteVideo = _remoteUid != null && widget.callType == 'video';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        body: Stack(
          children: [
            _buildBackgroundLayer(),
            if (hasRemoteVideo) _buildRemoteVideoStage(),
            SafeArea(
              child: Stack(
                children: [
                  if (!hasRemoteVideo) _buildWaitingView(),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(hasRemoteVideo ? 0.16 : 0.02),
                              Colors.transparent,
                              Colors.black.withOpacity(0.38),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildTopPanel(),
                  if (_localUserJoined && widget.callType == 'video' && !_isCameraOff)
                    _buildLocalPreview(),
                  if (widget.isIncoming && !_callAccepted)
                    _buildIncomingCallUI(),
                  if (_statusOverlay != null)
                    _buildStatusOverlay(),
                  if (_callAccepted || !widget.isIncoming)
                    _buildCallControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 110, 24, 210),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCallTypeBadge(),
            const SizedBox(height: 28),
            _buildAnimatedAvatar(size: 156),
            const SizedBox(height: 30),
            Text(
              widget.calleeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _primaryStatusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.76),
                fontSize: 16,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            _buildSignalIndicator(),
            const SizedBox(height: 24),
            _buildGlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: [
                  _buildMetricTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Secure',
                    subtitle: 'Encrypted route',
                  ),
                  const SizedBox(width: 14),
                  _buildMetricTile(
                    icon: widget.callType == 'video' ? Icons.hd_rounded : Icons.graphic_eq_rounded,
                    title: widget.callType == 'video' ? 'HD Video' : 'Clear Audio',
                    subtitle: _callAccepted ? 'Live now' : 'Preparing stream',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingCallUI() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: _buildGlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Incoming ${_callModeLabel.toLowerCase()}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Answer now or decline this call',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              _buildSignalIndicator(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _buildIncomingActionCard(
                      label: 'Decline',
                      subtitle: 'Send unavailable',
                      icon: Icons.call_end_rounded,
                      color: const Color(0xFFFB7185),
                      onTap: _rejectCall,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildIncomingActionCard(
                      label: 'Accept',
                      subtitle: 'Join instantly',
                      icon: widget.callType == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                      color: _accentColor,
                      onTap: _acceptCall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    return Positioned(
      left: 18,
      right: 18,
      bottom: 20,
      child: _buildGlassPanel(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_callAccepted && _callStartedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Connected • ${_formatDuration(_callDuration)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildControlButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onTap: _toggleMute,
                    isActive: !_isMuted,
                  ),
                ),
                const SizedBox(width: 12),
                _buildEndCallButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    onTap: _toggleSpeaker,
                    isActive: _isSpeakerOn,
                  ),
                ),
              ],
            ),
            if (widget.callType == 'video') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildControlButton(
                      icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_outlined,
                      label: _isCameraOff ? 'Camera off' : 'Camera',
                      onTap: _toggleCamera,
                      isActive: !_isCameraOff,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.cameraswitch_rounded,
                      label: 'Switch',
                      onTap: _switchCamera,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isActive ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: isActive ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _accentColor {
    return widget.callType == 'video'
        ? const Color(0xFF38BDF8)
        : const Color(0xFF34D399);
  }

  Color get _accentGlowColor {
    return widget.callType == 'video'
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF0EA5E9);
  }

  String get _callModeLabel {
    return widget.callType == 'video' ? 'Video Call' : 'Voice Call';
  }

  String get _primaryStatusText {
    if (_statusOverlay != null) return _statusOverlay!;
    if (widget.isIncoming && !_callAccepted) {
      return 'Someone is trying to reach you right now.';
    }
    if (_isConnecting) {
      return 'Connecting through a secure ${widget.callType} channel.';
    }
    if (_callAccepted && _callStartedAt != null) {
      return 'Conversation is live and stable.';
    }
    return widget.isIncoming ? 'Preparing your incoming call interface.' : 'Ringing on the other side.';
  }

  Widget _buildBackgroundLayer() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = math.sin(_pulseController.value * math.pi * 2);
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF07111F),
                      Color(0xFF09162A),
                      Color(0xFF050816),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -120,
                left: -40,
                child: _buildAmbientOrb(
                  size: 280,
                  color: _accentColor.withOpacity(0.18 + (pulse.abs() * 0.05)),
                ),
              ),
              Positioned(
                top: 140,
                right: -60,
                child: _buildAmbientOrb(
                  size: 220,
                  color: _accentGlowColor.withOpacity(0.14 + (pulse.abs() * 0.04)),
                ),
              ),
              Positioned(
                bottom: -110,
                left: 30,
                child: _buildAmbientOrb(
                  size: 260,
                  color: Colors.white.withOpacity(0.06 + (pulse.abs() * 0.015)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemoteVideoStage() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: widget.channelName),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.28),
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPanel() {
    return Positioned(
      top: 14,
      left: 18,
      right: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildGlassPanel(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              borderRadius: BorderRadius.circular(26),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildAvatarImage(iconSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.calleeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _callAccepted && _callStartedAt != null
                              ? '${_callModeLabel.toUpperCase()} • ${_formatDuration(_callDuration)}'
                              : _callModeLabel.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isIncoming || _callAccepted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _accentColor.withOpacity(0.22)),
                      ),
                      child: Text(
                        _isConnecting ? 'SYNCING' : 'LIVE',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconChip(
            icon: Icons.minimize_rounded,
            onTap: _minimizeCall,
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview() {
    return Positioned(
      top: 96,
      right: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildGlassPanel(
            padding: const EdgeInsets.all(6),
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 116,
              height: 162,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.36),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'You',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey<String>(_statusOverlay!),
              child: _buildGlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withOpacity(0.92),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusOverlay!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.callType == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
            size: 16,
            color: _accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            _callModeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar({required double size}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulseA = 0.78 + (_pulseController.value * 0.24);
        final pulseB = 0.62 + (((_pulseController.value + 0.33) % 1) * 0.26);
        return SizedBox(
          width: size + 70,
          height: size + 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulseA,
                child: Container(
                  width: size + 48,
                  height: size + 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentColor.withOpacity(0.22), width: 1.5),
                  ),
                ),
              ),
              Transform.scale(
                scale: pulseB,
                child: Container(
                  width: size + 18,
                  height: size + 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accentGlowColor.withOpacity(0.2), width: 1.5),
                  ),
                ),
              ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.04),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.18),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAvatarImage(iconSize: size * 0.34),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarImage({required double iconSize}) {
    if (widget.calleeAvatar != null && widget.calleeAvatar!.isNotEmpty) {
      return Image.network(
        widget.calleeAvatar!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person_rounded,
          size: iconSize,
          color: Colors.white.withOpacity(0.72),
        ),
      );
    }

    return Icon(
      Icons.person_rounded,
      size: iconSize,
      color: Colors.white.withOpacity(0.72),
    );
  }

  Widget _buildSignalIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final wave = math.sin((_pulseController.value * math.pi * 2) + (index * 0.75));
            final height = 10 + ((wave + 1) * 9);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: index.isEven ? _accentColor : _accentGlowColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildIncomingActionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.28),
                color.withOpacity(0.14),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.26)),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.22),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _endCall(notifyPeer: true, allowLog: true),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFB7185),
                Color(0xFFDC2626),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFB7185).withOpacity(0.34),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(height: 6),
              Text(
                'End',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor.withOpacity(0.14),
              ),
              child: Icon(icon, size: 18, color: _accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.64),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    required EdgeInsetsGeometry padding,
    required BorderRadius borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildAmbientOrb({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
