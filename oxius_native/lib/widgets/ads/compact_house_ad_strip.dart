import 'package:flutter/material.dart';

import '../../services/house_ads_service.dart';
import 'house_ad_card.dart';

/// Link-preview style one-line sponsored strip shown under a post's media
/// (above the caption) on a subset of feed posts. Thumbnail left, title +
/// "Sponsored" right, chevron — no button; tapping anywhere opens the
/// advertiser's destination. The post's creator earns the revenue share.
class CompactHouseAdStrip extends StatefulWidget {
  final String? creatorId;
  // Host post id — per-content creator earnings attribution.
  final String? contentId;

  const CompactHouseAdStrip({super.key, this.creatorId, this.contentId});

  @override
  State<CompactHouseAdStrip> createState() => _CompactHouseAdStripState();
}

class _CompactHouseAdStripState extends State<CompactHouseAdStrip>
    with AutomaticKeepAliveClientMixin {
  HouseAd? _ad;
  bool _tracked = false;

  @override
  bool get wantKeepAlive => _ad != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ad = await HouseAdsService.fetch('bn_feed');
    if (!mounted || ad == null) return;
    setState(() => _ad = ad);
    updateKeepAlive();
    if (!_tracked) {
      _tracked = true;
      HouseAdsService.track(
        eventType: 'impression',
        placement: 'bn_feed',
        adId: ad.id,
        creatorId: widget.creatorId,
        contentId: widget.contentId,
      );
    }
  }

  void _onTap() {
    final ad = _ad;
    if (ad == null) return;
    HouseAdsService.track(
      eventType: 'cta_click',
      placement: 'bn_feed',
      adId: ad.id,
      creatorId: widget.creatorId,
      contentId: widget.contentId,
    );
    HouseAdCard.launchCta(ad);
  }

  bool _closed = false;
  bool _apology = false;

  void _close() {
    final ad = _ad;
    setState(() => _apology = true);
    if (ad != null) {
      HouseAdsService.track(
        eventType: 'close',
        placement: 'bn_feed',
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
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'দুঃখিত, বিজ্ঞাপনটি আপনার পছন্দ হয়নি জেনে।',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ),
      );
    }
    final thumb = ad.images.isNotEmpty ? ad.images.first : ad.companionBanner;
    return Padding(
      // Sits tight under the media — border-less soft surface, no big gap.
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: thumb.isNotEmpty
                      ? Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbFallback(),
                        )
                      : _thumbFallback(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sponsored',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: Color(0xFF94A3B8)),
              // ✕ — hides this ad + mutes its category for 48h.
              InkWell(
                onTap: _close,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 15, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.campaign_outlined,
            size: 20, color: Color(0xFF94A3B8)),
      );
}
