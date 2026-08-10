import 'package:flutter/material.dart';

import '../app_network_image.dart';

/// The small presentational pieces the call screen is built out of.
///
/// None of them know anything about a call — they take what they draw. They
/// live here because call_screen.dart is a state machine, a media session and
/// a signalling client all at once, and four hundred lines of rounded
/// rectangles in the middle of that made the parts that actually decide
/// things harder to find.

/// The frosted slab every floating control sits on.
class CallGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const CallGlassPanel({
    super.key,
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: const Color(0xFF0F172A).withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

/// A tappable chip in the header — icon, optionally with a word beside it.
///
/// [dense] shrinks it for narrow phones, where the full-size chip took
/// enough width to truncate the caller's own name beside it.
class CallIconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool dense;

  const CallIconChip({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = dense ? 14.0 : 18.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          height: dense ? 38 : 50,
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? (dense ? 9 : 13) : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: const Color(0xFF0F172A).withValues(alpha: 0.72),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: dense ? 20 : 24),
              // A bare minus reads as "hide" or even "mute" to plenty of
              // people; the word removes the guess for the cost of 50px.
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A read-only fact about the call — "Secure", "Voice", the duration.
class CallInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const CallInfoPill({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Voice Call" / "Video Call", above the avatar while the call is being set up.
class CallTypeBadge extends StatelessWidget {
  final bool isVideo;
  final String label;
  final Color accent;

  const CallTypeBadge({
    super.key,
    required this.isVideo,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The peer's photo, or a person glyph when there is none.
class CallAvatarImage extends StatelessWidget {
  final String? avatarUrl;
  final double iconSize;

  const CallAvatarImage({
    super.key,
    required this.avatarUrl,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_rounded,
      size: iconSize,
      color: Colors.white.withValues(alpha: 0.72),
    );

    final url = avatarUrl;
    if (url == null || url.isEmpty) return fallback;
    return AppNetworkImage(url, errorWidget: fallback);
  }
}

/// The peer's photo with a ring that breathes outward while the call rings.
class CallAnimatedAvatar extends StatelessWidget {
  final double size;
  final Animation<double> pulse;
  final Color accent;
  final String? avatarUrl;

  const CallAnimatedAvatar({
    super.key,
    required this.size,
    required this.pulse,
    required this.accent,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = Curves.easeOut.transform(pulse.value);
        return SizedBox(
          width: size + 42,
          height: size + 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.2 * (1 - t),
                child: Container(
                  width: size + 34 + (t * 20),
                  height: size + 34 + (t * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withValues(alpha: 0.7), width: 1.6),
                  ),
                ),
              ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CallAvatarImage(
                  avatarUrl: avatarUrl,
                  iconSize: size * 0.34,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Accept / Decline on an incoming call.
class CallResponseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool compact;

  const CallResponseButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: backgroundColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: compact ? 20 : 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
