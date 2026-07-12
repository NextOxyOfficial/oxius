import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Server-controlled ads (Google AdMob).
///
/// The backend (`/api/ads/config/`) decides EVERYTHING — master on/off,
/// test mode, brand-safety rating, and which placements are live (with their
/// format, frequency and unit ids) — so ads can be tuned or killed instantly
/// from Django admin without an app update.
///
/// Supported placement formats: `native` (feed/list), `interstitial`
/// (full-screen between actions), `rewarded` (watch-to-continue), `app_open`.
///
/// test_mode=true serves Google's official SAMPLE ads (always fill, never
/// earn) so integration can be verified safely — clicking real ads on your
/// own device is a policy violation. Flip it off in admin for real ads.
class AdsService {
  AdsService._();

  // ── Google's official SAMPLE ad unit ids, per format ──────────────────
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testAppOpenAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const _testAppOpenIos = 'ca-app-pub-3940256099942544/5575463023';

  static bool _initialized = false;
  static bool _sdkReady = false;
  static bool _testMode = true;
  static Map<String, dynamic> _placements = {};

  // Preloaded full-screen ads, keyed by placement, so a tap shows instantly.
  static final Map<String, InterstitialAd> _interstitials = {};
  static final Map<String, RewardedAd> _rewardeds = {};
  // Global gap so full-screen ads never stack back-to-back (anti-annoyance).
  static DateTime _lastFullScreen = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minFullScreenGap = Duration(seconds: 45);

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
            'bn_feed_native': {'format': 'native', 'frequency': 4},
            'gig_list_native': {'format': 'native', 'frequency': 5},
            'gig_submit_rewarded': {'format': 'rewarded'},
            'shorts_fullscreen': {'format': 'interstitial', 'frequency': 5},
            'sale_list_native': {'format': 'native', 'frequency': 6},
            'news_list_native': {'format': 'native', 'frequency': 5},
            'classified_list_native': {'format': 'native', 'frequency': 6},
            'foodzone_list_native': {'format': 'native', 'frequency': 6},
            'app_open': {'format': 'app_open'},
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

  static String _format(String key) =>
      (_placement(key)?['format'] ?? 'native').toString();

  /// Whether this placement should render (sdk ready + enabled + has an id).
  static bool placementActive(String key) =>
      _sdkReady && (adUnitId(key) ?? '').isNotEmpty;

  /// Platform + format appropriate AdMob unit id for a placement. In test
  /// mode this is Google's sample unit for the placement's format, so every
  /// format can be verified safely.
  static String? adUnitId(String key) {
    final p = _placement(key);
    if (p == null) return null;
    if (_testMode) {
      final ios = Platform.isIOS;
      switch (_format(key)) {
        case 'interstitial':
          return ios ? _testInterstitialIos : _testInterstitialAndroid;
        case 'rewarded':
          return ios ? _testRewardedIos : _testRewardedAndroid;
        case 'app_open':
          return ios ? _testAppOpenIos : _testAppOpenAndroid;
        default:
          return ios ? _testNativeIos : _testNativeAndroid;
      }
    }
    final id = Platform.isIOS
        ? (p['ad_unit_id_ios'] ?? '').toString()
        : (p['ad_unit_id_android'] ?? '').toString();
    return id.isEmpty ? null : id;
  }

  /// Feed/list placements: insert one ad after every N items (server-tunable).
  static int feedFrequency(String key, {int fallback = 4}) {
    final p = _placement(key);
    final f = p == null ? null : int.tryParse('${p['frequency']}');
    return (f == null || f < 2) ? fallback : f;
  }

  static bool _fullScreenTooSoon() =>
      DateTime.now().difference(_lastFullScreen) < _minFullScreenGap;

  // ── Interstitial ────────────────────────────────────────────────────────

  /// Preload an interstitial so a later [showInterstitial] is instant.
  static void preloadInterstitial(String key) {
    if (!placementActive(key) || _interstitials.containsKey(key)) return;
    final unit = adUnitId(key);
    if (unit == null) return;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitials[key] = ad,
        onAdFailedToLoad: (e) =>
            debugPrint('[ads] interstitial $key failed: ${e.code}'),
      ),
    );
  }

  /// Show an interstitial for [key]. Returns after it's dismissed (or right
  /// away if none is ready / it's too soon). Never throws.
  static Future<void> showInterstitial(String key) async {
    if (!placementActive(key) || _fullScreenTooSoon()) return;
    final ad = _interstitials.remove(key);
    if (ad == null) {
      preloadInterstitial(key); // warm up for next time
      return;
    }
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _lastFullScreen = DateTime.now();
        preloadInterstitial(key);
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        preloadInterstitial(key);
        if (!done.isCompleted) done.complete();
      },
    );
    ad.show();
    await done.future;
  }

  // ── Rewarded ────────────────────────────────────────────────────────────

  static void preloadRewarded(String key) {
    if (!placementActive(key) || _rewardeds.containsKey(key)) return;
    final unit = adUnitId(key);
    if (unit == null) return;
    RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardeds[key] = ad,
        onAdFailedToLoad: (e) =>
            debugPrint('[ads] rewarded $key failed: ${e.code}'),
      ),
    );
  }

  /// Show a rewarded ad. Returns true if the user earned the reward (watched
  /// it through). Returns false immediately if no ad is ready — callers must
  /// treat "no ad" as "proceed" so ads never BLOCK the user's core action.
  static Future<bool> showRewarded(String key) async {
    if (!placementActive(key)) return false;
    final ad = _rewardeds.remove(key);
    if (ad == null) {
      preloadRewarded(key);
      return false;
    }
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _lastFullScreen = DateTime.now();
        preloadRewarded(key);
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        preloadRewarded(key);
        if (!done.isCompleted) done.complete();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    await done.future;
    return earned;
  }

  // ── App Open ────────────────────────────────────────────────────────────

  static AppOpenAd? _appOpenAd;
  static bool _appOpenShowing = false;

  static void loadAppOpen() {
    if (!placementActive('app_open') || _appOpenAd != null) return;
    final unit = adUnitId('app_open');
    if (unit == null) return;
    AppOpenAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (e) =>
            debugPrint('[ads] app-open failed: ${e.code}'),
      ),
    );
  }

  static void showAppOpenIfReady() {
    if (_appOpenShowing || _fullScreenTooSoon()) return;
    final ad = _appOpenAd;
    if (ad == null) {
      loadAppOpen();
      return;
    }
    _appOpenAd = null;
    _appOpenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _appOpenShowing = false;
        _lastFullScreen = DateTime.now();
        loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _appOpenShowing = false;
        loadAppOpen();
      },
    );
    ad.show();
  }
}
