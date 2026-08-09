import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/agora_call_service.dart';
import '../../services/call_bubble_service.dart';
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
    final name = info?['peerName']?.toString().trim() ?? '';
    final avatar = info?['peerAvatar']?.toString() ?? '';

    return Material(
      color: const Color(0xFF0B1220),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // The same green ring as the in-app bubble — one bubble,
                  // two places it can be drawn.
                  border: Border.all(color: const Color(0xFF22C55E), width: 2),
                ),
                child: ClipOval(
                  child: avatar.isNotEmpty
                      ? AppNetworkImage(
                          avatar,
                          width: 52,
                          height: 52,
                          errorWidget: const _PipAvatarFallback(),
                        )
                      : const _PipAvatarFallback(),
                ),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                _status,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
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
