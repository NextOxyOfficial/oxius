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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _categoryDetails?.title ?? 'Classified Ads',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Location breadcrumb
          if (_location != null) _buildLocationBreadcrumb(),
          
          // Search bar
          _buildSearchBar(),
          
          // Content
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post a classified button
                        _buildPostAdButton(),
                        
                        const SizedBox(height: 16),
                        
                        // Search results
                        if (_posts.isNotEmpty) ...[
                          _buildPostsList(_posts),
                          
                          // Pagination
                          if (_totalPages > 1) _buildPagination(),
                          
                          const Divider(height: 32),
                          
                          if (!_location!.allOverBangladesh) ...[
                            const Text(
                              'Nearby location\'s ads',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        
                        // Empty state
                        if (_searchError) _buildEmptyState(),
                        
                        // Nearby posts
                        if (_nearbyPosts.isNotEmpty && !_location!.allOverBangladesh) ...[
                          _buildPostsList(_nearbyPosts, isNearby: true),
                        ],
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Post Ads',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBreadcrumb() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _location!.displayLocation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF065F46),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: const Color(0xFF10B981),
            onPressed: _showLocationSelector,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _searchQuery = value,
              onSubmitted: (_) => _filterSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _filterSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAdButton() {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post Classified feature coming soon!')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Post Classified'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF10B981),
        side: const BorderSide(color: Color(0xFF10B981)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPostsList(List<ClassifiedPost> posts, {bool isNearby = false}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCard(post, isNearby: isNearby);
      },
    );
  }

  Widget _buildPostCard(ClassifiedPost post, {bool isNearby = false}) {
    return Card(
      elevation: isNearby ? 0 : 1,
      color: isNearby ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNearby ? Colors.grey[200]! : Colors.grey[100]!,
        ),
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: post.medias != null && post.medias!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.medias!.first.image ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        )
                      : post.categoryDetails?.image != null
                          ? CachedNetworkImage(
                              imageUrl: post.categoryDetails!.image!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(
                                Icons.category,
                                color: Colors.grey[400],
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
                  children: [
                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
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
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Location and time
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [post.city, post.state]
                                .where((e) => e != null)
                                .join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      post.getRelativeTime(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1 ? () => _filterSearch(page: _currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF10B981),
          ),
          
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
              
              return InkWell(
                onTap: () => _filterSearch(page: pageNum),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentPage == pageNum
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _currentPage == pageNum
                          ? const Color(0xFF10B981)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    pageNum.toString(),
                    style: TextStyle(
                      color: _currentPage == pageNum
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      fontWeight: _currentPage == pageNum
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Next button
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => _filterSearch(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No ads found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any ads matching your search criteria in this location.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showLocationSelector,
              icon: const Icon(Icons.location_on),
              label: const Text('Change Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
