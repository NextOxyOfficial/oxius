import 'package:flutter/material.dart';

import '../../services/house_ads_service.dart';
import 'house_ad_strip_view.dart';

/// The sponsored strip slot shown under a post's media (above the caption) on
/// a subset of feed posts, and in the sale / classified / food-zone lists.
///
/// This part only fetches, tracks and dismisses — how the row LOOKS lives in
/// [HouseAdStripView], which the skipped-mid-roll slot renders too, so the two
/// can never drift apart. The post's creator earns the revenue share.
class CompactHouseAdStrip extends StatefulWidget {
  final String? creatorId;
  // Host post id — per-content creator earnings attribution.
  final String? contentId;

  /// Which ad slot to serve. Defaults to the BN feed (the strip's original
  /// home); the sale, classified and food-zone lists pass their own so one
  /// compact row style is shared across every list.
  final String placement;

  const CompactHouseAdStrip({
    super.key,
    this.creatorId,
    this.contentId,
    this.placement = 'bn_feed',
  });

  @override
  State<CompactHouseAdStrip> createState() => _CompactHouseAdStripState();
}

class _CompactHouseAdStripState extends State<CompactHouseAdStrip>
    with AutomaticKeepAliveClientMixin {
  HouseAd? _ad;
  bool _tracked = false;
  bool _closed = false;
  bool _apology = false;

  @override
  bool get wantKeepAlive => _ad != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ad = await HouseAdsService.fetch(widget.placement);
    if (!mounted || ad == null) return;
    setState(() => _ad = ad);
    updateKeepAlive();
    if (!_tracked) {
      _tracked = true;
      HouseAdsService.track(
        eventType: 'impression',
        placement: widget.placement,
        adId: ad.id,
        creatorId: widget.creatorId,
        contentId: widget.contentId,
      );
    }
  }

  void _close() {
    final ad = _ad;
    setState(() => _apology = true);
    if (ad != null) {
      HouseAdsService.track(
        eventType: 'close',
        placement: widget.placement,
        adId: ad.id,
        creatorId: widget.creatorId,
      );
    }
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _closed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (ad == null || _closed) return const SizedBox.shrink();

    if (_apology) {
      return Padding(
        // Same insets as the live strip so dismissing an ad doesn't shift the
        // post's layout.
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Text(
            'দুঃখিত, বিজ্ঞাপনটি আপনার পছন্দ হয়নি জেনে।',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ),
      );
    }

    return HouseAdStripView(
      ad: ad,
      placement: widget.placement,
      creatorId: widget.creatorId,
      contentId: widget.contentId,
      onClose: _close,
    );
  }
}
