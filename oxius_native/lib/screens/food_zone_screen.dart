import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/classified_post.dart';
import '../models/geo_location.dart';
import '../services/food_zone_service.dart';
import '../services/geo_location_service.dart';
import '../services/api_service.dart';
import '../widgets/geo_selector_dialog.dart';
import '../widgets/geo_location_breadcrumb.dart';
import 'classified_post_details_screen.dart';

class FoodZoneScreen extends StatefulWidget {
  const FoodZoneScreen({super.key});

  @override
  State<FoodZoneScreen> createState() => _FoodZoneScreenState();
}

class _FoodZoneScreenState extends State<FoodZoneScreen> {
  late FoodZoneService _foodZoneService;
  late GeoLocationService _geoService;
  List<ClassifiedPost> _posts = [];
  List<FoodZoneCategory> _categories = [];
  GeoLocation? _location;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _selectedCategoryId;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _foodZoneService = FoodZoneService(baseUrl: ApiService.baseUrl);
    _geoService = GeoLocationService(baseUrl: ApiService.baseUrl);
    _initialize();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initialize() async {
    _location = await _geoService.getSavedLocation();
    if (_location == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationSelector();
      });
    } else {
      _loadData();
    }
  }

  void _showLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => GeoSelectorDialog(
        initialLocation: _location,
        onLocationSelected: (location) async {
          await _geoService.saveLocation(location);
          setState(() => _location = location);
          _loadData();
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final newQuery = _searchController.text.trim();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchQuery != newQuery) {
        print('🔍 Search query changed: "$_searchQuery" -> "$newQuery"');
        setState(() {
          _searchQuery = newQuery;
        });
        _loadData();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });
    
    try {
      final results = await Future.wait([
        _foodZoneService.fetchFoodZonePosts(
          page: 1,
          pageSize: 20,
          categoryId: _selectedCategoryId,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          location: _location,
        ),
        _foodZoneService.fetchFoodZoneCategories(),
      ]);
      
      setState(() {
        _posts = results[0] as List<ClassifiedPost>;
        _categories = results[1] as List<FoodZoneCategory>;
        _isLoading = false;
        _hasMore = _posts.length >= 20;
      });
    } catch (e) {
      print('Error loading food zone data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final posts = await _foodZoneService.fetchFoodZonePosts(
        page: _currentPage + 1,
        pageSize: 20,
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        location: _location,
      );
      
      setState(() {
        _posts.addAll(posts);
        _currentPage++;
        _isLoadingMore = false;
        _hasMore = posts.length >= 20;
      });
    } catch (e) {
      print('Error loading more posts: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onCategorySelected(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });
    
    try {
      final posts = await _foodZoneService.fetchFoodZonePosts(
        page: 1,
        pageSize: 20,
        categoryId: categoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        location: _location,
      );
      
      setState(() {
        _posts = posts;
        _isLoading = false;
        _hasMore = posts.length >= 20;
      });
    } catch (e) {
      print('Error loading posts by category: $e');
      setState(() => _isLoading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _loadData();
  }

  void _navigateToPost(ClassifiedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassifiedPostDetailsScreen(
          postId: post.id,
          postSlug: post.slug ?? post.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Food Zone',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Icon(Icons.search_rounded, size: 22, color: Color(0xFFE91E63)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search food items...',
                                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                              onPressed: _clearSearch,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Location breadcrumb
          if (_location != null) _buildLocationBreadcrumb(),
          
          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                  )
                : _posts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFFE91E63),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _posts.length) {
                              return _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFE91E63),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _buildFoodItem(_posts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBreadcrumb() {
    if (_location == null) return const SizedBox.shrink();

    return GeoLocationBreadcrumb(
      location: _location!,
      onChange: _showLocationSelector,
      backgroundColor: const Color(0xFFFCE4EC),
      borderColor: const Color(0xFFE91E63).withOpacity(0.2),
      iconColor: const Color(0xFFE91E63),
      textColor: const Color(0xFFC2185B),
      actionColor: const Color(0xFFE91E63),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No food items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Check back later for delicious options',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _clearSearch,
              child: const Text(
                'Clear Search',
                style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(ClassifiedPost post) {
    final imageUrl = post.medias?.isNotEmpty == true ? post.medias!.first.image : null;
    final posterName = post.user != null 
        ? '${post.user!.firstName ?? ''} ${post.user!.lastName ?? ''}'.trim()
        : null;
    
    return InkWell(
      onTap: () => _navigateToPost(post),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFFCE4EC),
                          child: const Center(
                            child: Icon(Icons.restaurant_menu, color: Color(0xFFE91E63), size: 24),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFFCE4EC),
                          child: const Center(
                            child: Icon(Icons.restaurant_menu, color: Color(0xFFE91E63), size: 24),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFFCE4EC),
                        child: const Center(
                          child: Icon(Icons.restaurant_menu, color: Color(0xFFE91E63), size: 24),
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
                  // Poster Name
                  if (posterName != null && posterName.isNotEmpty)
                    Text(
                      posterName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  if (post.city != null || post.upazila != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            [post.upazila, post.city].where((e) => e != null && e.isNotEmpty).join(', '),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  // Price
                  if (post.price != null && post.price! > 0)
                    Text(
                      '৳${post.price!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE91E63),
                      ),
                    )
                  else
                    const Text(
                      'Contact for price',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),
            // Arrow
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
