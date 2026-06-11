import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

import '../../services/ads_service.dart';

/// A MAX native ad styled like a Business Network post card.
///
/// Renders nothing until the ad actually loads (no empty gaps in the feed),
/// and collapses permanently for this slot if loading fails.
class FeedNativeAdCard extends StatefulWidget {
  final String placementKey;
  const FeedNativeAdCard({super.key, this.placementKey = 'bn_feed_native'});

  @override
  State<FeedNativeAdCard> createState() => _FeedNativeAdCardState();
}

class _FeedNativeAdCardState extends State<FeedNativeAdCard>
    with AutomaticKeepAliveClientMixin {
  bool _loaded = false;
  bool _failed = false;

  // Keep the loaded ad alive while scrolling so it doesn't reload every time
  // the card re-enters the viewport.
  @override
  bool get wantKeepAlive => _loaded;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final adUnitId = AdsService.adUnitId(widget.placementKey);
    if (_failed || adUnitId == null) return const SizedBox.shrink();

    final adLayout = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: MaxNativeAdView(
        adUnitId: adUnitId,
        height: 320,
        listener: NativeAdListener(
          onAdLoadedCallback: (ad) {
            if (mounted && !_loaded) setState(() => _loaded = true);
          },
          onAdLoadFailedCallback: (adUnitId, error) {
            if (mounted) setState(() => _failed = true);
          },
          onAdClickedCallback: (ad) {},
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const MaxNativeAdIconView(width: 38, height: 38),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MaxNativeAdTitleView(
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'বিজ্ঞাপন',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: MaxNativeAdAdvertiserView(
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const MaxNativeAdOptionsView(width: 18, height: 18),
                ],
              ),
              const SizedBox(height: 8),
              MaxNativeAdBodyView(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const MaxNativeAdMediaView(height: 160),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MaxNativeAdCallToActionView(
                    style: ButtonStyle(
                      foregroundColor:
                          const WidgetStatePropertyAll(Colors.white),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      overlayColor: WidgetStatePropertyAll(
                        Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Platform views must be laid out at real size to load, so reserve the
    // slot and cover it with a light placeholder until the ad arrives; a
    // failed load collapses the slot entirely.
    return Stack(
      children: [
        adLayout,
        if (!_loaded)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                'বিজ্ঞাপন লোড হচ্ছে…',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
          ),
      ],
    );
  }
}
