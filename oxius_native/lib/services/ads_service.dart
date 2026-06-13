import 'dart:convert';
import 'dart:io' show Platform;

// ── AppLovin MAX temporarily DISABLED (account approval pending) ──
// import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Server-controlled ads (AppLovin MAX).
///
/// The backend (`/api/ads/config/`) decides EVERYTHING — master on/off, the
/// MAX SDK key, and which placements are live with what frequency — so ads can
/// be tuned or killed instantly from Django admin without an app update.
/// When the config is disabled (or unreachable) the app renders zero ads.
class AdsService {
  AdsService._();

  static bool _initialized = false;
  static bool _sdkReady = false;
  static Map<String, dynamic> _placements = {};

  /// True once the MAX SDK has been initialized with the server's key.
  static bool get ready => _sdkReady;

  /// Fetch config and (if enabled) initialize the MAX SDK. Safe to call more
  /// than once; never throws.
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/ads/config/'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      if (data is! Map || data['enabled'] != true) {
        debugPrint('[ads] disabled by server config');
        return;
      }
      final sdkKey = (data['sdk_key'] ?? '').toString();
      final placements = data['placements'];
      if (placements is Map) {
        _placements = Map<String, dynamic>.from(placements);
      }
      if (sdkKey.isEmpty || _placements.isEmpty) {
        debugPrint('[ads] no sdk key / placements — staying off');
        return;
      }
      // ── AppLovin MAX temporarily DISABLED (account approval pending) ──
      // When the AppLovin account is approved, re-add `applovin_max` to
      // pubspec, restore the import above, and replace the two lines below with:
      //   final conf = await AppLovinMAX.initialize(sdkKey);
      //   _sdkReady = conf != null;
      _sdkReady = false;
      debugPrint('[ads] MAX disabled — account approval pending '
          '(sdkKey present=${sdkKey.isNotEmpty}, '
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

  /// Platform-appropriate MAX ad unit id for a placement.
  static String? adUnitId(String key) {
    final p = _placement(key);
    if (p == null) return null;
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
