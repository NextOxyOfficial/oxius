import 'package:flutter/material.dart';

/// The ONE scroll-jump circle used across the app — dark ink circle with a
/// white chevron. Use directly for custom logic (e.g. chat's jump-to-bottom)
/// or via [AdsyBackToTop] for the standard back-to-top behaviour.
class AdsyScrollCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  /// true = chevron up (back to top), false = chevron down (to bottom).
  final bool up;
  final double size;

  const AdsyScrollCircleButton({
    super.key,
    required this.onTap,
    this.up = true,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          up
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}

/// Universal "back to top" button — one look everywhere.
///
/// Attach the same [ScrollController] that drives the page's scrollable and
/// drop this widget inside a [Stack]; it fades in after the user scrolls past
/// [showAfter] and smoothly scrolls back to the top when tapped.
class AdsyBackToTop extends StatefulWidget {
  final ScrollController controller;

  /// Pixels scrolled before the button appears.
  final double showAfter;

  /// Distance from the bottom edge (raise it above bottom bars/pills).
  final double bottom;

  /// Distance from the right edge.
  final double right;

  const AdsyBackToTop({
    super.key,
    required this.controller,
    this.showAfter = 600,
    this.bottom = 16,
    this.right = 14,
  });

  @override
  State<AdsyBackToTop> createState() => _AdsyBackToTopState();
}

class _AdsyBackToTopState extends State<AdsyBackToTop> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant AdsyBackToTop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final show = widget.controller.position.pixels > widget.showAfter;
    if (show != _visible && mounted) {
      setState(() => _visible = show);
    }
  }

  void _scrollToTop() {
    if (!widget.controller.hasClients) return;
    widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.right,
      bottom: widget.bottom,
      child: IgnorePointer(
        ignoring: !_visible,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: AdsyScrollCircleButton(onTap: _scrollToTop),
        ),
      ),
    );
  }
}
