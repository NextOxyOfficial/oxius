import 'package:flutter/material.dart';

import '../../services/house_ads_service.dart';
import 'house_ad_card.dart';
import '../../config/app_config.dart';

/// The one-row sponsored strip: thumbnail, headline, "Sponsored", action.
///
/// Presentation only — the caller supplies the ad, so the same row serves the
/// slot that fetches its own ad (CompactHouseAdStrip) and the one that reuses
/// an ad the viewer has already been shown (a skipped mid-roll, kept reachable
/// under the media instead of vanishing).
///
/// The whole row is one tap target. Reading the headline and then having to
/// find a separate button is old-school ad behaviour; here the text does what
/// the button does.
class HouseAdStripView extends StatelessWidget {
  final HouseAd ad;
  final String placement;
  final String? creatorId;
  final String? contentId;

  /// Shown as a ✕ when provided.
  final VoidCallback? onClose;

  /// Copy above the row, e.g. "বিজ্ঞাপনটি এড়িয়ে গেছেন" for a skipped mid-roll.
  final String? note;

  const HouseAdStripView({
    super.key,
    required this.ad,
    required this.placement,
    this.creatorId,
    this.contentId,
    this.onClose,
    this.note,
  });

  void _open() {
    HouseAdsService.track(
      eventType: 'cta_click',
      placement: placement,
      adId: ad.id,
      creatorId: creatorId,
      contentId: contentId,
    );
    HouseAdCard.launchCta(ad, placement: placement);
  }

  @override
  Widget build(BuildContext context) {
    // Was `images.first ?? companionBanner`, which is only ever set for plain
    // image creatives — boost and video ads came out blank.
    final thumb = ad.thumbUrl;
    final subtitle = ad.description.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note != null) ...[
                  Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: thumb.isNotEmpty
                            ? Image.network(
                                AppConfig.getAbsoluteUrl(thumb),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _thumbFallback(ad),
                              )
                            : _thumbFallback(ad),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Sponsored',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 0.3,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const Spacer(),
                              if (onClose != null)
                                InkWell(
                                  onTap: onClose,
                                  borderRadius: BorderRadius.circular(999),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.close_rounded,
                                        size: 15, color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Three lines: one line told the reader almost
                          // nothing about what the ad was actually offering.
                          Text(
                            ad.title,
                            maxLines: subtitle.isEmpty ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Full-width tonal action. The old bare icon+label floated at
                // the end of a row and read as a link, not something to press.
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: _open,
                    icon: ad.ctaIconWidget(size: 16),
                    label: Text(
                      ad.ctaLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A video ad with no stored poster gets a video tile, not the generic
  /// megaphone — the megaphone reads as "this image failed to load".
  Widget _thumbFallback(HouseAd ad) {
    if (ad.isVideoWithoutPoster) {
      return Container(
        color: const Color(0xFF0F172A),
        alignment: Alignment.center,
        child: const Icon(Icons.play_arrow_rounded,
            size: 26, color: Colors.white),
      );
    }
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.campaign_outlined,
          size: 22, color: Color(0xFF94A3B8)),
    );
  }
}
