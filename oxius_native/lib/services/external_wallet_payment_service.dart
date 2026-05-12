import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_service.dart';
import 'api_service.dart';
import 'subscription_service.dart';
import 'diamond_service.dart';

/// Implements [PaymentService] using the existing AdsyPay wallet balance.
///
/// This is the active implementation on Android / Web.
/// On iOS it is never called — [PaymentPolicy.shouldBlockDigitalPayment()]
/// returns true before any call reaches this service.
class ExternalWalletPaymentService extends PaymentService {
  const ExternalWalletPaymentService();

  // ── Subscription ───────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> purchaseSubscription({
    required int months,
    required double total,
  }) async {
    return await SubscriptionService().createSubscription(
      months: months,
      total: total.round(),
    );
  }

  // ── Diamonds ───────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> purchaseDiamonds({
    required int amount,
    required double cost,
  }) async {
    return await DiamondService.purchaseDiamonds(amount: amount, cost: cost);
  }

  // ── Generic feature unlock ─────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> purchaseFeature({
    required String featureKey,
    required Map<String, dynamic> params,
  }) async {
    final headers = await ApiService.getHeaders();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/purchase-feature/$featureKey/'),
      headers: headers,
      body: json.encode(params),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final error = json.decode(response.body) as Map<String, dynamic>;
    throw Exception(
      error['error'] ?? error['message'] ?? 'Feature purchase failed',
    );
  }
}
