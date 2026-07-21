import 'package:flutter/material.dart';

/// THE one Pro badge for the whole app — matches the Business Network feed
/// design (indigo pill, white "Pro") with a subtle shimmer sheen sweeping
/// across every few seconds. Use this everywhere instead of hand-rolled
/// badge containers so the look never drifts between screens.
///
/// Usage: `if (user.isPro) const AdsyProBadge()` — optionally pass
/// [fontSize] to scale it (default 10, chat lists may use 9).
class AdsyProBadge extends StatefulWidget {
  /// Text size; padding scales with it so the pill keeps its proportions.
  final double fontSize;

  const AdsyProBadge({super.key, this.fontSize = 10});

  @override
  State<AdsyProBadge> createState() => _AdsyProBadgeState();
}

class _AdsyProBadgeState extends State<AdsyProBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.fontSize;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: fs * 0.6,
              vertical: fs * 0.2,
            ),
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              'Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: fs,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          // Soft shimmer sheen gliding over the pill.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final dx = -1.8 + 3.6 * _controller.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(dx - 0.7, -0.5),
                        end: Alignment(dx + 0.7, 0.5),
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
