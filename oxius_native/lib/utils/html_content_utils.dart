class HtmlContentUtils {
  static const Map<String, String> _entityMap = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
  };

  static String decodeEntities(String value) {
    var decoded = value;

    for (var index = 0; index < 3; index++) {
      final next = decoded.replaceAllMapped(
        RegExp(r'&(#(?:x[\da-fA-F]+|\d+)|[a-zA-Z]+);'),
        (match) {
          final code = match.group(1) ?? '';

          if (code.startsWith('#x') || code.startsWith('#X')) {
            final parsed = int.tryParse(code.substring(2), radix: 16);
            return parsed == null ? match.group(0)! : String.fromCharCode(parsed);
          }

          if (code.startsWith('#')) {
            final parsed = int.tryParse(code.substring(1));
            return parsed == null ? match.group(0)! : String.fromCharCode(parsed);
          }

          return _entityMap[code.toLowerCase()] ?? match.group(0)!;
        },
      );

      if (next == decoded) {
        break;
      }

      decoded = next;
    }

    return decoded;
  }

  static bool hasHtml(String value) {
    return RegExp(r'<[a-zA-Z][^>]*>').hasMatch(decodeEntities(value));
  }

  static String toPlainText(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    final normalized = decodeEntities(value)
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(
            r'<\s*/\s*(p|div|li|ul|ol|h[1-6]|blockquote|section|article|tr)\s*>',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll(RegExp(r'<\s*li\b[^>]*>', caseSensitive: false), '- ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('\u00A0', ' ')
        .replaceAll('\r', '');

    return normalized
        .split('\n')
        .map((line) => line.trim().replaceAll(RegExp(r' {3,}'), '  '))
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  static String previewText(String value, int maxLength) {
    final plainText = toPlainText(value);
    if (plainText.length <= maxLength) {
      return plainText;
    }

    return '${plainText.substring(0, maxLength).trimRight()}...';
  }

  static String toDisplayHtml(String value) {
    final normalized = decodeEntities(value).trim();
    if (normalized.isEmpty) {
      return '';
    }

    if (hasHtml(normalized)) {
      return normalized;
    }

    return normalized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('\n', '<br />');
  }
}