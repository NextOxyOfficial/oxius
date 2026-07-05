import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oxius_native/utils/app_fonts.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/classified_category_service.dart';
import '../services/translation_service.dart';
import 'classified_categories_grid.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class ClassifiedSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String initialValue;
  final EdgeInsetsGeometry? margin;
  final ClassifiedCategoryService? categoryService;
  final void Function(ClassifiedCategory category)? onCategoryTap;
  final bool showCategories;
  final bool embedded;

  const ClassifiedSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
    this.margin,
    this.categoryService,
    this.onCategoryTap,
    this.showCategories = true,
    this.embedded = false,
  });

  @override
  State<ClassifiedSearchBar> createState() => _ClassifiedSearchBarState();
}

class _ClassifiedSearchBarState extends State<ClassifiedSearchBar> {
  final TranslationService _ts = TranslationService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ScrollController _dropdownScrollController = ScrollController();
  final Object _tapRegionGroupId = Object();

  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  String _lastQuery = '';
  String _currentSearchQuery = '';
  bool _showDropdown = false;
  bool _loadingSearchResults = false;
  bool _loadingCategories = false;
  bool _isLoadingMorePosts = false;
  bool _hasMorePosts = true;
  int _currentPostsPage = 1;

  List<ClassifiedCategory> _categories = [];
  List<ClassifiedCategory> _filteredCategories = [];
  List<Map<String, dynamic>> _searchedPosts = [];

  // Animated "typing" placeholder suggestions.
  static const List<String> _hintSuggestions = [
    'সেলুন ও বিউটি সার্ভিস',
    'এসি ও ফ্রিজ সার্ভিসিং',
    'ইলেকট্রিক কাজ',
    'ঘর পরিষ্কার সার্ভিস',
    'গাড়ি মেরামত',
    'প্লাম্বিং সার্ভিস',
    'ওয়েব ডেভেলপমেন্ট',
    'রিয়েল এস্টেট এজেন্ট',
  ];
  Timer? _hintTimer;
  int _hintPhraseIndex = 0;
  int _hintCharIndex = 0;
  bool _hintDeleting = false;
  String _animatedHint = '';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _lastQuery = widget.initialValue;
    _ts.addListener(_onLangChanged);
    _focusNode.addListener(_onFocusChanged);
    _tickHint();

    if (widget.showCategories && widget.categoryService != null) {
      _loadCategories();
    }
  }

  void _tickHint() {
    if (!mounted) return;
    final phrase = _hintSuggestions[_hintPhraseIndex];
    final total = phrase.characters.length;
    int delay = 85;
    if (!_hintDeleting) {
      _hintCharIndex++;
      if (_hintCharIndex >= total) {
        _hintCharIndex = total;
        _hintDeleting = true;
        delay = 1500; // hold on the full phrase
      }
    } else {
      _hintCharIndex--;
      if (_hintCharIndex <= 0) {
        _hintCharIndex = 0;
        _hintDeleting = false;
        _hintPhraseIndex = (_hintPhraseIndex + 1) % _hintSuggestions.length;
        delay = 400;
      } else {
        delay = 40;
      }
    }
    setState(() {
      _animatedHint = phrase.characters.take(_hintCharIndex).toString();
    });
    _hintTimer = Timer(Duration(milliseconds: delay), _tickHint);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hintTimer?.cancel();
    _removeOverlay();
    _ts.removeListener(_onLangChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    _dropdownScrollController.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadCategories() async {
    if (widget.categoryService == null) return;

    setState(() {
      _loadingCategories = true;
    });

    try {
      final categories = await widget.categoryService!.fetchCategories();
      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        _showDropdown = true;
        _loadingSearchResults = true;
      });
      _showOverlay();
    } else {
      _clearSearchState(notifyParent: true);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_lastQuery == value) {
        if (mounted) setState(() {});
        return;
      }

      _lastQuery = value;
      if (trimmed.isEmpty) {
        _clearSearchState(notifyParent: true);
      } else {
        widget.onSearch(trimmed);
        _performSearch(trimmed);
      }

      if (mounted) setState(() {});
    });
  }

  void _clear() {
    _controller.clear();
    _clearSearchState(notifyParent: true);
  }

  void _clearSearchState({required bool notifyParent}) {
    _removeOverlay();

    if (mounted) {
      setState(() {
        _showDropdown = false;
        _loadingSearchResults = false;
        _filteredCategories = [];
        _searchedPosts = [];
        _currentSearchQuery = '';
        _hasMorePosts = true;
        _currentPostsPage = 1;
        _isLoadingMorePosts = false;
      });
    }

    if (notifyParent) {
      widget.onSearch('');
    }
  }

  void _dismissDropdown({bool unfocus = true}) {
    _removeOverlay();
    if (!mounted) return;

    setState(() {
      _showDropdown = false;
      _loadingSearchResults = false;
    });

    if (unfocus) {
      _focusNode.unfocus();
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    _currentPostsPage = 1;
    _hasMorePosts = true;
    _currentSearchQuery = query;

    try {
      final categoriesData = await _searchCategories(query);
      final postsData = await _searchPosts(query, page: 1);
      if (!mounted) return;

      setState(() {
        _filteredCategories = categoriesData.take(3).toList();
        _searchedPosts = postsData['results'] as List<Map<String, dynamic>>;
        _hasMorePosts = postsData['next'] != null;
        _loadingSearchResults = false;
      });
      _rebuildOverlay();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _filteredCategories = [];
        _searchedPosts = [];
        _hasMorePosts = false;
        _loadingSearchResults = false;
      });
      _rebuildOverlay();
    }
  }

  Future<List<ClassifiedCategory>> _searchCategories(String query) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/classified-categories/?title=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);
      final results = data is List
          ? data
          : (data is Map && data['results'] is List
              ? data['results'] as List
              : <dynamic>[]);

      return results
          .whereType<Map>()
          .map((json) =>
              ClassifiedCategory.fromJson(json.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _searchPosts(String query,
      {int page = 1}) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/classified-posts/?title=${Uri.encodeComponent(query)}&page=$page',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return {'results': <Map<String, dynamic>>[], 'next': null, 'count': 0};
      }

      final data = json.decode(response.body);
      if (data is Map && data['results'] is List) {
        return {
          'results': (data['results'] as List)
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(),
          'next': data['next'],
          'count': data['count'],
        };
      }

      if (data is List) {
        final results = data
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        return {'results': results, 'next': null, 'count': results.length};
      }
    } catch (_) {
      // Ignore and fall through to empty response.
    }

    return {'results': <Map<String, dynamic>>[], 'next': null, 'count': 0};
  }

  void _showOverlay() {
    _removeOverlay();
    _dropdownScrollController.addListener(_onDropdownScroll);
    _overlayEntry = OverlayEntry(builder: (_) => _buildDropdown());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _dropdownScrollController.removeListener(_onDropdownScroll);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _rebuildOverlay() {
    if (!_showDropdown) return;
    _showOverlay();
  }

  void _onDropdownScroll() {
    if (!_dropdownScrollController.hasClients) return;

    final position = _dropdownScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 50) {
      if (_hasMorePosts &&
          !_isLoadingMorePosts &&
          _currentSearchQuery.isNotEmpty) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMorePosts || !_hasMorePosts || _currentSearchQuery.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingMorePosts = true;
    });
    _rebuildOverlay();

    try {
      final nextPage = _currentPostsPage + 1;
      final postsData = await _searchPosts(_currentSearchQuery, page: nextPage);
      if (!mounted) return;

      setState(() {
        _searchedPosts
            .addAll(postsData['results'] as List<Map<String, dynamic>>);
        _currentPostsPage = nextPage;
        _hasMorePosts = postsData['next'] != null;
        _isLoadingMorePosts = false;
      });
      _rebuildOverlay();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMorePosts = false;
      });
      _rebuildOverlay();
    }
  }

  Widget _buildDropdown() {
    final categoriesLabel =
        _ts.t('search_results_categories', fallback: 'Categories');
    final servicesLabel =
        _ts.t('search_results_services', fallback: 'Services');
    final loadingMoreLabel =
        _ts.t('classified_loading_more', fallback: 'Loading more...');
    final allResultsLoadedLabel = _ts.t(
      'classified_all_results_loaded',
      fallback: 'All results loaded',
    );
    final noResultsLabel =
        _ts.t('classified_no_results_found', fallback: 'No results found');
    final tryDifferentKeywordsLabel = _ts.t(
      'classified_try_different_keywords',
      fallback: 'Try different keywords',
    );

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 62),
      child: TapRegion(
        groupId: _tapRegionGroupId,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 24,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(18),
            shadowColor: Colors.black.withValues(alpha: 0.12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: _loadingSearchResults
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: AdsyLoadingIndicator(
                          color: Color(0xFF06B6D4),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _dropdownScrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_filteredCategories.isNotEmpty) ...[
                            _buildSectionHeader(
                              icon: Icons.folder_outlined,
                              label: categoriesLabel,
                            ),
                            ..._filteredCategories.map(_buildCategoryItem),
                          ],
                          if (_searchedPosts.isNotEmpty) ...[
                            _buildSectionHeader(
                              icon: Icons.work_outline_rounded,
                              label: servicesLabel,
                              topPadding: _filteredCategories.isEmpty ? 12 : 10,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_searchedPosts.length}',
                                  style: AppFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ),
                            ..._searchedPosts.map(_buildPostItem),
                            if (_isLoadingMorePosts)
                              _buildFooterState(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: AdsyLoadingIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      loadingMoreLabel,
                                      style: AppFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!_hasMorePosts && _searchedPosts.isNotEmpty)
                              _buildFooterState(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      allResultsLoadedLabel,
                                      style: AppFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          if (_filteredCategories.isEmpty &&
                              _searchedPosts.isEmpty &&
                              !_loadingSearchResults)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 32, horizontal: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.search_off_rounded,
                                        size: 32,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      noResultsLabel,
                                      style: AppFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tryDifferentKeywordsLabel,
                                      style: AppFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    Widget? trailing,
    double topPadding = 12,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildFooterState({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: Center(child: child),
    );
  }

  Widget _buildCategoryItem(ClassifiedCategory category) {
    return InkWell(
      onTap: () {
        _dismissDropdown();
        Navigator.pushNamed(
          context,
          '/classified-category',
          arguments: {
            'categoryId': category.id,
            'categoryTitle': category.title,
          },
        );

        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(category);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? Image.network(
                        category.image!.startsWith('http')
                            ? category.image!
                            : '${AppConfig.mediaBaseUrl}${category.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildCategoryFallbackIcon(),
                      )
                    : Image.asset(
                        category.getIconAsset(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildCategoryFallbackIcon(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.title,
                style: AppFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFallbackIcon() {
    return const Icon(
      Icons.category_rounded,
      size: 20,
      color: Color(0xFF06B6D4),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    return InkWell(
      onTap: () {
        _dismissDropdown();
        Navigator.pushNamed(
          context,
          '/classified-post-details',
          arguments: {
            'postId': post['id']?.toString() ?? '',
            'postSlug': post['slug']?.toString() ?? '',
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildServiceImage(post),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['title']?.toString() ?? '',
                    style: AppFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post['category_name'] != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      post['category_name'].toString(),
                      style: AppFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceImage(Map<String, dynamic> post) {
    String? imageUrl;
    if (post['image'] != null && post['image'].toString().isNotEmpty) {
      imageUrl = post['image'].toString();
    } else if (post['images'] is List && (post['images'] as List).isNotEmpty) {
      imageUrl = (post['images'] as List).first.toString();
    } else if (post['featured_image'] != null &&
        post['featured_image'].toString().isNotEmpty) {
      imageUrl = post['featured_image'].toString();
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final resolvedUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${AppConfig.mediaBaseUrl}$imageUrl';
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.work_outline_rounded,
          size: 20,
          color: Color(0xFF10B981),
        ),
      );
    }

    return const Icon(
      Icons.work_outline_rounded,
      size: 20,
      color: Color(0xFF10B981),
    );
  }

  // ── Bottom-sheet search (used by the embedded "My Services" bar) ──
  Future<void> _openSearchSheet() async {
    _removeOverlay();
    final sheetController = TextEditingController(text: _controller.text);
    Timer? sheetDebounce;
    List<ClassifiedCategory> cats = [];
    List<Map<String, dynamic>> posts = [];
    bool loading = false;
    String query = sheetController.text.trim();

    void go(BuildContext ctx, String route, Map<String, dynamic> args) {
      Navigator.pop(ctx);
      Navigator.pushNamed(context, route, arguments: args);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> runSearch(String value) async {
              final trimmed = value.trim();
              query = trimmed;
              if (trimmed.isEmpty) {
                setSheet(() {
                  cats = [];
                  posts = [];
                  loading = false;
                });
                return;
              }
              setSheet(() => loading = true);
              final c = await _searchCategories(trimmed);
              final p = await _searchPosts(trimmed, page: 1);
              if (!sheetCtx.mounted) return;
              setSheet(() {
                cats = c.take(6).toList();
                posts = (p['results'] as List).cast<Map<String, dynamic>>();
                loading = false;
              });
            }

            void onChanged(String v) {
              sheetDebounce?.cancel();
              setSheet(() => query = v.trim());
              sheetDebounce =
                  Timer(const Duration(milliseconds: 350), () => runSearch(v));
            }

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: 0.92,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: TextField(
                          controller: sheetController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: onChanged,
                          onSubmitted: runSearch,
                          style: AppFonts.inter(
                              fontSize: 15, color: const Color(0xFF111827)),
                          decoration: InputDecoration(
                            hintText: _ts.t('classified_search_placeholder',
                                fallback: 'সেবা বা ক্যাটাগরি খুঁজুন...'),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: Color(0xFF06B6D4)),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 20),
                                    onPressed: () {
                                      sheetController.clear();
                                      onChanged('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF06B6D4), width: 1.4),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: loading
                            ? const Center(
                                child: AdsyLoadingIndicator(
                                    color: Color(0xFF06B6D4)))
                            : query.isEmpty
                                ? _sheetSuggestions((s) {
                                    sheetController.text = s;
                                    onChanged(s);
                                    runSearch(s);
                                  })
                                : (cats.isEmpty && posts.isEmpty)
                                    ? _sheetEmpty()
                                    : ListView(
                                        controller: scrollController,
                                        padding: const EdgeInsets.only(bottom: 24),
                                        children: [
                                          if (cats.isNotEmpty) ...[
                                            _sheetSectionLabel(_ts.t(
                                                'categories',
                                                fallback: 'ক্যাটাগরি')),
                                            ...cats.map((c) => ListTile(
                                                  leading: const Icon(
                                                      Icons.category_rounded,
                                                      color: Color(0xFF06B6D4)),
                                                  title: Text(c.title,
                                                      style: AppFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  trailing: const Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
                                                      size: 12),
                                                  onTap: () => go(
                                                      sheetCtx,
                                                      '/classified-category',
                                                      {
                                                        'categoryId': c.id,
                                                        'categoryTitle': c.title,
                                                      }),
                                                )),
                                          ],
                                          if (posts.isNotEmpty) ...[
                                            _sheetSectionLabel(_ts.t('posts',
                                                fallback: 'পোস্ট')),
                                            ...posts.map((p) => ListTile(
                                                  leading: const Icon(
                                                      Icons
                                                          .article_outlined,
                                                      color: Color(0xFF10B981)),
                                                  title: Text(
                                                      p['title']?.toString() ??
                                                          '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  subtitle: p['category_name'] !=
                                                          null
                                                      ? Text(
                                                          p['category_name']
                                                              .toString(),
                                                          style: AppFonts.inter(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey.shade600))
                                                      : null,
                                                  onTap: () => go(
                                                      sheetCtx,
                                                      '/classified-post-details',
                                                      {
                                                        'postId': p['id']
                                                                ?.toString() ??
                                                            '',
                                                        'postSlug': p['slug']
                                                                ?.toString() ??
                                                            '',
                                                      }),
                                                )),
                                          ],
                                        ],
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    sheetDebounce?.cancel();
    sheetController.dispose();
  }

  Widget _sheetSectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text,
            style: AppFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B))),
      );

  Widget _sheetSuggestions(ValueChanged<String> onPick) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _sheetSectionLabel(_ts.t('popular_searches', fallback: 'জনপ্রিয় খোঁজ')),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hintSuggestions
              .map((s) => ActionChip(
                    label: Text(s,
                        style: AppFonts.inter(
                            fontSize: 12.5, color: const Color(0xFF0F766E))),
                    backgroundColor: const Color(0xFFECFEFF),
                    side: const BorderSide(color: Color(0xFFA5F3FC)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                    onPressed: () => onPick(s),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _sheetEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(_ts.t('no_results', fallback: 'কিছু পাওয়া যায়নি'),
              style: AppFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final placeholder = _ts.t(
      'classified_search_placeholder',
      fallback: 'Search services, categories...',
    );
    final clearLabel = _ts.t('clear_search', fallback: 'Clear');
    final hasQuery = _controller.text.trim().isNotEmpty;
    final highlightBorder = _focusNode.hasFocus || hasQuery;
    final searchContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highlightBorder
                    ? const Color(0xFF06B6D4)
                    : Colors.grey.shade300,
                width: highlightBorder ? 1.2 : 1,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.embedded ? null : _onChanged,
              readOnly: widget.embedded,
              onTap: widget.embedded ? _openSearchSheet : null,
              textInputAction: TextInputAction.search,
              style: AppFonts.inter(
                fontSize: isMobile ? 15 : 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 14 : 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: highlightBorder
                        ? const Color(0xFF06B6D4)
                        : Colors.grey.shade600,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: _loadingSearchResults && hasQuery
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: AdsyLoadingIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                      )
                    : hasQuery
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: _clear,
                            tooltip: clearLabel,
                          )
                        : null,
                hintText: hasQuery
                    ? placeholder
                    : (_animatedHint.isEmpty ? placeholder : '$_animatedHint|'),
                hintStyle: AppFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (hasQuery) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _clear,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: const Color(0xFF0F766E),
                backgroundColor: Colors.white.withValues(alpha: 0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(
                clearLabel,
                style: AppFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      margin:
          widget.margin ?? EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: TapRegion(
        groupId: _tapRegionGroupId,
        onTapOutside: (_) => _dismissDropdown(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded)
              searchContent
            else
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFF0FDFA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: highlightBorder
                        ? const Color(0xFF99F6E4)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: searchContent,
              ),
            if (widget.showCategories && widget.categoryService != null) ...[
              const SizedBox(height: 12),
              ClassifiedCategoriesGrid(
                categories: _categories,
                isLoading: _loadingCategories,
                onTap: widget.onCategoryTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
