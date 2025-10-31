import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import '../services/classified_category_service.dart';
import '../config/app_config.dart';
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
        horizontal: isMobile ? 4 : 12,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 16),
          // Search bar (mobile first)
          ClassifiedSearchBar(
            onSearch: _onSearch,
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          // Show ads scroll widget with real data from backend
          if (_posts.isNotEmpty) ...[
            AdsScrollWidget(
              ads: {
                'results': _posts
              }, 
              sectionTitle: _translationService.t('recent_ads', fallback: 'Recent Ads'),
            ),
            const SizedBox(height: 12),
          ],
          _buildPostsArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translationService.t('my_services', fallback: 'My Services'),
                  style: GoogleFonts.roboto(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse and post services',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded 
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: const Color(0xFF06B6D4),
            ),
            label: Text(
              _isExpanded
                  ? _translationService.t('see_less', fallback: 'See Less')
                  : '${_translationService.t('see_more', fallback: 'See More')} ($remainingCount)',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF06B6D4),
              side: BorderSide(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isMobile) {
    final isLoading = _loadingButtons.contains('post-free-ad');
    
    return GestureDetector(
      onTap: isLoading ? null : () => _handleButtonClick('post-free-ad'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF10B981)),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Post Free Service',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF10B981),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPostsArea(bool isMobile) {
    if (_loadingPosts) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading services...',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _posts.length.clamp(0, 6),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, idx) {
          final p = _posts[idx];
          final title = (p['title_bn'] ?? p['title_en'] ?? p['title'] ?? '---').toString();
          final price = p['price']?.toString();
          final imageUrl = _getImageUrl(p);
          
          return Material(
            color: Colors.white,
            elevation: 0,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Navigate to post detail
                Navigator.pushNamed(
                  context,
                  '/classified-post-details',
                  arguments: p['id'],
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade100,
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFE6FBF4),
                                    child: const Icon(
                                      Icons.image_outlined,
                                      color: Color(0xFF10B981),
                                      size: 28,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFFE6FBF4),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF10B981),
                                  size: 28,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (price != null && price.isNotEmpty)
                            Text(
                              price,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (p['location'] ?? p['area'] ?? p['city'] ?? 'Not specified').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  String? _getImageUrl(Map<String, dynamic> post) {
    String? imageUrl;
    
    if (post['image'] != null && post['image'].toString().isNotEmpty) {
      imageUrl = post['image'].toString();
    } else if (post['images'] != null && post['images'] is List && (post['images'] as List).isNotEmpty) {
      imageUrl = (post['images'] as List).first.toString();
    } else if (post['featured_image'] != null && post['featured_image'].toString().isNotEmpty) {
      imageUrl = post['featured_image'].toString();
    }
    
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${AppConfig.mediaBaseUrl}$imageUrl';
    }
    
    return imageUrl;
  }
}