import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../utils/html_content_utils.dart';
import 'news_comments_sheet.dart';

/// The embedded Adsy News story shown inside a news reshare — used by both the
/// feed and the post-detail screen so the design lives in one place.
/// Mirrors [ResharedPostCard], which does the same job for post reshares.
class ResharedNewsCard extends StatelessWidget {
  final SharedNewsPreview news;
  final VoidCallback? onOpen;

  const ResharedNewsCard({
    super.key,
    required this.news,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final image = (news.image ?? '').isNotEmpty
        ? AppConfig.getAbsoluteUrl(news.image!)
        : '';
    final excerpt = HtmlContentUtils.toPlainText(news.content).trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.newspaper_rounded,
                            color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source badge — makes it obvious this is a news story
                    // rather than a user's post.
                    Row(
                      children: [
                        const Icon(Icons.newspaper_rounded,
                            size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          'এডসি নিউজ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (news.title.isNotEmpty)
                      Text(
                        news.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.35,
                        ),
                      ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          'আরও পড়ুন',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const Spacer(),
                        // The original story's engagement — tap opens its
                        // comments right here.
                        InkWell(
                          onTap: () => NewsCommentsSheet.show(
                            context,
                            newsId: news.id,
                            newsTitle: news.title,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.mode_comment_outlined,
                                    size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 3),
                                Text(
                                  '${news.commentCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.share_outlined,
                            size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 3),
                        Text(
                          '${news.shareCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
