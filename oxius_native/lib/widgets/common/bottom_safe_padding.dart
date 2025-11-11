import 'package:flutter/material.dart';

/// A widget that adds safe bottom padding to prevent content from being
/// hidden under device bottom navigation bars (gesture bars, software buttons).
/// 
/// Use this at the end of your ListView/SingleChildScrollView children list:
/// 
/// ```dart
/// ListView(
///   children: [
///     // Your content here
///     BottomSafePadding(), // Add this at the end
///   ],
/// )
/// ```
class BottomSafePadding extends StatelessWidget {
  /// Additional padding to add beyond the system safe area (default: 16)
  final double extraPadding;

  const BottomSafePadding({
    Key? key,
    this.extraPadding = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).padding.bottom + extraPadding,
    );
  }
}

/// Extension method to easily add bottom safe padding to a list of widgets
extension BottomSafePaddingExtension on List<Widget> {
  /// Adds a BottomSafePadding widget to the end of the list
  List<Widget> withBottomSafePadding({double extraPadding = 16}) {
    return [...this, BottomSafePadding(extraPadding: extraPadding)];
  }
}
