import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../utils/html_content_utils.dart';
import 'post_media_gallery.dart';

/// The embedded "original post" card shown inside a reshare/repost — used both
/// in the feed and on the post-detail screen so the design lives in one place.
///
///  - [onAuthorTap]  : open the original author's profile
///  - [onOpenPost]   : open the original post's detail (আরও পড়ুন / image tap)
///  - [onOpenVideo]  : play the original video full-screen (video tap)
class ResharedPostCard extends StatelessWidget {
  final SharedPostPreview shared;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onOpenPost;
  final VoidCallback? onOpenVideo;

  const ResharedPostCard({
    super.key,
    required this.shared,
    this.onAuthorTap,
    this.onOpenPost,
    this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = AppConfig.getAbsoluteUrl(shared.authorImage);
    final fullText = HtmlContentUtils.toPlainText(shared.content).trim();
    final isLongText = fullText.length > 160;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original author — tap opens their Business Network profile.
            InkWell(
              onTap: onAuthorTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE2E8F0),
                      ),
                      child: ClipOval(
                        child: avatar.isNotEmpty
                            ? Image.network(avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: Color(0xFF94A3B8)))
                            : const Icon(Icons.person_rounded,
                                size: 16, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        shared.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                    if (shared.authorVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          size: 13, color: Color(0xFF2563EB)),
                    ],
                  ],
                ),
              ),
            ),
            // Text (few lines) + "আরও পড়ুন" → original post detail.
            if (fullText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF334155),
                          height: 1.45),
                    ),
                    if (isLongText)
                      GestureDetector(
                        onTap: onOpenPost,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Text(
                            'আরও পড়ুন',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Full media gallery (multiple photos + video), same as the feed.
            if (shared.media.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: PostMediaGallery(
                  media: shared.media,
                  onMediaTap: (index) {
                    final tapped = index >= 0 && index < shared.media.length
                        ? shared.media[index]
                        : null;
                    if (tapped != null && tapped.isVideo) {
                      onOpenVideo?.call();
                    } else {
                      onOpenPost?.call();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
