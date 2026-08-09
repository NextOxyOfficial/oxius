import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/agora_call_service.dart';
import '../../services/call_navigation.dart';
import '../app_network_image.dart';

/// The floating call bubble: who you are talking to, and for how long.
///
/// This replaces the wide bar that used to sit across the top of every
/// screen. A bar that width has to go somewhere, and wherever it went it
/// covered an app bar, a search field or a tab strip. A bubble does not
/// compete for a row — it sits over a corner, drags anywhere the user
/// prefers, and snaps back to whichever edge is nearer when released.
///
/// The same bubble is drawn twice, by two different owners, so that leaving
/// the app does not lose it:
///
///  * inside the app, by this widget, over every route;
///  * outside the app, by Android's Picture-in-Picture window, which shows
///    the same avatar and the same running clock and needs no permission.
///
/// One tap goes back to the call either way.
class CallBubble extends StatefulWidget {
  const CallBubble({super.key});

  @override
  State<CallBubble> createState() => _CallBubbleState();
}

class _CallBubbleState extends State<CallBubble>
    with SingleTickerProviderStateMixin {
  /// Diameter of the avatar circle. The duration pill hangs below it.
  static const double _size = 62;
  static const double _margin = 12;

  /// Where the user last put it, as the bubble's top-left in logical pixels.
  /// Null until the first layout picks the default corner.
  Offset? _position;

  /// True between the first drag movement and the release, so the snap
  /// animation is skipped while the finger is still down.
  bool _dragging = false;

  StreamSubscription<bool>? _callStateSub;
  Timer? _ticker;
  bool _inCall = false;

  @override
  void initState() {
    super.initState();
    _inCall = AgoraCallService.isInCall;
    _syncTicker();
    _callStateSub = AgoraCallService.callStateStream.listen((inCall) {
      if (!mounted) return;
      setState(() => _inCall = inCall);
      _syncTicker();
    });
  }

  /// One timer, running only while there is a connected call to count.
  void _syncTicker() {
    final connected = (AgoraCallService.activeCallConnectedAtMs ?? 0) > 0;
    if (_inCall && connected) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _callStateSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  String get _label {
    final connectedAt = AgoraCallService.activeCallConnectedAtMs ?? 0;
    if (connectedAt <= 0) {
      return AgoraCallService.activeCallAccepted ? 'Connecting…' : 'Ringing…';
    }
    final total =
        (DateTime.now().millisecondsSinceEpoch - connectedAt) ~/ 1000;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    // The call screen already IS the call; a bubble pointing at it would be
    // a button that goes nowhere.
    if (!_inCall || AgoraCallService.isCallScreenVisible) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final size = media.size;

    // The pill under the avatar is part of the bubble's footprint, so the
    // clamp has to account for it or the clock can be pushed off-screen.
    const height = _size + 22;
    final minLeft = _margin;
    final maxLeft = size.width - _size - _margin;
    final minTop = media.padding.top + _margin;
    final maxTop = size.height - height - media.padding.bottom - _margin;

    // Default corner: bottom-right, clear of the navigation bar. Right rather
    // than left because that is the thumb's side on most phones.
    final fallback = Offset(maxLeft, maxTop - 24);
    final wanted = _position ?? fallback;
    final left = wanted.dx.clamp(minLeft, maxLeft > minLeft ? maxLeft : minLeft);
    final top = wanted.dy.clamp(minTop, maxTop > minTop ? maxTop : minTop);

    final info = AgoraCallService.activeCallInfo;
    final avatar = info?['peerAvatar']?.toString() ?? '';
    final isVideo = info?['callType']?.toString() == 'video';

    return AnimatedPositioned(
      // Instant while the finger is down — animating a drag makes it lag
      // behind the touch. The curve is only for the snap on release.
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: _size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => CallNavigation.openActiveCall(),
        onPanStart: (_) => setState(() {
          _dragging = true;
          _position = Offset(left, top);
        }),
        onPanUpdate: (d) => setState(() {
          _position = (_position ?? Offset(left, top)) + d.delta;
        }),
        onPanEnd: (_) => setState(() {
          _dragging = false;
          // Snap to the nearer side, the way every chat head does. Half-way
          // across the screen is the tipping point.
          final current = _position ?? Offset(left, top);
          final goRight = current.dx + _size / 2 > size.width / 2;
          _position = Offset(goRight ? maxLeft : minLeft, current.dy);
        }),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B1220),
                border: Border.all(color: const Color(0xFF22C55E), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipOval(
                      child: avatar.isNotEmpty
                          ? AppNetworkImage(
                              avatar,
                              width: _size,
                              height: _size,
                              errorWidget: const _BubbleAvatarFallback(),
                            )
                          : const _BubbleAvatarFallback(),
                    ),
                  ),
                  // A small marker so a glance tells voice from video without
                  // needing to read anything.
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  // Without tabular figures the clock jitters every second as
                  // the digits change width.
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleAvatarFallback extends StatelessWidget {
  const _BubbleAvatarFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1E293B),
        child: const Icon(Icons.person_rounded, size: 30, color: Colors.white70),
      );
}
