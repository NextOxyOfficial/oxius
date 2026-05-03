import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central payment configuration.
///
/// iOS compliance strategy
/// ────────────────────────
/// Apple App Store Guideline 3.1.1 forbids using an external payment system
/// to unlock digital features/content inside an iOS app.  We comply by
/// blocking all digital wallet-deductions on iOS at the policy layer.
///
/// Android / Web keep full monetisation unchanged.
///
/// Future IAP path
/// ───────────────
/// When Apple IAP is integrated, flip [enableIAP] = true.  Every policy
/// check in [PaymentPolicy] will then automatically allow digital purchases
/// on iOS through IAP instead.
class PaymentConfig {
  PaymentConfig._();

  // ── Platform ─────────────────────────────────────────────────────────────

  /// True only when running as a native iOS build (never on web).
  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  // ── Wallet / External gateway ─────────────────────────────────────────────

  /// ShurjoPay deposit & withdraw are allowed on every platform.
  /// Physical service payments (rideshare, COD e-shop) also use this path.
  static const bool enableExternalWallet = true;

  // ── Digital purchases ─────────────────────────────────────────────────────

  /// Allow wallet balance to be spent on DIGITAL features on Android / Web.
  static const bool enableDigitalPaymentsAndroid = true;

  /// Allow wallet balance to be spent on DIGITAL features on iOS.
  ///
  /// Must remain false until Apple IAP is live ([enableIAP] = true).
  static const bool enableDigitalPaymentsIOS = false;

  // ── IAP (future) ──────────────────────────────────────────────────────────

  /// Master switch for Apple In-App Purchase.
  ///
  /// Set this to `true` once the `in_app_purchase` integration is complete.
  /// All policy guards will automatically route iOS users through IAP instead
  /// of showing the blocked screen.
  static const bool enableIAP = false;
}
