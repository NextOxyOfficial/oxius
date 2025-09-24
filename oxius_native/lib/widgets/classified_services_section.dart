import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';
import '../services/classified_category_service.dart';
import 'classified_search_bar.dart';
import 'classified_categories_grid.dart';

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
    if (_initialized) return;
    _initialized = true;
    await _loadCategories();
    // Optionally load initial posts (could be trending/latest)
    await _loadPosts();
  }

  Future<void> _loadCategories() async {
    setState(() { _loadingCategories = true; });
    final cats = await ApiService.fetchClassifiedCategories();
    if (!mounted) return;
    setState(() {
      _categories
        ..clear()
        ..addAll(cats.map((catMap) => ClassifiedCategory.fromJson(catMap)).toList());
      _loadingCategories = false;
    });
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
        horizontal: isMobile ? 12 : 16,
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
          _buildPostsArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title section with gradient text and underline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF14B8A6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      _translationService.t('classified_service', fallback: 'Classified Service'),
                      style: GoogleFonts.roboto(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Gradient underline
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  height: 4,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF14B8A6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Action button
          _buildActionButton(isMobile),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isMobile) {
    final isLoading = _loadingButtons.contains('post-free-ad');
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : () => _handleButtonClick('post-free-ad'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF059669),
                style: BorderStyle.solid,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon or loading spinner
                SizedBox(
                  width: isMobile ? 16 : 18,
                  height: isMobile ? 16 : 18,
                  child: isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF059669),
                          ),
                        )
                      : const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                ),
                
                if (!isLoading) ...[
                  const SizedBox(width: 8),
                  Text(
                    _translationService.t('post_free_ad', fallback: 'Post Free Ad'),
                    style: GoogleFonts.roboto(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
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

  Widget _buildPlaceholderContent(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _translationService.t('classified_services_coming_soon', 
                fallback: 'Classified services content coming soon'),
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      return _buildPlaceholderContent(isMobile);
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