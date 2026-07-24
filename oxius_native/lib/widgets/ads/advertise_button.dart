import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _open() async {
    final uri = Uri.parse('https://adsyclub.com/business-network/abn-ads');
    // Try an in-app Custom Tab first; fall back to the external browser (and
    // finally the platform default) so the button always opens something even
    // when a device has no Custom Tabs provider.
    for (final mode in const [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ]) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (_) {
        // Try the next launch mode.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _open,
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
