import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/video_playback_manager.dart';
import '../ios_web_redirect_screen.dart' show buildWebRedirectUrl;
import 'package:oxius_native/l10n/tr.dart';

/// "AdsyClub-এ বিজ্ঞাপন দিন" — a borderless, soft-tinted button used in the
/// app drawers and the home footer. Tapping opens the web ads panel in an
/// in-app browser tab (a plain external launch bounces back into the app via
/// App Links and lands on the feed instead of the panel).
class AdvertiseButton extends StatelessWidget {
  final String? label;

  /// Compact variant trims padding/typography for tighter spots (e.g. footer).
  final bool compact;

  const AdvertiseButton({
    super.key,
    this.label,
    this.compact = false,
  });

  static const _ink = Color(0xFF1D4ED8);
  static const _tint = Color(0xFFEFF4FF);

  /// Opens the web ads panel. Reused by every "বিজ্ঞাপন দিন" entry point.
  static Future<void> openAdsPanel() =>
      openWebPath('business-network/abn-ads');

  /// Opens any adsyclub.com page in url_launcher's in-app WebView, signed in
  /// via the web-token flow when possible.
  ///
  /// The WebView is the ONLY launch mode that never goes through Android's
  /// URL resolution: /business-network/* is a VERIFIED App Link of this app
  /// (AndroidManifest pathPrefix), so Custom Tab / external / default modes
  /// all hand the intent back to the app itself — landing on the BN screen
  /// instead of the web page. An explicit WebView activity cannot bounce.
  /// Marks a web path as "opened from inside the app".
  ///
  /// The web app keys its app-promotion behaviour off this: without it the
  /// Nuxt deep-link bridge sees /business-network and navigates the page to
  /// `adsyclub://open?url=...`, which an Android WebView cannot resolve — the
  /// panel is replaced by net::ERR_UNKNOWN_URL_SCHEME (iOS silently ignores
  /// the unknown scheme, which is why only Android showed the error). It also
  /// suppresses the store fallback and the "download the app" banners.
  static String _tagAsInApp(String webPath) =>
      webPath.contains('?') ? '$webPath&app=1' : '$webPath?app=1';

  static Future<void> openWebPath(String webPath) async {
    // The in-app WebView is a separate activity, not a Flutter route, so
    // nothing else pauses the feed — a video kept playing (audible) behind the
    // ads panel. Silence it before we hand off.
    VideoPlaybackManager.instance.pauseAll();
    final taggedPath = _tagAsInApp(webPath);
    Uri uri;
    try {
      // Auto-login token URL. The flag rides along on the redirect target so
      // it survives the /auth/app-login hop into the real page.
      uri = await buildWebRedirectUrl(taggedPath);
    } catch (_) {
      uri = Uri.parse('https://adsyclub.com/$taggedPath');
    }
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (_) {
      // Last resort: Custom Tab (may bounce on some devices, but better
      // than a dead tap if the WebView is unavailable).
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: openAdsPanel,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_rounded,
                  size: compact ? 16 : 18, color: _ink),
              SizedBox(width: compact ? 7 : 8),
              Flexible(
                child: Text(
                  label ?? tr('AdsyClub-এ বিজ্ঞাপন দিন'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
