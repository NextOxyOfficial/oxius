import 'package:flutter/material.dart';

import '../services/link_preview_service.dart';
import '../utils/first_url_extractor.dart';
import '../utils/url_launcher_utils.dart';

class FirstLinkPreview extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry margin;

  const FirstLinkPreview({
    super.key,
    required this.text,
    this.margin = const EdgeInsets.only(top: 6),
  });

  @override
  Widget build(BuildContext context) {
    final url = FirstUrlExtractor.extract(text);
    if (url == null) return const SizedBox.shrink();

    return Container(
      margin: margin,
      child: LinkPreviewCard(url: url),
    );
  }
}

class LinkPreviewCard extends StatelessWidget {
  final String url;

  const LinkPreviewCard({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LinkPreviewData?>(
      future: LinkPreviewService.getPreview(url),
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
      height: 78,
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
    return InkWell(
      onTap: () {
        UrlLauncherUtils.launchExternalUrl(data.url);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
              SizedBox(
                width: 92,
                height: 92,
                child: Image.network(
                  data.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.link_rounded, color: Color(0xFF9CA3AF)),
                    );
                  },
                ),
              )
            else
              Container(
                width: 92,
                height: 92,
                color: const Color(0xFFF3F4F6),
                alignment: Alignment.center,
                child: const Icon(Icons.link_rounded, color: Color(0xFF9CA3AF)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.siteName != null && data.siteName!.isNotEmpty)
                      Text(
                        data.siteName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    if (data.title != null && data.title!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (data.description != null && data.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4B5563),
                          height: 1.2,
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
