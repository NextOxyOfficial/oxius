import 'dart:async';
import '../models/business_network_models.dart';
import 'dart:convert';

// material (not just foundation) for the CTA's IconData, which lives next to
// ctaLabel so the label and its icon can't drift apart.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../utils/shared_post_message.dart';
import '../widgets/common/adsy_chat_icon.dart';
import 'api_service.dart';

/// One advertiser ad from the ABN Ads Panel, served by
/// `GET /api/bn/ads/serve/`.
class HouseAd {
  final String id;
  final String title;
  final String description;
  final String format; // image | video | boost
  final List<String> images;
  final String videoUrl;
  final String companionBanner; // banner under the video creative
  final String adType; // click_to_website | call_on_whatsapp | ...
  final String adTypeDetails; // url / phone / email
  final String categoryId;
  final String categoryName;
  final String advertiser;
  // Owner identity — real avatar + tap-to-profile on every ad surface.
  final String advertiserId;
  final String advertiserImage;
  // Trust badges beside the advertiser name (blue check / Pro pill).
  final bool advertiserVerified;
  final bool advertiserPro;
  /// Whether the viewer already follows this advertiser — drives the Follow /
  /// Following state on every ad surface that shows their name.
  final bool advertiserIsFollowing;
  // format='boost': the promoted BN short to play inline in the reel.
  final Map<String, dynamic>? boostedPost;

  /// The boosted post, fully parsed. serve_ad ships the same serialization the
  /// feed endpoint uses, so the feed can render it through the ordinary
  /// PostCard instead of a lookalike built from a handful of flat fields.
  BusinessNetworkPost? get boostedPostModel {
    final raw = boostedPost?['post'];
    if (raw is! Map) return null;
    try {
      return BusinessNetworkPost.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  const HouseAd({
    required this.id,
    required this.title,
    required this.description,
    required this.format,
    required this.images,
    required this.videoUrl,
    required this.companionBanner,
    required this.adType,
    required this.adTypeDetails,
    required this.categoryId,
    required this.categoryName,
    required this.advertiser,
    this.advertiserId = '',
    this.advertiserImage = '',
    this.advertiserVerified = false,
    this.advertiserPro = false,
    this.advertiserIsFollowing = false,
    this.boostedPost,
  });

  static HouseAd? tryParse(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = (m['id'] ?? '').toString();
    if (id.isEmpty) return null;
    return HouseAd(
      id: id,
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      format: (m['format'] ?? 'image').toString(),
      images: [
        for (final u in (m['images'] as List? ?? const []))
          if (u.toString().isNotEmpty) u.toString()
      ],
      videoUrl: (m['video_url'] ?? '').toString(),
      companionBanner: (m['companion_banner'] ?? '').toString(),
      adType: (m['ad_type'] ?? '').toString(),
      adTypeDetails: (m['ad_type_details'] ?? '').toString(),
      categoryId: (m['category'] ?? '').toString(),
      categoryName: (m['category_name'] ?? '').toString(),
      advertiser: (m['advertiser'] ?? 'AdsyClub').toString(),
      advertiserId: (m['advertiser_id'] ?? '').toString(),
      advertiserImage: (m['advertiser_image'] ?? '').toString(),
      advertiserVerified: m['advertiser_verified'] == true,
      advertiserPro: m['advertiser_pro'] == true,
      advertiserIsFollowing: m['advertiser_is_following'] == true,
      boostedPost: m['boosted_post'] is Map
          ? Map<String, dynamic>.from(m['boosted_post'] as Map)
          : null,
    );
  }

  /// This ad as a chat attachment — what the advertiser sees quoted above the
  /// message when someone taps "মেসেজ করুন".
  ///
  /// Reuses the shared-post card the app already renders in chat, so an ad
  /// quoted from the feed and a post shared into a chat look the same. For a
  /// boost the card points at the real post; a plain creative has nowhere to
  /// link, so it stays a non-tappable reference.
  SharedPostMessage get chatAttachment {
    final post = boostedPostModel;
    final thumb = post?.shareThumbUrl.trim().isNotEmpty == true
        ? post!.shareThumbUrl.trim()
        : (images.isNotEmpty ? images.first : companionBanner);
    final headline = title.trim().isNotEmpty ? title.trim() : advertiser;
    final sub = description.trim().isNotEmpty ? description.trim() : categoryName;
    var url = '';
    if (post != null) {
      final ref = post.slug.trim().isNotEmpty ? post.slug.trim() : '${post.id}';
      url = 'https://adsyclub.com/business-network/posts/$ref';
    }
    return SharedPostMessage(
      ownerName: headline,
      authorName: headline,
      thumbUrl: thumb,
      postUrl: url,
      caption: sub,
    );
  }

  /// Short spoken-Bangla CTA label matching the ad's button type.
  String get ctaLabel {
    switch (adType) {
      case 'message_on_adsyconnect':
        return 'মেসেজ করুন';
      case 'call_on_whatsapp':
        return 'হোয়াটসঅ্যাপ';
      case 'call_on_phone':
        return 'কল করুন';
      case 'email_us':
        return 'ইমেইল করুন';
      default:
        return 'ভিজিট করুন';
    }
  }

  /// The CTA's icon as a WIDGET — use this over [ctaIcon] wherever possible.
  ///
  /// The AdsyConnect action gets the brand mark, not a generic bubble: the
  /// button opens a chat inside this app, and a Material glyph gave no hint
  /// of that. Everything else stays a plain icon.
  ///
  /// [color] is the row's text color. A glyph takes it as-is, but flattening
  /// the brand PNG to a dark tint would throw away the very thing that makes
  /// it recognizable — so the mark keeps its own colors on light surfaces and
  /// is tinted only when the caller asks for a light color, i.e. the button
  /// behind it is solid and an untinted mark would disappear into it.
  Widget ctaIconWidget({double size = 17, Color? color}) {
    if (adType == 'message_on_adsyconnect') {
      final onSolid = color != null && color.computeLuminance() > 0.6;
      return AdsyChatIcon(size: size, color: onSolid ? color : null);
    }
    return Icon(ctaIcon, size: size, color: color);
  }

  /// Icon paired with [ctaLabel]. Mirrors the web's ListBannerAd map and the
  /// ads-panel preview, so one ad type looks the same everywhere it runs.
  IconData get ctaIcon {
    switch (adType) {
      case 'message_on_adsyconnect':
        return Icons.chat_bubble_rounded;
      case 'call_on_whatsapp':
        // The brand mark, not a generic bubble — it says which app opens.
        return FontAwesomeIcons.whatsapp.data;
      case 'call_on_phone':
        return Icons.phone_outlined;
      case 'email_us':
        return Icons.mail_outline_rounded;
      default:
        return Icons.open_in_new_rounded;
    }
  }
}

/// House-ads layer of the hybrid ads system: serve a panel ad when one
/// matches, otherwise the caller falls back to AdMob. Every impression /
/// click (panel AND AdMob) is batched to `/api/bn/ads/track/` — that feed of
/// events powers viewer diamond rewards, creator earnings and the per-user
/// interest profile on the server.
class HouseAdsService {
  HouseAdsService._();

  static final List<Map<String, dynamic>> _pending = [];
  static Timer? _flushTimer;

  /// Fetch one ad for [placement]; null → show AdMob instead.
  static Future<HouseAd?> fetch(String placement) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await ApiService.client
          .get(
            Uri.parse(
              '${ApiService.baseUrl}/bn/ads/serve/'
              '?placement=$placement&platform=app',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      if (data is Map && data['source'] == 'panel') {
        return HouseAd.tryParse(data['ad']);
      }
      return null;
    } catch (e) {
      debugPrint('[house-ads] serve failed: $e');
      return null;
    }
  }

  /// Queue one tracking event (flushed in small batches).
  /// [creatorId] = owner of the content the ad appeared on/after — they get
  /// the creator revenue share for this view.
  static void track({
    required String eventType, // impression | click | cta_click | close
    required String placement,
    String source = 'panel',
    String? adId,
    String? creatorId,
    // BN post the ad rode on — per-content creator earnings breakdown.
    String? contentId,
  }) {
    _pending.add({
      'event_type': eventType,
      'placement': placement,
      'platform': 'app',
      'source': source,
      if (adId != null && adId.isNotEmpty) 'ad': adId,
      if (creatorId != null && creatorId.isNotEmpty) 'creator': creatorId,
      if (contentId != null && contentId.isNotEmpty) 'content': contentId,
    });
    if (eventType == 'close') flush(); // suppression must apply immediately
    if (_pending.length >= 20) {
      flush();
    } else {
      _flushTimer ??= Timer(const Duration(seconds: 10), flush);
    }
  }

  static Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pending.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();
    try {
      final headers = await ApiService.getHeaders();
      await ApiService.client
          .post(
            Uri.parse('${ApiService.baseUrl}/bn/ads/track/'),
            headers: headers,
            body: json.encode({'events': batch}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[house-ads] track flush failed: $e');
    }
  }
}
