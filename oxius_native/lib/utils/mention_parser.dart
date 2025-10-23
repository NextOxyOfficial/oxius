import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MentionParser {
  // Regex to match @mentions in text
  // Matches @Name or @First Last (capitalized words only, stops at lowercase or special chars)
  static final RegExp _mentionRegex = RegExp(
    r'@([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)(?=\s|[.!?,:;]|$)',
    multiLine: true,
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
