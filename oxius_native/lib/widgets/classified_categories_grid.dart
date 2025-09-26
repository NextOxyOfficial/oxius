import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/classified_category_service.dart';
import '../services/translation_service.dart';

class ClassifiedCategoriesGrid extends StatefulWidget {
  final List<ClassifiedCategory> categories;
  final String? selectedId;
  final void Function(ClassifiedCategory category)? onTap;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final int crossAxisCountMobile;
  final int crossAxisCountTablet;

  const ClassifiedCategoriesGrid({
    super.key,
    required this.categories,
    this.selectedId,
    this.onTap,
    this.isLoading = false,
    this.padding,
    this.crossAxisCountMobile = 4,
    this.crossAxisCountTablet = 4,
  });

  @override
  State<ClassifiedCategoriesGrid> createState() => _ClassifiedCategoriesGridState();
}

class _ClassifiedCategoriesGridState extends State<ClassifiedCategoriesGrid> {
  final TranslationService _ts = TranslationService();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final crossAxisCount = isTablet ? widget.crossAxisCountTablet : widget.crossAxisCountMobile;
  final aspectRatio = _calculateAspectRatio(isTablet, crossAxisCount);
  final legacyItemHeight = isTablet ? 150.0 : 120.0;

    if (widget.isLoading) {
      return _SkeletonGrid(
        crossAxisCount: crossAxisCount,
        aspectRatio: aspectRatio,
        itemHeight: legacyItemHeight,
      );
    }

    if (widget.categories.isEmpty) {
      return Center(
        child: Text(_ts.t('no_categories', fallback: 'No categories found')),
      );
    }

    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
        ),
        itemCount: widget.categories.length,
        itemBuilder: (context, i) {
          final c = widget.categories[i];
          final isSelected = widget.selectedId == c.id;
          return _CategoryTile(
            category: c,
            onTap: widget.onTap,
            isSelected: isSelected,
          );
        },
      ),
    );
  }

  double _calculateAspectRatio(bool isTablet, int crossAxisCount) {
    if (isTablet) {
      return crossAxisCount >= 5 ? 0.9 : 0.84;
    }
    if (crossAxisCount >= 4) {
      return 0.7;
    }
    return 0.8;
  }
}

class _CategoryTile extends StatelessWidget {
  final ClassifiedCategory category;
  final void Function(ClassifiedCategory category)? onTap;
  final bool isSelected;

  const _CategoryTile({
    required this.category,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade100;
    const highlightColor = Color(0xFF10B981);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap == null ? null : () => onTap!(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? highlightColor.withOpacity(0.12) : baseColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? highlightColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSelected ? 0.1 : 0.04),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: _CategoryImage(url: category.getIconAsset()),
              ),
              const SizedBox(height: 6),
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? highlightColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final String? url;
  const _CategoryImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const _PlaceholderIcon();
    }

    if (_isLocalAsset(url!)) {
      return Image.asset(
        url!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _PlaceholderIcon(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.contain,
      placeholder: (c, _) => const _ShimmerCircle(),
      errorWidget: (c, _, __) => const _PlaceholderIcon(),
    );
  }

  bool _isLocalAsset(String url) {
    return url.startsWith('assets/');
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.widgets_outlined,
      color: Color(0xFF6B7280),
      size: 20,
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final double? aspectRatio;
  final double itemHeight;

  const _SkeletonGrid({
    required this.crossAxisCount,
    this.aspectRatio,
    this.itemHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    final total = crossAxisCount * 2; // two rows skeleton
    final double effectiveAspectRatio = (aspectRatio != null && aspectRatio! > 0)
        ? aspectRatio!
        : (itemHeight > 0 ? 1 : 1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: effectiveAspectRatio,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
      ),
      itemCount: total,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}
