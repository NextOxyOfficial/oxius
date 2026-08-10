import 'package:flutter/material.dart';

/// The occasional call actions, on the left edge of the video.
///
/// Flip-camera and add-someone are not things a person reaches for the way
/// they reach for mute or hang up, and sitting in the bottom bar they made it
/// long enough to scroll on a small phone — which put the End button behind a
/// swipe. Out here they stay one tap away without competing.
///
/// Drawn as bare icons with no filled background: they sit on top of live
/// video, where a row of solid circles reads as clutter. A soft shadow keeps
/// them legible over a bright frame, and the tap target stays a full 44dp
/// even though nothing is painted around it.
class CallSideActions extends StatelessWidget {
  const CallSideActions({
    super.key,
    required this.top,
    required this.showFlipCamera,
    required this.onSwitchCamera,
    required this.onAddParticipants,
  });

  /// Where the column starts, so the caller can clear its own header.
  final double top;

  /// Flipping only means something while a camera is running.
  final bool showFlipCamera;

  final VoidCallback onSwitchCamera;
  final VoidCallback onAddParticipants;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 6,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFlipCamera)
            _Action(
              icon: Icons.cameraswitch_rounded,
              tooltip: 'Flip camera',
              onTap: onSwitchCamera,
            ),
          _Action(
            icon: Icons.person_add_alt_1_rounded,
            tooltip: 'Add to call',
            onTap: onAddParticipants,
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
              // Video is unpredictable — a white icon over a white wall is
              // invisible without something behind it, and a shadow does that
              // without painting a box.
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 6),
                Shadow(color: Colors.black38, blurRadius: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
