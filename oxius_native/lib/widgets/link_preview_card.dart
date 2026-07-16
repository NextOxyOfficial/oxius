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
          // In chat (bare) show nothing while loading — the grey skeleton
          // read as a stray background box. Elsewhere keep the skeleton.
          return widget.bare ? const SizedBox.shrink() : _buildLoading();
        }

        final data = snapshot.data;
        if (data == null) {
          // Bare/chat: a URL-only message hides its raw text and relies on
          // this widget, so never collapse to nothing — show a minimal
          // tappable link chip. Non-chat: nothing.
          return widget.bare ? _buildBareFallback() : const SizedBox.shrink();
        }

        return _buildCard(context, data);
      },
    );
  }

  Widget _buildBareFallback() {
    final onDark = widget.onDark;
    return InkWell(
      onTap: () => UrlLauncherUtils.launchExternalUrl(widget.url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded,
              size: 15,
              color: onDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFF2563EB)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              widget.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: onDark ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
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

  // Standard chat preview card: thumbnail left, title + domain right, inside a
  // white rounded bordered box. One consistent look for every link (and shared
  // post) in the chat.
  Widget _buildChatPreviewCard(
      LinkPreviewData data, String domain, bool hasImage) {
    final title = (data.title != null && data.title!.trim().isNotEmpty)
        ? data.title!.trim()
        : (domain.isNotEmpty ? domain : data.url);
    return InkWell(
      onTap: () => UrlLauncherUtils.launchExternalUrl(data.url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 78,
                child: hasImage
                    ? Image.network(
                        data.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _chatThumbFallback(data),
                      )
                    : _chatThumbFallback(data),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.25,
                        ),
                      ),
                      if (domain.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          domain.toLowerCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatThumbFallback(LinkPreviewData data) {
    final favicon = data.faviconUrl;
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: (favicon != null && favicon.isNotEmpty)
          ? Image.network(
              favicon,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.link_rounded,
                  size: 24, color: Color(0xFF94A3B8)),
            )
          : const Icon(Icons.link_rounded, size: 24, color: Color(0xFF94A3B8)),
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

    // In chat, every preview uses one standard, social-app card: a white
    // rounded bordered box with the thumbnail on the LEFT and the title +
    // domain on the RIGHT (like Messenger/WhatsApp). It reads cleanly on both
    // the blue (own) and light (received) bubbles.
    if (widget.bare) {
      return _buildChatPreviewCard(data, domain, hasImage);
    }

    // Rich link preview: cover image on top (rounded), then the domain, bold
    // title and short description directly on the bubble — NO surrounding
    // card background, so the preview reads as part of the message.
    final bare = widget.bare;
    final onDark = widget.onDark;
    final domainColor =
        onDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF6B7280);
    final titleColor =
        onDark ? Colors.white : const Color(0xFF111827);
    final descColor =
        onDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF4B5563);
    return InkWell(
      // launchExternalUrl routes correctly: an adsyclub link opens the in-app
      // screen (via the deep-link navigator, which also closes the chat
      // overlay), any third-party link opens the browser.
      onTap: () => UrlLauncherUtils.launchExternalUrl(data.url),
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
                      // Bare/chat: no filled icon box (it read as a stray
                      // background); a subtle tint only off-chat.
                      color: bare
                          ? Colors.transparent
                          : const Color(0xFFEDF2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    // Prefer the site's real favicon; fall back to a link icon.
                    child: (data.faviconUrl != null &&
                            data.faviconUrl!.isNotEmpty)
                        ? Image.network(
                            data.faviconUrl!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.link_rounded,
                                size: 22,
                                color: onDark
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : const Color(0xFF64748B)),
                          )
                        : Icon(Icons.link_rounded,
                            size: 22,
                            color: onDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF64748B)),
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
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: domainColor,
                          ),
                        ),
                      if (data.title != null && data.title!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          data.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: descColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                      // Blocked/OG-less site: still show the link itself so the
                      // card is meaningful (favicon + domain + the URL).
                      if ((data.title == null || data.title!.isEmpty) &&
                          (data.description == null ||
                              data.description!.isEmpty)) ...[
                        const SizedBox(height: 3),
                        Text(
                          data.url.replaceFirst(RegExp(r'^https?://'), ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: descColor,
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
