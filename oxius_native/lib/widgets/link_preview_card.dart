import 'package:flutter/material.dart';

import '../services/link_preview_service.dart';
import '../utils/first_url_extractor.dart';
import '../utils/url_launcher_utils.dart';

class FirstLinkPreview extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry margin;

  /// Chat mode: no card background/border (blends into the message bubble),
  /// text tuned for a dark (own/blue) or light (received) bubble, and the tap
  /// opens the link in a BROWSER (not the internal deep-link navigator).
  final bool bare;
  final bool onDark;

  const FirstLinkPreview({
    super.key,
    required this.text,
    this.margin = const EdgeInsets.only(top: 6),
    this.bare = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = FirstUrlExtractor.extract(text);
    if (url == null) return const SizedBox.shrink();

    return Container(
      margin: margin,
      child: LinkPreviewCard(url: url, bare: bare, onDark: onDark),
    );
  }
}

class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool bare;
  final bool onDark;

  const LinkPreviewCard({
    super.key,
    required this.url,
    this.bare = false,
    this.onDark = false,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  late Future<LinkPreviewData?> _future;

  @override
  void initState() {
    super.initState();
    _future = LinkPreviewService.getPreview(widget.url);
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = LinkPreviewService.getPreview(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LinkPreviewData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return _buildCard(context, data);
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(widthFactor: 0.85),
                SizedBox(height: 8),
                _Line(widthFactor: 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, LinkPreviewData data) {
    final hasImage = data.imageUrl != null && data.imageUrl!.isNotEmpty;
    final domain = (() {
      final site = (data.siteName ?? '').trim();
      if (site.isNotEmpty) return site;
      try {
        return Uri.parse(data.url).host.replaceFirst('www.', '');
      } catch (_) {
        return '';
      }
    })();

    // Rich link preview: cover image on top (rounded), then the domain, bold
    // title and short description directly on the bubble — NO surrounding
    // card background, so the preview reads as part of the message. Tapping
    // navigates immediately (DeepLinkService dismisses any chat overlay).
    return InkWell(
      onTap: () {
        UrlLauncherUtils.launchExternalUrl(data.url);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1.91,
                child: Image.network(
                  data.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: const Icon(Icons.link_rounded,
                        size: 28, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, hasImage ? 7 : 0, 0, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!hasImage) ...[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.link_rounded,
                        size: 22, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (domain.isNotEmpty)
                        Text(
                          domain.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      if (data.title != null && data.title!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          data.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (data.description != null &&
                          data.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          data.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4B5563),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final double widthFactor;

  const _Line({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
