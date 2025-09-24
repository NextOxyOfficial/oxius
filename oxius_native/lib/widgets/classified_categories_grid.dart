import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
    this.crossAxisCountMobile = 3,
    this.crossAxisCountTablet = 5,
  });

  @override
  State<ClassifiedCategoriesGrid> createState() => _ClassifiedCategoriesGridState();
}

class _ClassifiedCategoriesGridState extends State<ClassifiedCategoriesGrid> {
  final TranslationService _ts = TranslationService();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 640; // mimic sm: breakpoint
    final crossAxisCount = isTablet ? widget.crossAxisCountTablet : widget.crossAxisCountMobile;
    final itemHeight = isTablet ? 125.0 : 110.0;

    if (widget.isLoading) {
      return _SkeletonGrid(crossAxisCount: crossAxisCount, itemHeight: itemHeight);
    }

    if (widget.categories.isEmpty) {
      return Center(
        child: Text(_ts.t('no_categories', fallback: 'No categories found')),
      );
    }

    return Padding(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: (itemHeight / itemHeight),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
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
    final theme = Theme.of(context);
    final backgroundColor = isSelected 
        ? Colors.green.shade100.withOpacity(.6)
        : Colors.green.shade50.withOpacity(.35);
    final borderColor = isSelected 
        ? Colors.green.shade400
        : Colors.green.shade100;
        
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap == null ? null : () => onTap!(category),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _CategoryImage(url: category.getIconAsset()),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            )
          ],
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
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: _isLocalAsset(url!) 
        ? Image.asset(
            url!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => const _PlaceholderIcon(),
          )
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            placeholder: (c, _) => const _ShimmerCircle(),
            errorWidget: (c, _, __) => const _PlaceholderIcon(),
          ),
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.green.shade200),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.category, color: Colors.green, size: 30),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.shade100.withOpacity(.3),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  final int crossAxisCount;
  final double itemHeight;
  const _SkeletonGrid({required this.crossAxisCount, required this.itemHeight});

  @override
  Widget build(BuildContext context) {
    final total = crossAxisCount * 2; // two rows skeleton
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: (itemHeight / itemHeight),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: total,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade50),
          color: Colors.green.shade50.withOpacity(.3),
        ),
      ),
    );
  }
}
