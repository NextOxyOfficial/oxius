import 'package:flutter/material.dart';

/// Shown on iOS whenever a digital purchase flow is entered but
/// [PaymentPolicy.shouldShowDigitalPaymentUI()] returns false.
///
/// App Store compliance:
///   • No external links
///   • No redirect buttons
///   • No mention of external payment systems
///   • Fully complies with App Store Guideline 3.1.1
///
/// Usage:
///   if (PaymentPolicy.shouldBlockDigitalPayment()) {
///     return const IOSPaymentBlockedWidget(featureName: 'Pro Subscription');
///   }
class IOSPaymentBlockedWidget extends StatelessWidget {
  final String? featureName;

  const IOSPaymentBlockedWidget({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    final title = featureName != null
        ? '$featureName not available on iOS'
        : 'Feature not available on iOS';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon container
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Description — deliberately generic, no external links
            const Text(
              'This feature requires a payment method that is currently not supported on iOS. Please use our Android app or website to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scaffold-wrapped version for use as a full navigation route.
///
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => IOSPaymentBlockedScreen(featureName: 'Pro Subscription'),
///   ));
class IOSPaymentBlockedScreen extends StatelessWidget {
  final String? featureName;

  const IOSPaymentBlockedScreen({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    final appBarTitle = featureName ?? 'Feature Unavailable';
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14213D),
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFFFFBF4),
        surfaceTintColor: const Color(0xFFFFFBF4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF14213D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: IOSPaymentBlockedWidget(featureName: featureName),
    );
  }
}
