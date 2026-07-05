import 'package:flutter/material.dart';
import 'package:oxius_native/theme/app_text.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import '../services/classified_category_service.dart';
import '../config/app_config.dart';
import 'classified_search_bar.dart';
import 'classified_categories_grid.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class ClassifiedServicesSection extends StatefulWidget {
  const ClassifiedServicesSection({super.key});

  @override
  State<ClassifiedServicesSection> createState() =>
      _ClassifiedServicesSectionState();
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
    if (_initialized) return;
    _initialized = true;
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final cats = await ApiService.fetchClassifiedCategories();
      if (!mounted) return;
      final categoryObjects =
          cats.map((catMap) => ClassifiedCategory.fromJson(catMap)).toList();

      // Sort categories: featured first, then by update time
      categoryObjects.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return 0;
      });

      setState(() {
        _categories
          ..clear()
          ..addAll(categoryObjects);
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loadingPosts = true;
    });
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

    final hasMoreCategories = _categories.length > _initialCategoryCount;
    final visibleCategoryCount = hasMoreCategories && !_isExpanded
        ? _initialCategoryCount - 1
        : _categories.length;
    final categoriesToShow = _isExpanded
        ? _categories
        : _categories.take(visibleCategoryCount).toList();
    final remainingCount = (_categories.length - visibleCategoryCount)
        .clamp(0, _categories.length);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title gets a 6px effective screen inset (2 outer + 4 here)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildHeader(isMobile),
                ),
                const SizedBox(height: 10),
                ClassifiedSearchBar(
                  onSearch: _onSearch,
                  margin: EdgeInsets.zero,
                  embedded: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClassifiedCategoriesGrid(
            categories: categoriesToShow,
            selectedId: _selectedCategoryId,
            onTap: _onCategoryTap,
            isLoading: _loadingCategories,
            margin: const EdgeInsets.fromLTRB(2, 0, 2, 6),
            trailingTile: hasMoreCategories && !_loadingCategories
                ? _buildSeeMoreTile(
                    isMobile: isMobile,
                    remainingCount: remainingCount,
                  )
                : null,
          ),
          SizedBox(height: isMobile ? 10 : 12),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title =
        _translationService.t('classified_service', fallback: 'My Services');
    final subtitle = _translationService.t(
      'my_services_subtitle',
      fallback: 'Browse and post services',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plain icon next to the title (no background box) — clean app look.
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 8),
          child: Icon(
            Icons.design_services_outlined,
            size: isMobile ? 22 : 24,
            color: const Color(0xFF0891B2),
          ),
        ),
        Expanded(
          child: _buildHeaderContent(title, subtitle, isMobile),
        ),
        const SizedBox(width: 12),
        _buildActionButton(isMobile),
      ],
    );
  }

  Widget _buildHeaderContent(String title, String subtitle, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/classified'),
          child: Text(
            title,
            style: AppText.sectionTitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: AppText.sectionSubtitle(),
        ),
      ],
    );
  }

  Widget _buildSeeMoreTile({
    required bool isMobile,
    required int remainingCount,
  }) {
    final isSeeLess = _isExpanded;
    final compact = MediaQuery.of(context).size.width < 390;
    final label = isSeeLess
        ? _translationService.t('see_less', fallback: 'See Less')
        : '${_translationService.t('see_more', fallback: 'See More')} ($remainingCount)';

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 2 : 4, 6, compact ? 2 : 4, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: compact ? 50 : 56,
              height: compact ? 50 : 56,
              decoration: BoxDecoration(
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF67E8F9)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isSeeLess
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: compact ? 26 : 30,
                color: const Color(0xFF0891B2),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: compact ? 32 : 34,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.tileLabel(color: const Color(0xFF0891B2)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isMobile) {
    final isLoading = _loadingButtons.contains('post-free-ad');

    return GestureDetector(
      onTap: isLoading ? null : () => _handleButtonClick('post-free-ad'),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 10 : 11,
          horizontal: isMobile ? 6 : 8,
        ),
        color: Colors.transparent,
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: AdsyLoadingIndicator(
                  strokeWidth: 2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 17,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _translationService.t('post_free_ad',
                        fallback: 'Post Free Service'),
                    style: AppText.linkText(color: const Color(0xFF059669)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPostsArea(bool isMobile) {
    if (_loadingPosts) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const AdsyLoadingIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
              const SizedBox(height: 12),
              Text(
                _translationService.t(
                  'loading_services',
                  fallback: 'Loading services...',
                ),
                style: AppText.bodyText(),
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
          final title = (p['title_bn'] ?? p['title_en'] ?? p['title'] ?? '---')
              .toString();
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
                  arguments: {
                    'postId': p['id']?.toString() ?? '',
                    'postSlug': p['slug']?.toString() ?? '',
                  },
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
                            style: AppText.cardTitle(),
                          ),
                          const SizedBox(height: 6),
                          if (price != null && price.isNotEmpty)
                            Text(
                              price,
                              style: AppText.price(),
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
                                  (p['location'] ??
                                          p['area'] ??
                                          p['city'] ??
                                          'Not specified')
                                      .toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.cardSubtitle(),
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
    } else if (post['images'] != null &&
        post['images'] is List &&
        (post['images'] as List).isNotEmpty) {
      imageUrl = (post['images'] as List).first.toString();
    } else if (post['featured_image'] != null &&
        post['featured_image'].toString().isNotEmpty) {
      imageUrl = post['featured_image'].toString();
    }

    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${AppConfig.mediaBaseUrl}$imageUrl';
    }

    return imageUrl;
  }
}

/// Full-screen page that wraps ClassifiedServicesSection inside a Scaffold.
/// Accessible via the `/classified` route.
class ClassifiedServicesPage extends StatelessWidget {
  const ClassifiedServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF155E75)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'আমার সেবা',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF155E75),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFCCFBF1)),
        ),
      ),
      body: const SingleChildScrollView(
        child: ClassifiedServicesSection(),
      ),
    );
  }
}
