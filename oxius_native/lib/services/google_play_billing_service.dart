import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_service.dart';

/// Google Play In-App Purchase (Android) for the app's digital goods:
/// diamonds (consumable), Pro and Gold Sponsor (auto-renew subscriptions).
///
/// Flow: load product ids from the backend (`/iap/products/`) → query Play for
/// their real prices → launch the Play purchase → on success send the purchase
/// token to `/iap/verify/` for server-side verification + entitlement → finish
/// the purchase (consume diamonds). Nothing is granted client-side; the server
/// is the source of truth.
class GooglePlayBilling {
  GooglePlayBilling._();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool _available = false;
  static bool _initialized = false;

  static final Map<String, ProductDetails> _details = {};
  // In-flight purchase context, keyed by productId.
  static final Map<String, Completer<bool>> _pending = {};
  static final Map<String, Map<String, String>> _ctx = {};

  static bool get available => _available;

  /// Android-only: Google Play Billing. iOS IAP (StoreKit) is a separate,
  /// later setup — on iOS this whole service stays inert so the app never
  /// offers a broken Google Play option.
  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static Future<void> init() async {
    if (_initialized || !_supported) return;
    _initialized = true;
    try {
      _available = await _iap.isAvailable();
      _sub ??= _iap.purchaseStream.listen(
        _onPurchases,
        onError: (e) => debugPrint('[iap] purchaseStream error: $e'),
      );
    } catch (e) {
      debugPrint('[iap] init failed: $e');
    }
  }

  /// Product catalog rows from the backend for a kind (diamonds|pro|gold),
  /// merged with Play's live price/title. Empty until the admin fills the
  /// Play product ids.
  static Future<List<IapCatalogItem>> loadCatalog(String kind) async {
    if (!_supported) return []; // Android only
    await init();
    if (!_available) return [];
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/iap/products/?kind=$kind'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final rows = (jsonDecode(res.body)['products'] as List?) ?? [];
      final ids = rows
          .map((e) => (e['google_product_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (ids.isEmpty) return [];
      final resp = await _iap.queryProductDetails(ids);
      for (final p in resp.productDetails) {
        _details[p.id] = p;
      }
      final out = <IapCatalogItem>[];
      for (final row in rows) {
        final id = (row['google_product_id'] ?? '').toString();
        final pd = _details[id];
        if (pd == null) continue; // not available on Play yet
        out.add(IapCatalogItem(
          productId: id,
          kind: (row['kind'] ?? kind).toString(),
          title: (row['title'] ?? pd.title).toString(),
          diamonds: int.tryParse('${row['diamonds']}') ?? 0,
          isSubscription: row['is_subscription'] == true,
          price: pd.price, // Play's localized price string
          details: pd,
        ));
      }
      return out;
    } catch (e) {
      debugPrint('[iap] loadCatalog failed: $e');
      return [];
    }
  }

  /// Launch the Play purchase for [item]. Returns true once verified + granted
  /// by the server. [refId] links the purchase to an in-app object (e.g. a
  /// pending Gold Sponsor id).
  static Future<bool> buy(IapCatalogItem item, {String? refId}) async {
    if (!_supported) return false; // Android only
    await init();
    if (!_available) return false;
    final pd = _details[item.productId];
    if (pd == null) return false;

    // A previous attempt for the same product may still be pending.
    _pending[item.productId]?.complete(false);
    final completer = Completer<bool>();
    _pending[item.productId] = completer;
    _ctx[item.productId] = {
      'kind': item.kind,
      if (refId != null && refId.isNotEmpty) 'refId': refId,
    };

    final param = PurchaseParam(productDetails: pd);
    try {
      if (item.isSubscription) {
        await _iap.buyNonConsumable(purchaseParam: param);
      } else {
        // Diamonds — consumable so they can be bought again.
        await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
      }
    } catch (e) {
      debugPrint('[iap] buy launch failed: $e');
      _resolve(item.productId, false);
    }
    return completer.future
        .timeout(const Duration(minutes: 5), onTimeout: () => false);
  }

  static void _resolve(String productId, bool ok) {
    final c = _pending.remove(productId);
    _ctx.remove(productId);
    if (c != null && !c.isCompleted) c.complete(ok);
  }

  static Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          break; // wait
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          _resolve(p.productID, false);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ctx = _ctx[p.productID] ?? const {};
          final ok = await _verifyWithServer(
              p, ctx['kind'] ?? '', ctx['refId']);
          // Finish/consume regardless so the SDK doesn't replay it; if the
          // server didn't grant, the purchase is recorded server-side and can
          // be reconciled from the admin / RTDN.
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          _resolve(p.productID, ok);
          break;
      }
    }
  }

  static Future<bool> _verifyWithServer(
      PurchaseDetails p, String kind, String? refId) async {
    try {
      final token = p.verificationData.serverVerificationData;
      final headers = await ApiService.getHeaders();
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/iap/verify/'),
            headers: headers,
            body: jsonEncode({
              'product_id': p.productID,
              'purchase_token': token,
              if (refId != null) 'ref_id': refId,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      debugPrint('[iap] verify -> ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      debugPrint('[iap] verify request failed: $e');
      return false;
    }
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

class IapCatalogItem {
  final String productId;
  final String kind;
  final String title;
  final int diamonds;
  final bool isSubscription;
  final String price; // Play's localized price string
  final ProductDetails details;

  IapCatalogItem({
    required this.productId,
    required this.kind,
    required this.title,
    required this.diamonds,
    required this.isSubscription,
    required this.price,
    required this.details,
  });
}
