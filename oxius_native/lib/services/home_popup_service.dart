import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class HomePopup {
  const HomePopup({
    required this.id,
    required this.imageUrl,
    this.link,
    this.openExternal = false,
    this.viewingCondition = 'once',
  });

  final String id;
  final String imageUrl;
  final String? link;
  final bool openExternal;
  final String viewingCondition;

  bool get canRepeatInSession => viewingCondition == 'always';

  factory HomePopup.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['image'] ?? json['image_url'] ?? '').toString();
    final rawLink = (json['link'] ?? json['link_url'] ?? '').toString().trim();

    return HomePopup(
      id: (json['id'] ?? rawImage).toString(),
      imageUrl: ApiService.getAbsoluteUrl(rawImage),
      link: rawLink.isEmpty ? null : rawLink,
      openExternal: json['open_external'] == true,
      viewingCondition:
          (json['viewing_condition'] ?? 'once').toString().trim().toLowerCase(),
    );
  }
}

class HomePopupService {
  const HomePopupService._();

  static Future<HomePopup?> fetchActiveMobilePopup() async {
    try {
      final uri = Uri.parse(ApiService.getApiUrl('global-popup/mobile/'));
      final headers = await ApiService.getHeaders();
      final response = await ApiService.client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) {
        debugPrint(
          'HomePopupService: GET $uri -> ${response.statusCode}',
        );
      }

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      final List<dynamic> items = decoded is List
          ? decoded
          : decoded is Map<String, dynamic>
              ? (decoded['results'] as List<dynamic>? ?? const [])
              : const [];

      for (final item in items) {
        if (item is! Map) continue;
        final popup = HomePopup.fromJson(Map<String, dynamic>.from(item));
        if (popup.imageUrl.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              'HomePopupService: popup ${popup.id} image=${popup.imageUrl}',
            );
          }
          return popup;
        }
      }

      if (kDebugMode) {
        debugPrint('HomePopupService: no active popup returned');
      }
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('HomePopupService: failed to fetch popup: $error');
      }
      return null;
    }
  }

  static Future<void> trackMobileView(String popupId) async {
    try {
      final uri = Uri.parse(ApiService.getApiUrl('global-popup/track-view/'));
      final headers = await ApiService.getHeaders();
      await ApiService.client
          .post(
            uri,
            headers: headers,
            body: json.encode({
              'popup_type': 'mobile',
              'popup_id': popupId,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Tracking should never block or close the popup.
    }
  }
}
