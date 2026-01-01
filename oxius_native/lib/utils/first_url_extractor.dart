import 'package:flutter/foundation.dart';

class FirstUrlExtractor {
  static final RegExp _urlRegex = RegExp(
    r"((?:https?:\/\/)?(?:www\.)?(?:localhost|(?:\d{1,3}\.){3}\d{1,3}|[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+)(?::\d{2,5})?(?:\/[\w\-._~%!$&'()*+,;=:@\/?#\[\]]*)?)",
    caseSensitive: false,
  );

  static String? extract(String text) {
    if (text.isEmpty) return null;
    final match = _urlRegex.firstMatch(text);
    if (match == null) return null;

    final url = (match.group(1) ?? match.group(0) ?? '').trim();
    if (url.isEmpty) return null;

    return _stripTrailingPunctuation(url);
  }

  @visibleForTesting
  static String _stripTrailingPunctuation(String url) {
    const trailing = ['.', ',', ';', ':', ')', ']', '}', '"', "'"];
    var value = url;
    while (value.isNotEmpty) {
      final last = value[value.length - 1];
      if (!trailing.contains(last)) break;
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
