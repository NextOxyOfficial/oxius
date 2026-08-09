import 'dart:async';

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

  /// Connects to [channelName] as a room. The token is minted server-side and
  /// is scoped to this one room, so a stolen token cannot open another call.
  static Future<bool> joinChannel({
    required String channelName,
    required String callType,
    String? callId,
  }) async {
    lastError = null;
    try {
      final auth = await AdsyConnectService.fetchLiveKitToken(
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
        // Only a terminal disconnect is worth reporting. LiveKit reconnects
        // on its own for transient drops, and shouting about those would make
        // the call screen tear down a call that is about to recover.
        if (e.reason == lk.DisconnectReason.roomDeleted ||
            e.reason == lk.DisconnectReason.participantRemoved ||
            e.reason == lk.DisconnectReason.duplicateIdentity) {
          _errorController.add('Call ended');
        }
      })
      ..on<lk.RoomReconnectingEvent>((_) => _log('reconnecting…'))
      ..on<lk.RoomReconnectedEvent>((_) => _log('reconnected'));
  }

  /// Full reconnect. LiveKit already retries internally, so this is the call
  /// screen's escalation step when its own watchdog says nothing arrived.
  static Future<bool> rejoinChannel({
    required String channelName,
    required String callType,
    String? callId,
  }) =>
      joinChannel(
          channelName: channelName, callType: callType, callId: callId);

  static Future<void> leaveChannel() async {
    final room = _room;
    _room = null;
    _joinedRoomName = null;
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
      await lk.Hardware.instance.setSpeakerphoneOn(speakerOn);
    } catch (error) {
      _log('speaker toggle failed: $error');
    }
  }

  static bool get isConnected =>
      _room?.connectionState == lk.ConnectionState.connected;

  static String? get joinedRoomName => _joinedRoomName;
}
