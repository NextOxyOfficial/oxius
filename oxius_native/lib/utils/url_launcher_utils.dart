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
        mode: LaunchMode.externalApplication,
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
      url = 'https://$url';
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
}
