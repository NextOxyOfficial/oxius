import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/url_launcher_utils.dart';

class LinkifyText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkifyText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<LinkifyText> createState() => _LinkifyTextState();
}

class _LinkifyTextState extends State<LinkifyText> {
  static final RegExp _urlRegex = RegExp(
    r"((?:https?:\/\/)?(?:www\.)?(?:localhost|(?:\d{1,3}\.){3}\d{1,3}|[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+)(?::\d{2,5})?(?:\/[\w\-._~%!$&'()*+,;=:@\/?#\[\]]*)?)",
    caseSensitive: false,
  );

  late List<InlineSpan> _spans;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _spans = _buildSpans(widget.text);
  }

  @override
  void didUpdateWidget(covariant LinkifyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      for (final r in _recognizers) {
        r.dispose();
      }
      _recognizers.clear();
      _spans = _buildSpans(widget.text);
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  List<InlineSpan> _buildSpans(String text) {
    if (text.isEmpty) return [TextSpan(text: text, style: widget.style)];

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: widget.style,
        ));
      }

      final rawUrl = match.group(0) ?? '';
      if (rawUrl.isNotEmpty) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            UrlLauncherUtils.launchExternalUrl(rawUrl);
          };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
          text: rawUrl,
          style: widget.linkStyle ??
              (widget.style?.copyWith(
                    color: const Color(0xFF2563EB),
                    decoration: TextDecoration.none,
                  ) ??
                  const TextStyle(
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.none,
                  )),
          recognizer: recognizer,
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: widget.style,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
