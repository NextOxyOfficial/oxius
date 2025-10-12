import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../models/sale_post.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import 'package:intl/intl.dart';

/// Sale Listing Screen - Browse sale posts with filters and search
class SaleListScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const SaleListScreen({
    Key? key,
    this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  late SalePostService _postService;
  final TranslationService _translationService = TranslationService();
  
  List<SalePost> _posts = [];
  List<SaleCategory> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  
  // Filters
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _searchQuery;
  String _sortBy = 'newest';
  String? _selectedCondition;
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedArea;
  
  // Location data
  List<String> _divisions = [];
  List<String> _districts = [];
  List<String> _areas = [];
  
  // Price range
  double? _minPrice;
  double? _maxPrice;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  // Recent listings
  List<SalePost> _recentListings = [];
  bool _isLoadingRecentListings = false;
  int _recentListingsPage = 1;
  int _recentListingsTotalCount = 0;
  bool _isLoadingMoreRecent = false;
  final ScrollController _recentScrollController = ScrollController();
  
  // Expanded categories in sidebar
  final Set<String> _expandedCategories = <String>{};
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    _postService = SalePostService(baseUrl: ApiService.baseUrl);
    _selectedCategoryId = widget.categoryId;
    // Removed scroll listener - using "See More" button instead
    _fetchCategories();
    _fetchDivisions();
    _fetchPosts();
    _fetchRecentListings();
    _recentScrollController.addListener(_onRecentScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _recentScrollController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer for 300ms debounce
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value.trim().isEmpty ? null : value.trim();
      });
      _fetchPosts(refresh: true);
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _postService.fetchCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchDivisions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/geo/divisions/'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _divisions = data.map((d) => d['name'].toString()).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching divisions: $e');
    }
  }

  Future<void> _fetchDistricts(String division) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/geo/districts/?division=$division'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _districts = data.map((d) => d['name'].toString()).toList();
            _selectedDistrict = null;
            _selectedArea = null;
            _areas = [];
          });
        }
      }
    } catch (e) {
      print('Error fetching districts: $e');
    }
  }

  Future<void> _fetchAreas(String district) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/geo/areas/?district=$district'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _areas = data.map((a) => a['name'].toString()).toList();
            _selectedArea = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching areas: $e');
    }
  }

  void _onRecentScroll() {
    if (_recentScrollController.position.pixels >= _recentScrollController.position.maxScrollExtent - 50) {
      if (!_isLoadingMoreRecent && _recentListings.length < _recentListingsTotalCount) {
        _loadMoreRecentListings();
      }
    }
  }

  Future<void> _fetchRecentListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _recentListingsPage = 1;
        _recentListings = [];
      });
    }
    
    setState(() => _isLoadingRecentListings = true);
    try {
      final response = await _postService.fetchPosts(
        sortBy: 'newest',
        page: _recentListingsPage,
        pageSize: 5,
      );
      if (mounted) {
        setState(() {
          _recentListings = response.results;
          _recentListingsTotalCount = response.count;
          _isLoadingRecentListings = false;
        });
      }
    } catch (e) {
      print('Error fetching recent listings: $e');
      if (mounted) {
        setState(() => _isLoadingRecentListings = false);
      }
    }
  }

  Future<void> _loadMoreRecentListings() async {
    if (_isLoadingMoreRecent) return;
    
    setState(() => _isLoadingMoreRecent = true);
    try {
      final nextPage = _recentListingsPage + 1;
      final response = await _postService.fetchPosts(
        sortBy: 'newest',
        page: nextPage,
        pageSize: 5,
      );
      if (mounted) {
        setState(() {
          _recentListingsPage = nextPage;
          _recentListings.addAll(response.results);
          _isLoadingMoreRecent = false;
        });
      }
    } catch (e) {
      print('Error loading more recent listings: $e');
      if (mounted) {
        setState(() => _isLoadingMoreRecent = false);
      }
    }
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _posts.clear();
      }
    });

    try {
      final response = await _postService.fetchPosts(
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
        title: _searchQuery,
        sortBy: _sortBy,
        condition: _selectedCondition,
        division: _selectedDivision,
        district: _selectedDistrict,
        area: _selectedArea,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        page: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _posts = response.results;
          } else {
            _posts.addAll(response.results);
          }
          _totalCount = response.count;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchPosts();

    setState(() => _isLoadingMore = false);
  }

  void _applyFilters() {
    _fetchPosts(refresh: true);
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##,###');
    return '৳${formatter.format(price)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatLocation(SalePost post) {
    if (post.division != null && post.district != null && post.area != null) {
      return '${post.division}, ${post.district}, ${post.area}';
    } else if (post.division != null && post.district != null) {
      return '${post.division}, ${post.district}';
    } else if (post.division != null) {
      return post.division!;
    }
    return 'All Over Bangladesh';
  }

  bool _hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedSubcategoryId != null ||
        _selectedDivision != null ||
        _selectedDistrict != null ||
        _selectedArea != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _selectedCondition != null ||
        _searchQuery != null;
  }

  String? _getCategoryName(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Sale Products'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/my-sale-posts');
            },
            tooltip: 'My Posts',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      drawer: _buildSidebarDrawer(),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Results Count & Sort
          _buildResultsBar(),
          
          // Posts Grid with additional sections
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: _scrollController,
                    children: [
                      // Active Filters
                      if (_hasActiveFilters()) _buildActiveFilters(),
                      
                      // Posts Grid
                      if (_posts.isEmpty)
                        _buildEmptyState()
                      else
                        _buildPostsGridSection(),
                      
                      // Recent Listings
                      if (_recentListings.isNotEmpty) _buildRecentListings(),
                      
                      // Tips and Safety
                      _buildTipsAndSafety(),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create post
          Navigator.pushNamed(context, '/my-sale-posts', arguments: {'tab': 'post-sale'});
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Post Ad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 22),
          suffixIcon: _searchQuery != null
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = null);
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: (value) {
          setState(() => _searchQuery = value.isEmpty ? null : value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildResultsBar() {
    final hasLocationFilter = _selectedDivision != null || _selectedDistrict != null || _selectedArea != null;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '$_totalCount Products',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasLocationFilter) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 12, color: const Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              _selectedArea ?? _selectedDistrict ?? _selectedDivision ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDivision = null;
                                  _selectedDistrict = null;
                                  _selectedArea = null;
                                  _districts = [];
                                  _areas = [];
                                });
                                _applyFilters();
                              },
                              child: const Icon(Icons.close, size: 14, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: PopupMenuButton<String>(
                initialValue: _sortBy,
                offset: const Offset(0, 40),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Sort',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade600),
                  ],
                ),
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _applyFilters();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'newest',
                    child: Text('Newest First', style: TextStyle(fontSize: 14)),
                  ),
                  const PopupMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low to High', style: TextStyle(fontSize: 14)),
                  ),
                  const PopupMenuItem(
                    value: 'price_high',
                    child: Text('Price: High to Low', style: TextStyle(fontSize: 14)),
                  ),
                  const PopupMenuItem(
                    value: 'most_viewed',
                    child: Text('Most Viewed', style: TextStyle(fontSize: 14)),
                  ),
                ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGridSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _selectedCategoryId != null 
                  ? '${_getCategoryName(_selectedCategoryId)} Listings'
                  : 'Browse All Listings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _posts.length,
            itemBuilder: (context, index) => _buildPostCard(_posts[index]),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          // See More Button
          if (!_isLoadingMore && _posts.length < _totalCount)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TextButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more, size: 20),
                  label: Text(
                    'Load More',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
            ),
          // All Posts Loaded Message
          if (!_isLoadingMore && _posts.length >= _totalCount && _posts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All posts loaded!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You've seen all $_totalCount available listings",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(SalePost post) {
    final imageUrl = post.images != null && post.images!.isNotEmpty
        ? post.images![0].image
        : 'https://via.placeholder.com/300x200?text=No+Image';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/sale/detail',
          arguments: {'slug': post.slug, 'id': post.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade300, size: 35),
                    ),
                  ),
                ),
                // Condition Badge (if available)
                if (post.condition != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.condition!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Price and Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(post.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                            height: 1,
                          ),
                        ),
                      ),
                      if (post.createdAt != null)
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Location - Always show
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _formatLocation(post),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearchResult = _searchQuery != null && _searchQuery!.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchResult ? Icons.search_off : Icons.inventory_2_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearchResult ? 'No search results found' : 'No listings found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isSearchResult
                    ? 'No posts found matching "$_searchQuery". Try using different keywords or check the spelling.'
                    : _selectedCategoryId != null
                        ? 'No listings found in this category. Try selecting a different category or adjusting your filters.'
                        : 'No listings available at the moment. Check back later for new posts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            if (isSearchResult)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = null;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear search and browse all listings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = null;
                    _selectedCategoryId = null;
                    _selectedSubcategoryId = null;
                    _selectedCondition = null;
                    _selectedDivision = null;
                    _selectedDistrict = null;
                    _selectedArea = null;
                    _minPrice = null;
                    _maxPrice = null;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear Filters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Categories',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '$_totalCount Total Listings',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.apps, color: Color(0xFF10B981)),
                    title: const Text('All Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('$_totalCount', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    selected: _selectedCategoryId == null,
                    selectedColor: const Color(0xFF10B981),
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedSubcategoryId = null;
                      });
                      Navigator.pop(context);
                      _applyFilters();
                    },
                  ),
                  const Divider(height: 1),
                  ..._categories.map((category) {
                    final isExpanded = _expandedCategories.contains(category.id);
                    final isSelected = _selectedCategoryId == category.id;
                    
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.folder_outlined,
                            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade600,
                          ),
                          title: Text(
                            category.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade800,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (category.subcategories?.isNotEmpty ?? false)
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.grey.shade600,
                                ),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981),
                          onTap: () {
                            if (category.subcategories?.isNotEmpty ?? false) {
                              setState(() {
                                if (isExpanded) {
                                  _expandedCategories.remove(category.id);
                                } else {
                                  _expandedCategories.add(category.id);
                                }
                              });
                            } else {
                              setState(() {
                                _selectedCategoryId = category.id;
                                _selectedSubcategoryId = null;
                              });
                              Navigator.pop(context);
                              _applyFilters();
                            }
                          },
                        ),
                        if (isExpanded && (category.subcategories?.isNotEmpty ?? false))
                          ...(category.subcategories ?? []).map((sub) {
                            final isSubSelected = _selectedSubcategoryId == sub.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 72, right: 16),
                              title: Text(
                                sub.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSubSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
                                  fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              selected: isSubSelected,
                              selectedColor: const Color(0xFF10B981),
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                  _selectedSubcategoryId = sub.id;
                                });
                                Navigator.pop(context);
                                _applyFilters();
                              },
                            );
                          }).toList(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Filters:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = widget.categoryId;
                    _selectedSubcategoryId = null;
                    _selectedCondition = null;
                    _selectedDivision = null;
                    _selectedDistrict = null;
                    _selectedArea = null;
                    _minPrice = null;
                    _maxPrice = null;
                    _searchQuery = null;
                    _searchController.clear();
                    _minPriceController.clear();
                    _maxPriceController.clear();
                    _districts = [];
                    _areas = [];
                  });
                  _applyFilters();
                },
                child: const Text('Clear All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedCategoryId != null)
                _buildFilterChip(
                  'Category: ${_getCategoryName(_selectedCategoryId)}',
                  () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedSubcategoryId = null;
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedDivision != null)
                _buildFilterChip(
                  'Division: $_selectedDivision',
                  () {
                    setState(() {
                      _selectedDivision = null;
                      _selectedDistrict = null;
                      _selectedArea = null;
                      _districts = [];
                      _areas = [];
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedDistrict != null)
                _buildFilterChip(
                  'District: $_selectedDistrict',
                  () {
                    setState(() {
                      _selectedDistrict = null;
                      _selectedArea = null;
                      _areas = [];
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedArea != null)
                _buildFilterChip(
                  'Area: $_selectedArea',
                  () {
                    setState(() => _selectedArea = null);
                    _applyFilters();
                  },
                ),
              if (_minPrice != null || _maxPrice != null)
                _buildFilterChip(
                  'Price: ${_minPrice != null ? "৳${_minPrice!.toInt()}" : "Any"} - ${_maxPrice != null ? "৳${_maxPrice!.toInt()}" : "Any"}',
                  () {
                    setState(() {
                      _minPrice = null;
                      _maxPrice = null;
                      _minPriceController.clear();
                      _maxPriceController.clear();
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedCondition != null)
                _buildFilterChip(
                  'Condition: ${_selectedCondition!.replaceAll('_', ' ').toUpperCase()}',
                  () {
                    setState(() => _selectedCondition = null);
                    _applyFilters();
                  },
                ),
              if (_searchQuery != null)
                _buildFilterChip(
                  'Search: "$_searchQuery"',
                  () {
                    setState(() {
                      _searchQuery = null;
                      _searchController.clear();
                    });
                    _applyFilters();
                  },
                  color: const Color(0xFF10B981),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove, {Color color = const Color(0xFF6B7280)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentListings() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200, style: BorderStyle.solid, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Listings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.amber.shade700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: ListView.builder(
              controller: _recentScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _recentListings.length + (_isLoadingMoreRecent ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the end
                if (index == _recentListings.length) {
                  return Container(
                    width: 80,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                }
                
                final listing = _recentListings[index];
                final imageUrl = listing.images != null && listing.images!.isNotEmpty
                    ? listing.images![0].image
                    : 'https://via.placeholder.com/300x200?text=No+Image';

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/sale/detail',
                      arguments: {'slug': listing.slug, 'id': listing.id},
                    );
                  },
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              if (_getCategoryName(listing.categoryId) != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getCategoryName(listing.categoryId) ?? '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.amber.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                listing.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937), height: 1.2),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 10, color: Colors.grey.shade600),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      _formatLocation(listing),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _formatPrice(listing.price),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (listing.createdAt != null)
                                    Text(
                                      _formatDate(listing.createdAt),
                                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsAndSafety() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Smart Buying Tips
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade500, Colors.indigo.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Buying Tips',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          Text(
                            'Make informed purchases',
                            style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem(Icons.visibility, 'Inspect Before You Buy', 'Always examine items thoroughly', Colors.blue.shade500),
                _buildTipItem(Icons.location_on, 'Meet in Public Places', 'Choose safe, well-lit locations', Colors.blue.shade500),
                _buildTipItem(Icons.verified, 'Verify Authenticity', 'Check documentation before purchase', Colors.blue.shade500),
                _buildTipItem(Icons.compare, 'Compare Market Prices', 'Research similar listings', Colors.blue.shade500),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Security & Safety
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade500, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security & Safety',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                          Text(
                            'Stay protected while shopping',
                            style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem(Icons.lock, 'Protect Personal Info', 'Never share banking details', Colors.green.shade500),
                _buildTipItem(Icons.warning_amber, 'Spot Red Flags', 'Be cautious of unrealistic deals', Colors.green.shade500),
                _buildTipItem(Icons.chat_bubble_outline, 'Use Platform Messaging', 'Keep communications secure', Colors.green.shade500),
                _buildTipItem(Icons.group, 'Trust Your Instincts', 'Walk away if something feels wrong', Colors.green.shade500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = widget.categoryId;
                        _selectedSubcategoryId = null;
                        _selectedCondition = null;
                        _selectedDivision = null;
                        _selectedDistrict = null;
                        _selectedArea = null;
                        _minPrice = null;
                        _maxPrice = null;
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        _districts = [];
                        _areas = [];
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Category Filter
                    if (_categories.isNotEmpty) ...[
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategoryId == category.id;
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = selected ? category.id : null;
                                _selectedSubcategoryId = null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Condition Filter
                    const Text('Condition', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['new', 'like_new', 'good', 'fair', 'poor'].map((condition) {
                        final isSelected = _selectedCondition == condition;
                        return FilterChip(
                          label: Text(condition.replaceAll('_', ' ').toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCondition = selected ? condition : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location Filters
                    const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    
                    // Division Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDivision,
                      decoration: InputDecoration(
                        labelText: 'Division',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Divisions')),
                        ..._divisions.map((division) => DropdownMenuItem(
                          value: division,
                          child: Text(division),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDivision = value;
                          if (value != null) {
                            _fetchDistricts(value);
                          } else {
                            _districts = [];
                            _areas = [];
                            _selectedDistrict = null;
                            _selectedArea = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // District Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Districts')),
                        ..._districts.map((district) => DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        )),
                      ],
                      onChanged: _selectedDivision == null ? null : (value) {
                        setState(() {
                          _selectedDistrict = value;
                          if (value != null) {
                            _fetchAreas(value);
                          } else {
                            _areas = [];
                            _selectedArea = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Area Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedArea,
                      decoration: InputDecoration(
                        labelText: 'Area',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Areas')),
                        ..._areas.map((area) => DropdownMenuItem(
                          value: area,
                          child: Text(area),
                        )),
                      ],
                      onChanged: _selectedDistrict == null ? null : (value) {
                        setState(() {
                          _selectedArea = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Price Range Filter
                    const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min Price',
                              prefixText: '৳',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _minPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Price',
                              prefixText: '৳',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _maxPrice = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
