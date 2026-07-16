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
/// A Google Play purchase that belongs to a different AdsyClub account.
///
/// Play allows only one active subscription per base plan per *Google* account,
/// and it has no idea which AdsyClub account is signed in. So a user who buys
/// Pro on one AdsyClub account and then signs into another is told "already
/// subscribed" forever. This describes that situation so the UI can explain it
/// and offer to move the entitlement.
class IapOwnershipConflict {
  final String purchaseToken;
  final String productId;

  /// Masked email of the AdsyClub account holding it, e.g. `a***@gmail.com`.
  final String ownerHint;
  final bool canTransfer;

  /// Why a transfer is unavailable, e.g. `cooldown_12d`, when [canTransfer]
  /// is false.
  final String reason;

  const IapOwnershipConflict({
    required this.purchaseToken,
    required this.productId,
    this.ownerHint = '',
    this.canTransfer = false,
    this.reason = '',
  });
}

class GooglePlayBilling {
  GooglePlayBilling._();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool _available = false;
  static bool _initialized = false;

  static final Map<String, ProductDetails> _details = {};
  // Server-issued obfuscatedAccountId for the signed-in user. Attached to every
  // purchase so Play (and our verify step) can tell which AdsyClub account
  // bought it — a Google account and an AdsyClub account are not the same thing.
  static String _accountId = '';
  // Set when a purchase turns out to belong to a different AdsyClub account.
  static IapOwnershipConflict? lastConflict;
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
      // Authenticated so the response carries this user's obfuscatedAccountId,
      // which Play needs attached to the purchase.
      final res = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/iap/products/?kind=$kind'),
            headers: await ApiService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body);
      _accountId = (body['account_id'] ?? '').toString();
      final rows = (body['products'] as List?) ?? [];
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

    // applicationUserName maps to Play's obfuscatedAccountId.
    final param = PurchaseParam(
      productDetails: pd,
      applicationUserName: _accountId.isEmpty ? null : _accountId,
    );
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
      // Real amount paid on Google Play (localized) so the history shows it.
      final pd = _details[p.productID];
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/iap/verify/'),
            headers: headers,
            body: jsonEncode({
              'product_id': p.productID,
              'purchase_token': token,
              if (refId != null) 'ref_id': refId,
              if (pd != null) 'amount': pd.rawPrice,
              if (pd != null) 'currency': pd.currencyCode,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      if (res.statusCode == 409) {
        // The buyer's Google account already spent this purchase on a different
        // AdsyClub account. Play will keep saying "already subscribed" no matter
        // which AdsyClub account is signed in, so record the details and let the
        // UI offer to move the entitlement here.
        final data = jsonDecode(res.body);
        if (data['error'] == 'token_owned_by_other_account') {
          lastConflict = IapOwnershipConflict(
            purchaseToken: token,
            productId: p.productID,
            ownerHint: (data['owner_hint'] ?? '').toString(),
          );
          await _hydrateConflict();
        }
        return false;
      }
      debugPrint('[iap] verify -> ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      debugPrint('[iap] verify request failed: $e');
      return false;
    }
  }

  /// Ask the server whether [lastConflict] can actually be transferred (it has
  /// the cooldown rules), so the UI knows which buttons to show.
  static Future<void> _hydrateConflict() async {
    final c = lastConflict;
    if (c == null) return;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/iap/resolve-token/'),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({'purchase_token': c.purchaseToken}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      lastConflict = IapOwnershipConflict(
        purchaseToken: c.purchaseToken,
        productId: c.productId,
        ownerHint: (data['owner_hint'] ?? c.ownerHint).toString(),
        canTransfer: data['can_transfer'] == true,
        reason: (data['reason'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('[iap] resolve-token failed: $e');
    }
  }

  /// Pull past purchases from Play so an existing subscription bought on this
  /// Google account surfaces (either restoring the entitlement, or raising a
  /// conflict via [lastConflict]). Call before offering to subscribe.
  static Future<IapOwnershipConflict?> checkExistingPurchases() async {
    if (!_supported) return null;
    await init();
    if (!_available) return null;
    lastConflict = null;
    try {
      await _iap.restorePurchases();
      // restorePurchases replays through the purchase stream; give it a beat to
      // land before reporting what it found.
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('[iap] restorePurchases failed: $e');
    }
    return lastConflict;
  }

  /// Move the entitlement behind [purchaseToken] onto the signed-in AdsyClub
  /// account. The Google-side subscription is untouched — only which of the
  /// user's AdsyClub accounts holds it changes.
  static Future<bool> transferToCurrentAccount(String purchaseToken) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/iap/transfer/'),
            headers: await ApiService.getHeaders(),
            body: jsonEncode({'purchase_token': purchaseToken}),
          )
          .timeout(const Duration(seconds: 25));
      final ok = res.statusCode == 200 &&
          jsonDecode(res.body)['success'] == true;
      if (ok) lastConflict = null;
      if (!ok) debugPrint('[iap] transfer -> ${res.statusCode} ${res.body}');
      return ok;
    } catch (e) {
      debugPrint('[iap] transfer request failed: $e');
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
