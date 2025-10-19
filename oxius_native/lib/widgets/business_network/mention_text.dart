import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final Function(String)? onMentionTap;

  const MentionText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _buildTextSpans(context);
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final List<TextSpan> spans = [];
    final RegExp mentionRegex = RegExp(r'@(\w+(?:\s+\w+)*)');
    
    int lastMatchEnd = 0;
    
    for (final match in mentionRegex.allMatches(text)) {
      // Add text before mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style ?? const TextStyle(color: Colors.black87),
        ));
      }
      
      // Add mention with highlighting
      final mentionText = match.group(0)!;
      spans.add(TextSpan(
        text: mentionText,
        style: (style ?? const TextStyle()).copyWith(
          color: const Color(0xFF3B82F6),
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onMentionTap != null) {
              onMentionTap!(mentionText);
            }
          },
      ));
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style ?? const TextStyle(color: Colors.black87),
      ));
    }
    
    return spans;
  }
}
