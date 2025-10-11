import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/classified_category_service.dart';
import '../screens/classified_category_list_screen.dart';

/// Widget to display classified categories in a grid
/// Can be added to the home screen or any other screen
class ClassifiedCategoriesWidget extends StatefulWidget {
  final int? maxCategories; // Limit number of categories to show, null for all
  final EdgeInsets? padding;
  
  const ClassifiedCategoriesWidget({
    Key? key,
    this.maxCategories,
    this.padding,
  }) : super(key: key);

  @override
  State<ClassifiedCategoriesWidget> createState() => _ClassifiedCategoriesWidgetState();
}

class _ClassifiedCategoriesWidgetState extends State<ClassifiedCategoriesWidget> {
  late final ClassifiedCategoryService _categoryService;
  List<ClassifiedCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _categoryService = ClassifiedCategoryService(baseUrl: ApiService.baseUrl);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final categories = await _categoryService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = widget.maxCategories != null
              ? categories.take(widget.maxCategories!).toList()
              : categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Classified Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (widget.maxCategories != null && _categories.length >= widget.maxCategories!)
                TextButton(
                  onPressed: () {
                    // Navigate to all categories screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View All Categories - Coming Soon')),
                    );
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Loading State
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          
          // Categories Grid
          if (!_isLoading && _categories.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          
          // Empty State
          if (!_isLoading && _categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No categories available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ClassifiedCategory category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassifiedCategoryListScreen(
                categoryId: category.id,
                categorySlug: category.slug ?? category.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Icon/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: category.image != null && category.image!.isNotEmpty
                      ? category.image!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: category.image!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.category,
                                color: Color(0xFF10B981),
                                size: 32,
                              ),
                            )
                          : Image.asset(
                              category.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.category,
                                color: Color(0xFF10B981),
                                size: 32,
                              ),
                            )
                      : const Icon(
                          Icons.category,
                          color: Color(0xFF10B981),
                          size: 32,
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Category Title
              Text(
                category.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal list version of classified categories
/// Useful for home screen hero sections
class ClassifiedCategoriesHorizontalList extends StatefulWidget {
  final int maxCategories;
  
  const ClassifiedCategoriesHorizontalList({
    Key? key,
    this.maxCategories = 6,
  }) : super(key: key);

  @override
  State<ClassifiedCategoriesHorizontalList> createState() => 
      _ClassifiedCategoriesHorizontalListState();
}

class _ClassifiedCategoriesHorizontalListState 
    extends State<ClassifiedCategoriesHorizontalList> {
  late final ClassifiedCategoryService _categoryService;
  List<ClassifiedCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _categoryService = ClassifiedCategoryService(baseUrl: ApiService.baseUrl);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final categories = await _categoryService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories.take(widget.maxCategories).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryItem(category);
        },
      ),
    );
  }

  Widget _buildCategoryItem(ClassifiedCategory category) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassifiedCategoryListScreen(
              categoryId: category.id,
              categorySlug: category.slug ?? category.id,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: category.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: category.image!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: category.image!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(
                                Icons.category,
                                color: Color(0xFF10B981),
                                size: 24,
                              ),
                            )
                          : Image.asset(
                              category.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.category,
                                color: Color(0xFF10B981),
                                size: 24,
                              ),
                            ),
                    )
                  : const Icon(
                      Icons.category,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
