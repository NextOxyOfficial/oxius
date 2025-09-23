import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/sale_service.dart';

class SaleCategory extends StatefulWidget {
  const SaleCategory({super.key});

  @override
  State<SaleCategory> createState() => _SaleCategoryState();
}

class _SaleCategoryState extends State<SaleCategory> {
  final TranslationService _translationService = TranslationService();
  int? selectedCategory;
  bool isLoading = false;
  bool isLoadingCategories = true;
  bool isLoadingBanners = true;
  bool bannersFetched = false;
  bool categoriesFetched = false;
  List<dynamic> categories = [];
  List<dynamic> banners = [];
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    // Initialize translations and listen for language changes so UI updates dynamically
    _translationService.initialize();
    _translationService.addListener(_onTranslationsChanged);
    _initData();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initData() async {
    try {
      setState(() {
        isLoadingCategories = true;
        isLoadingBanners = true;
      });
      final results = await Future.wait([
        SaleService.fetchCategories(),
        SaleService.fetchBanners(),
      ]);
      final List<dynamic> fetchedCategories = results[0];
      final List<dynamic> fetchedBanners = results[1];
      setState(() {
        categories = fetchedCategories;
        banners = fetchedBanners;
        categoriesFetched = true;
        bannersFetched = true;
        isLoadingCategories = false;
        isLoadingBanners = false;
      });
      if (categories.isNotEmpty) {
        selectedCategory = categories.first['id'];
        await _loadPostsForCategory(selectedCategory!);
      }
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
        isLoadingBanners = false;
      });
      debugPrint('Error initializing sale data: $e');
    }
  }

  Future<void> _loadPostsForCategory(int categoryId) async {
    setState(() {
      isLoading = true;
      products = [];
    });
    try {
      final data = await SaleService.fetchPosts(categoryId: categoryId, page: 1, limit: 8);
      final results = (data['results'] ?? []) as List<dynamic>;
      setState(() {
        products = results.take(8).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch posts: $e');
      setState(() {
        isLoading = false;
        products = [];
      });
    }
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  void selectCategory(Map<String, dynamic> category) {
    final id = category['id'] as int;
    if (selectedCategory == id) return;
    setState(() {
      selectedCategory = id;
    });
    _loadPostsForCategory(id);
  }

  String getSelectedCategoryName() {
    if (selectedCategory == null || categories.isEmpty) return '';
    // Cast to the expected map type to avoid runtime type issues
    final list = categories.cast<Map<String, dynamic>>();
    final Map<String, dynamic> selected = list.firstWhere(
      (cat) => cat['id'] == selectedCategory,
      orElse: () => list.first,
    );
    return selected['name'] ?? selected['category'] ?? '';
  }

  List<dynamic> getFilteredProducts() => products;

  Widget _buildCategoryIcon(dynamic category) {
    final iconUrl = category['icon'] as String?;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.network(
          iconUrl,
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.widgets_outlined,
            size: 20,
            color: Colors.grey,
          ),
        ),
      );
    }
    return const Icon(Icons.widgets_outlined, size: 20, color: Colors.grey);
  }

  String _formatPrice(dynamic price, bool negotiable) {
    if (negotiable && (price == null || price.toString().isEmpty)) {
      return _translationService.t('negotiable', fallback: 'Negotiable');
    }
    try {
      final num p = price is String ? num.parse(price) : (price as num);
      final s = p
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      return '৳$s';
    } catch (_) {
      return '৳${price ?? ''}';
    }
  }

  String _formatLocation(Map<String, dynamic> p) {
    final parts = [p['area'], p['district'], p['division']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.first.toString() : '';
  }

  String _relativeDate(dynamic createdAt) {
    try {
      final dt = DateTime.tryParse(createdAt?.toString() ?? '');
      if (dt == null) return '';
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 1) return '${diff.inDays}d ago';
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header Section
          _buildHeader(context),
          
          // Banner Section
          _buildBannerSection(),
          
          // Categories Section
          _buildCategoriesSection(isMobile),
          
          // Products Section
          if (selectedCategory != null) _buildProductsSection(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.05),
            const Color(0xFF06B6D4).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header row: icon with dot + title on same line, subtitle below (left aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_offer_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _translationService.t('sale_listing', fallback: 'Sale Listings'),
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _translationService.t('buy_and_sell_products', fallback: 'Buy & sell amazing products'),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  _translationService.t('marketplace', fallback: 'Marketplace'),
                  Icons.shopping_bag_outlined,
                  false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  _translationService.t('my_posts', fallback: 'My Posts'),
                  Icons.description_outlined,
                  false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  _translationService.t('post_sale', fallback: 'Post Sale'),
                  Icons.add_circle_outline,
                  true, // Highlighted
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? const Color(0xFF10B981).withOpacity(0.1)
            : Colors.white,
        border: Border.all(
          color: isHighlighted 
              ? const Color(0xFF10B981)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isHighlighted 
                ? const Color(0xFF10B981)
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isHighlighted 
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 80,
                child: _buildBannerTile(index: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 80,
                child: _buildBannerTile(index: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTile({required int index}) {
    if (isLoadingBanners && !bannersFetched) {
      return Container(color: Colors.grey.shade200);
    }
    if (banners.isEmpty || index >= banners.length) {
      final colors = [0xFF3B82F6, 0xFF4F46E5];
      return Container(color: Color(colors[index % colors.length]).withOpacity(0.1));
    }
    final b = banners[index];
    final img = b['image'] as String?;
    return img == null || img.isEmpty
        ? Container(color: Colors.grey.shade100)
        : Image.network(
            img,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ),
          );
  }

  Widget _buildCategoriesSection(bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: (categories.isEmpty
                  ? <dynamic> []
                  : categories)
              .map((category) {
            final isSelected = selectedCategory == category['id'];
            
            return GestureDetector(
              onTap: () => selectCategory(Map<String, dynamic>.from(category)),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected 
                      ? Border.all(color: const Color(0xFF10B981))
                      : null,
                ),
                child: Column(
                  children: [
                    _buildCategoryIcon(category),
                    const SizedBox(height: 4),
                    Text(
                      category['name'] ?? category['category'] ?? 'Category',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected 
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductsSection(bool isMobile) {
    if (isLoading) {
      return _buildLoadingSkeleton();
    }

    final products = getFilteredProducts();
    
    if (products.isEmpty) {
      return _buildNoProductsFound();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getSelectedCategoryName(),
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: () {
                  debugPrint('View all ${getSelectedCategoryName()} items');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _translationService.t('view_all', fallback: 'View All'),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Products grid
          if (isMobile)
            _buildMobileProductsList(products)
          else
            _buildDesktopProductsGrid(products),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMobileProductsList(List<dynamic> products) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 4, right: 4),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index] as Map<String, dynamic>;
          return Container(
            width: MediaQuery.of(context).size.width * 0.45,
            margin: EdgeInsets.only(right: index == products.length - 1 ? 4 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Stack(
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        image: ((product['main_image'] is String) && (product['main_image'] as String).isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(product['main_image'] as String),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    // Price badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatPrice(product['price'], product['negotiable'] == true),
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Product details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title'] ?? '',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const Spacer(),
                        
                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                _formatLocation(product),
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Condition and date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                product['condition'] ?? '',
                                style: GoogleFonts.roboto(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Text(
                              _relativeDate(product['created_at']),
                              style: GoogleFonts.roboto(
                                fontSize: 8,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopProductsGrid(List<dynamic> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index] as Map<String, dynamic>;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Similar structure as mobile but adjusted for desktop
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: ((product['main_image'] is String) && (product['main_image'] as String).isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(product['main_image'] as String),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] ?? '',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(product['price'], product['negotiable'] == true),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.45,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProductsFound() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _translationService.t('no_listings_found', fallback: 'No listings found'),
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _translationService.t('no_items_currently_listed', fallback: 'No items currently listed in this category'),
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}