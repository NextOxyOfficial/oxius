import 'package:flutter/material.dart';

import '../../services/house_ads_service.dart';
import '../business_network/post_card.dart';
import 'house_ad_card.dart';

/// Business Network feed ad slot — house ads only.
///
/// This used to be a waterfall that fell back to Google AdMob when no
/// advertiser matched. AdMob is gone (account terminated for invalid traffic,
/// appeal refused), so the slot now asks the ABN Ads Panel and renders nothing
/// when it has nothing to show — an empty slot reads as a normal feed, whereas
/// a dead ad request reads as a broken app.
class FeedNativeAdCard extends StatefulWidget {
  final String placementKey;
  // Owner of the content this ad slot follows (creator revenue share).
  final String? creatorId;
  const FeedNativeAdCard({
    super.key,
    this.placementKey = 'bn_feed_native',
    this.creatorId,
  });

  @override
  State<FeedNativeAdCard> createState() => _FeedNativeAdCardState();
}

class _FeedNativeAdCardState extends State<FeedNativeAdCard>
    with AutomaticKeepAliveClientMixin {
  HouseAd? _houseAd;
  bool _boostTracked = false;

  // Serve-API placement key: 'bn_feed_native' → 'bn_feed' etc.
  String get _housePlacement =>
      widget.placementKey.replaceAll('_native', '').replaceAll('_fullscreen', '');

  // Keep the loaded ad alive while the feed recycles items — otherwise every
  // scroll-away disposes and re-requests the ad (wasted fill + flicker).
  @override
  bool get wantKeepAlive => _houseAd != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final house = await HouseAdsService.fetch(_housePlacement);
    if (!mounted || house == null) return;
    setState(() => _houseAd = house);
    updateKeepAlive();
    // A boost renders as a plain PostCard, which knows nothing about ads —
    // so nothing reported the exposure and the campaign never accrued views,
    // spend, creator share or viewer diamonds. HouseAdCard tracks its own,
    // hence the boost-only condition.
    if (house.boostedPostModel != null && !_boostTracked) {
      _boostTracked = true;
      HouseAdsService.track(
        eventType: 'impression',
        placement: _housePlacement,
        adId: house.id,
        creatorId: widget.creatorId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final house = _houseAd;
    if (house == null) return const SizedBox.shrink();
    // A boosted post IS a post — render the real PostCard so it reads and
    // behaves exactly like the rest of the feed (like / comment / share all
    // work because it is the genuine post), with "Sponsored" in the timestamp
    // slot. Only non-boost creatives use the ad-card chrome.
    final boosted = house.boostedPostModel;
    if (boosted != null) {
      // Pass the campaign so the card can offer its action button.
      return PostCard(post: boosted, isSponsored: true, sponsoredAd: house);
    }
    return HouseAdCard(
      ad: house,
      placement: _housePlacement,
      creatorId: widget.creatorId,
    );
  }
}
