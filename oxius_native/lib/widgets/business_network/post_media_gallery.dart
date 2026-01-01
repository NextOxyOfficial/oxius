import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';

class PostMediaGallery extends StatelessWidget {
  final List<PostMedia> media;
  final Function(int) onMediaTap;

  const PostMediaGallery({
    super.key,
    required this.media,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaLayout(context),
      ),
    );
  }

  Widget _buildMediaLayout(BuildContext context) {
    if (media.length == 1) {
      return _buildSingleImage(context, 0);
    } else if (media.length == 2) {
      return _buildTwoImages(context);
    } else if (media.length == 3) {
      return _buildThreeImages(context);
    } else if (media.length == 4) {
      return _buildFourImages(context);
    } else {
      return _buildFiveOrMoreImages(context);
    }
  }

  Widget _buildMediaContent(
    BuildContext context,
    int index, {
    required BoxFit fit,
    double errorIconSize = 48,
  }) {
    final item = media[index];
    final imageUrl = item.bestThumbnailUrl;

    if (imageUrl.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: item.isVideo ? Colors.grey.shade900 : Colors.grey.shade200,
            child: Center(
              child: Icon(
                item.isVideo ? Icons.play_circle_fill_rounded : Icons.image,
                size: errorIconSize,
                color: item.isVideo ? Colors.white.withOpacity(0.9) : Colors.grey,
              ),
            ),
          ),
          if (item.isVideo)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: fit,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(
                  item.isVideo ? Icons.play_circle_fill_rounded : Icons.image,
                  size: errorIconSize,
                  color: item.isVideo ? Colors.grey.shade700 : Colors.grey,
                ),
              ),
            );
          },
        ),
        if (item.isVideo)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (item.isVideo)
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleImage(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onMediaTap(index),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 500,
          minHeight: 200,
        ),
        child: _buildMediaContent(
          context,
          index,
          fit: BoxFit.contain,
          errorIconSize: 48,
        ),
      ),
    );
  }

  Widget _buildTwoImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onMediaTap(0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildMediaContent(
                    context,
                    0,
                    fit: BoxFit.cover,
                    errorIconSize: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: GestureDetector(
                onTap: () => onMediaTap(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildMediaContent(
                    context,
                    1,
                    fit: BoxFit.cover,
                    errorIconSize: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => onMediaTap(0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildMediaContent(
                    context,
                    0,
                    fit: BoxFit.cover,
                    errorIconSize: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onMediaTap(1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: _buildMediaContent(
                          context,
                          1,
                          fit: BoxFit.cover,
                          errorIconSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onMediaTap(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: _buildMediaContent(
                          context,
                          2,
                          fit: BoxFit.cover,
                          errorIconSize: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFourImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(0),
                    child: _buildMediaContent(
                      context,
                      0,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(1),
                    child: _buildMediaContent(
                      context,
                      1,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(2),
                    child: _buildMediaContent(
                      context,
                      2,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(3),
                    child: _buildMediaContent(
                      context,
                      3,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveOrMoreImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(0),
                    child: _buildMediaContent(
                      context,
                      0,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(1),
                    child: _buildMediaContent(
                      context,
                      1,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(2),
                    child: _buildMediaContent(
                      context,
                      2,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaContent(
                          context,
                          3,
                          fit: BoxFit.cover,
                          errorIconSize: 32,
                        ),
                        if (media.length > 4)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            child: Center(
                              child: Text(
                                '+${media.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
