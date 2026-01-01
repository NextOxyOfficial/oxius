import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class UrlLauncherUtils {
  static Future<bool> launchExternalUrl(String? url) async {
    final uri = _normalizeToUri(url);
    if (uri == null) return false;

    try {
      final ok = await canLaunchUrl(uri);
      if (!ok) return false;

      return await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
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
    } else if (!url.contains('://') && !url.startsWith('mailto:') && !url.startsWith('tel:')) {
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
    if (lower.startsWith('localhost') || lower.startsWith('127.0.0.1') || lower.startsWith('0.0.0.0')) {
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
}
