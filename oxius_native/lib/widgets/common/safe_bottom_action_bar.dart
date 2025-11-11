import 'package:flutter/material.dart';

/// A bottom action bar that automatically handles safe area for device gestures.
/// Use this as a bottomNavigationBar replacement for action buttons.
/// 
/// Example:
/// ```dart
/// Scaffold(
///   bottomNavigationBar: SafeBottomActionBar(
///     child: Row(
///       children: [
///         Expanded(child: ElevatedButton(...)),
///         SizedBox(width: 8),
///         Expanded(child: ElevatedButton(...)),
///       ],
///     ),
///   ),
/// )
/// ```
class SafeBottomActionBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BoxDecoration? decoration;
  final double? elevation;

  const SafeBottomActionBar({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = Colors.white,
    this.decoration,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: padding,
        decoration: decoration ??
            BoxDecoration(
              color: backgroundColor,
              boxShadow: elevation != null
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: elevation!,
                        offset: const Offset(0, -2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, -1),
                      ),
                    ],
            ),
        child: child,
      ),
    );
  }
}

/// Pre-built safe bottom action bar with two buttons (e.g., Call & Chat)
class SafeBottomTwoActionBar extends StatelessWidget {
  final VoidCallback? onFirstAction;
  final VoidCallback? onSecondAction;
  final Widget firstButtonChild;
  final Widget secondButtonChild;
  final Color? firstButtonColor;
  final Color? secondButtonColor;
  final bool firstButtonOutlined;
  final bool secondButtonOutlined;

  const SafeBottomTwoActionBar({
    Key? key,
    required this.onFirstAction,
    required this.onSecondAction,
    required this.firstButtonChild,
    required this.secondButtonChild,
    this.firstButtonColor = const Color(0xFF10B981),
    this.secondButtonColor = const Color(0xFF10B981),
    this.firstButtonOutlined = false,
    this.secondButtonOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeBottomActionBar(
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              onPressed: onFirstAction,
              child: firstButtonChild,
              color: firstButtonColor!,
              outlined: firstButtonOutlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildButton(
              onPressed: onSecondAction,
              child: secondButtonChild,
              color: secondButtonColor!,
              outlined: secondButtonOutlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required Widget child,
    required Color color,
    required bool outlined,
  }) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: child,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: child,
      );
    }
  }
}
