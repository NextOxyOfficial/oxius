import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import '../services/classified_category_service.dart';
import 'classified_search_bar.dart';
import 'classified_categories_grid.dart';
import 'ads_scroll.dart'; // Import the new ads scroll widget

class ClassifiedServicesSection extends StatefulWidget {
  const ClassifiedServicesSection({super.key});

  @override
  State<ClassifiedServicesSection> createState() => _ClassifiedServicesSectionState();
}

class _ClassifiedServicesSectionState extends State<ClassifiedServicesSection> {
  final TranslationService _translationService = TranslationService();
  final Set<String> _loadingButtons = <String>{};
  final List<ClassifiedCategory> _categories = [];
  List<Map<String, dynamic>> _posts = [];
  bool _loadingCategories = false;
  bool _loadingPosts = false;
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _translationService.addListener(_onTranslationsChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleButtonClick(String buttonId) {
    setState(() {
      _loadingButtons.add(buttonId);
    });
    
    // Navigate to classified services page (placeholder)
    // TODO: Implement navigation to /my-classified-services
    
    // Remove loading state after navigation simulation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _loadingButtons.remove(buttonId);
        });
      }
    });
  }

  Future<void> _bootstrap() async {
    print('DEBUG: Bootstrap called, initialized: $_initialized');
    if (_initialized) return;
    _initialized = true;
    print('DEBUG: Starting bootstrap process...');
    await _loadCategories();
    // Optionally load initial posts (could be trending/latest)
    await _loadPosts();
    print('DEBUG: Bootstrap completed');
  }

  Future<void> _loadCategories() async {
    print('DEBUG: Loading categories...');
    setState(() { _loadingCategories = true; });
    try {
      final cats = await ApiService.fetchClassifiedCategories();
      print('DEBUG: API returned ${cats.length} categories');
      if (!mounted) return;
      final categoryObjects = cats.map((catMap) {
        print('DEBUG: Processing category: ${catMap['title']}');
        return ClassifiedCategory.fromJson(catMap);
      }).toList();
      print('DEBUG: Created ${categoryObjects.length} category objects');
      setState(() {
        _categories
          ..clear()
          ..addAll(categoryObjects);
        _loadingCategories = false;
      });
      print('DEBUG: Categories state updated, total: ${_categories.length}');
    } catch (e, stackTrace) {
      print('DEBUG: Error loading categories: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() { _loadingPosts = true; });
    final posts = await ApiService.fetchClassifiedPosts(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
      page: 1,
      pageSize: 12,
    );
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loadingPosts = false;
    });
  }

  void _onSearch(String q) {
    _searchQuery = q;
    _loadPosts();
  }

  void _onCategoryTap(ClassifiedCategory cat) {
    final id = cat.id.toString();
    setState(() {
      if (_selectedCategoryId == id) {
        _selectedCategoryId = null; // toggle off
      } else {
        _selectedCategoryId = id;
      }
    });
    _loadPosts();
    // TODO: Navigate to category detail screen (stub)
    // For now we just log
    // ignore: avoid_print
    print('Category tapped: $id');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 16),
          // Search bar (mobile first)
          ClassifiedSearchBar(
            onSearch: _onSearch,
            margin: EdgeInsets.only(left: isMobile ? 0 : 4, right: isMobile ? 0 : 4, bottom: 8),
          ),
          // Categories horizontal chips
          ClassifiedCategoriesGrid(
            categories: _categories,
            selectedId: _selectedCategoryId,
            onTap: _onCategoryTap,
            isLoading: _loadingCategories,
          ),
          const SizedBox(height: 8),
          // Always show ads scroll widget with fallback data
          AdsScrollWidget(
            ads: {
              'results': _posts.isNotEmpty ? _posts : _getMockAds()
            }, 
            sectionTitle: _translationService.t('recent_ads', fallback: 'Recent Ads'),
          ),
          _buildPostsArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF34D399)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        _translationService.t('classified_service', fallback: 'Classified Service'),
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 4,
                      width: isMobile ? 60 : 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF34D399)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isMobile) {
    final isLoading = _loadingButtons.contains('post-free-ad');
    
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white24,
          onTap: isLoading ? null : () => _handleButtonClick('post-free-ad'),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 22,
              vertical: isMobile ? 8 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                if (!isLoading) ...[
                  const SizedBox(width: 8),
                  Text(
                    _translationService.t('post_free_ad', fallback: 'Post Free Ad'),
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsArea(bool isMobile) {
    if (_loadingPosts) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade600),
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Simple list placeholder - can be upgraded later to card grid
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length.clamp(0, 6), // show up to 6 for initial mobile compact view
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final p = _posts[idx];
        final title = (p['title_bn'] ?? p['title_en'] ?? p['title'] ?? '---').toString();
        final price = p['price']?.toString();
        return Material(
          color: Colors.white,
          elevation: 0,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            // TODO: Navigate to post detail screen
            // ignore: avoid_print
            // For now log tap
            // You can implement Navigator.push(...) when detail page exists
            onLongPress: () { print('Post long pressed: '+ (p['id']?.toString() ?? '')); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FBF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_outlined, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (price != null) Text(
                          price,
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                (p['location'] ?? p['area'] ?? p['city'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(fontSize: 11.5, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Mock ads data for fallback when no posts are available
  List<Map<String, dynamic>> _getMockAds() {
    return [
      {
        'id': '1',
        'title': 'iPhone 13 Pro Max 256GB - Excellent Condition',
        'price': '95000',
        'image': 'https://placehold.co/300x200?text=iPhone',
        'upazila': 'Dhanmondi',
        'city': 'Dhaka',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=iPhone'}
        ],
      },
      {
        'id': '2',
        'title': 'Toyota Corolla 2020 - Low Mileage',
        'price': '2500000',
        'image': 'https://placehold.co/300x200?text=Toyota+Corolla',
        'upazila': 'Gulshan',
        'city': 'Dhaka',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Toyota+Corolla'}
        ],
      },
      {
        'id': '3',
        'title': '3 Bedroom Apartment for Rent',
        'price': '25000',
        'image': 'https://placehold.co/300x200?text=Apartment',
        'upazila': 'Uttara',
        'city': 'Dhaka',
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Apartment'}
        ],
      },
      {
        'id': '4',
        'title': 'Gaming Laptop RTX 3060 - Like New',
        'price': '85000',
        'image': 'https://placehold.co/300x200?text=Gaming+Laptop',
        'upazila': 'Mirpur',
        'city': 'Dhaka',
        'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Gaming+Laptop'}
        ],
      },
      {
        'id': '5',
        'title': 'Yamaha R15 V4 - 2023 Model',
        'price': '380000',
        'image': 'https://placehold.co/300x200?text=Yamaha+R15',
        'upazila': 'Banani',
        'city': 'Dhaka',
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Yamaha+R15'}
        ],
      },
    ];
  }
}