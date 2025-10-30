import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/translation_service.dart';
import '../services/classified_category_service.dart';
import '../services/api_service.dart';
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
    
    try {
      // Search in categories using API (like Vue project)
      final categoriesData = await _searchCategories(query);
      final matchedCategories = categoriesData.take(3).toList();
      
      print('📁 Found ${matchedCategories.length} matching categories');
      
      // Search in posts using API with title parameter (like Vue project)
      final posts = await _searchPosts(query);
      
      print('📄 Found ${posts.length} matching posts');
      
      if (mounted) {
        setState(() {
          _filteredCategories = matchedCategories;
          _searchedPosts = posts;
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
  
  Future<List<Map<String, dynamic>>> _searchPosts(String query) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/classified-posts/?title=${Uri.encodeComponent(query)}');
      print('🔎 Searching posts: $uri');
      
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
        
        return results.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
      return [];
    } catch (e) {
      print('❌ Posts search error: $e');
      return [];
    }
  }
  
  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdown(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  void _rebuildOverlay() {
    if (_showDropdown) {
      _removeOverlay();
      _showOverlay();
    }
  }
  
  Widget _buildDropdown() {
    return Positioned(
      width: MediaQuery.of(context).size.width - 32,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_filteredCategories.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Categories',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          ..._filteredCategories.map((cat) => _buildCategoryItem(cat)),
                        ],
                        if (_searchedPosts.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, _filteredCategories.isEmpty ? 16 : 8, 16, 8),
                            child: Text(
                              'Services',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          ..._searchedPosts.map((post) => _buildPostItem(post)),
                        ],
                        if (_filteredCategories.isEmpty && _searchedPosts.isEmpty && !_loadingSearchResults)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No results found',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category_rounded,
                size: 18,
                color: const Color(0xFF06B6D4),
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
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 18,
                color: Colors.grey.shade600,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post['category_name'] != null)
                    Text(
                      post['category_name'],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                  fontSize: isMobile ? 14 : 15,
                  height: 1.4,
                  color: const Color(0xFF111827),
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
                    color: Colors.grey.shade500,
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
                          color: Colors.grey.shade400,
                        ),
                        onPressed: _clear,
                        tooltip: 'Clear',
                      )
                    : null,
                hintText: placeholder,
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF06B6D4),
                    width: 2,
                  ),
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
