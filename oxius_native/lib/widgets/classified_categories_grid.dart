import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:oxius_native/theme/app_text.dart';
import '../services/classified_category_service.dart';
import '../services/category_icon_mapping.dart';

class ClassifiedCategoriesGrid extends StatefulWidget {
  final List<ClassifiedCategory> categories;
  final String? selectedId;
  final void Function(ClassifiedCategory category)? onTap;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? trailingTile;

  const ClassifiedCategoriesGrid({
    super.key,
    required this.categories,
    this.selectedId,
    this.onTap,
    this.isLoading = false,
    this.padding,
    this.margin,
    this.trailingTile,
  });

  @override
  State<ClassifiedCategoriesGrid> createState() =>
      _ClassifiedCategoriesGridState();
}

class _ClassifiedCategoriesGridState extends State<ClassifiedCategoriesGrid> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 340
        ? 3
        : width < 760
            ? 4
            : width < 1100
                ? 5
                : 6;
    final childAspectRatio = width < 340
        ? 0.72
        : width < 390
            ? 0.58
            : width < 760
                ? 0.76
                : 0.84;
    final spacing = width < 390 ? 8.0 : 10.0;

    if (widget.isLoading) {
      return _buildLoadingSkeleton(crossAxisCount, childAspectRatio);
    }

    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: widget.padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount:
            widget.categories.length + (widget.trailingTile != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.categories.length) {
            return widget.trailingTile!;
          }

          final category = widget.categories[index];
          final isSelected = widget.selectedId == category.id;

          return _CategoryTile(
            category: category,
            isSelected: isSelected,
            onTap: () => widget.onTap?.call(category),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(int crossAxisCount, double childAspectRatio) {
    final width = MediaQuery.of(context).size.width;
    final spacing = width < 390 ? 8.0 : 10.0;

    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: crossAxisCount * 2,
        itemBuilder: (context, index) => const _LoadingTile(),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final ClassifiedCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 390;
    final highlightColor = const Color(0xFF0F766E);
    final labelColor =
        widget.isSelected ? const Color(0xFF065F46) : const Color(0xFF334155);

    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(compact ? 2 : 4, 6, compact ? 2 : 4, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: compact ? 50 : 56,
                    height: compact ? 50 : 56,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? highlightColor.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _CategoryImage(
                        url: widget.category.getIconAsset(),
                        categoryTitle: widget.category.title,
                        size: compact ? 30 : 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: compact ? 32 : 34,
                    child: Text(
                      widget.category.title,
                      textAlign: TextAlign.center,
                      style: AppText.tileLabel(color: labelColor).copyWith(
                        fontSize: compact ? 11.2 : 12,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 52,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

// Category image widget with enhanced offline support
class _CategoryImage extends StatelessWidget {
  final String? url;
  final String? categoryTitle;
  final double size;

  const _CategoryImage({
    this.url,
    this.categoryTitle,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Print category info to see what we're working with
    debugPrint('CategoryImage: title="$categoryTitle", url="$url"');

    // Priority 1: Try network image first (with original colors preserved)
    if (url != null && url!.isNotEmpty && !_isLocalAsset(url!)) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        // Don't apply color tinting to preserve original icon colors
        placeholder: (c, _) => _ShimmerIcon(size: size),
        errorWidget: (c, _, __) => _getLocalAssetOrDefault(),
        // Cache the image for offline use
        cacheManager: CacheManager(
          Config(
            'category_icons_cache',
            stalePeriod: const Duration(days: 30), // Cache for 30 days
            maxNrOfCacheObjects: 200,
          ),
        ),
      );
    }

    // Priority 2: Use local asset if URL is a local asset path
    if (url != null && url!.isNotEmpty && _isLocalAsset(url!)) {
      return Image.asset(
        url!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _getLocalAssetOrDefault(),
      );
    }

    // Priority 3: Use offline local asset mapping or default
    return _getLocalAssetOrDefault();
  }

  Widget _getLocalAssetOrDefault() {
    // Try to get local asset mapping first
    final localAsset =
        CategoryIconMapping.getClassifiedIconAsset(categoryTitle);
    if (localAsset != null) {
      debugPrint('Using local asset: $localAsset for "$categoryTitle"');
      return Image.asset(
        localAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            CategoryIconMapping.getDefaultIcon(isSale: false, size: size),
      );
    }

    // Final fallback to default icon
    return CategoryIconMapping.getDefaultIcon(isSale: false, size: size);
  }

  bool _isLocalAsset(String url) {
    return url.startsWith('assets/');
  }
}

// Shimmer placeholder matching hero section style
class _ShimmerIcon extends StatelessWidget {
  final double size;

  const _ShimmerIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
