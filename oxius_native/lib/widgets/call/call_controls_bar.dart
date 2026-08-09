import 'package:flutter/material.dart';

/// Screen-edge gap the control bar is allowed to reach.
///
/// Shared with the width test below, and with the self-view's clearance —
/// they must all use the same number or the bar and the things that dodge it
/// disagree.
const double kCallControlsInset = 12;

/// Whether the call controls need a second row at this width.
///
/// A plain function so the arithmetic can be tested at specific screen
/// widths. The whole point is that the controls never overflow and never
/// hide behind a scroll gesture, and neither is something you can eyeball on
/// one device.
///
/// The numbers are the ones the bar lays out with: [count] round buttons,
/// the last of them the larger End button, separated by a gap, all inside
/// the bar's horizontal padding and the screen inset.
bool callControlsNeedTwoRows({
  required double screenWidth,
  required bool compact,
  required bool isVideo,
}) {
  // mute, speaker, add, end always; video adds camera and flip, audio adds
  // the upgrade-to-video button.
  final count = isVideo ? 6 : 5;
  final btn = compact ? 52.0 : 56.0;
  final end = compact ? 62.0 : 68.0;
  final gap = compact ? 8.0 : 10.0;
  final hPad = compact ? 10.0 : 14.0;
  final needed = (count - 1) * btn +
      end +
      (count - 1) * gap +
      hPad * 2 +
      kCallControlsInset * 2;
  return needed > screenWidth;
}

/// How much taller the bar is when it wraps — the self-view reads this so it
/// never parks under End, where dragging it clear means pressing the button
/// you are trying to avoid.
double callControlsWrapExtraHeight({required bool compact}) =>
    compact ? 64.0 : 70.0;

/// One round button with its word underneath.
class CallRoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final bool isActive;
  final Color? activeBg;
  final Color? iconColor;
  final VoidCallback onTap;

  const CallRoundControl({
    super.key,
    required this.icon,
    required this.label,
    required this.size,
    required this.isActive,
    required this.onTap,
    this.activeBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (activeBg ?? Colors.white)
            .withValues(alpha: activeBg != null ? 1 : 0.22)
        : Colors.white.withValues(alpha: 0.14);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
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
        ),
        const SizedBox(height: 5),
        // Icons alone leave people guessing which one is the speaker and
        // which the microphone, and a call is the worst place to find out by
        // trial and error.
        SizedBox(
          width: size + 12,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// The bar of controls across the bottom of a call.
///
/// Two rows rather than a horizontal scroller when the controls do not fit.
/// A scrolling control bar hides controls behind a gesture nobody thinks to
/// try during a call — End can be the one off the edge — and gives no hint
/// that anything is there.
class CallControlsBar extends StatelessWidget {
  final bool compact;
  final bool isVideo;
  final Color accent;

  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final bool awaitingVideoUpgrade;

  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onRequestVideo;
  final VoidCallback onAddParticipants;
  final VoidCallback onEndCall;

  const CallControlsBar({
    super.key,
    required this.compact,
    required this.isVideo,
    required this.accent,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isCameraOff,
    required this.awaitingVideoUpgrade,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onRequestVideo,
    required this.onAddParticipants,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 10.0 : 14.0;
    final endSize = compact ? 62.0 : 68.0;
    final btnSize = compact ? 52.0 : 56.0;
    final gap = compact ? 8.0 : 10.0;

    // Split by what a control does, not by where the arithmetic happens to
    // land: things you toggle about your own devices, then the two that
    // change who is on the call. A width-balanced split would put Flip and
    // Add together on one row and read like an accident.
    final toggles = <Widget>[
      CallRoundControl(
        icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
        label: isMuted ? 'Unmute' : 'Mute',
        size: btnSize,
        isActive: isMuted,
        activeBg: const Color(0xFFEF4444),
        onTap: onToggleMute,
      ),
      CallRoundControl(
        icon: isSpeakerOn
            ? Icons.volume_up_rounded
            : Icons.volume_down_rounded,
        label: 'Speaker',
        size: btnSize,
        isActive: isSpeakerOn,
        activeBg: accent,
        onTap: onToggleSpeaker,
      ),
      if (!isVideo)
        CallRoundControl(
          icon: Icons.videocam_outlined,
          label: awaitingVideoUpgrade ? 'Waiting' : 'Video',
          size: btnSize,
          isActive: awaitingVideoUpgrade,
          activeBg: accent,
          onTap: onRequestVideo,
        ),
      if (isVideo) ...[
        CallRoundControl(
          icon: isCameraOff
              ? Icons.videocam_off_rounded
              : Icons.videocam_rounded,
          label: 'Camera',
          size: btnSize,
          isActive: isCameraOff,
          activeBg: const Color(0xFFEF4444),
          onTap: onToggleCamera,
        ),
        CallRoundControl(
          icon: Icons.cameraswitch_rounded,
          label: 'Flip',
          size: btnSize,
          isActive: false,
          onTap: onSwitchCamera,
        ),
      ],
    ];

    final actions = <Widget>[
      CallRoundControl(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add',
        size: btnSize,
        isActive: false,
        onTap: onAddParticipants,
      ),
      CallRoundControl(
        icon: Icons.call_end_rounded,
        label: 'End',
        size: endSize,
        isActive: true,
        activeBg: const Color(0xFFEF4444),
        iconColor: Colors.white,
        onTap: onEndCall,
      ),
    ];

    Widget row(List<Widget> children) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              children[i],
            ],
          ],
        );

    final wrap = callControlsNeedTwoRows(
      screenWidth: MediaQuery.sizeOf(context).width,
      compact: compact,
      isVideo: isVideo,
    );

    return Positioned(
      left: kCallControlsInset,
      right: kCallControlsInset,
      bottom: compact ? 16 : 24,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: hPad, vertical: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(wrap ? 28 : 36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: wrap
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    row(toggles),
                    SizedBox(height: compact ? 8 : 10),
                    row(actions),
                  ],
                )
              : row([...toggles, ...actions]),
        ),
      ),
    );
  }
}
