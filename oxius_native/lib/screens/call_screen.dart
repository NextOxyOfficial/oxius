import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/agora_call_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/fcm_service.dart';
import 'inbox_screen.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final String? callId;
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
    this.callId,
    this.isIncoming = false,
    this.callType = 'video',
    this.isReturning = false,
    this.autoAccept = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with RouteAware, SingleTickerProviderStateMixin {
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
  StreamSubscription<int>? _localJoinSub;
  StreamSubscription<int>? _remoteJoinSub;
  StreamSubscription<int>? _remoteLeaveSub;
  StreamSubscription<String>? _engineErrorSub;
  Timer? _durationTimer;
  Timer? _ringingTimer;
  Timer? _outgoingRingbackTimer;
  Timer? _connectWatchdog;
  bool _rejoinAttempted = false;
  DateTime? _callStartedAt;
  Duration _callDuration = Duration.zero;
  String? _statusOverlay;
  bool _isClosing = false;
  bool _isMinimizing = false;
  bool _didEndCall = false;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  final AudioPlayer _outgoingTonePlayer = AudioPlayer();
  bool _incomingAlertActive = false;
  bool _acceptanceSent = false;
  late final AnimationController _pulseController;

  bool get _isCompactLayout => MediaQuery.sizeOf(context).height < 760;

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
    _enableWakelock();

    _bindServiceStreams();

    if (widget.isReturning) {
      _restoreActiveCallState();
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
      callId: widget.callId,
    );

    if (widget.autoAccept) {
      _callAccepted = true;
    } else if (widget.isIncoming) {
      unawaited(_startIncomingAlert());
    }

    // Start ringing timeout for outgoing calls — if the other party doesn't
    // pick up within 60 seconds, end the call automatically.
    if (!widget.isIncoming) {
      _startOutgoingRingback();
      _ringingTimer = Timer(const Duration(seconds: 60), () {
        if (!mounted || _didEndCall || _remoteUid != null) return;
        _showOverlayAndClose('No answer');
        unawaited(_endCall(
          notifyPeer: true,
          allowLog: true,
          outcomeOverride: 'missed',
        ));
      });
    }

    // Incoming ringing timeout — stop ringing 5 seconds before the caller's
    // 60-second timeout so the recipient never rings longer than the caller
    // waits.  This also prevents stale/ghost call screens from lingering.
    if (widget.isIncoming && !widget.autoAccept) {
      _ringingTimer = Timer(const Duration(seconds: 55), () {
        if (!mounted || _didEndCall || _callAccepted) return;
        _showOverlayAndClose('Missed call');
        unawaited(_endCall(
          notifyPeer: true,
          allowLog: false,
          outcomeOverride: 'missed',
        ));
      });
    }

    unawaited(_initializeCall());
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

  bool _wakelockEnabled = false;

  Future<void> _enableWakelock() async {
    if (_wakelockEnabled) return;
    try {
      await WakelockPlus.enable();
      _wakelockEnabled = true;
    } catch (e) {
      debugPrint('⚠️ Wakelock enable failed: $e');
    }
  }

  Future<void> _disableWakelock() async {
    if (!_wakelockEnabled) return;
    _wakelockEnabled = false;
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('⚠️ Wakelock disable failed: $e');
    }
  }

  void _bindServiceStreams() {
    _callStatusSub = AgoraCallService.callStatusStream.listen((data) {
      final type = data['type']?.toString();
      if (type != 'call_status') return;

      final channel = data['channel_name']?.toString();
      if (channel == null || channel != widget.channelName) return;

      final status = data['status']?.toString();
      if (status == null) return;

      if (!mounted) return;

      if (status == 'accepted') {
        _stopOutgoingRingback();
        setState(() {
          _callAccepted = true;
        });
        // Both sides have now committed — if media doesn't connect shortly,
        // self-heal with a one-shot re-join.
        _startConnectWatchdog();
        return;
      }

      if (_didEndCall) {
        return;
      }

      if (status == 'rejected' || status == 'declined') {
        _showOverlayAndClose('Call declined');
        unawaited(_endCall(
          notifyPeer: false,
          allowLog: !widget.isIncoming,
          outcomeOverride: 'rejected',
          closeImmediately: true,
        ));
      } else if (status == 'busy') {
        _showOverlayAndClose('User busy');
        unawaited(_endCall(
          notifyPeer: false,
          allowLog: !widget.isIncoming,
          outcomeOverride: 'busy',
          closeImmediately: true,
        ));
      } else if (status == 'cancelled' || status == 'missed') {
        _showOverlayAndClose('Call cancelled');
        unawaited(_endCall(
          notifyPeer: false,
          allowLog: !widget.isIncoming,
          outcomeOverride: 'cancelled',
          closeImmediately: true,
        ));
      } else if (status == 'ended' || status == 'failed') {
        _showOverlayAndClose('Call ended');
        unawaited(_endCall(
          notifyPeer: false,
          allowLog: !widget.isIncoming,
          outcomeOverride: 'ended',
          closeImmediately: true,
        ));
      }
    });

    _localJoinSub = AgoraCallService.localUserJoinedStream.listen((_) {
      if (!mounted) return;
      setState(() {
        _localUserJoined = true;
        _isConnecting = false;
      });
    });

    _remoteJoinSub =
        AgoraCallService.remoteUserJoinedStream.listen((remoteUid) {
      if (!mounted) return;
      _ringingTimer?.cancel();
      _ringingTimer = null;
      _cancelConnectWatchdog();
      _stopOutgoingRingback();
      setState(() {
        _remoteUid = remoteUid;
        _callAccepted = true;
        _isConnecting = false;
      });
      _startCallTimer();
    });

    _remoteLeaveSub = AgoraCallService.remoteUserLeftStream.listen((remoteUid) {
      if (!mounted || _didEndCall) return;
      // Only end the call when our KNOWN remote peer leaves.
      // If _remoteUid is null (peer never joined yet), ignore — this prevents
      // the call from ending prematurely due to stale Agora events.
      if (_remoteUid == null || remoteUid != _remoteUid) {
        return;
      }
      setState(() {
        _remoteUid = null;
      });
      _showOverlayAndClose('Call ended');
      unawaited(_endCall(
        notifyPeer: false,
        allowLog: !widget.isIncoming,
        outcomeOverride: 'ended',
      ));
    });

    _engineErrorSub = AgoraCallService.engineErrorStream.listen((message) {
      // Log the error for debugging but never expose raw Agora SDK messages
      // to the user — they are technical and unprofessional.
      debugPrint('🎤 Agora engine error (suppressed from UI): $message');

      // If the Agora connection completely failed/disconnected and the call
      // was never connected (still ringing), end the call gracefully.
      if (!_didEndCall &&
          _remoteUid == null &&
          message.contains('Connection lost')) {
        _showOverlayAndClose('Connection lost');
        unawaited(_endCall(
          notifyPeer: true,
          allowLog: !widget.isIncoming,
          outcomeOverride: 'failed',
        ));
      }
    });
  }

  void _restoreActiveCallState() {
    final info = AgoraCallService.activeCallInfo;
    _engine = AgoraCallService.engine;
    _localUserJoined = _engine != null;
    _callAccepted = AgoraCallService.activeCallAccepted;
    _isConnecting = !_callAccepted;
    _remoteUid = info?['remoteUid'] is int ? info!['remoteUid'] as int : null;

    final connectedAtMs = AgoraCallService.activeCallConnectedAtMs;
    if (connectedAtMs != null) {
      _isConnecting = false;
      _startCallTimer(
        connectedAt: DateTime.fromMillisecondsSinceEpoch(connectedAtMs),
        syncGlobalState: false,
      );
    }

    if (_engine == null) {
      unawaited(_resumeExistingChannelConnection());
    }
  }

  Future<void> _resumeExistingChannelConnection() async {
    await _enableWakelock();
    try {
      _engine = await AgoraCallService.initEngine(callType: widget.callType);
      await _joinChannel();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not restore the call. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

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

    // Race-condition guard: _stopIncomingAlert() may have been called while we
    // were awaiting playRingtone(). In that case stop() ran before the ringtone
    // actually started, so the ringtone would loop forever. Stop it now.
    if (!_incomingAlertActive) {
      try {
        await _ringtonePlayer.stop();
      } catch (_) {}
      return;
    }

    try {
      if (await Vibration.hasVibrator()) {
        if (!_incomingAlertActive) return; // stop requested during vibration check
        if (await Vibration.hasCustomVibrationsSupport()) {
          if (!_incomingAlertActive) return;
          await Vibration.vibrate(pattern: const [0, 1200, 800], repeat: 0);
        } else {
          if (!_incomingAlertActive) return;
          await Vibration.vibrate(duration: 1200);
        }
      }
    } catch (_) {
      // Ignore vibration failures.
    }
  }

  Future<void> _stopIncomingAlert() async {
    // Always stop unconditionally — calling stop() when nothing is playing is
    // safe and idempotent. Removing the early-return guard ensures the stop
    // call always reaches native audio even when _incomingAlertActive is false
    // (e.g. called before _startIncomingAlert completed its first await).
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

  void _startOutgoingRingback() {
    if (_outgoingRingbackTimer != null || widget.isIncoming) {
      return;
    }

    Future<void> playBeep() async {
      if (_didEndCall || _callAccepted || _remoteUid != null) {
        _stopOutgoingRingback();
        return;
      }
      try {
        await _outgoingTonePlayer.stop();
        await _outgoingTonePlayer.setAsset('assets/audio/adsy_call_tone.wav');
        await _outgoingTonePlayer.setVolume(0.55);
        unawaited(_outgoingTonePlayer.play());
      } catch (_) {
        try {
          await SystemSound.play(SystemSoundType.click);
        } catch (_) {
          // Ignore unavailable platform sounds.
        }
      }
    }

    unawaited(playBeep());
    _outgoingRingbackTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => unawaited(playBeep()));
  }

  void _stopOutgoingRingback() {
    _outgoingRingbackTimer?.cancel();
    _outgoingRingbackTimer = null;
    unawaited(_outgoingTonePlayer.stop());
  }

  Future<void> _initializeCall() async {
    try {
      // For incoming calls that are still ringing (user hasn't accepted yet) we
      // intentionally skip calling initEngine here.  Agora's enableAudio() claims
      // the Android audio session and preempts the STREAM_RING audio stream,
      // which causes the ringtone to be replaced by a system beep.  We only
      // initialise (and join) the engine once the user taps Accept.
      if (widget.isIncoming && !widget.autoAccept) {
        setState(() {
          _isConnecting = false;
        });
        return;
      }

      _engine = await AgoraCallService.initEngine(callType: widget.callType);

      if (widget.isIncoming && widget.autoAccept) {
        await _acceptCall();
      } else {
        final notified = await AgoraCallService.sendCallNotification(
          calleeId: widget.calleeId,
          channelName: widget.channelName,
          callType: widget.callType,
        );

        if (!notified) {
          _stopOutgoingRingback();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _formatCallStartError(
                  AgoraCallService.lastNotificationError,
                  fallback: 'Could not reach the recipient. Please try again.',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
          AgoraCallService.setInCall(false);
          return;
        }

        await _joinChannel();
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('permission_permanently_denied')) {
          final isMic = errStr.contains('microphone');
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isMic
                  ? 'Microphone Access Required'
                  : 'Camera Access Required'),
              content: Text(
                isMic
                    ? 'Microphone permission is blocked. Please go to Settings → AdsyClub → Microphone and enable it.'
                    : 'Camera permission is blocked. Please go to Settings → AdsyClub → Camera and enable it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        } else {
          final msg = errStr.toLowerCase().contains('permission')
              ? 'Please allow microphone${widget.callType == 'video' ? ' and camera' : ''} permission to start the call.'
              : _formatCallStartError(
                  AgoraCallService.lastError ??
                      AgoraCallService.lastNotificationError ??
                      errStr,
                  fallback:
                      'Unable to start call. Please check your connection.',
                );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _joinChannel() async {
    setState(() => _isConnecting = true);

    final success = await AgoraCallService.joinChannel(
      channelName: widget.channelName,
      uid: _localUid,
      callType: widget.callType,
    );

    // Keep a local reference so _restoreActiveCallState works if the user
    // minimizes and returns while on an incoming call that was accepted here.
    _engine ??= AgoraCallService.engine;

    if (!success && mounted) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _formatCallStartError(
              AgoraCallService.lastError,
              fallback: 'Could not join the call. Please try again.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      AgoraCallService.setInCall(false);
      Navigator.pop(context);
    }
  }

  Future<void> _acceptCall() async {
    if (_acceptanceSent) {
      return;
    }

    // 1. Notify caller immediately (fire-and-forget, no await).
    _notifyCallAccepted();

    // 2. Stop ringtone/vibration (fire-and-forget for instant UX).
    unawaited(_stopIncomingAlert());
    unawaited(FCMService.dismissVisibleCallUi(channelName: widget.channelName));

    // 3. Update UI immediately — show "Connecting…" state.
    if (!mounted) return;
    setState(() {
      _callAccepted = true;
      _isConnecting = true;
    });

    // 4. Start a safety timer — if the remote peer doesn't join within 30s
    //    after we accepted, the caller probably already left.
    _ringingTimer?.cancel();
    _ringingTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _didEndCall || _remoteUid != null) return;
      _showOverlayAndClose('Could not connect');
      unawaited(_endCall(
        notifyPeer: true,
        allowLog: widget.isIncoming,
        outcomeOverride: 'failed',
      ));
    });

    // 5. Now initialise the engine and join the channel.
    try {
      // Make sure the ringtone/vibration audio stream is fully released BEFORE
      // Agora claims the audio session. enableAudio() inside initEngine() grabs
      // the Android audio focus; if the looping ringtone is still playing the
      // two streams collide and the accepted call ends up with garbled or
      // missing audio (perceived as "the call didn't connect properly").
      await _stopIncomingAlert();
      _engine = await AgoraCallService.initEngine(callType: widget.callType);
      await _joinChannel();
      // We've accepted and joined — start the self-heal watchdog in case the
      // caller's media doesn't reach us within the grace window.
      _startConnectWatchdog();
    } catch (e) {
      _ringingTimer?.cancel();
      _ringingTimer = null;
      if (mounted) {
        final errStr = e.toString();
        unawaited(AgoraCallService.leaveChannel());
        AgoraCallService.setInCall(false);
        if (errStr.contains('permission_permanently_denied')) {
          final isMic = errStr.contains('microphone');
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isMic
                  ? 'Microphone Access Required'
                  : 'Camera Access Required'),
              content: Text(
                isMic
                    ? 'Microphone permission is blocked. Please go to Settings → AdsyClub → Microphone and enable it.'
                    : 'Camera permission is blocked. Please go to Settings → AdsyClub → Camera and enable it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        } else {
          final msg = errStr.toLowerCase().contains('permission')
              ? 'Please allow microphone${widget.callType == 'video' ? ' and camera' : ''} permission.'
              : 'Unable to join the call. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
          if (mounted) Navigator.of(context).pop();
        }
      }
    }
  }

  void _notifyCallAccepted() {
    if (!widget.isIncoming || _acceptanceSent) {
      return;
    }

    _acceptanceSent = true;
    AgoraCallService.markCallAccepted();
    AgoraCallService.sendCallStatus(
      receiverId: widget.calleeId,
      channelName: widget.channelName,
      status: 'accepted',
      callType: widget.callType,
      callId: widget.callId,
    );
  }

  Future<void> _rejectCall() async {
    // Guard re-entry — only reject once.
    if (_isClosing || _didEndCall) return;
    _isClosing = true;
    _didEndCall = true;

    // 1. Stop ringtone/vibration immediately (fire-and-forget).
    unawaited(_stopIncomingAlert());
    unawaited(FCMService.dismissVisibleCallUi(channelName: widget.channelName));

    // 2. Notify the caller in the background — don't block the UI.
    unawaited(AgoraCallService.sendCallStatus(
      receiverId: widget.calleeId,
      channelName: widget.channelName,
      status: 'rejected',
      callType: widget.callType,
      callId: widget.callId,
    ));

    // 3. Release incoming call tracking.
    if (widget.isIncoming) {
      FCMService.releaseIncomingCallTracking(
        callerId: widget.calleeId,
        channelName: widget.channelName,
      );
    }

    // 4. Clean up Agora state (engine is null for incoming — fast no-op).
    unawaited(AgoraCallService.leaveChannel());
    AgoraCallService.setInCall(false);

    // 5. Pop the screen immediately.
    _durationTimer?.cancel();
    _durationTimer = null;
    _ringingTimer?.cancel();
    _ringingTimer = null;
    _cancelConnectWatchdog();
    _stopOutgoingRingback();
    if (mounted) {
      _popCallScreen();
    }
  }

  Future<void> _endCall({
    required bool notifyPeer,
    required bool allowLog,
    String? outcomeOverride,
    bool closeImmediately = false,
  }) async {
    if (_isClosing || _didEndCall) return;
    _isClosing = true;
    _didEndCall = true;

    _durationTimer?.cancel();
    _durationTimer = null;
    _ringingTimer?.cancel();
    _ringingTimer = null;
    _cancelConnectWatchdog();

    unawaited(_stopIncomingAlert());
    unawaited(FCMService.dismissVisibleCallUi(channelName: widget.channelName));

    final localOutcome =
        outcomeOverride ?? ((_callStartedAt != null) ? 'ended' : 'cancelled');

    // Notify peer in background (fire-and-forget).
    if (notifyPeer) {
      unawaited(AgoraCallService.sendCallStatus(
        receiverId: widget.calleeId,
        channelName: widget.channelName,
        status: localOutcome,
        callType: widget.callType,
        callId: widget.callId,
      ));
    }

    // Log call in background (fire-and-forget).
    if (allowLog) {
      unawaited(_sendCallLog(localOutcome));
    }

    if (widget.isIncoming) {
      FCMService.releaseIncomingCallTracking(
        callerId: widget.calleeId,
        channelName: widget.channelName,
      );
    }

    // Clean up Agora state.
    unawaited(AgoraCallService.leaveChannel());
    AgoraCallService.setInCall(false);

    // Show brief overlay, then close the screen.
    if (!closeImmediately && mounted && _statusOverlay != null) {
      // Let the overlay paint for a short moment so the user sees "Call ended".
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (mounted) {
      _popCallScreen();
    }
  }

  void _showAdsyConnectInbox() {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const InboxScreen(initialTab: 0)),
    );
  }

  /// Shared helper to pop or replace the call screen.
  ///
  /// If the CallScreen was pushed on top of another screen (e.g. the chat
  /// interface), simply pop back to it so the user returns to the exact
  /// context they came from. Only fall back to the AdsyConnect inbox when
  /// the CallScreen is the root of the stack — this happens when the call
  /// was answered from a killed/locked-state CallKit notification, where
  /// there is no underlying chat screen to return to.
  void _popCallScreen() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    _showAdsyConnectInbox();
  }

  /// Self-heal watchdog: once a call is accepted by both sides, the media
  /// should connect within a couple of seconds. If no remote peer has appeared
  /// after a short grace period, our own channel join may have silently stalled
  /// (a transient token/network hiccup). Re-join ONCE before the longer
  /// "Could not connect" timeout gives up — this rescues calls that would
  /// otherwise sit on "Connecting…" forever.
  void _startConnectWatchdog() {
    if (_rejoinAttempted) return;
    _connectWatchdog?.cancel();
    _connectWatchdog = Timer(const Duration(seconds: 9), () async {
      if (!mounted ||
          _didEndCall ||
          _remoteUid != null ||
          _rejoinAttempted) {
        return;
      }
      _rejoinAttempted = true;
      final ok = await AgoraCallService.rejoinChannel(
        channelName: widget.channelName,
        uid: _localUid,
        callType: widget.callType,
      );
      debugPrint('🔁 Connect watchdog re-join attempted: $ok');
    });
  }

  void _cancelConnectWatchdog() {
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
  }

  void _startCallTimer({DateTime? connectedAt, bool syncGlobalState = true}) {
    if (_callStartedAt != null) return;
    _callStartedAt = connectedAt ?? DateTime.now();
    _callDuration = DateTime.now().difference(_callStartedAt!);
    if (syncGlobalState) {
      AgoraCallService.markCallConnected(_callStartedAt);
    }
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

  String _formatCallStartError(String? rawMessage, {required String fallback}) {
    final value = (rawMessage ?? '').trim();
    if (value.isEmpty) {
      return fallback;
    }

    final lower = value.toLowerCase();
    if (lower.contains('permission')) {
      return 'Please allow microphone${widget.callType == 'video' ? ' and camera' : ''} permission to start the call.';
    }
    if (lower.contains('session expired') || lower.contains('sign in again')) {
      return 'Your session expired. Please sign in again.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Call request timed out. Please check your connection and try again.';
    }
    if (lower.contains('recipient is unavailable')) {
      return 'Recipient is unavailable right now.';
    }
    if (lower.contains('service is unavailable')) {
      return 'Call service is unavailable right now. Please try again.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network error while starting the call. Please try again.';
    }
    if (lower.contains('invalid channel')) {
      return 'Invalid call session. Please try again.';
    }
    if (lower.contains('token')) {
      return 'Call session expired. Please try again.';
    }
    if (value.startsWith('{') ||
        value.startsWith('[') ||
        value.startsWith('<')) {
      return fallback;
    }
    if (value.length > 140) {
      return fallback;
    }
    return value;
  }

  Future<void> _sendCallLog(String outcome) async {
    if (widget.isIncoming) return;

    final label = widget.callType == 'video' ? 'Video call' : 'Audio call';

    try {
      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(widget.calleeId);
      final chatroomId = chatroom['id']?.toString();
      if (chatroomId == null || chatroomId.isEmpty) return;

      String text;
      if (outcome == 'ended' &&
          _callStartedAt != null &&
          _callDuration.inSeconds >= 1) {
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

  @override
  void dispose() {
    try {
      FCMService.routeObserver.unsubscribe(this);
    } catch (_) {
      // Ignore
    }

    _callStatusSub?.cancel();
    _localJoinSub?.cancel();
    _remoteJoinSub?.cancel();
    _remoteLeaveSub?.cancel();
    _engineErrorSub?.cancel();
    _durationTimer?.cancel();
    _ringingTimer?.cancel();
    _cancelConnectWatchdog();
    _stopOutgoingRingback();
    AgoraCallService.setCallScreenVisible(false);

    // CRITICAL: Only tear down the Agora session when the user has explicitly
    // ended the call (_didEndCall) OR when there is no active call to preserve.
    // If _didEndCall is false and a call is still active, the user has merely
    // navigated away from the CallScreen — we must keep the Agora engine,
    // channel, and remote stream alive so audio/video continues and so the
    // CallScreen can be restored via OngoingCallBar with isReturning=true.
    // Releasing the channel here would prematurely end the call for the peer.
    final shouldTeardown = _didEndCall || !AgoraCallService.isInCall;

    if (shouldTeardown) {
      unawaited(_stopIncomingAlert());
      if (widget.isIncoming) {
        FCMService.releaseIncomingCallTracking(
          callerId: widget.calleeId,
          channelName: widget.channelName,
        );
      }

      if (!_didEndCall && AgoraCallService.isInCall) {
        final status = _callStartedAt != null ? 'ended' : 'cancelled';
        unawaited(AgoraCallService.sendCallStatus(
          receiverId: widget.calleeId,
          channelName: widget.channelName,
          status: status,
          callType: widget.callType,
          callId: widget.callId,
        ));
      }

      unawaited(AgoraCallService.leaveChannel());
      AgoraCallService.setInCall(false);
      unawaited(_disableWakelock());
    } else {
      // Call is being minimized / backgrounded — keep Agora alive, keep the
      // wakelock active so video/audio stays awake while in the background
      // (this matches WhatsApp/Telegram behaviour).
      debugPrint(
          '📞 CallScreen disposed while call still active — preserving engine for background continuity');
    }

    _pulseController.dispose();
    unawaited(_outgoingTonePlayer.dispose());
    super.dispose();
  }

  void _minimizeCall() {
    // Guard against being called twice (e.g. back button + minimize button race)
    if (_isMinimizing) return;
    _isMinimizing = true;
    AgoraCallService.setCallScreenVisible(false);

    // Always minimize back to AdsyConnect instead of revealing unrelated
    // routes that may be sitting under the call screen.
    _showAdsyConnectInbox();
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
                              Colors.black
                                  .withValues(alpha: hasRemoteVideo ? 0.16 : 0.02),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.38),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildTopPanel(),
                  if (_localUserJoined &&
                      widget.callType == 'video' &&
                      !_isCameraOff)
                    _buildLocalPreview(),
                  if (widget.isIncoming && !_callAccepted)
                    _buildIncomingCallUI(),
                  if (_statusOverlay != null) _buildStatusOverlay(),
                  if (_callAccepted || !widget.isIncoming) _buildCallControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    final compact = _isCompactLayout;
    final bottomReserved = widget.isIncoming && !_callAccepted
        ? (compact ? 210.0 : 248.0)
        : (compact ? 150.0 : 188.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(24, compact ? 90 : 104, 24, bottomReserved),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    math.max(0, constraints.maxHeight - (compact ? 170 : 206)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCallTypeBadge(),
                  SizedBox(height: compact ? 20 : 24),
                  _buildAnimatedAvatar(size: compact ? 116 : 138),
                  SizedBox(height: compact ? 18 : 24),
                  Text(
                    widget.calleeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 26 : 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Text(
                    _primaryStatusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: compact ? 14 : 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildInfoPill(
                        icon: Icons.lock_outline_rounded,
                        label: 'Secure call',
                      ),
                      _buildInfoPill(
                        icon: widget.callType == 'video'
                            ? Icons.videocam_outlined
                            : Icons.call_outlined,
                        label: widget.callType == 'video'
                            ? 'Video ready'
                            : 'Voice ready',
                      ),
                      if (_callAccepted && _callStartedAt != null)
                        _buildInfoPill(
                          icon: Icons.schedule_rounded,
                          label: _formatDuration(_callDuration),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingCallUI() {
    final compact = _isCompactLayout;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, compact ? 14 : 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _buildGlassPanel(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 20,
              compact ? 18 : 20,
              compact ? 18 : 20,
              compact ? 16 : 18,
            ),
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Incoming ${_callModeLabel.toLowerCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer now or decline the call.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 17 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 18 : 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildIncomingResponseButton(
                        label: 'Decline',
                        icon: Icons.call_end_rounded,
                        backgroundColor: const Color(0xFFEF4444),
                        onTap: _rejectCall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildIncomingResponseButton(
                        label: 'Accept',
                        icon: widget.callType == 'video'
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        backgroundColor: _accentColor,
                        onTap: _acceptCall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls() {
    final compact = _isCompactLayout;
    final isVideo = widget.callType == 'video';
    final hPad = compact ? 10.0 : 14.0;
    final endSize = compact ? 62.0 : 68.0;
    final btnSize = compact ? 52.0 : 56.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: compact ? 16 : 24,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: hPad, vertical: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoundControl(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                size: btnSize,
                isActive: _isMuted,
                activeBg: const Color(0xFFEF4444),
                onTap: _toggleMute,
              ),
              SizedBox(width: compact ? 8 : 10),
              _buildRoundControl(
                icon: _isSpeakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                size: btnSize,
                isActive: _isSpeakerOn,
                activeBg: _accentColor,
                onTap: _toggleSpeaker,
              ),
              if (isVideo) ...[
                SizedBox(width: compact ? 8 : 10),
                _buildRoundControl(
                  icon: _isCameraOff
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  size: btnSize,
                  isActive: _isCameraOff,
                  activeBg: const Color(0xFFEF4444),
                  onTap: _toggleCamera,
                ),
                SizedBox(width: compact ? 8 : 10),
                _buildRoundControl(
                  icon: Icons.cameraswitch_rounded,
                  size: btnSize,
                  isActive: false,
                  onTap: _switchCamera,
                ),
              ],
              SizedBox(width: compact ? 10 : 12),
              _buildRoundControl(
                icon: Icons.call_end_rounded,
                size: endSize,
                isActive: true,
                activeBg: const Color(0xFFEF4444),
                iconColor: Colors.white,
                onTap: () => unawaited(_endCall(
                  notifyPeer: true,
                  allowLog: true,
                  closeImmediately: true,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundControl({
    required IconData icon,
    required double size,
    required bool isActive,
    Color? activeBg,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final bg = isActive
        ? (activeBg ?? Colors.white).withValues(alpha: activeBg != null ? 1 : 0.22)
        : Colors.white.withValues(alpha: 0.14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(
              color: Colors.white.withValues(alpha: isActive ? 0.0 : 0.14),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: size * 0.42,
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

  String get _callModeLabel {
    return widget.callType == 'video' ? 'Video Call' : 'Voice Call';
  }

  String get _primaryStatusText {
    if (_statusOverlay != null) return _statusOverlay!;
    if (widget.isIncoming && !_callAccepted) {
      return 'Ready to answer this call.';
    }
    if (_callAccepted && _callStartedAt != null) {
      return 'Connected and stable.';
    }
    if (_isConnecting) {
      if (_callAccepted) {
        return 'Connecting the call...';
      }
      return widget.isIncoming
          ? 'Joining the call...'
          : 'Ringing on the other side.';
    }
    return widget.isIncoming ? 'Incoming call' : 'Calling now.';
  }

  Widget _buildBackgroundLayer() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.callType == 'video'
                ? const [
                    Color(0xFF172554),
                    Color(0xFF111827),
                    Color(0xFF030712),
                  ]
                : const [
                    Color(0xFF064E3B),
                    Color(0xFF0F172A),
                    Color(0xFF030712),
                  ],
          ),
        ),
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
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPanel() {
    final compact = _isCompactLayout;
    final hasRemoteVideo = _remoteUid != null && widget.callType == 'video';
    final subtitle = _callAccepted && _callStartedAt != null
        ? _formatDuration(_callDuration)
        : _isConnecting
            ? (widget.isIncoming ? 'Incoming…' : 'Calling…')
            : 'In call';

    // Slim pill for active video call to keep the opponent's video unobstructed;
    // fuller header while waiting (audio call or pre-connect).
    if (hasRemoteVideo) {
      return Positioned(
        top: compact ? 8 : 12,
        left: 14,
        right: 14,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.calleeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildIconChip(
              icon: Icons.minimize_rounded,
              onTap: _minimizeCall,
            ),
          ],
        ),
      );
    }

    return Positioned(
      top: compact ? 8 : 14,
      left: 18,
      right: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildGlassPanel(
              padding: EdgeInsets.fromLTRB(compact ? 12 : 14, compact ? 12 : 14,
                  compact ? 12 : 14, compact ? 12 : 14),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: [
                  Container(
                    width: compact ? 40 : 46,
                    height: compact ? 40 : 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 15 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _callAccepted && _callStartedAt != null
                              ? '${_callModeLabel.toUpperCase()} • ${_formatDuration(_callDuration)}'
                              : _primaryStatusText.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
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
    final compact = _isCompactLayout;
    return Positioned(
      top: compact ? 82 : 96,
      right: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildGlassPanel(
            padding: const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: compact ? 92 : 108,
              height: compact ? 128 : 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.46),
                        borderRadius: BorderRadius.circular(12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.92),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.callType == 'video'
                ? Icons.videocam_rounded
                : Icons.call_rounded,
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
        final pulse = Curves.easeOut.transform(_pulseController.value);
        return SizedBox(
          width: size + 42,
          height: size + 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.2 * (1 - pulse),
                child: Container(
                  width: size + 34 + (pulse * 20),
                  height: size + 34 + (pulse * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _accentColor.withValues(alpha: 0.7), width: 1.6),
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
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      spreadRadius: 4,
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
          color: Colors.white.withValues(alpha: 0.72),
        ),
      );
    }

    return Icon(
      Icons.person_rounded,
      size: iconSize,
      color: Colors.white.withValues(alpha: 0.72),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accentColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingResponseButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: _isCompactLayout ? 12 : 14,
            vertical: _isCompactLayout ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: backgroundColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: _isCompactLayout ? 20 : 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isCompactLayout ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    required EdgeInsetsGeometry padding,
    required BorderRadius borderRadius,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: const Color(0xFF0F172A).withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF0F172A).withValues(alpha: 0.72),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
