import '../config/payment_config.dart';

/// Single source of truth for every payment-related policy decision.
///
/// Usage
/// ─────
///   • Before calling a digital-purchase API:
///       if (!PaymentPolicy.canUseWalletForDigital()) return;
///
///   • Before rendering a purchase button / bottom-sheet:
///       if (!PaymentPolicy.shouldShowDigitalPaymentUI()) {
///         return const IOSPaymentBlockedWidget(featureName: 'Pro Subscription');
///       }
///
/// To enable IAP later, flip PaymentConfig.enableIAP = true.
/// No changes are needed here or in the calling screens.
class PaymentPolicy {
  PaymentPolicy._();

  // ── Core queries ───────────────────────────────────────────────────────────

  /// Can the current platform deduct wallet balance for a DIGITAL feature?
  ///
  /// Digital features include:
  ///   • Pro subscription
  ///   • Diamond purchase
  ///   • Gold sponsorship
  ///   • Gig posting fee
  ///   • Product slot purchase
  ///   • Rideshare custom location save
  ///   • Any other in-app feature unlock
  static bool canUseWalletForDigital() {
    // IAP overrides everything — when enabled iOS goes through IAP.
    if (PaymentConfig.enableIAP) return true;

    // Block on iOS until IAP is live.
    if (PaymentConfig.isIOS) return false;

    // Android / Web use external wallet freely.
    return PaymentConfig.enableDigitalPaymentsAndroid;
  }

  /// Physical-service payments (rideshare trips, COD e-shop orders) are always
  /// allowed on every platform.  Wallet balance may be used for these.
  static bool canUseWalletForPhysical() => true;

  /// Whether to render any digital-purchase UI element (buttons, upgrade
  /// screens, diamond sheets, sponsorship flows, etc.).
  ///
  /// When false, replace UI with [IOSPaymentBlockedWidget].
  static bool shouldShowDigitalPaymentUI() => canUseWalletForDigital();

  /// Whether to show native IAP purchase UI.
  /// Returns true only when IAP is enabled AND running on iOS.
  static bool shouldShowIAPUI() =>
      PaymentConfig.enableIAP && PaymentConfig.isIOS;

  // ── Convenience aliases (improve readability at call sites) ───────────────

  /// Opposite of [shouldShowDigitalPaymentUI] — use in `if` guards to
  /// short-circuit payment calls.
  static bool shouldBlockDigitalPayment() => !canUseWalletForDigital();
}
