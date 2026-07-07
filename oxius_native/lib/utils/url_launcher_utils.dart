import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services/deep_link_service.dart';

class UrlLauncherUtils {
  static Future<bool> launchExternalUrl(String? url) async {
    final uri = _normalizeToUri(url);
    if (uri == null) return false;

    try {
      if (_isAdsyClubUri(uri)) {
        await DeepLinkService.instance.openInternalLink(uri.toString());
        return true;
      }

      final ok = await canLaunchUrl(uri);
      if (!ok) return false;

      return await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  /// Always open in a browser (external app, in-app tab fallback) — never the
  /// internal deep-link navigator. Used from CHAT link previews: routing an
  /// adsyclub link through openInternalLink there pushed the destination
  /// UNDER the chat route (it only appeared after backing out). A browser
  /// launch navigates instantly and never stacks a screen behind the chat.
  static Future<bool> launchInBrowser(String? url) async {
    final uri = _normalizeToUri(url);
    if (uri == null) return false;
    try {
      if (!await canLaunchUrl(uri)) return false;
      final ok = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (ok) return true;
      // Some devices lack a default browser for externalApplication — fall
      // back to an in-app browser tab so the tap never silently no-ops.
      return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      return false;
    }
  }

  static Uri? _normalizeToUri(String? raw) {
    if (raw == null) return null;
    var url = raw.trim();
    if (url.isEmpty) return null;

    url = _stripTrailingPunctuation(url);
    if (url.isEmpty) return null;

    if (url.startsWith('/')) {
      url = AppConfig.getAbsoluteUrl(url);
    } else if (!url.contains('://') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('tel:')) {
      final scheme = _shouldDefaultToHttp(url) ? 'http' : 'https';
      url = '$scheme://$url';
    }

    return Uri.tryParse(url);
  }

  static String _stripTrailingPunctuation(String url) {
    const trailing = ['.', ',', ';', ':', ')', ']', '}', '"', '\''];
    var value = url;
    while (value.isNotEmpty) {
      final last = value[value.length - 1];
      if (!trailing.contains(last)) break;
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static bool _shouldDefaultToHttp(String urlWithoutScheme) {
    final lower = urlWithoutScheme.toLowerCase();
    if (lower.startsWith('localhost') ||
        lower.startsWith('127.0.0.1') ||
        lower.startsWith('0.0.0.0')) {
      return true;
    }
    if (lower.startsWith('10.') || lower.startsWith('192.168.')) return true;
    final m = RegExp(r'^172\.(\d{1,2})\.').firstMatch(lower);
    if (m != null) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n >= 16 && n <= 31) return true;
    }
    return false;
  }

  static bool _isAdsyClubUri(Uri uri) {
    final host = uri.host.toLowerCase();
    return (uri.scheme == 'https' || uri.scheme == 'http') &&
        (host == 'adsyclub.com' || host == 'www.adsyclub.com');
  }
}
