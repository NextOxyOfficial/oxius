import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'adsyconnect_service.dart';
import 'agora_call_service.dart';

/// Media engine backed by our own LiveKit SFU.
///
/// This is a straight swap for the media half of [AgoraCallService]: the same
/// join / leave / mute / camera operations and the same three participant
/// streams, so the call screen's ringing, timers, watchdogs and recovery
/// ladder keep working untouched. Everything else about a call — the ring
/// signal, push, call status, session bookkeeping — still goes through the
/// existing services; only where the audio and video travel changes.
///
/// Why our own SFU: with Agora a failed call was a black box. Here every
/// connection attempt lands in a log we can read, and the transports are ours
/// to fix — including TURN over TLS on 443, which is the only path that
/// survives a network that drops UDP outright.
/// One other person in the call, as the UI needs them.
class CallPeer {
  const CallPeer({
    required this.uid,
    required this.identity,
    required this.name,
    required this.videoTrack,
    required this.isMuted,
    required this.isSpeaking,
  });

  /// The synthetic integer the call screen keys its existing logic off.
  final int uid;

  /// The server puts the user's id here when minting the token, so this is
  /// what ties a tile back to an AdsyClub account.
  final String identity;
  final String name;
  final lk.VideoTrack? videoTrack;
  final bool isMuted;
  final bool isSpeaking;
}

class LiveKitCallService {
  LiveKitCallService._();

  static lk.Room? _room;
  static lk.EventsListener<lk.RoomEvent>? _listener;
  static String? _joinedRoomName;

  static final StreamController<int> _localJoinedController =
      StreamController<int>.broadcast();
  static final StreamController<int> _remoteJoinedController =
      StreamController<int>.broadcast();
  static final StreamController<int> _remoteLeftController =
      StreamController<int>.broadcast();
  static final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// True while the SDK is re-establishing a dropped transport. The call is
  /// not over and must not be torn down, but the audio has stopped — and a
  /// call screen that keeps counting a duration through silence is lying to
  /// the user about what is happening.
  static final StreamController<bool> _reconnectingController =
      StreamController<bool>.broadcast();
  static Stream<bool> get reconnectingStream => _reconnectingController.stream;

  /// In-call messages between the two people already in the room — today the
  /// audio-to-video upgrade handshake.
  ///
  /// These deliberately do NOT go through the backend call-status endpoint.
  /// Both parties are already connected to the same SFU, so a data packet
  /// arrives in one hop instead of a round trip through the server and a push;
  /// and an offer that took three seconds to reach the other phone would be
  /// answered after the person had given up on it.
  static const String signalTopic = 'adsy-call';

  static final StreamController<Map<String, dynamic>> _signalController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get signalStream =>
      _signalController.stream;

  /// Sends an in-call message to the other side, reporting whether it left.
  ///
  /// The return value matters: this used to swallow both failure modes, so a
  /// video-upgrade request that was never sent was indistinguishable from one
  /// waiting for an answer. The button said "Waiting" for the length of the
  /// offer window and then gave up, and to the user tapping it simply did
  /// nothing.
  static Future<bool> sendSignal(Map<String, dynamic> payload) async {
    final participant = _room?.localParticipant;
    if (participant == null) {
      _log('signal dropped, not in a room: ${payload['type']}');
      return false;
    }
    try {
      await participant.publishData(
        utf8.encode(jsonEncode(payload)),
        reliable: true,
        topic: signalTopic,
      );
      return true;
    } catch (error) {
      _log('signal send failed: $error');
      return false;
    }
  }

  /// Fires whenever the set of renderable video tracks may have changed — a
  /// track subscribed, dropped, muted or unmuted.
  ///
  /// The call screen reads [remoteVideoTrack] while building, so without this
  /// it only ever sees the tracks that happened to exist the last time
  /// something else made it rebuild. A camera switched on mid-call — which is
  /// exactly what an audio-to-video upgrade is — would arrive to a screen that
  /// never looked again.
  static final StreamController<void> _tracksChangedController =
      StreamController<void>.broadcast();
  static Stream<void> get videoTracksChangedStream =>
      _tracksChangedController.stream;

  /// True while this device's own link to the SFU is bad enough that the
  /// other side is hearing it.
  ///
  /// Only the local participant's quality is reported: a remote peer's poor
  /// connection is their problem to see and act on, and telling this user
  /// their network is bad when it is not sends them to reset a working router.
  static final StreamController<bool> _poorConnectionController =
      StreamController<bool>.broadcast();
  static Stream<bool> get poorConnectionStream =>
      _poorConnectionController.stream;

  static bool _hasPoorConnection = false;
  static bool get hasPoorConnection => _hasPoorConnection;

  static void _setPoorConnection(bool value) {
    if (_hasPoorConnection == value) return;
    _hasPoorConnection = value;
    _poorConnectionController.add(value);
  }

  static bool _isReconnecting = false;
  static bool get isReconnecting => _isReconnecting;

  static void _setReconnecting(bool value) {
    if (_isReconnecting == value) return;
    _isReconnecting = value;
    _reconnectingController.add(value);
  }

  /// The call screen keys its UI off integer uids (an Agora concept). LiveKit
  /// identifies participants by string identity, so each remote identity is
  /// given a stable synthetic uid for the duration of the process.
  static final Map<String, int> _uidByIdentity = {};
  static int _nextSyntheticUid = 1;

  static Stream<int> get localUserJoinedStream => _localJoinedController.stream;
  static Stream<int> get remoteUserJoinedStream =>
      _remoteJoinedController.stream;
  static Stream<int> get remoteUserLeftStream => _remoteLeftController.stream;
  static Stream<String> get engineErrorStream => _errorController.stream;

  static lk.Room? get room => _room;
  static String? lastError;

  static int _uidFor(String identity) => _uidByIdentity.putIfAbsent(
      identity, () => _nextSyntheticUid++);

  static void _log(String message) => debugPrint('📡 LiveKit: $message');

  /// The remote participant's video track, or null while they are audio-only
  /// or their camera is off. The call screen renders it with
  /// [lk.VideoTrackRenderer].
  static lk.VideoTrack? get remoteVideoTrack {
    final room = _room;
    if (room == null) return null;
    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        final track = pub.track;
        if (track is lk.VideoTrack && pub.subscribed && !pub.muted) {
          return track;
        }
      }
    }
    return null;
  }

  /// Everyone else in the room, in a shape the call screen can render without
  /// knowing anything about LiveKit.
  ///
  /// A one-to-one call only ever has one of these and the screen shows it
  /// full-bleed; a group call has several and they go into a grid. Sorted by
  /// identity so the tiles do not reshuffle themselves on every rebuild.
  static List<CallPeer> get peers {
    final room = _room;
    if (room == null) return const [];
    final list = room.remoteParticipants.values.map((participant) {
      lk.VideoTrack? video;
      for (final pub in participant.videoTrackPublications) {
        final track = pub.track;
        if (track is lk.VideoTrack && pub.subscribed && !pub.muted) {
          video = track;
          break;
        }
      }
      final audioMuted = participant.audioTrackPublications.isEmpty ||
          participant.audioTrackPublications.every((pub) => pub.muted);
      return CallPeer(
        uid: _uidFor(participant.identity),
        identity: participant.identity,
        name: participant.name.isNotEmpty ? participant.name : participant.identity,
        videoTrack: video,
        isMuted: audioMuted,
        isSpeaking: participant.isSpeaking,
      );
    }).toList()
      ..sort((a, b) => a.identity.compareTo(b.identity));
    return list;
  }

  static lk.VideoTrack? get localVideoTrack {
    final room = _room;
    if (room == null) return null;
    for (final pub in room.localParticipant?.videoTrackPublications ??
        const <lk.LocalTrackPublication<lk.LocalVideoTrack>>[]) {
      final track = pub.track;
      if (track is lk.VideoTrack && !pub.muted) return track;
    }
    return null;
  }

  /// A token fetched before it was needed, waiting for the join that uses it.
  ///
  /// Answering a call used to pay for a round trip to mint the token, at the
  /// one moment the user is watching the screen and waiting. The channel is
  /// known the instant the phone starts ringing and the endpoint issues a
  /// token for any non-terminal session, so it can be fetched during the
  /// ring instead — by the time Accept is pressed the join has everything it
  /// needs and goes straight to the media server.
  static LiveKitAuth? _warmAuth;
  static String? _warmChannel;
  static DateTime? _warmAt;

  /// Long enough to cover a full ring, short enough that a token is never
  /// used near its expiry.
  static const Duration _warmTtl = Duration(seconds: 90);

  /// Fetches the join token ahead of time. Safe to call more than once, and
  /// safe to fail — the join refetches when there is nothing warm.
  static Future<void> prewarmToken({
    required String channelName,
    String? callId,
  }) async {
    if (_warmChannel == channelName && _warmFresh) return;
    try {
      final auth = await AdsyConnectService.fetchLiveKitToken(
        channelName: channelName,
        callId: callId,
      );
      if (auth == null) return;
      _warmAuth = auth;
      _warmChannel = channelName;
      _warmAt = DateTime.now();
    } catch (_) {
      // A prewarm that fails costs nothing; the join will fetch its own.
    }
  }

  static bool get _warmFresh =>
      _warmAt != null && DateTime.now().difference(_warmAt!) < _warmTtl;

  static void _clearWarmToken() {
    _warmAuth = null;
    _warmChannel = null;
    _warmAt = null;
  }

  /// Connects to [channelName] as a room. The token is minted server-side and
  /// is scoped to this one room, so a stolen token cannot open another call.
  static Future<bool> joinChannel({
    required String channelName,
    required String callType,
    String? callId,
    /// Rebuild the connection even if this side thinks it is already in the
    /// room. A repair is called precisely because "connected" is not
    /// producing media, so believing it is the one thing that must not
    /// happen here.
    bool force = false,
  }) async {
    lastError = null;
    try {
      // Already in this room. Answering now joins from two places — the
      // CallKit accept handler and the call screen — because on a locked
      // iPhone the screen may not exist for seconds yet and the media must
      // not wait for it. Whichever arrives second has nothing to do, and must
      // not tear the live connection down to rebuild it: that would drop the
      // audio the first one had already established.
      if (!force && _joinedRoomName == channelName && isConnected) {
        _log('already in $channelName — join is a no-op');
        return true;
      }

      // Single use, deliberately. A rejoin happens because something went
      // wrong, and handing it the same token the failed attempt used is how
      // a self-heal turns into a second failure.
      LiveKitAuth? auth;
      if (_warmChannel == channelName && _warmFresh) {
        auth = _warmAuth;
      }
      _clearWarmToken();

      auth ??= await AdsyConnectService.fetchLiveKitToken(
        channelName: channelName,
        callId: callId,
      );
      if (auth == null) {
        lastError = 'Call token unavailable';
        return false;
      }

      await leaveChannel();

      final wantsVideo = callType == 'video';
      // Ask for mic (and camera) up front with the app's own wording, rather
      // than letting the first track request surface a bare system prompt
      // mid-connect — and so a refusal fails here with a clear reason.
      await AgoraCallService.ensurePermissions(callType: callType);
      final room = lk.Room(
        roomOptions: lk.RoomOptions(
          adaptiveStream: true,
          // Simulcast lets the SFU drop to a smaller layer for a struggling
          // receiver instead of stalling the whole call.
          dynacast: true,
          defaultVideoPublishOptions: const lk.VideoPublishOptions(
            simulcast: true,
          ),
          defaultAudioPublishOptions: const lk.AudioPublishOptions(
            dtx: true,
          ),
        ),
      );
      _room = room;
      _attachListeners(room);

      await room.connect(
        auth.url,
        auth.token,
        connectOptions: const lk.ConnectOptions(
          // One other person in a 1:1 call — take their tracks as they land.
          // Timeouts stay at the SDK defaults; the call screen already runs
          // its own connect watchdog and recovery ladder on top of them.
          autoSubscribe: true,
        ),
      );

      await room.localParticipant?.setMicrophoneEnabled(true);
      if (wantsVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }

      _joinedRoomName = channelName;
      _log('joined room $channelName as ${room.localParticipant?.identity}');
      _localJoinedController.add(0);

      // A participant already in the room raises no event for us, so surface
      // them now — otherwise the callee who joins second never sees the
      // caller and the screen sits on "Connecting…".
      for (final participant in room.remoteParticipants.values) {
        _remoteJoinedController.add(_uidFor(participant.identity));
      }
      return true;
    } catch (error) {
      lastError = error.toString();
      _log('join failed: $error');
      _errorController.add('Call connection failed');
      return false;
    }
  }

  static void _attachListeners(lk.Room room) {
    _listener?.dispose();
    final listener = room.createListener();
    _listener = listener;

    listener
      ..on<lk.ParticipantConnectedEvent>((e) {
        _log('remote joined: ${e.participant.identity}');
        _remoteJoinedController.add(_uidFor(e.participant.identity));
      })
      ..on<lk.ParticipantDisconnectedEvent>((e) {
        _log('remote left: ${e.participant.identity}');
        _remoteLeftController.add(_uidFor(e.participant.identity));
      })
      ..on<lk.RoomDisconnectedEvent>((e) {
        _log('disconnected: ${e.reason}');
        _setReconnecting(false);
        // Only a terminal disconnect is worth reporting. LiveKit reconnects
        // on its own for transient drops, and shouting about those would make
        // the call screen tear down a call that is about to recover.
        if (e.reason == lk.DisconnectReason.roomDeleted ||
            e.reason == lk.DisconnectReason.participantRemoved ||
            e.reason == lk.DisconnectReason.duplicateIdentity) {
          _errorController.add('Call ended');
        }
      })
      ..on<lk.ParticipantConnectionQualityUpdatedEvent>((e) {
        if (e.participant is! lk.LocalParticipant) return;
        _setPoorConnection(
          e.connectionQuality == lk.ConnectionQuality.poor ||
              e.connectionQuality == lk.ConnectionQuality.lost,
        );
      })
      ..on<lk.TrackSubscribedEvent>((_) => _tracksChangedController.add(null))
      ..on<lk.TrackUnsubscribedEvent>((_) => _tracksChangedController.add(null))
      ..on<lk.TrackMutedEvent>((_) => _tracksChangedController.add(null))
      ..on<lk.TrackUnmutedEvent>((_) => _tracksChangedController.add(null))
      ..on<lk.LocalTrackPublishedEvent>(
          (_) => _tracksChangedController.add(null))
      ..on<lk.LocalTrackUnpublishedEvent>(
          (_) => _tracksChangedController.add(null))
      ..on<lk.DataReceivedEvent>((e) {
        if (e.topic != signalTopic) return;
        try {
          final decoded = jsonDecode(utf8.decode(e.data));
          if (decoded is Map) {
            _signalController.add(Map<String, dynamic>.from(decoded));
          }
        } catch (error) {
          _log('malformed signal ignored: $error');
        }
      })
      ..on<lk.RoomReconnectingEvent>((_) {
        _log('reconnecting…');
        _setReconnecting(true);
      })
      ..on<lk.RoomReconnectedEvent>((_) {
        _log('reconnected');
        _setReconnecting(false);
      });
  }

  /// Full reconnect. LiveKit already retries internally, so this is the call
  /// screen's escalation step when its own watchdog says nothing arrived.
  /// Tears the connection down and builds it again.
  ///
  /// Always forced. Every caller is a recovery path — a stalled join, a peer
  /// asking to reconnect — and the idempotent shortcut in [joinChannel] would
  /// turn each of them into a no-op that reports success, leaving the call
  /// exactly as broken as it was and the ladder none the wiser.
  static Future<bool> rejoinChannel({
    required String channelName,
    required String callType,
    String? callId,
  }) =>
      joinChannel(
        channelName: channelName,
        callType: callType,
        callId: callId,
        force: true,
      );

  static Future<void> leaveChannel() async {
    final room = _room;
    _room = null;
    _joinedRoomName = null;
    _setReconnecting(false);
    _setPoorConnection(false);
    try {
      _listener?.dispose();
    } catch (_) {}
    _listener = null;
    if (room == null) return;
    try {
      await room.disconnect();
      await room.dispose();
    } catch (error) {
      _log('leave error (ignored): $error');
    }
  }

  static Future<void> toggleMute(bool muted) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!muted);
    } catch (error) {
      _log('mic toggle failed: $error');
    }
  }

  static Future<void> toggleCamera(bool enabled) async {
    try {
      await _room?.localParticipant?.setCameraEnabled(enabled);
    } catch (error) {
      _log('camera toggle failed: $error');
    }
  }

  static Future<void> switchCamera() async {
    try {
      final pubs = _room?.localParticipant?.videoTrackPublications ??
          const <lk.LocalTrackPublication<lk.LocalVideoTrack>>[];
      for (final pub in pubs) {
        final track = pub.track;
        if (track is lk.LocalVideoTrack) {
          final current = track.currentOptions;
          if (current is lk.CameraCaptureOptions) {
            await track.setCameraPosition(
              current.cameraPosition == lk.CameraPosition.front
                  ? lk.CameraPosition.back
                  : lk.CameraPosition.front,
            );
          }
          return;
        }
      }
    } catch (error) {
      _log('camera switch failed: $error');
    }
  }

  static Future<void> toggleSpeaker(bool speakerOn) async {
    try {
      // Hardware.setSpeakerphoneOn is deprecated in livekit 2.11 and is now
      // a forwarder to exactly this call, so the behaviour is unchanged —
      // but audio-routing shims are the kind of thing that quietly becomes a
      // no-op a version later, and losing the speaker toggle mid-call is not
      // a failure anyone would report clearly.
      await lk.AudioManager.instance.setSpeakerOutputPreferred(speakerOn);
    } catch (error) {
      _log('speaker toggle failed: $error');
    }
  }

  static bool get isConnected =>
      _room?.connectionState == lk.ConnectionState.connected;

  static String? get joinedRoomName => _joinedRoomName;
}
