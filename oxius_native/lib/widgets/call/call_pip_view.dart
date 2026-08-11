import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../services/agora_call_service.dart';
import '../../services/call_bubble_service.dart';
import '../../services/livekit_call_service.dart';
import '../app_network_image.dart';

/// The call bubble, as Android draws it once the user has left the app.
///
/// PiP hands the activity a window roughly the size of a matchbox and keeps
/// rendering whatever route is on top — a full call screen, or the inbox the
/// user minimised to — and neither is legible at that size. So while PiP is
/// on, this covers everything with the same face and the same running clock
/// the in-app [CallBubble] shows, so leaving the app changes where the bubble
/// is drawn and nothing else about it.
///
/// Tapping the window is Android's own gesture for going full screen again,
/// so there is no button to add.
class CallPipView extends StatelessWidget {
  const CallPipView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CallBubbleService.instance.inPictureInPicture,
      builder: (context, inPip, _) {
        if (!inPip) return const SizedBox.shrink();
        return const Positioned.fill(child: _PipBody());
      },
    );
  }
}

class _PipBody extends StatefulWidget {
  const _PipBody();

  @override
  State<_PipBody> createState() => _PipBodyState();
}

class _PipBodyState extends State<_PipBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Only while the window is actually up: a per-second rebuild of the whole
    // subtree is cheap here and pointless anywhere else.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _status {
    final connectedAt = AgoraCallService.activeCallConnectedAtMs ?? 0;
    if (connectedAt <= 0) {
      return AgoraCallService.activeCallAccepted ? 'Connecting…' : 'Ringing…';
    }
    final seconds =
        (DateTime.now().millisecondsSinceEpoch - connectedAt) ~/ 1000;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final info = AgoraCallService.activeCallInfo;
    final avatar = info?['peerAvatar']?.toString() ?? '';
    final isVideo = info?['callType']?.toString() == 'video';

    // A video call in a floating window should be the video. The window is
    // small but it is a whole window — far more room than the in-app bubble —
    // so their camera fills it and ours sits in the corner, which is the call
    // screen's own arrangement at a smaller size.
    final remote = isVideo ? LiveKitCallService.remoteVideoTrack : null;
    final local = isVideo ? LiveKitCallService.localVideoTrack : null;
    if (remote != null) {
      return Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            lk.VideoTrackRenderer(remote, fit: lk.VideoViewFit.cover),
            if (local != null)
              Positioned(
                right: 6,
                top: 6,
                width: 46,
                height: 62,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: const Color(0xFF0B1220),
                    child: lk.VideoTrackRenderer(local,
                        fit: lk.VideoViewFit.cover),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _status,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Deliberately the in-app bubble's composition, not a smaller call
    // screen: ringed face, call-type marker, one dark pill underneath. The
    // window it is drawn in changes; the thing being drawn should not.
    const face = 64.0;

    return Material(
      color: const Color(0xFF0B1220),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: face,
                height: face,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B1220),
                  border: Border.all(color: const Color(0xFF22C55E), width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipOval(
                        child: avatar.isNotEmpty
                            ? AppNetworkImage(
                                avatar,
                                width: face,
                                height: face,
                                errorWidget: const _PipAvatarFallback(),
                              )
                            : const _PipAvatarFallback(),
                      ),
                    ),
                    // A glance tells voice from video without reading.
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _status,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
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

class _PipAvatarFallback extends StatelessWidget {
  const _PipAvatarFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1E293B),
        child: const Icon(Icons.person_rounded, size: 26, color: Colors.white70),
      );
}
