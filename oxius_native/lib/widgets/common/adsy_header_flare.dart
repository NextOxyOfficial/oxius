import 'package:flutter/material.dart';

/// The homepage header's signature edge treatment: the two corners descend
/// BELOW the bar with a concave curve (flaring down into the page). Place
/// [AdsyHeaderFlares] directly under the header bar; [color] must match the
/// header background.
class AdsyHeaderFlares extends StatelessWidget {
  final Color color;
  final double size;

  const AdsyHeaderFlares({
    super.key,
    this.color = const Color(0xFFFBFCFD),
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    // Decorative only — must never intercept touches on content beneath
    // (the BN feed renders this strip as part of a floating overlay).
    return IgnorePointer(
      child: SizedBox(
        height: size,
        child: Row(
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: AdsyHeaderCornerPainter(isLeft: true, color: color),
            ),
            const Spacer(),
            CustomPaint(
              size: Size(size, size),
              painter: AdsyHeaderCornerPainter(isLeft: false, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class AdsyHeaderCornerPainter extends CustomPainter {
  final bool isLeft;
  final Color color;

  const AdsyHeaderCornerPainter({required this.isLeft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      // White sliver hugging the left screen edge; the arc bulges toward
      // the top-left so the corner reads as flaring DOWN from the header.
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
      path.arcToPoint(
        Offset(0, size.height),
        radius: Radius.circular(size.width),
        clockwise: false,
      );
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.arcToPoint(
        Offset(size.width, size.height),
        radius: Radius.circular(size.width),
        clockwise: true,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AdsyHeaderCornerPainter oldDelegate) =>
      oldDelegate.isLeft != isLeft || oldDelegate.color != color;
}
