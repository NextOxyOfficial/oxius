import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Social-login buttons shared by the login and register screens.
/// [onProvider] is called with `'google'`, `'facebook'` or `'apple'`.
///
/// On iOS a "Continue with Apple" button renders ABOVE the row — App Store
/// guideline 4.8 requires Apple sign-in with equal prominence whenever other
/// third-party logins are offered.
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
    final showApple = !kIsWeb && Platform.isIOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showApple) ...[
          _AppleButton(
            onPressed: enabled ? () => onProvider('apple') : null,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _GoogleButton(
                onPressed: enabled ? () => onProvider('google') : null,
              ),
            ),
            const SizedBox(width: 12),
            // Facebook sign-in is not live yet — rendered disabled.
            const Expanded(child: _FacebookButton(onPressed: null)),
          ],
        ),
        const SizedBox(height: 6),
        // Caption sits directly under the (disabled) Facebook button.
        Row(
          children: const [
            Expanded(child: SizedBox()),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'এখন পাওয়া যাচ্ছে না',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Black "Continue with Apple" button per Apple's Human Interface Guidelines.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Colors.black,
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
            Icon(Icons.apple, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Continue with Apple',
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
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
  static const _disabledBg = Color(0xFFE5E7EB);
  static const _disabledFg = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    final Color fg = disabled ? _disabledFg : Colors.white;
    // No blue glow when disabled — it should read as clearly inactive.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled
            ? const []
            : [
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
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: _fbBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _disabledBg,
          disabledForegroundColor: _disabledFg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.facebook, size: 22, color: fg),
            const SizedBox(width: 10),
            Text(
              'Facebook',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: fg,
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
