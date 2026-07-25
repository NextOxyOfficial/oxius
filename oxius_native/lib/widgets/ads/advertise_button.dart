import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ios_web_redirect_screen.dart' show buildWebRedirectUrl;

/// "AdsyClub-এ বিজ্ঞাপন দিন" — a borderless, soft-tinted button used in the
/// app drawers and the home footer. Tapping opens the web ads panel in an
/// in-app browser tab (a plain external launch bounces back into the app via
/// App Links and lands on the feed instead of the panel).
class AdvertiseButton extends StatelessWidget {
  final String label;

  /// Compact variant trims padding/typography for tighter spots (e.g. footer).
  final bool compact;

  const AdvertiseButton({
    super.key,
    this.label = 'AdsyClub-এ বিজ্ঞাপন দিন',
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
  static Future<void> openWebPath(String webPath) async {
    Uri uri;
    try {
      uri = await buildWebRedirectUrl(webPath); // auto-login token URL
    } catch (_) {
      uri = Uri.parse('https://adsyclub.com/$webPath');
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
                  label,
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
