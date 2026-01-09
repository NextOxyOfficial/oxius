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

  /// Parse text and return a list of TextSpans with mentions styled as chips
  static List<InlineSpan> parseTextWithMentions(
    String text,
    BuildContext context, {
    Function(String)? onMentionTap,
  }) {
    if (text.isEmpty) return [TextSpan(text: text)];

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _mentionRegexDelimited.allMatches(text)) {
      // Add text before mention
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            height: 1.3,
          ),
        ));
      }

      // Add mention as a styled chip
      final mentionName = (match.group(1) ?? '').replaceAll('\u00A0', ' ').trim();
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => onMentionTap?.call(mentionName),
          child: Container(
            margin: const EdgeInsets.only(left: 1, right: 0),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50.withOpacity(0.8),
                  Colors.purple.shade50.withOpacity(0.8),
                ],
              ),
              border: Border.all(
                color: Colors.blue.shade200.withOpacity(0.6),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '@$mentionName',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
                height: 1.0,
              ),
            ),
          ),
        ),
      ));

      lastIndex = match.end;
    }

    // Fallback pass (only for the remaining segments) to support older content
    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      int localLast = 0;
      for (final match in _mentionRegexCapitalizedFallback.allMatches(remaining)) {
        if (match.start > localLast) {
          spans.add(TextSpan(
            text: remaining.substring(localLast, match.start),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ));
        }

        final mentionName = (match.group(1) ?? '').replaceAll('\u00A0', ' ').trim();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => onMentionTap?.call(mentionName),
            child: Container(
              margin: const EdgeInsets.only(left: 1, right: 0),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50.withOpacity(0.8),
                    Colors.purple.shade50.withOpacity(0.8),
                  ],
                ),
                border: Border.all(
                  color: Colors.blue.shade200.withOpacity(0.6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '@$mentionName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ));

        localLast = match.end;
      }

      if (localLast < remaining.length) {
        spans.add(TextSpan(
          text: remaining.substring(localLast),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            height: 1.3,
          ),
        ));
      }

      return spans;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade800,
          height: 1.3,
        ),
      ));
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
        final mentionName = (mentionMatch.group(1) ?? '').replaceAll('\u00A0', ' ').trim();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => onMentionTap?.call(mentionName),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50.withOpacity(0.8),
                    Colors.purple.shade50.withOpacity(0.8),
                  ],
                ),
                border: Border.all(
                  color: Colors.blue.shade200.withOpacity(0.6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '@$mentionName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ));

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
      final nextMentionFallback = _mentionRegexCapitalizedFallback.firstMatch(substring);
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

      spans.add(TextSpan(
        text: text.substring(index, nextIndex),
        style: normalStyle,
      ));
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
    return _mentionRegexDelimited.hasMatch(text) || _mentionRegexCapitalizedFallback.hasMatch(text);
  }
}
