import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

  // Video-format state: muted autoplay, 5s countdown then a Skip button.
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoSkipped = false;
  int _skipCountdown = 5;
  Timer? _countdownTimer;
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
      // Billable after 3 seconds of playback.
      _billableTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_videoSkipped) _trackImpression();
      });
      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        if (_skipCountdown > 0) {
          setState(() => _skipCountdown--);
        } else {
          t.cancel();
        }
      });
    } catch (e) {
      debugPrint('[house-ads] video init failed: $e');
      if (mounted) setState(() {});
    }
  }

  void _skipVideo() {
    // Skip after 5s: the view already counted (>3s watched) — collapse the
    // video, keep the compact card + companion banner clickable.
    setState(() => _videoSkipped = true);
    _video?.pause();
    HouseAdsService.track(
      eventType: 'skip',
      placement: widget.placement,
      adId: widget.ad.id,
      creatorId: widget.creatorId,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _billableTimer?.cancel();
    _video?.dispose();
    super.dispose();
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
    final ad = widget.ad;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.campaign_outlined,
                    size: 15, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                const Text(
                  'Sponsored',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                Text(
                  ad.advertiser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // ── Creative: 5s-skippable video OR image ──
          if (_isVideo && _videoReady && !_videoSkipped)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: (_video!.value.aspectRatio <= 0)
                      ? 16 / 9
                      : _video!.value.aspectRatio.clamp(0.8, 1.9),
                  child: VideoPlayer(_video!),
                ),
                // Countdown → Skip button (top-right, YouTube-style).
                Positioned(
                  top: 8,
                  right: 8,
                  child: _skipCountdown > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Skip in $_skipCountdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _skipVideo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.close_rounded,
                                    size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onCtaTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      ad.ctaLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
