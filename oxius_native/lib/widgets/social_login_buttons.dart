import 'package:flutter/material.dart';

/// Google + Facebook social-login button row, shared by the login and register
/// screens. [onProvider] is called with `'google'` or `'facebook'`.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    required this.onProvider,
    this.enabled = true,
  });

  final void Function(String provider) onProvider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GoogleButton(
            onPressed: enabled ? () => onProvider('google') : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FacebookButton(
            onPressed: enabled ? () => onProvider('facebook') : null,
          ),
        ),
      ],
    );
  }
}

/// White Google button with the multi-color "G" mark.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDCE6F2), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleLogo(size: 20),
            const SizedBox(width: 10),
            Text(
              'Google',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid Facebook-blue button.
class _FacebookButton extends StatelessWidget {
  const _FacebookButton({required this.onPressed});

  final VoidCallback? onPressed;
  static const _fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _fbBlue.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: _fbBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.facebook, size: 22, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Facebook',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand-accurate multi-color Google "G" drawn with a CustomPainter so no
/// asset is required.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      w - stroke,
      h - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four colored arcs of the Google ring.
    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, _deg(-20), _deg(95), false, paint);
    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, _deg(75), _deg(70), false, paint);
    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, _deg(140), _deg(60), false, paint);
    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, _deg(195), _deg(90), false, paint);

    // Horizontal bar of the "G".
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.52, h * 0.40, w * 0.46, stroke),
      barPaint,
    );
  }

  double _deg(double d) => d * 3.1415926535 / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
