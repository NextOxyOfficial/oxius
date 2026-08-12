import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Server-controlled ad SLOTS for our own (house) ads.
///
/// AdMob was removed in August 2026: Google terminated the publisher account
/// for invalid traffic and refused the appeal. The likely trigger was a
/// rewarded video on gig submit — an ad watched for a reward, inside an app
/// people open to earn, is exactly the incentivised pattern ad networks ban.
/// It is not coming back in any form, with any network.
///
/// Every ad the app shows now comes from the ABN Ads Panel through
/// [HouseAdsService], so 100% of the revenue stays on the platform and no
/// third party can switch it off.
///
/// What remains here is the part house ads still need: the backend
/// (`/api/ads/config/`) decides which feed/list slots are live and how often
/// they repeat, so slots stay tunable from Django admin without an app update.
class AdsService {
  AdsService._();

  static bool _initialized = false;
  static Map<String, dynamic> _placements = {};

  /// Fetch the slot config. Safe to call more than once; never throws.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/ads/config/'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['placements'] is Map) {
          _placements = Map<String, dynamic>.from(data['placements'] as Map);
        }
      }
    } catch (e) {
      // No config just means "defaults", and the default is ON — these are ads
      // we own, so a network blip must never blank out our own inventory.
      debugPrint('[ads] slot config fetch failed: $e');
    }
  }

  static Map<String, dynamic>? _placement(String key) {
    final p = _placements[key];
    return p is Map ? Map<String, dynamic>.from(p) : null;
  }

  /// Whether a feed/list house-ad slot should render. Slots are on unless the
  /// server config explicitly sets `placements[key] = false`.
  static bool hybridSlotActive(String key) => _placements[key] != false;

  /// Feed/list slots: insert one ad after every N items (server-tunable).
  static int feedFrequency(String key, {int fallback = 4}) {
    final p = _placement(key);
    final f = p == null ? null : int.tryParse('${p['frequency']}');
    return (f == null || f < 2) ? fallback : f;
  }
}
