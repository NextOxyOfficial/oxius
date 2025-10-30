import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/sale_post.dart';
import '../models/geo_location.dart';
import '../services/sale_post_service.dart';
import '../services/geo_location_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import '../widgets/sale_skeleton_loader.dart';
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
  late GeoLocationService _geoService;
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
  
  // Search state
  bool _isSearchActive = false;
  
  // Location data (using proper geo models)
  List<Region> _regions = [];
  List<City> _cities = [];
  List<Upazila> _upazilas = [];
  
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
  
  // Expanded categories in filter
  final Set<String> _expandedCategories = <String>{};
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    _postService = SalePostService(baseUrl: ApiService.baseUrl);
    _geoService = GeoLocationService(baseUrl: ApiService.baseUrl);
    _selectedCategoryId = widget.categoryId;
    // Removed scroll listener - using "See More" button instead
    _fetchCategories();
    _fetchRegions();
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

  Future<void> _fetchRegions([StateSetter? setModalState]) async {
    try {
      final regions = await _geoService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
        });
        if (setModalState != null) {
          setModalState(() {
            _regions = regions;
          });
        }
      }
    } catch (e) {
      print('Error fetching regions: $e');
    }
  }

  Future<void> _fetchCities(String regionName, [StateSetter? setModalState]) async {
    try {
      final cities = await _geoService.fetchCities(regionName: regionName);
      if (mounted) {
        setState(() {
          _cities = cities;
          _selectedDistrict = null;
          _selectedArea = null;
          _upazilas = [];
        });
        if (setModalState != null) {
          setModalState(() {
            _cities = cities;
          });
        }
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  Future<void> _fetchUpazilas(String cityName, [StateSetter? setModalState]) async {
    try {
      final upazilas = await _geoService.fetchUpazilas(cityName: cityName);
      if (mounted) {
        setState(() {
          _upazilas = upazilas;
          _selectedArea = null;
        });
        if (setModalState != null) {
          setModalState(() {
            _upazilas = upazilas;
          });
        }
      }
    } catch (e) {
      print('Error fetching upazilas: $e');
    }
  }

  void _onRecentScroll() {
    if (_recentScrollController.position.pixels >= _recentScrollController.position.maxScrollExtent - 50) {
      if (!_isLoadingMoreRecent && _recentListings.length < _recentListingsTotalCount) {
        _loadMoreRecentListings();
      }
    }
  }

  Future<void> _handleRefresh() async {
    // Refresh all data
    await Future.wait([
      _fetchPosts(refresh: true),
      _fetchRecentListings(refresh: true),
    ]);
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

  String? _getCategoryName(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return categoryId;
    }
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'newest':
        return 'Newest';
      case 'price_low':
        return 'Price: Low';
      case 'price_high':
        return 'Price: High';
      case 'most_viewed':
        return 'Most Viewed';
      default:
        return 'Sort';
    }
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

  Widget _buildAppliedFilters() {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Applied Filters',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
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
                    _cities = [];
                    _upazilas = [];
                  });
                  _applyFilters();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear All', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (_selectedCategoryId != null)
                _buildFilterChip(
                  _getCategoryName(_selectedCategoryId) ?? 'Category',
                  Icons.category,
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
                  _selectedDivision!,
                  Icons.location_on,
                  () {
                    setState(() {
                      _selectedDivision = null;
                      _selectedDistrict = null;
                      _selectedArea = null;
                      _cities = [];
                      _upazilas = [];
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedDistrict != null)
                _buildFilterChip(
                  _selectedDistrict!,
                  Icons.location_city,
                  () {
                    setState(() {
                      _selectedDistrict = null;
                      _selectedArea = null;
                      _upazilas = [];
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedArea != null)
                _buildFilterChip(
                  _selectedArea!,
                  Icons.place,
                  () {
                    setState(() => _selectedArea = null);
                    _applyFilters();
                  },
                ),
              if (_minPrice != null || _maxPrice != null)
                _buildFilterChip(
                  '৳${_minPrice?.toInt() ?? 0} - ৳${_maxPrice?.toInt() ?? 'Any'}',
                  Icons.attach_money,
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
                  _selectedCondition!.replaceAll('_', ' ').toUpperCase(),
                  Icons.stars,
                  () {
                    setState(() => _selectedCondition = null);
                    _applyFilters();
                  },
                ),
              if (_searchQuery != null)
                _buildFilterChip(
                  '"$_searchQuery"',
                  Icons.search,
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

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove, {Color? color}) {
    final chipColor = color ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: chipColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: chipColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    setState(() {
                      _searchQuery = value.isEmpty ? null : value;
                    });
                    _fetchPosts();
                  });
                },
              )
            : Text(
                widget.categoryName ?? 'Sale Products',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _searchQuery = null;
                  _fetchPosts();
                }
              });
            },
            tooltip: _isSearchActive ? 'Close Search' : 'Search',
          ),
          if (AuthService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.list_alt_rounded, size: 22),
              onPressed: () {
                Navigator.pushNamed(context, '/my-sale-posts');
              },
              tooltip: 'My Posts',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 22),
            onPressed: _showFilters,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading && _posts.isEmpty
          ? const SaleSkeletonLoader(itemCount: 6)
          : RefreshIndicator(
              color: const Color(0xFF10B981),
              onRefresh: _handleRefresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                // Location Header
                if (_selectedDivision != null || _selectedDistrict != null || _selectedArea != null)
                  _buildLocationHeader(),
                
                // Results Count & Sort
                _buildResultsBar(),
                
                // Applied Filters
                if (_hasActiveFilters()) _buildAppliedFilters(),
                
                // Posts Grid
                if (_posts.isEmpty)
                  _buildEmptyState()
                else
                  _buildPostsGridSection(),
                
                // Recent Listings
                _buildRecentListings(),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
      floatingActionButton: AuthService.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/create-sale-post');
              },
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Post Ad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.1)),
            )
          : null,
    );
  }

  Widget _buildLocationHeader() {
    String locationText = '';
    if (_selectedArea != null) {
      locationText = '$_selectedArea, $_selectedDistrict, $_selectedDivision';
    } else if (_selectedDistrict != null) {
      locationText = '$_selectedDistrict, $_selectedDivision';
    } else if (_selectedDivision != null) {
      locationText = _selectedDivision!;
    }

    return Container(
      color: const Color(0xFF10B981),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Showing results for',
                  style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  locationText,
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: -0.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _selectedDivision = null;
                _selectedDistrict = null;
                _selectedArea = null;
                _cities = [];
                _upazilas = [];
              });
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 20),
          suffixIcon: _searchQuery != null
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = null);
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
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
                            Icon(Icons.location_on_rounded, size: 11, color: const Color(0xFF10B981)),
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
                                  _cities = [];
                                  _upazilas = [];
                                });
                                _applyFilters();
                              },
                              child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF10B981)),
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
                    Icon(Icons.sort_rounded, size: 15, color: Colors.grey.shade700),
                    const SizedBox(width: 5),
                    Text(
                      _getSortLabel(_sortBy),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.grey.shade600),
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
                    child: Text('Newest First', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'price_low',
                    child: Text('Price: Low to High', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'price_high',
                    child: Text('Price: High to Low', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'most_viewed',
                    child: Text('Most Viewed', style: TextStyle(fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Text(
              _selectedCategoryId != null 
                  ? '${_getCategoryName(_selectedCategoryId)} Listings'
                  : 'Browse All Listings',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937), letterSpacing: -0.2),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _posts.length,
            itemBuilder: (context, index) => _buildPostCard(_posts[index]),
          ),
          if (_isLoadingMore)
            const SaleSkeletonLoader(itemCount: 4),
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
    final bool hasImage = post.images != null && post.images!.isNotEmpty;
    
    // Get the image URL - use directly like sale_detail_screen.dart does
    String getImageUrl() {
      if (!hasImage) return '';
      final imageUrl = post.images![0].image;
      print('🖼️ Sale List - Image URL: $imageUrl');
      return imageUrl; // Use directly - backend returns absolute URLs
    }

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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: getImageUrl(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade400, size: 40),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No Image',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 40),
                                const SizedBox(height: 4),
                                Text(
                                  'No Image',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Condition Badge (if available)
                if (post.condition != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.condition!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      height: 1.2,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 3),
                  
                  // Location
                  if (_formatLocation(post).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_rounded, size: 11, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatLocation(post),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Price and Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _formatPrice(post.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.createdAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
            height: 160,
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
                final bool hasImage = listing.images != null && listing.images!.isNotEmpty;

                // Get image URL - use directly like sale_detail_screen.dart does
                String getImageUrl() {
                  if (!hasImage) return '';
                  final imageUrl = listing.images![0].image;
                  print('🖼️ Recent Sale - Image URL: $imageUrl');
                  return imageUrl; // Use directly - backend returns absolute URLs
                }

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
                              hasImage
                                  ? CachedNetworkImage(
                                      imageUrl: getImageUrl(),
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 110,
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        height: 110,
                                        color: Colors.grey.shade100,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade400, size: 32),
                                            const SizedBox(height: 4),
                                            Text(
                                              'No Image',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 110,
                                      width: double.infinity,
                                      color: Colors.grey.shade100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
                                          const SizedBox(height: 4),
                                          Text(
                                            'No Image',
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                                          ),
                                        ],
                                      ),
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        children: [
          // Security & Safety
          Container(
            padding: const EdgeInsets.all(12),
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
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security & Safety',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF065F46), letterSpacing: -0.1),
                          ),
                          Text(
                            'Stay protected while shopping',
                            style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
      isDismissible: true,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return DraggableScrollableSheet(
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
                      setModalState(() {
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
                          _cities = [];
                          _upazilas = [];
                        });
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
                    // Location Filters (Moved to Top)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        const Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Division Dropdown
                    DropdownButtonFormField<String>(
                      value: _regions.any((r) => r.nameEng == _selectedDivision) ? _selectedDivision : null,
                      decoration: InputDecoration(
                        labelText: 'Division',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Divisions')),
                        ..._regions.map((region) => DropdownMenuItem(
                          value: region.nameEng,
                          child: Text(region.nameEng),
                        )),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          setState(() {
                            _selectedDivision = value;
                            if (value != null) {
                              _fetchCities(value, setModalState);
                            } else {
                              _cities = [];
                              _upazilas = [];
                              _selectedDistrict = null;
                              _selectedArea = null;
                            }
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // District Dropdown
                    DropdownButtonFormField<String>(
                      value: _cities.any((c) => c.nameEng == _selectedDistrict) ? _selectedDistrict : null,
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Districts')),
                        ..._cities.map((city) => DropdownMenuItem(
                          value: city.nameEng,
                          child: Text(city.nameEng),
                        )),
                      ],
                      onChanged: _selectedDivision == null ? null : (value) {
                        setModalState(() {
                          setState(() {
                            _selectedDistrict = value;
                            if (value != null) {
                              _fetchUpazilas(value, setModalState);
                            } else {
                              _upazilas = [];
                              _selectedArea = null;
                            }
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Area Dropdown
                    DropdownButtonFormField<String>(
                      value: _upazilas.any((u) => u.nameEng == _selectedArea) ? _selectedArea : null,
                      decoration: InputDecoration(
                        labelText: 'Area',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Areas')),
                        ..._upazilas.map((upazila) => DropdownMenuItem(
                          value: upazila.nameEng,
                          child: Text(upazila.nameEng),
                        )),
                      ],
                      onChanged: _selectedDistrict == null ? null : (value) {
                        setModalState(() {
                          setState(() {
                            _selectedArea = value;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Category Filter with Subcategories
                    if (_categories.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.category, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // All Categories Option
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.apps, color: Color(0xFF10B981), size: 20),
                              title: const Text('All Categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              trailing: _selectedCategoryId == null 
                                ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                                : null,
                              selected: _selectedCategoryId == null,
                              selectedTileColor: const Color(0xFF10B981).withOpacity(0.1),
                              onTap: () {
                                setModalState(() {
                                  setState(() {
                                    _selectedCategoryId = null;
                                    _selectedSubcategoryId = null;
                                  });
                                });
                              },
                            ),
                            const Divider(height: 1),
                            // Categories with Subcategories
                            ..._categories.map((category) {
                              final isExpanded = _expandedCategories.contains(category.id);
                              final isSelected = _selectedCategoryId == category.id;
                              final hasSubcategories = category.subcategories?.isNotEmpty ?? false;
                              
                              return Column(
                                children: [
                                  ListTile(
                                    dense: true,
                                    leading: category.icon != null && category.icon!.isNotEmpty
                                      ? Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: CachedNetworkImage(
                                              imageUrl: category.icon!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Icon(
                                                Icons.folder_outlined,
                                                color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade600,
                                                size: 20,
                                              ),
                                              errorWidget: (context, url, error) => Icon(
                                                Icons.folder_outlined,
                                                color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade600,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.folder_outlined,
                                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                    title: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected && !hasSubcategories)
                                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                                        if (hasSubcategories)
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            color: Colors.grey.shade600,
                                          ),
                                      ],
                                    ),
                                    selected: isSelected,
                                    selectedTileColor: const Color(0xFF10B981).withOpacity(0.1),
                                    onTap: () {
                                      if (hasSubcategories) {
                                        setModalState(() {
                                          setState(() {
                                            if (isExpanded) {
                                              _expandedCategories.remove(category.id);
                                            } else {
                                              _expandedCategories.add(category.id);
                                            }
                                          });
                                        });
                                      } else {
                                        setModalState(() {
                                          setState(() {
                                            _selectedCategoryId = category.id;
                                            _selectedSubcategoryId = null;
                                          });
                                        });
                                      }
                                    },
                                  ),
                                  // Subcategories
                                  if (isExpanded && hasSubcategories)
                                    Container(
                                      color: Colors.grey.shade50,
                                      child: Column(
                                        children: (category.subcategories ?? []).map((sub) {
                                          final isSubSelected = _selectedSubcategoryId == sub.id;
                                          return ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.only(left: 56, right: 16),
                                            title: Text(
                                              sub.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isSubSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
                                                fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                            trailing: isSubSelected 
                                              ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18)
                                              : null,
                                            selected: isSubSelected,
                                            selectedTileColor: const Color(0xFF10B981).withOpacity(0.15),
                                            onTap: () {
                                              setModalState(() {
                                                setState(() {
                                                  _selectedCategoryId = category.id;
                                                  _selectedSubcategoryId = sub.id;
                                                });
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  const Divider(height: 1),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                            setModalState(() {
                              setState(() {
                                _selectedCondition = selected ? condition : null;
                              });
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    
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
                              setModalState(() {
                                setState(() {
                                  _minPrice = double.tryParse(value);
                                });
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
                              setModalState(() {
                                setState(() {
                                  _maxPrice = double.tryParse(value);
                                });
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
      );
        },
      ),
    );
  }
}
