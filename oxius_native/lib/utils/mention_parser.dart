import 'package:flutter/material.dart';

import 'url_launcher_utils.dart';

class MentionParser {
  // Regex to match @mentions in text
  // Primary format (preferred): store mentions with TWO spaces after the name.
  // Example: "@Md Biplob Hossain  hello"
  // This allows unambiguous multi-word mention parsing.
  static final RegExp _mentionRegexDelimited = RegExp(
    r'@([A-Za-z\u0980-\u09FF][A-Za-z0-9_\u0980-\u09FF]*(?:[ \u00A0]+[A-Za-z\u0980-\u09FF][A-Za-z0-9_\u0980-\u09FF]*)*)\s{2,}',
  );

  // Fallback for older content: multi-word mentions where each word starts with a capital letter
  // (prevents swallowing normal sentence words like "is", "and" etc.).
  static final RegExp _mentionRegexCapitalizedFallback = RegExp(
    r'@([A-Z\u0980-\u09FF][A-Za-z0-9_\u0980-\u09FF]*(?:[ \u00A0]+[A-Z\u0980-\u09FF][A-Za-z0-9_\u0980-\u09FF]*)*)',
  );

  static final RegExp _urlRegex = RegExp(
    r"((?:https?:\/\/)?(?:www\.)?(?:localhost|(?:\d{1,3}\.){3}\d{1,3}|[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+)(?::\d{2,5})?(?:\/[\w\-._~%!$&'()*+,;=:@\/?#\[\]]*)?)",
    caseSensitive: false,
  );

  // Emoji codepoints (approximate, but covers the common set incl. ZWJ
  // sequences, skin-tone modifiers, flags and variation selectors). Used to
  // render emojis a little larger than the text they sit next to.
  static final RegExp _emojiRegex = RegExp(
    r'(?:[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{2B00}-\u{2BFF}\u{2190}-\u{21FF}\u{1F1E6}-\u{1F1FF}\u{2122}\u{2139}\u{20E3}\u{FE0F}\u{200D}])+',
    unicode: true,
  );

  /// Split [text] into spans, rendering emoji runs ~1.4x larger than the
  /// surrounding text so emojis in posts/comments don't look tiny.
  static List<InlineSpan> _emojiAwareSpans(String text, TextStyle baseStyle) {
    if (text.isEmpty) return const <InlineSpan>[];
    final double base = baseStyle.fontSize ?? 14;
    // Emojis a touch larger than the text, not oversized (was 1.4 — too big).
    final TextStyle emojiStyle = baseStyle.copyWith(fontSize: base * 1.18);
    final List<InlineSpan> spans = [];
    int last = 0;
    for (final m in _emojiRegex.allMatches(text)) {
      if (m.start > last) {
        spans.add(
            TextSpan(text: text.substring(last, m.start), style: baseStyle));
      }
      spans.add(
          TextSpan(text: text.substring(m.start, m.end), style: emojiStyle));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    return spans;
  }

  // flutter_mentions default markup format:
  //   ${trigger}[__${id}__](__${display}__)
  // Example:
  //   @[__123__](__Md\u00A0Biplob\u00A0Hossain__)
  static final RegExp _flutterMentionsMarkupRegex = RegExp(
    r'([@#])\[__(.*?)__\]\(__([\s\S]*?)__\)',
  );

  /// Convert flutter_mentions controller.markupText into a stable text format
  /// that keeps multi-word names grouped for parsing & chip rendering.
  ///
  /// Output format:
  ///   @Full Name␠␠rest of text
  /// (double space after each mention)
  static String markupToDelimitedText(String markupText) {
    if (markupText.isEmpty) return markupText;

    // Normalize NBSP so stored text is human readable.
    final normalized = markupText.replaceAll('\u00A0', ' ');

    // Replace markup mentions with "@Display  ".
    final replaced = normalized.replaceAllMapped(
      _flutterMentionsMarkupRegex,
      (match) {
        final trigger = match.group(1) ?? '@';
        final display = (match.group(3) ?? '').replaceAll('\u00A0', ' ').trim();
        if (display.isEmpty) return '';
        return '$trigger$display  ';
      },
    );

    return replaced;
  }

  static List<String> extractMentionIdsFromMarkup(String markupText) {
    final ids = <String>[];
    if (markupText.isEmpty) return ids;

    for (final m in _flutterMentionsMarkupRegex.allMatches(markupText)) {
      final trigger = m.group(1);
      if (trigger != '@') continue;
      final id = (m.group(2) ?? '').trim();
      if (id.isNotEmpty) ids.add(id);
    }

    return ids;
  }

  /// One canonical mention rendering for every surface (post title, content,
  /// comments). Standard social-app treatment: plain semibold link-blue text,
  /// no filled chip — it reads as a tappable entity without decoration.
  static WidgetSpan _mentionChipSpan(
    String mentionName,
    Function(String)? onMentionTap, {
    double fontSize = 12.5,
  }) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onMentionTap?.call(mentionName),
        // The delimited mention format stores two spaces after the name and
        // the regex consumes them, so without this padding the mention and
        // the following text run together ("@NameText").
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '@$mentionName',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563EB),
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  /// Parse text and return a list of TextSpans with mentions styled as chips
  static List<InlineSpan> parseTextWithMentions(
    String text,
    BuildContext context, {
    Function(String)? onMentionTap,
    TextStyle? style,
  }) {
    if (text.isEmpty) return [TextSpan(text: text, style: style)];

    // Default plain-text style. Callers can override via [style] so the
    // surrounding Text.rich parent size/color is respected.
    final plainStyle = style ??
        TextStyle(
          fontSize: 15,
          color: Colors.grey.shade900,
          height: 1.4,
        );

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _mentionRegexDelimited.allMatches(text)) {
      // Add text before mention
      if (match.start > lastIndex) {
        spans.addAll(_emojiAwareSpans(
            text.substring(lastIndex, match.start), plainStyle));
      }

      // Add mention as a styled chip
      final mentionName =
          (match.group(1) ?? '').replaceAll('\u00A0', ' ').trim();
      spans.add(_mentionChipSpan(mentionName, onMentionTap,
          fontSize: plainStyle.fontSize ?? 15));

      lastIndex = match.end;
    }

    // Fallback pass (only for the remaining segments) to support older content
    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      int localLast = 0;
      for (final match
          in _mentionRegexCapitalizedFallback.allMatches(remaining)) {
        if (match.start > localLast) {
          spans.addAll(_emojiAwareSpans(
              remaining.substring(localLast, match.start), plainStyle));
        }

        final mentionName =
            (match.group(1) ?? '').replaceAll('\u00A0', ' ').trim();
        spans.add(_mentionChipSpan(mentionName, onMentionTap,
            fontSize: plainStyle.fontSize ?? 15));

        localLast = match.end;
      }

      if (localLast < remaining.length) {
        spans.addAll(
            _emojiAwareSpans(remaining.substring(localLast), plainStyle));
      }

      return spans;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.addAll(_emojiAwareSpans(text.substring(lastIndex), plainStyle));
    }

    return spans;
  }

  static List<InlineSpan> parseTextWithMentionsAndLinks(
    String text,
    BuildContext context, {
    Function(String)? onMentionTap,
    TextStyle? style,
    TextStyle? linkStyle,
  }) {
    if (text.isEmpty) return [TextSpan(text: text, style: style)];

    final normalStyle = style ??
        TextStyle(
          fontSize: 13,
          color: Colors.grey.shade800,
          height: 1.3,
        );

    final effectiveLinkStyle = linkStyle ??
        normalStyle.copyWith(
          color: const Color(0xFF2563EB),
          decoration: TextDecoration.none,
        );

    final List<InlineSpan> spans = [];
    int index = 0;

    while (index < text.length) {
      final mentionMatch = _mentionRegexDelimited.matchAsPrefix(text, index) ??
          _mentionRegexCapitalizedFallback.matchAsPrefix(text, index);
      final urlMatch = _urlRegex.matchAsPrefix(text, index);

      if (mentionMatch != null) {
        final mentionName =
            (mentionMatch.group(1) ?? '').replaceAll('\u00A0', ' ').trim();
        spans.add(_mentionChipSpan(mentionName, onMentionTap,
            fontSize: normalStyle.fontSize ?? 13));

        index = mentionMatch.end;
        continue;
      }

      if (urlMatch != null) {
        final url = urlMatch.group(1) ?? urlMatch.group(0) ?? '';
        if (url.isNotEmpty) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () {
                  UrlLauncherUtils.launchExternalUrl(url);
                },
                child: Text(url, style: effectiveLinkStyle),
              ),
            ),
          );
        }

        index = urlMatch.end;
        continue;
      }

      final substring = text.substring(index);
      final nextMentionDelimited = _mentionRegexDelimited.firstMatch(substring);
      final nextMentionFallback =
          _mentionRegexCapitalizedFallback.firstMatch(substring);
      final nextUrl = _urlRegex.firstMatch(substring);

      int nextIndex = text.length;
      if (nextMentionDelimited != null) {
        final pos = index + nextMentionDelimited.start;
        if (pos < nextIndex) nextIndex = pos;
      }
      if (nextMentionFallback != null) {
        final pos = index + nextMentionFallback.start;
        if (pos < nextIndex) nextIndex = pos;
      }
      if (nextUrl != null) {
        final pos = index + nextUrl.start;
        if (pos < nextIndex) nextIndex = pos;
      }

      spans.addAll(
          _emojiAwareSpans(text.substring(index, nextIndex), normalStyle));
      index = nextIndex;
    }

    return spans;
  }

  /// Extract all mentions from text
  static List<String> extractMentions(String text) {
    final mentions = <String>[];
    for (final match in _mentionRegexDelimited.allMatches(text)) {
      final mention = match.group(1);
      if (mention != null && mention.isNotEmpty) {
        mentions.add(mention.replaceAll('\u00A0', ' ').trim());
      }
    }

    for (final match in _mentionRegexCapitalizedFallback.allMatches(text)) {
      final mention = match.group(1);
      if (mention != null && mention.isNotEmpty) {
        final normalized = mention.replaceAll('\u00A0', ' ').trim();
        if (!mentions.contains(normalized)) {
          mentions.add(normalized);
        }
      }
    }
    return mentions;
  }

  /// Check if text contains mentions
  static bool hasMentions(String text) {
    return _mentionRegexDelimited.hasMatch(text) ||
        _mentionRegexCapitalizedFallback.hasMatch(text);
  }
}
