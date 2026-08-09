import 'package:flutter/material.dart';

import 'call_chrome.dart';

/// The things a call says to you without interrupting it.
///
/// All three are positioned, so they are placed directly into the call
/// screen's Stack. The two pills stack: the transient note sits below the
/// connection warning when both are up, rather than on top of it.

/// Where a pill sits under the header, and how far the second one drops.
double _pillTop({required bool compact}) => compact ? 78 : 92;
const double _pillStackGap = 40;

/// "Your connection is weak" — shown while the media layer says so.
class CallPoorConnectionBanner extends StatelessWidget {
  final bool compact;

  const CallPoorConnectionBanner({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _pillTop(compact: compact),
      left: 18,
      right: 18,
      child: const Center(
        child: _Pill(
          background: Color(0xE9B45309),
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.white,
          text: 'Your connection is weak',
          bold: true,
        ),
      ),
    );
  }
}

/// "Someone left the call" and the like — up for a few seconds, then gone.
///
/// Deliberately not the status overlay: that one is for the end of a call
/// and stays until the screen goes, which would leave "Carol left" reading
/// like a hang-up for the rest of the conversation.
class CallTransientNote extends StatelessWidget {
  final String text;
  final bool compact;

  /// Drops below the connection warning when that is also up.
  final bool stacked;

  const CallTransientNote({
    super.key,
    required this.text,
    required this.compact,
    required this.stacked,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _pillTop(compact: compact) + (stacked ? _pillStackGap : 0),
      left: 18,
      right: 18,
      child: Center(
        child: _Pill(
          background: const Color(0xFF0F172A).withValues(alpha: 0.88),
          border: Colors.white.withValues(alpha: 0.12),
          icon: Icons.logout_rounded,
          iconColor: const Color(0xFF94A3B8),
          text: text,
        ),
      ),
    );
  }
}

/// "Call ended", "Call declined" — the last thing shown before the screen goes.
class CallStatusOverlay extends StatelessWidget {
  final String text;

  const CallStatusOverlay({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey<String>(text),
              child: CallGlassPanel(
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
                      text,
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
}

class _Pill extends StatelessWidget {
  final Color background;
  final Color? border;
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool bold;

  const _Pill({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.border,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
