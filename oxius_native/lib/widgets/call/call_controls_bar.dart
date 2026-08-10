import 'package:flutter/material.dart';

/// Screen-edge gap the control bar is allowed to reach.
///
/// Shared with the width test below, and with the self-view's clearance —
/// they must all use the same number or the bar and the things that dodge it
/// disagree.
const double kCallControlsInset = 12;

/// The sizes the control bar lays out with at a given width.
///
/// One row, always. The controls used to be a fixed size and either
/// overflowed, scrolled (hiding End off the edge), or wrapped to a second
/// row that ate the screen. Sizing them to the width instead means every
/// control is visible and reachable on every phone, and the bar stays one
/// line high.
class CallControlMetrics {
  /// Diameter of an ordinary round control.
  final double button;

  /// Diameter of End, which stays a little larger than the rest.
  final double end;

  final double gap;
  final double hPad;
  final double vPad;

  /// Whether each control shows its word.
  ///
  /// The labels are worth real width — 12dp per control — and on the
  /// narrowest phones a video call cannot afford six of them AND buttons big
  /// enough to hit. Given that choice the words go: an icon you can press
  /// beats a label under a target too small to press.
  final bool showLabels;

  /// Total height of the bar, labels and padding included.
  ///
  /// Everything that has to stay clear of the bar reads this rather than
  /// keeping its own guess, which is how the info pills ended up drawn
  /// underneath the buttons.
  final double height;

  const CallControlMetrics({
    required this.button,
    required this.end,
    required this.gap,
    required this.hPad,
    required this.vPad,
    required this.height,
    required this.showLabels,
  });
}

/// Height of the word under each control: the 5px gap plus one 10px line.
const double _kControlLabelHeight = 18;

/// How much wider a control is than its button.
///
/// The label under each button gets a box of `size + 12` so a word like
/// "Speaker" is not clipped, and THAT is the control's real footprint. The
/// first version of this arithmetic measured buttons and forgot the labels,
/// which came to 60dp across five controls — enough to push End off the edge
/// of a 360dp phone even though the numbers said it fitted.
const double _kControlLabelPad = 12;

/// A control smaller than this stops being a reliable tap target.
const double _kMinControlSize = 38;

/// End relative to the others — enough to find without looking.
const double _kEndScale = 1.12;

CallControlMetrics callControlMetrics({
  required double screenWidth,
  required bool compact,
  required bool isVideo,
}) {
  // mute, speaker, add, end always; video adds camera and flip, audio adds
  // the upgrade-to-video button.
  final count = isVideo ? 6 : 5;
  final hPad = compact ? 8.0 : 12.0;
  final vPad = compact ? 7.0 : 9.0;
  var gap = compact ? 6.0 : 8.0;

  double fit(double g, bool labels) =>
      (screenWidth -
          kCallControlsInset * 2 -
          hPad * 2 -
          (count - 1) * g -
          (labels ? count * _kControlLabelPad : 0)) /
      (count - 1 + _kEndScale);

  var showLabels = true;
  var button = fit(gap, showLabels);

  // Too tight for a comfortable target. Buy back width in the order that
  // costs the user least: first the gaps, then the words.
  if (button < _kMinControlSize) {
    gap = 4;
    button = fit(gap, showLabels);
  }
  if (button < _kMinControlSize) {
    showLabels = false;
    gap = compact ? 6.0 : 8.0;
    button = fit(gap, showLabels);
  }

  // And never larger than the old fixed size, or a tablet gets dinner plates.
  final maxButton = compact ? 52.0 : 56.0;
  if (button > maxButton) button = maxButton;

  final end = button * _kEndScale;
  return CallControlMetrics(
    button: button,
    end: end,
    gap: gap,
    hPad: hPad,
    vPad: vPad,
    showLabels: showLabels,
    height: end + (showLabels ? _kControlLabelHeight : 0) + vPad * 2,
  );
}

/// One round button with its word underneath.
class CallRoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final bool isActive;
  final Color? activeBg;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool showLabel;

  const CallRoundControl({
    super.key,
    required this.icon,
    required this.label,
    required this.size,
    required this.isActive,
    required this.onTap,
    this.activeBg,
    this.iconColor,
    this.showLabel = true,
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
        // Icons alone leave people guessing which one is the speaker and
        // which the microphone, and a call is the worst place to find out by
        // trial and error — so the word stays wherever there is room for it.
        if (!showLabel)
          SizedBox(width: size)
        else ...[
          const SizedBox(height: 5),
          SizedBox(
            width: size + _kControlLabelPad,
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
      ],
    );
  }
}

/// The bar of controls across the bottom of a call — always a single row.
///
/// Neither of the earlier answers worked. A horizontal scroller hid controls
/// behind a gesture nobody thinks to try mid-call, and End could be the one
/// off the edge. Wrapping to a second row kept them all visible but took a
/// large bite out of a phone screen. Sizing the controls to the width fits
/// every one of them on one line instead, on every phone.
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
  final VoidCallback onRequestVideo;
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
    required this.onRequestVideo,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    final m = callControlMetrics(
      screenWidth: MediaQuery.sizeOf(context).width,
      compact: compact,
      isVideo: isVideo,
    );
    final btnSize = m.button;
    final endSize = m.end;

    final controls = <Widget>[
      CallRoundControl(
        icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
        label: isMuted ? 'Unmute' : 'Mute',
        size: btnSize,
        showLabel: m.showLabels,
        isActive: isMuted,
        activeBg: const Color(0xFFEF4444),
        onTap: onToggleMute,
      ),
      CallRoundControl(
        icon: isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
        label: 'Speaker',
        size: btnSize,
        showLabel: m.showLabels,
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
          icon:
              isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
          label: 'Camera',
          size: btnSize,
          isActive: isCameraOff,
          activeBg: const Color(0xFFEF4444),
          onTap: onToggleCamera,
        ),
      ],
      // Flip and Add are not here: they live on the left edge as bare icons
      // (see CallSideActions). Both are occasional, and next to Mute, Speaker
      // and End — which are not — they made the bar long enough to scroll on
      // a small phone, pushing the one button that must never be hunted for.
      CallRoundControl(
        icon: Icons.call_end_rounded,
        label: 'End',
        size: endSize,
        showLabel: m.showLabels,
        isActive: true,
        activeBg: const Color(0xFFEF4444),
        iconColor: Colors.white,
        onTap: onEndCall,
      ),
    ];

    return Positioned(
      left: kCallControlsInset,
      right: kCallControlsInset,
      bottom: compact ? 10 : 16,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: m.hPad, vertical: m.vPad),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(m.height / 2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < controls.length; i++) ...[
                if (i > 0) SizedBox(width: m.gap),
                controls[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
