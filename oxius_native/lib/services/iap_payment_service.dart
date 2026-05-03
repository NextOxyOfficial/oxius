import 'payment_service.dart';

/// Placeholder for Apple In-App Purchase integration.
///
/// This service will be wired up once the `in_app_purchase` Flutter plugin is
/// integrated.  Until then [PaymentConfig.enableIAP] remains false and this
/// class is never instantiated.
///
/// To activate:
///   1. Add `in_app_purchase` to pubspec.yaml.
///   2. Implement each method using the IAP plugin.
///   3. Register product IDs in App Store Connect.
///   4. Set PaymentConfig.enableIAP = true.
///   5. [PaymentServiceFactory] will automatically use this service on iOS.
class IAPPaymentService extends PaymentService {
  const IAPPaymentService();

  // ── Apple product ID constants ─────────────────────────────────────────────
  // Define these once actual IAP products are created in App Store Connect.
  //
  // static const String kProMonthly     = 'com.adsyclub.pro.monthly';
  // static const String kProYearly      = 'com.adsyclub.pro.yearly';
  // static const String kDiamonds10     = 'com.adsyclub.diamonds.10';
  // static const String kDiamonds50     = 'com.adsyclub.diamonds.50';
  // static const String kDiamonds100    = 'com.adsyclub.diamonds.100';
  // static const String kProductSlot    = 'com.adsyclub.slot.product';
  // static const String kCustomLocation = 'com.adsyclub.rideshare.custom_location';

  @override
  Future<Map<String, dynamic>> purchaseSubscription({
    required int months,
    required double total,
  }) async {
    // TODO: launch IAP flow for the correct subscription product ID.
    throw UnimplementedError('IAPPaymentService.purchaseSubscription not yet implemented');
  }

  @override
  Future<Map<String, dynamic>?> purchaseDiamonds({
    required int amount,
    required double cost,
  }) async {
    // TODO: map [amount] to the nearest IAP diamond package product ID.
    throw UnimplementedError('IAPPaymentService.purchaseDiamonds not yet implemented');
  }

  @override
  Future<Map<String, dynamic>> purchaseFeature({
    required String featureKey,
    required Map<String, dynamic> params,
  }) async {
    // TODO: look up the IAP product ID for [featureKey] and launch IAP flow.
    throw UnimplementedError('IAPPaymentService.purchaseFeature not yet implemented');
  }
}
