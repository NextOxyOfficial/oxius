import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/translation_service.dart';
import '../services/classified_category_service.dart';
import '../services/category_icon_mapping.dart';

class ClassifiedCategoriesGrid extends StatefulWidget {
  final List<ClassifiedCategory> categories;
  final String? selectedId;
  final void Function(ClassifiedCategory category)? onTap;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const ClassifiedCategoriesGrid({
    super.key,
    required this.categories,
    this.selectedId,
    this.onTap,
    this.isLoading = false,
    this.padding,
  });

  @override
  State<ClassifiedCategoriesGrid> createState() => _ClassifiedCategoriesGridState();
}

class _ClassifiedCategoriesGridState extends State<ClassifiedCategoriesGrid> {
  final TranslationService _ts = TranslationService();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (widget.categories.isEmpty) {
      return Center(
        child: Text(_ts.t('no_categories', fallback: 'No categories found')),
      );
    }

    // Hero section inspired grid layout: 4 columns with square tiles
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 categories per row like hero section
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9, // Slightly taller than square like hero section
        ),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
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

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemCount: 8, // Show 8 skeleton items
        itemBuilder: (context, index) => const _LoadingTile(),
      ),
    );
  }
}

// Hero section inspired category tile with AnimatedScale and rounded square design
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color scheme similar to hero section
    final backgroundColor = isDark ? Colors.grey.shade800 : const Color(0xFFF9FAFB);
    final highlightColor = theme.colorScheme.primary;
    final iconColor = widget.isSelected ? highlightColor : Colors.grey.shade600;
    final labelColor = widget.isSelected ? Colors.grey.shade800 : Colors.grey.shade600;
    
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null ? null : (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with hero section styling - rounded square
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.isSelected ? highlightColor.withValues(alpha: 0.1) : backgroundColor,
                borderRadius: BorderRadius.circular(12), // Rounded square like hero section
                border: widget.isSelected 
                  ? Border.all(color: highlightColor.withValues(alpha: 0.3), width: 1.5)
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _CategoryImage(
                  url: widget.category.getIconAsset(),
                  categoryTitle: widget.category.title,
                  // Don't pass color to preserve original icon colors
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label with hero section typography
            Text(
              widget.category.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: labelColor,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Loading skeleton tile matching hero section design
class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
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
    final localAsset = CategoryIconMapping.getClassifiedIconAsset(categoryTitle);
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
