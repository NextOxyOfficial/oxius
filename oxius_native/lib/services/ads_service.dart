import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Server-controlled ads (Google AdMob).
///
/// The backend (`/api/ads/config/`) decides EVERYTHING — master on/off,
/// test mode, brand-safety rating, and which placements are live with what
/// frequency and unit ids — so ads can be tuned or killed instantly from
/// Django admin without an app update.
///
/// test_mode=true serves Google's official sample ads (safe while the AdMob
/// review is pending — clicking real ads on your own device is a policy
/// violation). Flip it off in admin once AdMob approves the app.
class AdsService {
  AdsService._();

  // Google's official sample ad unit ids (always fill, never earn).
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  static bool _initialized = false;
  static bool _sdkReady = false;
  static bool _testMode = true;
  static Map<String, dynamic> _placements = {};

  /// True once the Mobile Ads SDK has been initialized.
  static bool get ready => _sdkReady;

  /// Fetch config and (if enabled) initialize the SDK. Safe to call more
  /// than once; never throws. No-op on web (google_mobile_ads is mobile-only).
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    try {
      var enabled = false;
      try {
        final res = await http
            .get(Uri.parse('${ApiService.baseUrl}/ads/config/'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map && data['enabled'] == true) {
            enabled = true;
            _testMode = data['test_mode'] != false;
            final placements = data['placements'];
            if (placements is Map) {
              _placements = Map<String, dynamic>.from(placements);
            }
            final rating = (data['content_rating'] ?? 'G').toString();
            await MobileAds.instance.updateRequestConfiguration(
              RequestConfiguration(maxAdContentRating: rating),
            );
          }
        }
      } catch (e) {
        debugPrint('[ads] config fetch failed: $e');
      }

      // Debug preview: even with the server config off/unreachable, show
      // Google's sample ads in debug builds so placements can be previewed.
      if (!enabled) {
        if (!kDebugMode) {
          debugPrint('[ads] disabled by server config');
          return;
        }
        _testMode = true;
        if (_placements.isEmpty) {
          _placements = {
            // NOTE: frequency 4 — the feed reserves i%5 slots for sponsored
            // products and i%10 for suggestions, so 5 would never render.
            'bn_feed_native': {'format': 'native', 'frequency': 4},
          };
        }
        debugPrint('[ads] server config off — debug test-ads preview');
      }

      await MobileAds.instance.initialize();
      _sdkReady = true;
      debugPrint('[ads] AdMob ready (test=$_testMode, '
          'placements=${_placements.keys.toList()})');
    } catch (e) {
      debugPrint('[ads] init skipped: $e');
    }
  }

  static Map<String, dynamic>? _placement(String key) {
    final p = _placements[key];
    return p is Map ? Map<String, dynamic>.from(p) : null;
  }

  /// Whether this placement should render (sdk ready + enabled + has an id).
  static bool placementActive(String key) =>
      _sdkReady && (adUnitId(key) ?? '').isNotEmpty;

  /// Platform-appropriate AdMob ad unit id for a placement. In test mode this
  /// is Google's sample native unit, so integration can be verified safely.
  static String? adUnitId(String key) {
    final p = _placement(key);
    if (p == null) return null;
    if (_testMode) {
      return Platform.isIOS ? _testNativeIos : _testNativeAndroid;
    }
    final id = Platform.isIOS
        ? (p['ad_unit_id_ios'] ?? '').toString()
        : (p['ad_unit_id_android'] ?? '').toString();
    return id.isEmpty ? null : id;
  }

  /// Feed placements: insert one ad after every N items (server-tunable).
  static int feedFrequency(String key, {int fallback = 4}) {
    final p = _placement(key);
    final f = p == null ? null : int.tryParse('${p['frequency']}');
    return (f == null || f < 2) ? fallback : f;
  }
}
