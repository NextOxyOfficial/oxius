/// Abstract contract for all digital-purchase flows.
///
/// Current implementation: [ExternalWalletPaymentService] (wallet balance).
/// Future implementation:   [IAPPaymentService]            (Apple IAP).
///
/// Switch is controlled by [PaymentConfig.enableIAP].  See [PaymentServiceFactory].
abstract class PaymentService {
  const PaymentService();

  // ── Subscriptions ──────────────────────────────────────────────────────────

  /// Purchase a Pro subscription for [months] months at [total] BDT/currency.
  /// Returns the API response map on success; throws on failure.
  Future<Map<String, dynamic>> purchaseSubscription({
    required int months,
    required double total,
  });

  // ── Diamonds ───────────────────────────────────────────────────────────────

  /// Purchase [amount] diamonds at [cost] BDT/currency.
  /// Returns the API response map on success; throws on failure.
  Future<Map<String, dynamic>?> purchaseDiamonds({
    required int amount,
    required double cost,
  });

  // ── Generic feature unlock ─────────────────────────────────────────────────

  /// Purchase a generic digital feature (product slot, custom location, etc.).
  ///
  /// [featureKey] — machine-readable identifier (e.g. 'product_slot',
  ///                'custom_location', 'gold_sponsor').
  /// [params]     — feature-specific parameters forwarded to the backend.
  Future<Map<String, dynamic>> purchaseFeature({
    required String featureKey,
    required Map<String, dynamic> params,
  });
}
