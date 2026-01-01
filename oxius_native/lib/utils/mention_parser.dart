import 'package:flutter/material.dart';

import 'url_launcher_utils.dart';

class MentionParser {
  // Regex to match @mentions in text
  // Matches @Name or @First Last (capitalized words only, stops at lowercase or special chars)
  static final RegExp _mentionRegex = RegExp(
    r'@([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)(?=\s|[.!?,:;]|$)',
    multiLine: true,
  );

  static final RegExp _urlRegex = RegExp(
    r"((?:https?:\/\/)?(?:www\.)?(?:localhost|(?:\d{1,3}\.){3}\d{1,3}|[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+)(?::\d{2,5})?(?:\/[\w\-._~%!$&'()*+,;=:@\/?#\[\]]*)?)",
    caseSensitive: false,
  );

  /// Parse text and return a list of TextSpans with mentions styled as chips
  static List<InlineSpan> parseTextWithMentions(
    String text,
    BuildContext context, {
    Function(String)? onMentionTap,
  }) {
    if (text.isEmpty) return [TextSpan(text: text)];

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in _mentionRegex.allMatches(text)) {
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
      final mentionName = match.group(1) ?? '';
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => onMentionTap?.call(mentionName),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                height: 1.2,
              ),
            ),
          ),
        ),
      ));

      lastIndex = match.end;
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
          decoration: TextDecoration.underline,
        );

    final List<InlineSpan> spans = [];
    int index = 0;

    while (index < text.length) {
      final mentionMatch = _mentionRegex.matchAsPrefix(text, index);
      final urlMatch = _urlRegex.matchAsPrefix(text, index);

      if (mentionMatch != null) {
        final mentionName = mentionMatch.group(1) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => onMentionTap?.call(mentionName),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  height: 1.2,
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

      final nextMention = _mentionRegex.firstMatch(text.substring(index));
      final nextUrl = _urlRegex.firstMatch(text.substring(index));

      int nextIndex = text.length;
      if (nextMention != null) {
        nextIndex = (index + nextMention.start) < nextIndex ? (index + nextMention.start) : nextIndex;
      }
      if (nextUrl != null) {
        nextIndex = (index + nextUrl.start) < nextIndex ? (index + nextUrl.start) : nextIndex;
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
    for (final match in _mentionRegex.allMatches(text)) {
      final mention = match.group(1);
      if (mention != null && mention.isNotEmpty) {
        mentions.add(mention);
      }
    }
    return mentions;
  }

  /// Check if text contains mentions
  static bool hasMentions(String text) {
    return _mentionRegex.hasMatch(text);
  }
}
