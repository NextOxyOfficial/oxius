import 'package:flutter/material.dart';

/// The AdsyConnect brand chat icon (blue bubble with dots) used EVERYWHERE a
/// chat/message icon appears, so messaging is instantly recognizable across
/// the app. Falls back to a Material bubble if the asset ever fails.
class AdsyChatIcon extends StatelessWidget {
  final double size;

  /// Optional tint. Most placements keep the asset's own colors (pass null);
  /// pass white for use on solid/colored buttons.
  final Color? color;

  const AdsyChatIcon({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/chat_icon.png',
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.chat_bubble_rounded,
        size: size,
        color: color ?? const Color(0xFF2563EB),
      ),
    );
  }
}
