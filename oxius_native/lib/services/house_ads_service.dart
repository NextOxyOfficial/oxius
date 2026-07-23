import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

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
  // format='boost': the promoted BN short to play inline in the reel.
  final Map<String, dynamic>? boostedPost;

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
      boostedPost: m['boosted_post'] is Map
          ? Map<String, dynamic>.from(m['boosted_post'] as Map)
          : null,
    );
  }

  /// Bangla CTA label matching the ad's button type.
  String get ctaLabel {
    switch (adType) {
      case 'call_on_whatsapp':
        return 'WhatsApp-এ মেসেজ করুন';
      case 'call_on_phone':
        return 'কল করুন';
      case 'email_us':
        return 'ইমেইল করুন';
      default:
        return 'ওয়েবসাইট দেখুন';
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
    required String eventType, // impression | click | cta_click
    required String placement,
    String source = 'panel',
    String? adId,
    String? creatorId,
  }) {
    _pending.add({
      'event_type': eventType,
      'placement': placement,
      'platform': 'app',
      'source': source,
      if (adId != null && adId.isNotEmpty) 'ad': adId,
      if (creatorId != null && creatorId.isNotEmpty) 'creator': creatorId,
    });
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
