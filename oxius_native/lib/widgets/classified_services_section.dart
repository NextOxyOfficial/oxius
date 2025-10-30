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
  bool _isExpanded = false;
  static const int _initialCategoryCount = 16;

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
    // Navigate to post form screen
    Navigator.pushNamed(context, '/classified-post-form');
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
    setState(() {
      _searchQuery = q;
    });
    _loadPosts();
  }

  void _onCategoryTap(ClassifiedCategory cat) {
    // Navigate to the category detail screen
    Navigator.pushNamed(
      context,
      '/classified-category',
      arguments: {
        'categoryId': cat.id.toString(),
        'categorySlug': cat.slug ?? cat.id.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    // Determine which categories to show
    final categoriesToShow = _isExpanded 
        ? _categories 
        : _categories.take(_initialCategoryCount).toList();
    
    final hasMoreCategories = _categories.length > _initialCategoryCount;
    
    print('DEBUG BUILD: Total categories: ${_categories.length}, Showing: ${categoriesToShow.length}, Has more: $hasMoreCategories, Loading: $_loadingCategories, Expanded: $_isExpanded');
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 16,
        vertical: 4,
      ),
      child: Column(
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 12),
          // Search bar (mobile first)
          ClassifiedSearchBar(
            onSearch: _onSearch,
            margin: EdgeInsets.only(left: isMobile ? 0 : 4, right: isMobile ? 0 : 4, bottom: 8),
          ),
          // Categories horizontal chips (limited or all based on expanded state)
          ClassifiedCategoriesGrid(
            categories: categoriesToShow,
            selectedId: _selectedCategoryId,
            onTap: _onCategoryTap,
            isLoading: _loadingCategories,
          ),
          // See More / See Less button
          if (hasMoreCategories && !_loadingCategories)
            _buildSeeMoreButton(isMobile),
          const SizedBox(height: 4),
          // Show ads scroll widget with real data from backend
          if (_posts.isNotEmpty)
            AdsScrollWidget(
              ads: {
                'results': _posts
              }, 
              sectionTitle: _translationService.t('recent_ads', fallback: 'Recent Ads'),
            ),
          _buildPostsArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 8 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              _translationService.t('my_services', fallback: 'My Services'),
              style: GoogleFonts.roboto(
                fontSize: screenWidth * 0.048,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButton(isMobile),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton(bool isMobile) {
    final remainingCount = _categories.length - _initialCategoryCount;
    
    return Padding(
      padding: EdgeInsets.only(
        right: isMobile ? 16 : 24,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded
                      ? _translationService.t('see_less', fallback: 'See Less')
                      : '${_translationService.t('see_more', fallback: 'See More')} ($remainingCount)',
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded 
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isMobile) {
    final isLoading = _loadingButtons.contains('post-free-ad');
    
    return OutlinedButton.icon(
      onPressed: isLoading ? null : () => _handleButtonClick('post-free-ad'),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
              ),
            )
          : const Icon(
              Icons.add,
              size: 16,
            ),
      label: isLoading
          ? const SizedBox.shrink()
          : Text(
              _translationService.t('post_free_service', fallback: 'Post Free Service'),
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF06B6D4),
        side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
}