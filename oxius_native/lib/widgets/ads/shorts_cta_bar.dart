import 'package:flutter/material.dart';

import '../../services/house_ads_service.dart';
import 'house_ad_card.dart';

/// "Sponsored" marker for a full-screen short.
///
/// A pill rather than bare grey text: on a moving video a plain word gets lost
/// against whatever frame is behind it, and the disclosure has to stay legible.
class ShortsSponsoredPill extends StatelessWidget {
  const ShortsSponsoredPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'Sponsored',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The advertiser's action on a full-screen short.
///
/// A full-width bar, not the small translucent pill this used to be — that
/// pill sat in the middle of a busy frame and read as decoration. This is the
/// same idea as the feed's tonal button, restyled for a dark video: a light
/// surface with dark text so it stays readable over any frame, and a trailing
/// chevron so it is obviously the way forward.
class ShortsCtaBar extends StatelessWidget {
  final HouseAd ad;
  final String placement;

  const ShortsCtaBar({super.key, required this.ad, required this.placement});

  void _open() {
    HouseAdsService.track(
      eventType: 'cta_click',
      placement: placement,
      adId: ad.id,
    );
    HouseAdCard.launchCta(ad);
  }

  @override
  Widget build(BuildContext context) {
    if (ad.adType.isEmpty || ad.adType == 'none') {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(ad.ctaIcon, size: 17, color: const Color(0xFF111827)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ad.ctaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}
