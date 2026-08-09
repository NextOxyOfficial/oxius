import 'dart:async';

import 'package:async/async.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io' show Platform;

import 'package:livekit_client/livekit_client.dart' as lk;

import '../services/agora_call_service.dart';
import '../services/auth_service.dart';
import '../services/livekit_call_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/fcm_service.dart';
import '../widgets/call/add_participant_sheet.dart';
import '../widgets/call/call_banners.dart';
import '../widgets/call/call_chrome.dart';
import '../widgets/call/call_controls_bar.dart';
import 'inbox_screen.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// The audio-to-video handshake. An upgrade needs both sides to agree — the
/// other person may be somewhere they would rather not be seen.
enum _VideoUpgrade { idle, asked, invited }

/// The states a call passes through, in the order the user experiences them.
enum _CallStage {
  incoming,
  ringing,
  connecting,
  connected,
  reconnecting,
  unreachable,
  ended,
}

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

  /// Set when this call is ringing a whole group chat rather than one person.
  ///
  /// Only the outgoing side needs it: the ring goes to every member at once
  /// through a different endpoint, and the header says the group's name
  /// instead of one member's. Everything after the ring is identical — a
  /// group call is the same CallSession with participants attached.
  final String? groupId;
  final String? groupName;

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
    this.groupId,
    this.groupName,
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
  bool _proxyAttempted = false;
  bool _recoveryInFlight = false;
  DateTime? _callStartedAt;
  Duration _callDuration = Duration.zero;
  String? _statusOverlay;

  /// "Someone left the call" and the like — shown briefly, then gone.
  String? _transientNote;
  Timer? _transientNoteTimer;

  /// Which member of a group took the callee slot on the server.
  ///
  /// A status event is still addressed to one person — that is the shape of
  /// the endpoint — and the server fans it out to everyone else on the call
  /// from there. For a group there is no widget.calleeId to use, so the
  /// server names one when the call starts.
  String? _groupPrimaryCalleeId;
  bool _isClosing = false;
  bool _isMinimizing = false;
  bool _didEndCall = false;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  final AudioPlayer _outgoingTonePlayer = AudioPlayer();
  bool _incomingAlertActive = false;
  bool _acceptanceSent = false;
  bool _isReconnecting = false;
  StreamSubscription<bool>? _reconnectingSub;
  StreamSubscription<Map<String, dynamic>>? _signalSub;
  StreamSubscription<void>? _tracksSub;
  StreamSubscription<bool>? _poorConnectionSub;
  StreamSubscription<bool>? _callStateSub;
  bool _hasPoorConnection = false;
  late final AnimationController _pulseController;

  /// The call's current mode. Starts as whatever the call was placed as, and
  /// becomes 'video' if the two sides agree to upgrade mid-call — which is why
  /// it is state and not `widget.callType`.
  late String _callType;

  /// Where the audio-to-video handshake stands.
  _VideoUpgrade _upgrade = _VideoUpgrade.idle;
  Timer? _upgradeTimeout;

  /// Where the user has dragged the self-view to, as a fraction of the free
  /// space in each axis. Fractions rather than pixels so the preview keeps its
  /// corner across a rotation or a keyboard resize.
  Alignment _selfViewAlignment = const Alignment(1, -1);
  Offset? _selfViewDragOrigin;

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
    _callType = widget.callType;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
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
      callType: _callType,
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

      // One person out of several leaving. Not the end of anything — the
      // media layer drops their tile on its own, and the rest keep talking.
      if (status == 'participant_left') {
        final who = data['left_user_name']?.toString().trim() ?? '';
        if (who.isNotEmpty) _showTransientNote('$who left the call');
        return;
      }

      // The same protection one level down, for a terminal status that
      // somehow arrives while other people are still connected. Whoever sent
      // it is speaking for themselves; the call is over when the last person
      // goes, and the remote-leave handler above is what decides that.
      if (_peers.isNotEmpty) {
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
        _showOverlayAndClose('User is busy');
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

    _localJoinSub = _localJoinedStream.listen((_) {
      if (!mounted) return;
      setState(() {
        _localUserJoined = true;
        _isConnecting = false;
      });
    });

    _remoteJoinSub = _remoteJoinedStream.listen((remoteUid) {
      if (!mounted) return;
      _ringingTimer?.cancel();
      _ringingTimer = null;
      _cancelConnectWatchdog();
      _stopOutgoingRingback();
      setState(() {
        // The first peer to arrive stays the "primary" one the timers and
        // watchdogs are written against. A third person joining a group call
        // must not overwrite it, or their leaving would look like the call
        // itself ending.
        _remoteUid ??= remoteUid;
        _callAccepted = true;
        _isConnecting = false;
      });
      _startCallTimer();
      // The one moment that proves the media path works end to end.
      unawaited(AgoraCallService.reportMediaConnected(
        channelName: widget.channelName,
        callId: widget.callId,
      ));
    });

    _remoteLeaveSub = _remoteLeftStream.listen((remoteUid) {
      if (!mounted || _didEndCall) return;
      // If _remoteUid is null (peer never joined yet), ignore — this prevents
      // the call from ending prematurely due to stale engine events.
      if (_remoteUid == null) return;

      // A call is over when the last other person has gone, not when a
      // particular one has. In a group call the person who started it can
      // drop out while three others carry on talking.
      final remaining = _peers;
      if (remaining.isNotEmpty) {
        setState(() {
          if (remoteUid == _remoteUid) _remoteUid = remaining.first.uid;
        });
        return;
      }
      if (remoteUid != _remoteUid) return;

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

    _isReconnecting = LiveKitCallService.isReconnecting;
    _reconnectingSub = LiveKitCallService.reconnectingStream.listen((value) {
      if (!mounted) return;
      setState(() => _isReconnecting = value);
    });

    _signalSub = LiveKitCallService.signalStream.listen(_handleInCallSignal);

    _poorConnectionSub = LiveKitCallService.poorConnectionStream.listen((poor) {
      if (!mounted) return;
      setState(() => _hasPoorConnection = poor);
    });

    // The call can be ended from outside this screen — the "End call" action on
    // the ongoing-call notification. When that happens the screen has to go,
    // and it has no other way of finding out.
    _callStateSub = AgoraCallService.callStateStream.listen((inCall) {
      if (!mounted || inCall || _didEndCall || _isClosing) return;
      _markScreenClosing();
      _durationTimer?.cancel();
      _cancelConnectWatchdog();
      _popCallScreen();
    });

    // A camera coming on or going off at either end changes what there is to
    // render, and nothing else would tell this screen to look again.
    _tracksSub = LiveKitCallService.videoTracksChangedStream.listen((_) {
      if (mounted) setState(() {});
    });

    _engineErrorSub = _engineErrorStream.listen((message) {
      // Log the error for debugging but never expose raw Agora SDK messages
      // to the user — they are technical and unprofessional.
      debugPrint('🎤 Agora engine error (suppressed from UI): $message');

      // If the Agora connection completely failed/disconnected and the call
      // was never connected (still ringing), end the call gracefully.
      // "Connection lost" BEFORE anyone connected is not a reason to hang up
      // — it is the signal that our media path never came up. Killing the
      // call here (which is what used to happen, ~9s after accept — the
      // production log is full of failed/dur=9 rows) also killed the 14s
      // self-heal watchdog before it could ever run, so the one recovery
      // mechanism in this screen was dead in exactly the case it was
      // written for. Escalate instead; only give up when the ladder is done.
      if (!_didEndCall &&
          _remoteUid == null &&
          message.contains('Connection lost')) {
        unawaited(_escalateConnectRecovery('connection-lost'));
        return;
      }

      // Lost AFTER we were connected is a genuine drop — end it.
      if (!_didEndCall &&
          _remoteUid != null &&
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
    // "Already in the room?" — the SFU connection is the only truth now that
    // there is no engine object to hold on to.
    _localUserJoined = LiveKitCallService.isConnected;
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

    if (!LiveKitCallService.isConnected) {
      unawaited(_resumeExistingChannelConnection());
    }
  }

  Future<void> _resumeExistingChannelConnection() async {
    await _enableWakelock();
    try {
      // LiveKit builds its room inside joinChannel — nothing to spin up first.
      await _joinChannel();
    } catch (_) {
      if (!mounted) return;
      AdsyToast.error(context, 'Could not restore the call. Please try again.');
      _markScreenClosing();
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
        // stop requested during vibration check
        if (!_incomingAlertActive) return;
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

      // NOT initEngine() here. Building the engine before the first token
      // fetch means it is created from whatever App ID happens to be known,
      // and on a push-woken cold start that is nothing at all — producing an
      // engine that belongs to no project and can never carry audio.
      // joinChannel() fetches the token (which carries the App ID) and then
      // builds the engine in the right order; _acceptCall does the same.
      if (widget.isIncoming && widget.autoAccept) {
        await _acceptCall();
      } else {
        // A group call rings every member through one endpoint; the server
        // reports back which of them took the callee slot, and status events
        // are addressed there before it fans them out to the rest.
        final bool notified;
        if (widget.groupId != null) {
          final primary = await AgoraCallService.startGroupCall(
            groupId: widget.groupId!,
            channelName: widget.channelName,
            callType: _callType,
          );
          notified = primary != null;
          if (primary != null) _groupPrimaryCalleeId = primary;
        } else {
          notified = await AgoraCallService.sendCallNotification(
            calleeId: widget.calleeId,
            channelName: widget.channelName,
            callType: _callType,
          );
        }

        if (!notified) {
          _stopOutgoingRingback();
          if (!mounted) return;
          AdsyToast.error(
            context,
            _formatCallStartError(
              AgoraCallService.lastNotificationError,
              fallback: 'Could not reach the recipient. Please try again.',
            ),
          );
          _markScreenClosing();
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
          _markScreenClosing();
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isMic
                  ? 'Microphone permission needed'
                  : 'Camera permission needed'),
              content: Text(
                isMic
                    ? 'Microphone access is off. Turn it on in Settings -> AdsyClub -> Microphone.'
                    : 'Camera access is off. Turn it on in Settings -> AdsyClub -> Camera.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Not now'),
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
              ? 'Allow microphone${_callType == 'video' ? ' and camera' : ''} access to start the call.'
              : _formatCallStartError(
                  AgoraCallService.lastError ??
                      AgoraCallService.lastNotificationError ??
                      errStr,
                  fallback:
                      'Could not start the call. Check your internet connection.',
                );
          AdsyToast.error(context, msg);
          _markScreenClosing();
          Navigator.pop(context);
        }
      }
    }
  }

  /// Which media engine this call uses. Read once when the screen is built
  /// so a call cannot change engines halfway through, and so the answer is
  /// already known — the provider is fetched at app start.
  /// Which media engine this call uses.
  ///
  /// Seeded from whatever is already known so the UI has an answer
  /// immediately, then CONFIRMED with the server right before joining. It
  /// cannot be decided once at build time: a call that wakes a killed app
  /// builds this screen before the startup provider fetch has finished, and
  /// the stale default made the callee join a different server than the
  /// caller — the call rang, was accepted, and never connected.

  // Merged: the engine that is not in use never emits, and merging removes
  // any dependence on knowing which one that is at subscribe time.
  Stream<int> get _localJoinedStream => StreamGroup.merge([
        LiveKitCallService.localUserJoinedStream,
        AgoraCallService.localUserJoinedStream,
      ]);

  // Merged: the engine that is not in use never emits, and merging removes
  // any dependence on knowing which one that is at subscribe time.
  Stream<int> get _remoteJoinedStream => StreamGroup.merge([
        LiveKitCallService.remoteUserJoinedStream,
        AgoraCallService.remoteUserJoinedStream,
      ]);

  // Merged: the engine that is not in use never emits, and merging removes
  // any dependence on knowing which one that is at subscribe time.
  Stream<int> get _remoteLeftStream => StreamGroup.merge([
        LiveKitCallService.remoteUserLeftStream,
        AgoraCallService.remoteUserLeftStream,
      ]);

  Stream<String> get _engineErrorStream => StreamGroup.merge([
        LiveKitCallService.engineErrorStream,
        AgoraCallService.engineErrorStream,
      ]);

  String? get _engineLastError => LiveKitCallService.lastError;

  Future<bool> _engineJoin() => LiveKitCallService.joinChannel(
        channelName: widget.channelName,
        callType: _callType,
        callId: widget.callId,
      );

  Future<void> _engineLeave() => LiveKitCallService.leaveChannel();

  Future<void> _joinChannel() async {
    setState(() => _isConnecting = true);

    final success = await _engineJoin();

    // Keep a local reference so _restoreActiveCallState works if the user
    // minimizes and returns while on an incoming call that was accepted here.

    if (!success && mounted) {
      setState(() => _isConnecting = false);
      AdsyToast.error(
        context,
        _formatCallStartError(
          _engineLastError,
          fallback: 'Could not join the call. Please try again.',
        ),
      );
      _markScreenClosing();
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
    // iOS: the CallKit call must OUTLIVE the accept — CallKit owns the audio
    // session, and ending it here tears that session down under Agora. This
    // is the same defect _handleCallAccepted had; this path had it too.
    unawaited(FCMService.dismissVisibleCallUi(
      channelName: widget.channelName,
      endCallKit: !Platform.isIOS,
    ));

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
      // joinChannel fetches the token FIRST — which is what carries the App
      // ID — and builds the engine from it. Calling initEngine here instead
      // built the engine from whatever App ID was known at accept time,
      // which on a push-woken cold start is none.
      await _joinChannel();
      // We've accepted and joined — start the self-heal watchdog in case the
      // caller's media doesn't reach us within the grace window.
      _startConnectWatchdog();
    } catch (e) {
      _ringingTimer?.cancel();
      _ringingTimer = null;
      if (mounted) {
        final errStr = e.toString();
        unawaited(_engineLeave());
        _markScreenClosing();
        AgoraCallService.setInCall(false);
        if (errStr.contains('permission_permanently_denied')) {
          final isMic = errStr.contains('microphone');
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isMic
                  ? 'Microphone permission needed'
                  : 'Camera permission needed'),
              content: Text(
                isMic
                    ? 'Microphone access is off. Turn it on in Settings -> AdsyClub -> Microphone.'
                    : 'Camera access is off. Turn it on in Settings -> AdsyClub -> Camera.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Not now'),
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
              ? 'Allow microphone${_callType == 'video' ? ' and camera' : ''} access.'
              : 'Could not join the call. Please try again.';
          AdsyToast.error(context, msg);
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
      receiverId: _statusReceiverId,
      channelName: widget.channelName,
      status: 'accepted',
      callType: _callType,
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
      receiverId: _statusReceiverId,
      channelName: widget.channelName,
      status: 'rejected',
      callType: _callType,
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
    unawaited(_engineLeave());
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

    if (_callStartedAt != null) {
      unawaited(HapticFeedback.lightImpact());
    }

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
        receiverId: _statusReceiverId,
        channelName: widget.channelName,
        status: localOutcome,
        callType: _callType,
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
    unawaited(_engineLeave());
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

  /// Records that this screen is closing itself.
  ///
  /// The call-state listener exists to close the screen when the call is ended
  /// from somewhere else — the notification's hang-up action. Without this
  /// flag it also fires for the screen's own failure paths, which pop
  /// directly, and pops a second time: the chat underneath disappears too.
  void _markScreenClosing() {
    _isClosing = true;
    _didEndCall = true;
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
    _connectWatchdog?.cancel();
    // Stage 1 at 10s: a plain re-join with a fresh token, which rescues a
    // transient stall. An iPhone woken by VoIP push needs ~6s from CallKit
    // accept to mounting this screen, so anything earlier interrupts the
    // peer mid-join.
    _connectWatchdog = Timer(const Duration(seconds: 10), () {
      unawaited(_escalateConnectRecovery('watchdog'));
    });
  }

  /// The connect-recovery ladder. Each rung runs once per call.
  ///
  ///   1. re-join with a fresh token   — fixes a stalled/transient join
  ///   2. re-join through Agora's cloud proxy (TCP/443) — fixes the
  ///      restrictive-network case, which is what actually breaks half the
  ///      calls in production
  ///   3. give up with an honest message
  Future<void> _escalateConnectRecovery(String reason) async {
    if (!mounted || _didEndCall || _remoteUid != null) return;
    if (_recoveryInFlight) return;
    _recoveryInFlight = true;
    try {
      if (!_rejoinAttempted) {
        _rejoinAttempted = true;
        debugPrint('🔁 Connect recovery [$reason] stage 1: re-join');
        final ok = await LiveKitCallService.rejoinChannel(
          channelName: widget.channelName,
          callType: _callType,
          callId: widget.callId,
        );
        debugPrint('🔁 stage 1 re-join: $ok');
        // rejoinChannel awaits a token fetch with retries. The user can hang
        // up inside that window — _endCall and dispose both cancel the
        // watchdog, and re-arming it afterwards would leave a timer holding a
        // closure over a dead State, still climbing the ladder.
        if (!mounted || _didEndCall || _remoteUid != null) return;
        // Give the peer a moment to appear before escalating again.
        _connectWatchdog?.cancel();
        _connectWatchdog = Timer(const Duration(seconds: 8), () {
          unawaited(_escalateConnectRecovery('stage1-timeout'));
        });
        return;
      }

      if (!_proxyAttempted) {
        _proxyAttempted = true;
        debugPrint('🛡️ Connect recovery [$reason] stage 2: cloud proxy');
        if (mounted) setState(() => _isConnecting = true);
        // Cloud Proxy is an Agora-specific escape hatch. On LiveKit the same
        // job is done by our own TURN over TLS on 443, which the client
        // already falls back to on its own — so a full re-join is the only
        // escalation left.
        final ok = await LiveKitCallService.rejoinChannel(
          channelName: widget.channelName,
          callType: _callType,
          callId: widget.callId,
        );
        debugPrint('🛡️ stage 2 cloud-proxy re-join: $ok');
        if (!mounted || _didEndCall || _remoteUid != null) return;
        _connectWatchdog?.cancel();
        _connectWatchdog = Timer(const Duration(seconds: 10), () {
          unawaited(_escalateConnectRecovery('stage2-timeout'));
        });
        return;
      }

      // Ladder exhausted — now it is a real failure.
      if (!mounted || _didEndCall || _remoteUid != null) return;
      debugPrint('❌ Connect recovery exhausted [$reason]');
      _showOverlayAndClose('Could not connect');
      unawaited(_endCall(
        notifyPeer: true,
        allowLog: !widget.isIncoming,
        outcomeOverride: 'failed',
      ));
    } finally {
      _recoveryInFlight = false;
    }
  }

  void _cancelConnectWatchdog() {
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
  }

  void _startCallTimer({DateTime? connectedAt, bool syncGlobalState = true}) {
    if (_callStartedAt != null) return;
    // The moment the call actually connects, felt rather than read — the phone
    // is often already at an ear by now.
    unawaited(HapticFeedback.mediumImpact());
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
      return 'Allow microphone${_callType == 'video' ? ' and camera' : ''} access to start the call.';
    }
    if (lower.contains('session expired') || lower.contains('sign in again')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'The call request timed out. Check your connection and try again.';
    }
    if (lower.contains('recipient is unavailable')) {
      return 'User is unavailable right now.';
    }
    if (lower.contains('service is unavailable')) {
      return 'The call service is unavailable. Please try again shortly.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network problem while starting the call. Please try again.';
    }
    if (lower.contains('invalid channel')) {
      return 'Invalid call session. Please try again.';
    }
    if (lower.contains('token')) {
      return 'The call session expired. Please try again.';
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

    final label = _callType == 'video' ? 'Video call' : 'Audio call';

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
        receiverId: _statusReceiverId,
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

  /// A note that clears itself, for something that happened to someone else.
  ///
  /// [_showOverlayAndClose] is for the end of a call and stays up until the
  /// screen goes. "Someone left" is not the end of anything, so it must not
  /// use the same overlay — it would sit there reading like a hang-up
  /// through the rest of the conversation.
  void _showTransientNote(String text) {
    if (!mounted) return;
    setState(() => _transientNote = text);
    _transientNoteTimer?.cancel();
    _transientNoteTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _transientNote = null);
    });
  }

  // ---------------------------------------------------------------------
  // Group calls
  // ---------------------------------------------------------------------

  /// Everyone else currently in the room.
  List<CallPeer> get _peers => LiveKitCallService.peers;

  /// A call rung at a group is a group call from the first second, before
  /// anyone has picked up — otherwise the header would show one member's
  /// name while five phones ring.
  bool get _isGroupCall => _peers.length > 1 || widget.groupId != null;

  /// Where a status event is addressed. See [_groupPrimaryCalleeId].
  String get _statusReceiverId => _groupPrimaryCalleeId ?? widget.calleeId;

  Future<void> _addParticipants() async {
    if (_stage != _CallStage.connected) {
      AdsyToast.info(context, 'You can add people once the call connects');
      return;
    }

    final excluded = <String>{
      widget.calleeId,
      for (final peer in _peers) peer.identity,
      if (AuthService.currentUser?.id != null)
        AuthService.currentUser!.id.toString(),
    }..removeWhere((id) => id.isEmpty);

    final picked =
        await AddParticipantSheet.show(context, excludedUserIds: excluded);
    if (picked == null || picked.isEmpty || !mounted) return;

    final results = await AdsyConnectService.inviteToCall(
      channelName: widget.channelName,
      inviteeIds: picked,
      callId: widget.callId,
    );
    if (!mounted) return;

    if (results.isEmpty) {
      AdsyToast.error(context, 'Could not add anyone');
      return;
    }

    // Report what actually happened per person. "Invited 3" would be a lie
    // when one of them was already on another call.
    int count(String status) =>
        results.where((r) => r['status'] == status).length;

    final ringing = count('ringing');
    final busy = count('busy');
    final unreachable = count('unreachable');
    final notAllowed = count('not_allowed');
    final full = count('call_full');

    final parts = <String>[
      if (ringing > 0) 'Ringing $ringing',
      if (busy > 0) '$busy on another call',
      if (unreachable > 0) '$unreachable unreachable',
      if (notAllowed > 0) '$notAllowed cannot be added',
      if (full > 0) 'The call is full',
    ];
    if (parts.isEmpty) {
      AdsyToast.error(context, 'Could not add anyone');
    } else if (ringing > 0) {
      AdsyToast.success(context, parts.join(' • '));
    } else {
      AdsyToast.info(context, parts.join(' • '));
    }
  }

  // ---------------------------------------------------------------------
  // Audio → video upgrade
  //
  // Turning a voice call into a video call cannot be one-sided: the camera
  // that has to come on belongs to the other person, who may be somewhere
  // they would rather not be seen. So it is an offer, and it needs an answer.
  // ---------------------------------------------------------------------

  static const Duration _upgradeOfferWindow = Duration(seconds: 30);

  void _handleInCallSignal(Map<String, dynamic> signal) {
    if (!mounted) return;
    switch (signal['type']?.toString()) {
      case 'video_upgrade_request':
        // Ignore an offer for a call that is already video, or while we have
        // an offer of our own in flight — whoever asked first wins, and the
        // other side's request lapses on its own timeout.
        if (_callType == 'video' || _upgrade != _VideoUpgrade.idle) return;
        _upgradeTimeout?.cancel();
        _upgradeTimeout = Timer(_upgradeOfferWindow, () {
          if (!mounted || _upgrade != _VideoUpgrade.invited) return;
          setState(() => _upgrade = _VideoUpgrade.idle);
        });
        setState(() => _upgrade = _VideoUpgrade.invited);
        break;

      case 'video_upgrade_response':
        if (_upgrade != _VideoUpgrade.asked) return;
        _upgradeTimeout?.cancel();
        _upgradeTimeout = null;
        if (signal['accepted'] == true) {
          unawaited(_applyVideoUpgrade());
        } else {
          setState(() => _upgrade = _VideoUpgrade.idle);
          AdsyToast.info(context, '${widget.calleeName} declined video');
        }
        break;
    }
  }

  Future<void> _requestVideoUpgrade() async {
    if (_callType == 'video' || _upgrade != _VideoUpgrade.idle) return;
    if (_stage != _CallStage.connected) {
      AdsyToast.info(context, 'You can switch to video once the call connects');
      return;
    }

    // Ask for the camera before making a promise we may not be able to keep:
    // a refusal here should cost the other person nothing.
    try {
      await AgoraCallService.ensurePermissions(callType: 'video');
    } catch (_) {
      if (!mounted) return;
      AdsyToast.error(context, 'Video calls need camera permission');
      return;
    }
    if (!mounted) return;

    setState(() => _upgrade = _VideoUpgrade.asked);
    _upgradeTimeout?.cancel();
    _upgradeTimeout = Timer(_upgradeOfferWindow, () {
      if (!mounted || _upgrade != _VideoUpgrade.asked) return;
      setState(() => _upgrade = _VideoUpgrade.idle);
      AdsyToast.info(context, 'No response to the video request');
    });

    await LiveKitCallService.sendSignal({'type': 'video_upgrade_request'});
  }

  Future<void> _answerVideoUpgrade(bool accepted) async {
    _upgradeTimeout?.cancel();
    _upgradeTimeout = null;

    if (!accepted) {
      setState(() => _upgrade = _VideoUpgrade.idle);
      await LiveKitCallService.sendSignal(
        {'type': 'video_upgrade_response', 'accepted': false},
      );
      return;
    }

    try {
      await AgoraCallService.ensurePermissions(callType: 'video');
    } catch (_) {
      if (mounted) {
        setState(() => _upgrade = _VideoUpgrade.idle);
        AdsyToast.error(context, 'Video calls need camera permission');
      }
      // The other side is still waiting on an answer; a refused permission is
      // a "no" to them, not silence.
      await LiveKitCallService.sendSignal(
        {'type': 'video_upgrade_response', 'accepted': false},
      );
      return;
    }

    await LiveKitCallService.sendSignal(
      {'type': 'video_upgrade_response', 'accepted': true},
    );
    await _applyVideoUpgrade();
  }

  /// Switches this side to video once both have agreed.
  Future<void> _applyVideoUpgrade() async {
    if (!mounted) return;
    setState(() {
      _callType = 'video';
      _isCameraOff = false;
      _upgrade = _VideoUpgrade.idle;
    });

    await LiveKitCallService.toggleCamera(true);

    // Everything outside this screen reads the call type from here: the
    // minimised bar, the floating bubble, and the foreground service — which
    // has to claim the camera type now that a camera is running.
    AgoraCallService.setActiveCallInfo(
      channelName: widget.channelName,
      peerId: widget.calleeId,
      peerName: widget.calleeName,
      peerAvatar: widget.calleeAvatar,
      callType: 'video',
      isIncoming: widget.isIncoming,
      callId: widget.callId,
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    LiveKitCallService.toggleMute(_isMuted);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    LiveKitCallService.toggleCamera(!_isCameraOff);
  }

  void _switchCamera() {
    LiveKitCallService.switchCamera();
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    LiveKitCallService.toggleSpeaker(_isSpeakerOn);
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
    _reconnectingSub?.cancel();
    _signalSub?.cancel();
    _tracksSub?.cancel();
    _poorConnectionSub?.cancel();
    _callStateSub?.cancel();
    _transientNoteTimer?.cancel();
    _upgradeTimeout?.cancel();
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
    // CallScreen can be restored via the call bubble with isReturning=true.
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
          receiverId: _statusReceiverId,
          channelName: widget.channelName,
          status: status,
          callType: _callType,
          callId: widget.callId,
        ));
      }

      unawaited(_engineLeave());
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

    // No permission prompt here any more. Minimising used to be the moment
    // this asked for "display over other apps", which Android can only grant
    // on a system Settings page — a detour out of a live call, for a
    // permission most people would not recognise. Leaving the app now
    // shrinks it into a Picture-in-Picture window instead, which needs
    // nothing granted, and the in-app minimise below keeps the ongoing-call
    // bar it always had.

    // Always minimize back to AdsyConnect instead of revealing unrelated
    // routes that may be sitting under the call screen.
    _showAdsyConnectInbox();
  }

  @override
  Widget build(BuildContext context) {
    // With three or more people the single full-bleed remote stage stops
    // being the right shape and everyone goes into a grid instead.
    final isGroup = _isGroupCall;
    final hasRemoteVideo =
        !isGroup && _remoteUid != null && _callType == 'video';

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
                  if (isGroup)
                    _buildParticipantGrid()
                  else if (!hasRemoteVideo)
                    _buildWaitingView(),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(
                                  alpha: hasRemoteVideo ? 0.16 : 0.02),
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
                      _callType == 'video' &&
                      !_isCameraOff &&
                      // In a grid the self-view would float over the tiles it
                      // is already sitting beside.
                      !isGroup)
                    _buildLocalPreview(),
                  if (widget.isIncoming && !_callAccepted)
                    _buildIncomingCallUI(),
                  if (_upgrade == _VideoUpgrade.invited)
                    _buildVideoUpgradeInvite(),
                  if (_hasPoorConnection && _stage == _CallStage.connected)
                    CallPoorConnectionBanner(compact: _isCompactLayout),
                  if (_statusOverlay != null)
                    CallStatusOverlay(text: _statusOverlay!),
                  if (_transientNote != null)
                    CallTransientNote(
                      text: _transientNote!,
                      compact: _isCompactLayout,
                      stacked: _hasPoorConnection,
                    ),
                  if (_callAccepted || !widget.isIncoming) _callControlsBar(),
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
                  CallTypeBadge(
                    isVideo: _callType == 'video',
                    label: _callModeLabel,
                    accent: _accentColor,
                  ),
                  SizedBox(height: compact ? 20 : 24),
                  CallAnimatedAvatar(
                    size: compact ? 116 : 138,
                    pulse: _pulseController,
                    accent: _accentColor,
                    avatarUrl: widget.calleeAvatar,
                  ),
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
                  SizedBox(height: compact ? 10 : 12),
                  // The duration is the headline once a call is up — it is
                  // the one number the user actually looks for — so it gets
                  // the size and weight, and the prose steps aside.
                  if (_stage == _CallStage.connected)
                    Text(
                      _formatDuration(_callDuration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 30 : 34,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStageDot(),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            _primaryStatusText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: compact ? 14 : 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: compact ? 18 : 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      CallInfoPill(
                        icon: Icons.lock_outline_rounded,
                        label: 'Secure',
                        accent: _accentColor,
                      ),
                      CallInfoPill(
                        icon: _callType == 'video'
                            ? Icons.videocam_outlined
                            : Icons.call_outlined,
                        label: _callModeLabel,
                        accent: _accentColor,
                      ),
                      // Silence from a muted microphone looks exactly like
                      // silence from a broken call, and only one of them is
                      // worth hanging up over.
                      if (_stage == _CallStage.connected &&
                          _peers.length == 1 &&
                          _peers.first.isMuted)
                        CallInfoPill(
                          icon: Icons.mic_off_rounded,
                          label: '${widget.calleeName} is muted',
                          accent: _accentColor,
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
          child: CallGlassPanel(
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
                  'Incoming $_callModeLabel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer or decline?',
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
                      child: CallResponseButton(
                        label: 'Decline',
                        icon: Icons.call_end_rounded,
                        backgroundColor: const Color(0xFFEF4444),
                        onTap: _rejectCall,
                        compact: _isCompactLayout,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CallResponseButton(
                        label: 'Accept',
                        icon: _callType == 'video'
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        backgroundColor: _accentColor,
                        onTap: _acceptCall,
                        compact: _isCompactLayout,
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

  /// Whether the control bar is two rows tall right now. The self-view reads
  /// this too, so its clearance and the bar's shape can never disagree.
  bool get _controlsWrap => callControlsNeedTwoRows(
        screenWidth: MediaQuery.sizeOf(context).width,
        compact: _isCompactLayout,
        isVideo: _callType == 'video',
      );

  /// The control bar, wired to this call.
  ///
  /// The bar itself knows nothing about calls — it takes flags and
  /// callbacks — so this is the one place the two are joined.
  Widget _callControlsBar() => CallControlsBar(
        compact: _isCompactLayout,
        isVideo: _callType == 'video',
        accent: _accentColor,
        isMuted: _isMuted,
        isSpeakerOn: _isSpeakerOn,
        isCameraOff: _isCameraOff,
        awaitingVideoUpgrade: _upgrade == _VideoUpgrade.asked,
        onToggleMute: _toggleMute,
        onToggleSpeaker: _toggleSpeaker,
        onToggleCamera: _toggleCamera,
        onSwitchCamera: _switchCamera,
        onRequestVideo: () => unawaited(_requestVideoUpgrade()),
        onAddParticipants: () => unawaited(_addParticipants()),
        onEndCall: () => unawaited(_endCall(
              notifyPeer: true,
              allowLog: true,
              closeImmediately: true,
            )),
      );

  Color get _accentColor {
    return _callType == 'video'
        ? const Color(0xFF38BDF8)
        : const Color(0xFF34D399);
  }

  String get _callModeLabel {
    return _callType == 'video' ? 'video call' : 'audio call';
  }

  /// A dot that pulses while the call is still being worked on and holds
  /// steady once it is up, so progress is visible at a glance.
  Widget _buildStageDot() {
    final settled = _stage == _CallStage.connected;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _stageColor,
        boxShadow: [
          BoxShadow(color: _stageColor.withValues(alpha: 0.5), blurRadius: 6),
        ],
      ),
    );
    if (settled) return dot;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = (math.sin(_pulseController.value * 2 * math.pi) + 1) / 2;
        return Opacity(opacity: 0.45 + (t * 0.55), child: child);
      },
      child: dot,
    );
  }

  /// Where the call is right now, as one value instead of four booleans read
  /// in a different order by each part of the screen. Every label — the header
  /// line, the big status under the name, the notification — comes from here,
  /// so they cannot disagree about whether a call is ringing or connected.
  _CallStage get _stage {
    if (_didEndCall) return _CallStage.ended;
    if (widget.isIncoming && !_callAccepted) return _CallStage.incoming;
    if (_callStartedAt != null) {
      return _isReconnecting ? _CallStage.reconnecting : _CallStage.connected;
    }
    if (_callAccepted) return _CallStage.connecting;
    if (widget.isIncoming) return _CallStage.connecting;
    // Our own side of an outgoing call is still coming up: the room has not
    // been joined yet, so "ringing" would be describing something that has
    // not started.
    if (_isConnecting) return _CallStage.connecting;
    if (!AgoraCallService.lastCallReachable) return _CallStage.unreachable;
    return _CallStage.ringing;
  }

  /// The short line that sits beside the name — a duration once there is one.
  String get _stageLabel {
    switch (_stage) {
      case _CallStage.incoming:
        return 'Incoming call';
      case _CallStage.ringing:
        return 'Ringing…';
      case _CallStage.connecting:
        return 'Connecting…';
      case _CallStage.connected:
        return _formatDuration(_callDuration);
      case _CallStage.reconnecting:
        return 'Reconnecting…';
      case _CallStage.unreachable:
        return 'Unreachable';
      case _CallStage.ended:
        return 'Call ended';
    }
  }

  /// The fuller sentence shown under the name while there is no video to look
  /// at. A status overlay ("Call declined") outranks it — that is the last
  /// thing the user needs to read before the screen closes.
  String get _primaryStatusText {
    if (_statusOverlay != null) return _statusOverlay!;
    switch (_stage) {
      case _CallStage.incoming:
        return _callType == 'video'
            ? 'Incoming video call'
            : 'Incoming audio call';
      case _CallStage.ringing:
        return 'Ringing…';
      case _CallStage.connecting:
        return 'Connecting…';
      case _CallStage.connected:
        return _formatDuration(_callDuration);
      case _CallStage.reconnecting:
        return 'The call resumes when the network is back';
      case _CallStage.unreachable:
        // The server had nowhere to deliver the ring. Saying "ringing" here
        // is simply untrue, and it costs the caller thirty seconds to learn
        // it themselves.
        return 'Cannot reach their device';
      case _CallStage.ended:
        return 'Call ended';
    }
  }

  /// Green once the media is up, amber while it is being worked on, red when
  /// the call cannot proceed. Read together with [_stageLabel] it answers
  /// "is this working?" without the user parsing any text at all.
  Color get _stageColor {
    switch (_stage) {
      case _CallStage.connected:
        return const Color(0xFF34D399);
      case _CallStage.reconnecting:
      case _CallStage.connecting:
      case _CallStage.ringing:
      case _CallStage.incoming:
        return const Color(0xFFFBBF24);
      case _CallStage.unreachable:
      case _CallStage.ended:
        return const Color(0xFFEF4444);
    }
  }

  Widget _buildBackgroundLayer() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _callType == 'video'
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

  Widget _remoteVideoView() {
    final track = LiveKitCallService.remoteVideoTrack;
    // Their camera may be off or not yet subscribed; the stage behind this
    // already shows the avatar, so an empty box here is the right answer.
    if (track == null) return const SizedBox.shrink();
    return lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.cover);
  }

  Widget _localVideoView() {
    final track = LiveKitCallService.localVideoTrack;
    if (track == null) return const SizedBox.shrink();
    return lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.cover);
  }

  /// Everyone in a group call, as a grid.
  ///
  /// A one-to-one call gives the other person the whole screen; that stops
  /// making sense the moment there are three of you, and someone whose camera
  /// is off still needs a tile — they are in the call, and silently vanishing
  /// from the screen is not how anyone reads that.
  Widget _buildParticipantGrid() {
    final peers = _peers;
    // The user is in the call too. The floating self-view is suppressed in a
    // grid because it would hover over the tiles, so without a tile of their
    // own they would be the one person on the call who cannot see themselves.
    final tiles = peers.length + 1;
    // Two across is the most a phone can show without faces becoming stamps.
    final columns = tiles <= 2 ? 1 : 2;

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 68, 10, 120),
        child: GridView.builder(
          // Eight people is two columns of four, which does not fit a phone.
          // Scrolling is the difference between "the rest are below" and
          // "the rest are not on the call".
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: columns == 1 ? 1.1 : 0.78,
          ),
          itemCount: tiles,
          itemBuilder: (context, index) {
            if (index == 0) return _buildSelfTile();
            return _buildPeerTile(peers[index - 1]);
          },
        ),
      ),
    );
  }

  Widget _buildSelfTile() {
    final track = _callType == 'video' && !_isCameraOff
        ? LiveKitCallService.localVideoTrack
        : null;
    return _buildTile(
      name: 'You',
      videoTrack: track,
      isMuted: _isMuted,
      isSpeaking: false,
    );
  }

  Widget _buildPeerTile(CallPeer peer) => _buildTile(
        name: peer.name,
        videoTrack: peer.videoTrack,
        isMuted: peer.isMuted,
        isSpeaking: peer.isSpeaking,
      );

  Widget _buildTile({
    required String name,
    required lk.VideoTrack? videoTrack,
    required bool isMuted,
    required bool isSpeaking,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF111827),
        border: Border.all(
          // Whoever is talking gets the ring. In a group call that is the one
          // thing you cannot work out from the audio alone.
          color:
              isSpeaking ? _accentColor : Colors.white.withValues(alpha: 0.10),
          width: isSpeaking ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null)
            lk.VideoTrackRenderer(videoTrack, fit: lk.VideoViewFit.cover)
          else
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white70, size: 32),
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                if (isMuted)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.mic_off_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildRemoteVideoStage() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _remoteVideoView(),
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
    final hasRemoteVideo =
        !_isGroupCall && _remoteUid != null && _callType == 'video';
    // In a group call the header names the call, not one person in it — and
    // when the call was rung at a named group, that name is what people
    // recognise, so it wins over the generic label.
    final String title;
    if (widget.groupName != null && widget.groupName!.trim().isNotEmpty) {
      final joined = _peers.length + 1;
      title = joined > 1
          ? '${widget.groupName!.trim()} • $joined'
          : widget.groupName!.trim();
    } else if (_isGroupCall) {
      title = 'Group call • ${_peers.length + 1}';
    } else {
      title = widget.calleeName;
    }
    final subtitle = _stageLabel;

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
                    _buildStageDot(),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
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
                        // A ticking duration must not shuffle the name
                        // sideways every second.
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            CallIconChip(
              icon: Icons.remove_rounded,
              label: 'Minimise',
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
            child: CallGlassPanel(
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
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CallAvatarImage(
                        avatarUrl: widget.calleeAvatar, iconSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 15 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStageDot(),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                '$_callModeLabel • $_stageLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          CallIconChip(
            icon: Icons.remove_rounded,
            label: 'Minimise',
            onTap: _minimizeCall,
          ),
        ],
      ),
    );
  }

  /// The self-view, draggable anywhere on the stage and snapping to the
  /// nearest corner on release.
  ///
  /// Fixed to the top-right it covered the other person's face whenever they
  /// happened to be standing on that side of their own frame, and there was
  /// nothing the user could do about it. The position is kept as an
  /// [Alignment] so a rotation or a keyboard does not throw it off screen.
  Widget _buildLocalPreview() {
    final compact = _isCompactLayout;
    final width = compact ? 92.0 : 108.0;
    final height = compact ? 128.0 : 150.0;
    // Clear of the header pill above and the control bar below — and the bar
    // is a row taller when the controls wrap, so the clearance follows it.
    // Getting this wrong parks the self-view under End, where dragging it
    // out of the way means pressing the button you are trying to avoid.
    final margin = EdgeInsets.fromLTRB(
      14,
      74,
      14,
      116 +
          (_controlsWrap
              ? callControlsWrapExtraHeight(compact: compact)
              : 0.0),
    );

    return Positioned.fill(
      child: Padding(
        padding: margin,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final freeX = math.max(0.0, constraints.maxWidth - width);
            final freeY = math.max(0.0, constraints.maxHeight - height);

            return AnimatedAlign(
              // Only the settle after a release is animated; during the
              // drag the finger sets the position directly.
              duration: _selfViewDragOrigin == null
                  ? const Duration(milliseconds: 220)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              alignment: _selfViewAlignment,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => setState(() {
                  _selfViewDragOrigin = Offset(
                    (_selfViewAlignment.x + 1) / 2 * freeX,
                    (_selfViewAlignment.y + 1) / 2 * freeY,
                  );
                }),
                onPanUpdate: (details) {
                  final origin = _selfViewDragOrigin;
                  if (origin == null) return;
                  final next = origin + details.delta;
                  setState(() {
                    _selfViewDragOrigin = next;
                    _selfViewAlignment = Alignment(
                      freeX == 0
                          ? 0
                          : (next.dx.clamp(0.0, freeX) / freeX) * 2 - 1,
                      freeY == 0
                          ? 0
                          : (next.dy.clamp(0.0, freeY) / freeY) * 2 - 1,
                    );
                  });
                },
                onPanEnd: (_) => setState(() {
                  _selfViewDragOrigin = null;
                  // Snap to the nearest corner. Anywhere in between reads
                  // as dropped-by-accident.
                  _selfViewAlignment = Alignment(
                    _selfViewAlignment.x < 0 ? -1 : 1,
                    _selfViewAlignment.y < 0 ? -1 : 1,
                  );
                }),
                child: CallGlassPanel(
                  padding: const EdgeInsets.all(4),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _localVideoView(),
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
              ),
            );
          },
        ),
      ),
    );
  }

  /// Says the quiet part out loud when this device's own link is struggling.
  ///
  /// Without it a bad connection is indistinguishable from the other person
  /// having stopped talking, and the usual response is to say "hello?" for
  /// twenty seconds and then blame the app.
  /// "X left the call" — same pill as the connection warning, sitting just
  /// below it so the two can be on screen at once without overlapping.
  /// The other side has asked to turn the voice call into a video call.
  ///
  /// Deliberately a panel above the controls rather than a modal dialog: a
  /// dialog would sit over the hang-up button, and someone who does not want
  /// to be on camera should never have to answer a prompt before they can end
  /// the call.
  Widget _buildVideoUpgradeInvite() {
    final compact = _isCompactLayout;
    return Positioned(
      left: 18,
      right: 18,
      bottom: compact ? 118 : 140,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: CallGlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.videocam_rounded, color: _accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.calleeName} wants to switch to video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CallResponseButton(
                        label: 'No',
                        icon: Icons.videocam_off_rounded,
                        backgroundColor: const Color(0xFF334155),
                        onTap: () => unawaited(_answerVideoUpgrade(false)),
                        compact: _isCompactLayout,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CallResponseButton(
                        label: 'Turn on camera',
                        icon: Icons.videocam_rounded,
                        backgroundColor: _accentColor,
                        onTap: () => unawaited(_answerVideoUpgrade(true)),
                        compact: _isCompactLayout,
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
}
