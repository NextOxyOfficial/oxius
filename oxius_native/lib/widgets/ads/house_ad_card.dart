import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../screens/business_network/profile_screen.dart';
import '../../services/house_ads_service.dart';
import '../../utils/url_launcher_utils.dart';

/// Native-style card for an ABN Ads Panel (house) ad — same chrome as the
/// AdMob feed card ("Sponsored" strip + white card) so both blend into the
/// feed identically. Tracks its own impression once and CTA clicks.
class HouseAdCard extends StatefulWidget {
  final HouseAd ad;
  final String placement;
  // Owner of the content this ad appeared on/after (creator revenue share).
  final String? creatorId;

  const HouseAdCard({
    super.key,
    required this.ad,
    required this.placement,
    this.creatorId,
  });

  /// Advertiser name + trust badges (blue verified check, Pro pill) — the
  /// same row every ad surface uses beside the owner's name.
  static Widget advertiserNameRow(
    HouseAd ad, {
    Color color = const Color(0xFF111827),
    double fontSize = 13.5,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            ad.advertiser,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (ad.advertiserVerified) ...[
          const SizedBox(width: 3),
          Icon(Icons.verified,
              size: fontSize + 1.5, color: const Color(0xFF3B82F6)),
        ],
        if (ad.advertiserPro) ...[
          const SizedBox(width: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Pro',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Icon matching the ad's CTA type — shown beside the label on every
  /// promo chip (feed card, shorts sheet, boost chip, mid-roll).
  static IconData ctaIcon(HouseAd ad) {
    switch (ad.adType) {
      case 'call_on_whatsapp':
        return Icons.chat_bubble_outline_rounded;
      case 'call_on_phone':
        return Icons.call_outlined;
      case 'email_us':
        return Icons.mail_outline_rounded;
      default:
        return Icons.open_in_new_rounded;
    }
  }

  /// Launch the ad's CTA action (website / WhatsApp / call / email).
  static void launchCta(HouseAd ad) {
    final details = ad.adTypeDetails.trim();
    if (details.isEmpty) return;
    switch (ad.adType) {
      case 'call_on_whatsapp':
        final digits = details.replaceAll(RegExp(r'[^0-9+]'), '');
        UrlLauncherUtils.launchExternalUrl('https://wa.me/$digits');
        break;
      case 'call_on_phone':
        UrlLauncherUtils.launchExternalUrl('tel:$details');
        break;
      case 'email_us':
        UrlLauncherUtils.launchExternalUrl('mailto:$details');
        break;
      default:
        final url = details.startsWith('http') ? details : 'https://$details';
        UrlLauncherUtils.launchExternalUrl(url);
    }
  }

  @override
  State<HouseAdCard> createState() => _HouseAdCardState();
}

class _HouseAdCardState extends State<HouseAdCard>
    with AutomaticKeepAliveClientMixin {
  bool _impressionTracked = false;
  // ✕-closed: a brief apology note shows, then the card collapses; the
  // server mutes this ad + its whole category for this user for 48 hours.
  bool _closed = false;
  bool _apologyShowing = false;
  Timer? _apologyTimer;

  void _closeAd() {
    setState(() => _apologyShowing = true);
    HouseAdsService.track(
      eventType: 'close',
      placement: widget.placement,
      adId: widget.ad.id,
      creatorId: widget.creatorId,
    );
    _apologyTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _closed = true);
    });
  }

  /// The gentle "sorry you didn't like this" note every ad surface shows
  /// for a few seconds after ✕.
  static Widget apologyNote() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.sentiment_dissatisfied_rounded,
              size: 20, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'দুঃখিত, বিজ্ঞাপনটি আপনার পছন্দ হয়নি জেনে।',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Video-format state: muted autoplay, flows in the feed like a post.
  VideoPlayerController? _video;
  bool _videoReady = false;
  Timer? _billableTimer;

  bool get _isVideo =>
      widget.ad.format == 'video' && widget.ad.videoUrl.isNotEmpty;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initVideo();
    } else {
      _trackImpression();
    }
  }

  /// One BILLABLE impression per mounted card — burns advertiser budget and
  /// feeds viewer rewards + creator share. For video the impression only
  /// counts after 3s of actual playback (ThruPlay-style billable view).
  void _trackImpression() {
    if (_impressionTracked) return;
    _impressionTracked = true;
    HouseAdsService.track(
      eventType: 'impression',
      placement: widget.placement,
      adId: widget.ad.id,
      creatorId: widget.creatorId,
    );
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.ad.videoUrl));
      _video = c;
      await c.initialize();
      await c.setVolume(0); // feed autoplay is always muted
      await c.setLooping(false);
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() => _videoReady = true);
      c.play();
      // Billable after 3 seconds of playback (ThruPlay-style).
      _billableTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) _trackImpression();
      });
    } catch (e) {
      debugPrint('[house-ads] video init failed: $e');
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _apologyTimer?.cancel();
    _billableTimer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  Widget _avatarInitial(String name) => Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'A',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      );

  /// Advertiser avatar/name → their BN profile.
  void _openAdvertiserProfile() {
    final id = widget.ad.advertiserId;
    if (id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: id)),
    );
  }

  void _onCtaTap() {
    HouseAdsService.track(
      eventType: 'cta_click',
      placement: widget.placement,
      adId: widget.ad.id,
      creatorId: widget.creatorId,
    );
    HouseAdCard.launchCta(widget.ad);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_closed) return const SizedBox.shrink();
    if (_apologyShowing) return apologyNote();
    final ad = widget.ad;
    return Container(
      // Full screen width, edge-to-edge like a regular feed post; also pins
      // the video Stack's width so the Skip chip can never fall off-screen.
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
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
          // Feed-post style header: advertiser avatar + name, "Sponsored"
          // as the meta line underneath. Tapping either opens the
          // advertiser's BN profile.
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openAdvertiserProfile,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: ad.advertiserImage.isNotEmpty
                        ? Image.network(
                            ad.advertiserImage,
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) =>
                                _avatarInitial(ad.advertiser),
                          )
                        : _avatarInitial(ad.advertiser),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _openAdvertiserProfile,
                        child: HouseAdCard.advertiserNameRow(ad),
                      ),
                      const SizedBox(height: 1),
                      const Row(
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 12, color: Color(0xFF94A3B8)),
                          SizedBox(width: 3),
                          Text(
                            'Sponsored',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ✕ — hides this ad + mutes its category for 48h.
                InkWell(
                  onTap: _closeAd,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          // ── Creative: 5s-skippable video OR image ──
          // In-feed the video ad flows like a normal post — NO skip button
          // (nothing is being interrupted). The skippable variant lives in
          // the mid-roll overlay inside feed videos (post_media_gallery).
          if (_isVideo && _videoReady)
            ClipRect(
              child: AspectRatio(
                aspectRatio: (_video!.value.aspectRatio <= 0)
                    ? 16 / 9
                    : _video!.value.aspectRatio.clamp(0.8, 1.9),
                // Cover-fill exactly like feed post videos — without this
                // the platform video view letterboxes (side gaps on web).
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _video!.value.size.width > 0
                        ? _video!.value.size.width
                        : 16,
                    height: _video!.value.size.height > 0
                        ? _video!.value.size.height
                        : 9,
                    child: VideoPlayer(_video!),
                  ),
                ),
              ),
            )
          else if (ad.images.isNotEmpty)
            GestureDetector(
              onTap: _onCtaTap,
              child: Image.network(
                ad.images.first,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // ── Companion banner UNDER the video (survives skip) ──
          if (_isVideo && ad.companionBanner.isNotEmpty)
            GestureDetector(
              onTap: _onCtaTap,
              child: Image.network(
                ad.companionBanner,
                width: double.infinity,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (ad.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ad.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // AdsyConnect-ink soft chip: icon + text, no border, no fill
                // bar — the one promo-button style used across all ads.
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: _onCtaTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFF111827).withValues(alpha: 0.06),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(HouseAdCard.ctaIcon(ad),
                              size: 15, color: const Color(0xFF111827)),
                          const SizedBox(width: 6),
                          Text(
                            ad.ctaLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
