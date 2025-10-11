import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/classified_post.dart';
import '../models/geo_location.dart';
import '../services/classified_post_service.dart';
import '../services/geo_location_service.dart';
import '../services/api_service.dart';
import '../widgets/geo_selector_dialog.dart';
import 'classified_post_details_screen.dart';

class ClassifiedCategoryListScreen extends StatefulWidget {
  final String categoryId;
  final String categorySlug;

  const ClassifiedCategoryListScreen({
    Key? key,
    required this.categoryId,
    required this.categorySlug,
  }) : super(key: key);

  @override
  State<ClassifiedCategoryListScreen> createState() => _ClassifiedCategoryListScreenState();
}

class _ClassifiedCategoryListScreenState extends State<ClassifiedCategoryListScreen> {
  late final ClassifiedPostService _postService;
  late final GeoLocationService _geoService;
  
  CategoryDetails? _categoryDetails;
  GeoLocation? _location;
  
  List<ClassifiedPost> _posts = [];
  List<ClassifiedPost> _nearbyPosts = [];
  
  bool _isLoading = false;
  bool _isNearbyLoading = false;
  bool _searchError = false;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);
    _geoService = GeoLocationService(baseUrl: ApiService.baseUrl);
    _initialize();
  }

  Future<void> _initialize() async {
    // Load saved location
    _location = await _geoService.getSavedLocation();
    
    // Show location selector if no location is set
    if (_location == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationSelector();
      });
    } else {
      // Load data
      await _loadCategoryDetails();
      await _filterSearch();
      await _fetchNearbyAds();
    }
  }

  Future<void> _loadCategoryDetails() async {
    final details = await _postService.fetchCategoryDetails(widget.categorySlug);
    if (mounted && details != null) {
      setState(() => _categoryDetails = details);
    }
  }

  Future<void> _filterSearch({int page = 1}) async {
    if (_location == null) return;
    
    setState(() {
      if (page == 1) {
        _posts = [];
        _currentPage = 1;
      }
      _isLoading = true;
      _searchError = false;
    });

    try {
      final response = await _postService.fetchPosts(
        categoryId: widget.categoryId,
        title: _searchQuery,
        location: _location,
        page: page,
        pageSize: 20,
      );

      if (mounted) {
        setState(() {
          if (page == 1) {
            _posts = response.results;
          } else {
            _posts.addAll(response.results);
          }
          _currentPage = page;
          _totalCount = response.count;
          _totalPages = response.totalPages;
          _searchError = response.results.isEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchError = true;
        });
      }
    }
  }

  Future<void> _fetchNearbyAds() async {
    if (_location == null || _location!.allOverBangladesh) return;
    
    setState(() => _isNearbyLoading = true);
    
    try {
      final nearby = await _postService.fetchNearbyPosts(
        categoryId: widget.categoryId,
        location: _location!,
      );
      
      if (mounted) {
        setState(() {
          _nearbyPosts = nearby;
          _isNearbyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isNearbyLoading = false);
      }
    }
  }

  void _showLocationSelector() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GeoSelectorDialog(
        initialLocation: _location,
        onLocationSelected: (location) async {
          await _geoService.saveLocation(location);
          setState(() => _location = location);
          await _loadCategoryDetails();
          await _filterSearch();
          await _fetchNearbyAds();
        },
      ),
    );
  }

  void _clearLocation() async {
    await _geoService.clearLocation();
    setState(() => _location = null);
    _showLocationSelector();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _categoryDetails?.title ?? 'Classified Ads',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Location breadcrumb
          if (_location != null) _buildLocationBreadcrumb(),
          
          // Search bar
          _buildSearchBar(),
          
          // Results count
          if (!_isLoading && _posts.isNotEmpty) _buildResultsCount(),
          
          // Content
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search results
                        if (_posts.isNotEmpty) ...[
                          _buildPostsList(_posts),
                          
                          // Pagination
                          if (_totalPages > 1) _buildPagination(),
                          
                          const SizedBox(height: 16),
                          
                          if (!_location!.allOverBangladesh && _nearbyPosts.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              color: const Color(0xFFECFDF5),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Nearby Location Ads',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                        
                        // Empty state
                        if (_searchError) _buildEmptyState(),
                        
                        // Nearby posts
                        if (_nearbyPosts.isNotEmpty && !_location!.allOverBangladesh) ...[
                          _buildPostsList(_nearbyPosts, isNearby: true),
                        ],
                        
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to post ad screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post Ad feature coming soon!')),
          );
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Post Ads',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        elevation: 4,
      ),
    );
  }
  
  Widget _buildResultsCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '$_totalCount results',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF10B981).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: Color(0xFF10B981),
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _location!.displayLocation,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            ),
          ),
          InkWell(
            onTap: _showLocationSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search ads...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) => _searchQuery = value,
                onSubmitted: (_) => _filterSearch(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _filterSearch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Search',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<ClassifiedPost> posts, {bool isNearby = false}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCard(post, isNearby: isNearby);
      },
    );
  }

  Widget _buildPostCard(ClassifiedPost post, {bool isNearby = false}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassifiedPostDetailsScreen(
                postId: post.id,
                postSlug: post.slug ?? post.id,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 110,
                  height: 110,
                  color: const Color(0xFFF3F4F6),
                  child: post.medias != null && post.medias!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.medias!.first.image ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        )
                      : post.categoryDetails?.image != null
                          ? CachedNetworkImage(
                              imageUrl: post.categoryDetails!.image!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(
                                Icons.category,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            )
                          : Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Price
                    Text(
                      post.displayPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            [post.city, post.state]
                                .where((e) => e != null)
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Time
                    Text(
                      post.getRelativeTime(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: _currentPage > 1 ? Colors.white : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _currentPage > 1 ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              ),
            ),
            child: IconButton(
              onPressed: _currentPage > 1 ? () => _filterSearch(page: _currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left, size: 20),
              color: _currentPage > 1 ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              padding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Page numbers
          ...List.generate(
            _totalPages > 5 ? 5 : _totalPages,
            (index) {
              int pageNum;
              if (_totalPages <= 5) {
                pageNum = index + 1;
              } else {
                int start = (_currentPage - 2).clamp(1, _totalPages - 4);
                pageNum = start + index;
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => _filterSearch(page: pageNum),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 36,
                    constraints: const BoxConstraints(minWidth: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _currentPage == pageNum
                          ? const Color(0xFF10B981)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _currentPage == pageNum
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        pageNum.toString(),
                        style: TextStyle(
                          color: _currentPage == pageNum
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontWeight: _currentPage == pageNum
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 8),
          
          // Next button
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: _currentPage < _totalPages ? Colors.white : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _currentPage < _totalPages ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              ),
            ),
            child: IconButton(
              onPressed: _currentPage < _totalPages
                  ? () => _filterSearch(page: _currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right, size: 20),
              color: _currentPage < _totalPages ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 56,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Ads Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any ads matching your search criteria in this location.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showLocationSelector,
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Change Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
