import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/translation_service.dart';
import '../services/classified_category_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'classified_categories_grid.dart';

class ClassifiedSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String initialValue;
  final EdgeInsetsGeometry? margin;
  final ClassifiedCategoryService? categoryService;
  final void Function(ClassifiedCategory category)? onCategoryTap;
  final bool showCategories;

  const ClassifiedSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
    this.margin,
    this.categoryService,
    this.onCategoryTap,
    this.showCategories = true,
  });

  @override
  State<ClassifiedSearchBar> createState() => _ClassifiedSearchBarState();
}

class _ClassifiedSearchBarState extends State<ClassifiedSearchBar> {
  final TranslationService _ts = TranslationService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  String _lastQuery = '';
  List<ClassifiedCategory> _categories = [];
  bool _loadingCategories = false;
  
  // Search results dropdown
  OverlayEntry? _overlayEntry;
  bool _showDropdown = false;
  List<ClassifiedCategory> _filteredCategories = [];
  List<Map<String, dynamic>> _searchedPosts = [];
  bool _loadingSearchResults = false;
  
  // Pagination for services
  int _currentPostsPage = 1;
  bool _hasMorePosts = true;
  bool _isLoadingMorePosts = false;
  String _currentSearchQuery = '';
  final ScrollController _dropdownScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue;
    _lastQuery = widget.initialValue;
    _ts.addListener(_onLangChanged);
    if (widget.showCategories && widget.categoryService != null) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    _ts.removeListener(_onLangChanged);
    _controller.dispose();
    _dropdownScrollController.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    if (!mounted) return;
    setState(() {}); // refresh placeholder translation
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    
    // Show dropdown immediately when typing
    if (value.trim().isNotEmpty) {
      setState(() {
        _showDropdown = true;
        _loadingSearchResults = true; // Show loading immediately
      });
      _showOverlay();
    } else {
      setState(() => _showDropdown = false);
      _removeOverlay();
    }
    
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_lastQuery != value) {
        _lastQuery = value;
        if (value.trim().isNotEmpty) {
          _performSearch(value.trim());
        } else {
          setState(() {
            _filteredCategories = [];
            _searchedPosts = [];
            _loadingSearchResults = false;
          });
        }
        widget.onSearch(value.trim());
      }
      setState(() {}); // update clear icon state
    });
  }

  void _clear() {
    _controller.clear();
    _removeOverlay();
    setState(() {
      _showDropdown = false;
      _filteredCategories = [];
      _searchedPosts = [];
    });
    _onChanged('');
  }

  Future<void> _loadCategories() async {
    if (widget.categoryService == null) return;
    
    setState(() {
      _loadingCategories = true;
    });

    try {
      final categories = await widget.categoryService!.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }
  
  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    
    print('🔍 Performing search for: $query');
    
    // Reset pagination
    _currentPostsPage = 1;
    _hasMorePosts = true;
    _currentSearchQuery = query;
    
    try {
      // Search in categories using API (like Vue project)
      final categoriesData = await _searchCategories(query);
      final matchedCategories = categoriesData.take(3).toList();
      
      print('📁 Found ${matchedCategories.length} matching categories');
      
      // Search in posts using API with title parameter and pagination (page 1, 10 items)
      final postsData = await _searchPosts(query, page: 1);
      
      print('📄 Found ${postsData['results'].length} matching posts');
      
      if (mounted) {
        setState(() {
          _filteredCategories = matchedCategories;
          _searchedPosts = postsData['results'];
          _hasMorePosts = postsData['next'] != null;
          _loadingSearchResults = false;
        });
        // Rebuild overlay with new results
        _removeOverlay();
        _showOverlay();
      }
    } catch (e) {
      print('❌ Search error: $e');
      if (mounted) {
        setState(() {
          _loadingSearchResults = false;
          _filteredCategories = [];
          _searchedPosts = [];
          _hasMorePosts = false;
        });
        _removeOverlay();
        _showOverlay();
      }
    }
  }
  
  Future<List<ClassifiedCategory>> _searchCategories(String query) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/classified-categories/?title=${Uri.encodeComponent(query)}');
      print('🔎 Searching categories: $uri');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results;
        
        if (data is List) {
          results = data;
        } else if (data is Map && data['results'] != null) {
          results = data['results'];
        } else {
          results = [];
        }
        
        return results.map((json) => ClassifiedCategory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Category search error: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> _searchPosts(String query, {int page = 1}) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/classified-posts/?title=${Uri.encodeComponent(query)}&page=$page');
      print('🔎 Searching posts: $uri');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data['results'] != null) {
          // Paginated response
          return {
            'results': (data['results'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(),
            'next': data['next'],
            'count': data['count'],
          };
        } else if (data is List) {
          // Non-paginated response
          return {
            'results': data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(),
            'next': null,
            'count': data.length,
          };
        }
      }
      return {'results': [], 'next': null, 'count': 0};
    } catch (e) {
      print('❌ Posts search error: $e');
      return {'results': [], 'next': null, 'count': 0};
    }
  }
  
  void _showOverlay() {
    _removeOverlay();
    
    // Setup scroll listener for pagination
    _dropdownScrollController.addListener(_onDropdownScroll);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdown(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  void _removeOverlay() {
    _dropdownScrollController.removeListener(_onDropdownScroll);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  void _rebuildOverlay() {
    if (_showDropdown) {
      _removeOverlay();
      _showOverlay();
    }
  }
  
  void _onDropdownScroll() {
    if (_dropdownScrollController.position.pixels >= _dropdownScrollController.position.maxScrollExtent - 50) {
      // User scrolled near bottom, load more posts
      if (_hasMorePosts && !_isLoadingMorePosts && _currentSearchQuery.isNotEmpty) {
        _loadMorePosts();
      }
    }
  }
  
  Future<void> _loadMorePosts() async {
    if (_isLoadingMorePosts || !_hasMorePosts) return;
    
    setState(() {
      _isLoadingMorePosts = true;
    });
    _rebuildOverlay();
    
    try {
      final nextPage = _currentPostsPage + 1;
      print('📄 Loading more posts, page $nextPage');
      
      final postsData = await _searchPosts(_currentSearchQuery, page: nextPage);
      
      if (mounted) {
        setState(() {
          _searchedPosts.addAll(postsData['results']);
          _currentPostsPage = nextPage;
          _hasMorePosts = postsData['next'] != null;
          _isLoadingMorePosts = false;
        });
        _rebuildOverlay();
      }
    } catch (e) {
      print('❌ Load more error: $e');
      if (mounted) {
        setState(() {
          _isLoadingMorePosts = false;
        });
        _rebuildOverlay();
      }
    }
  }
  
  Widget _buildDropdown() {
    return Positioned(
      width: MediaQuery.of(context).size.width - 24,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 62),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withOpacity(0.08),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: _loadingSearchResults
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
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
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Categories',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._filteredCategories.map((cat) => _buildCategoryItem(cat)),
                        ],
                        if (_searchedPosts.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.fromLTRB(16, _filteredCategories.isEmpty ? 12 : 10, 16, 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Services',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                if (_searchedPosts.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_searchedPosts.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ..._searchedPosts.map((post) => _buildPostItem(post)),
                          if (_isLoadingMorePosts)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Loading more...',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!_hasMorePosts && _searchedPosts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                              ),
                              child: Center(
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
                                      'All results loaded',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                        if (_filteredCategories.isEmpty && _searchedPosts.isEmpty && !_loadingSearchResults)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                                    'No results found',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try different keywords',
                                    style: GoogleFonts.inter(
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
    );
  }
  
  Widget _buildCategoryItem(ClassifiedCategory category) {
    return InkWell(
      onTap: () {
        _removeOverlay();
        _focusNode.unfocus();
        setState(() => _showDropdown = false);
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
                  color: const Color(0xFF06B6D4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? Image.network(
                        category.image!.startsWith('http')
                            ? category.image!
                            : '${AppConfig.mediaBaseUrl}${category.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            category.getIconAsset(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.category_rounded,
                                size: 20,
                                color: Color(0xFF06B6D4),
                              );
                            },
                          );
                        },
                      )
                    : Image.asset(
                        category.getIconAsset(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.category_rounded,
                            size: 20,
                            color: Color(0xFF06B6D4),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.title,
                style: GoogleFonts.inter(
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
  
  Widget _buildPostItem(Map<String, dynamic> post) {
    return InkWell(
      onTap: () {
        _removeOverlay();
        _focusNode.unfocus();
        setState(() => _showDropdown = false);
        // Navigate to classified post detail
        Navigator.pushNamed(
          context,
          '/classified-post-details',
          arguments: post['id'],
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
                  color: const Color(0xFF10B981).withOpacity(0.08),
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
                    post['title'] ?? '',
                    style: GoogleFonts.inter(
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
                      post['category_name'],
                      style: GoogleFonts.inter(
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
    // Try to get image from various possible fields
    String? imageUrl;
    
    // Check for image in different formats
    if (post['image'] != null && post['image'].toString().isNotEmpty) {
      imageUrl = post['image'].toString();
    } else if (post['images'] != null && post['images'] is List && (post['images'] as List).isNotEmpty) {
      imageUrl = (post['images'] as List).first.toString();
    } else if (post['featured_image'] != null && post['featured_image'].toString().isNotEmpty) {
      imageUrl = post['featured_image'].toString();
    }
    
    // If we have an image URL, display it
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Convert to absolute URL if needed
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${AppConfig.mediaBaseUrl}$imageUrl';
      }
      
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.work_outline_rounded,
            size: 20,
            color: Color(0xFF10B981),
          );
        },
      );
    }
    
    // Fallback to icon
    return const Icon(
      Icons.work_outline_rounded,
      size: 20,
      color: Color(0xFF10B981),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final placeholder = _ts.t('classified_search_placeholder', fallback: 'Search services, categories...');
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompositedTransformTarget(
            link: _layerLink,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
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
                    color: Colors.grey.shade600,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: _clear,
                        tooltip: 'Clear',
                      )
                    : null,
                hintText: placeholder,
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            ),
          ),
          if (widget.showCategories && widget.categoryService != null) ...[
            const SizedBox(height: 12),
            ClassifiedCategoriesGrid(
              categories: _categories,
              isLoading: _loadingCategories,
              onTap: widget.onCategoryTap,
            ),
          ]
        ],
      ),
    );
  }
}
