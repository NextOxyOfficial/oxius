import 'package:flutter/material.dart';

class WebCheckoutFrame extends StatelessWidget {
  final String checkoutUrl;
  final ValueChanged<String>? onPageLoaded;

  const WebCheckoutFrame({
    super.key,
    required this.checkoutUrl,
    this.onPageLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}