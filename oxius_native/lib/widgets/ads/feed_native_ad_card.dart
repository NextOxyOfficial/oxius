import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads_service.dart';

/// Business Network feed native ad slot (Google AdMob).
///
/// Uses the SDK's native TEMPLATE rendering (no platform-side factory
/// needed): a medium template styled to sit flush with the feed's post
/// cards, under a small "Sponsored" strip. Renders nothing until the ad
/// actually loads, so the feed never shows an empty grey box.
class FeedNativeAdCard extends StatefulWidget {
  final String placementKey;
  const FeedNativeAdCard({super.key, this.placementKey = 'bn_feed_native'});

  @override
  State<FeedNativeAdCard> createState() => _FeedNativeAdCardState();
}

class _FeedNativeAdCardState extends State<FeedNativeAdCard>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  // Keep the loaded ad alive while the feed recycles items — otherwise every
  // scroll-away disposes and re-requests the ad (wasted fill + flicker).
  @override
  bool get wantKeepAlive => _loaded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (kIsWeb) return;
    final unitId = AdsService.adUnitId(widget.placementKey);
    if (unitId == null || unitId.isEmpty) return;

    _ad = NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF0F172A),
          size: 14.5,
          style: NativeTemplateFontStyle.bold,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF64748B),
          size: 12.5,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF64748B),
          size: 12,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF16A34A),
          size: 14,
          style: NativeTemplateFontStyle.bold,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _loaded = true);
            updateKeepAlive();
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _failed = true);
          debugPrint(
              '[ads] feed native failed: ${error.code} ${error.message}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (ad == null || _failed || !_loaded) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined,
                    size: 15, color: Color(0xFF94A3B8)),
                SizedBox(width: 6),
                Text(
                  'Sponsored',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Medium native template height flexes with the device text scale —
          // a fixed 320 clipped the CTA on phones with larger fonts.
          Builder(builder: (context) {
            final textScale =
                MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
            final height =
                (356.0 + (textScale - 1.0) * 140.0).clamp(356.0, 440.0);
            return SizedBox(
              height: height,
              width: double.infinity,
              child: AdWidget(ad: ad),
            );
          }),
        ],
      ),
    );
  }
}
