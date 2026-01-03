import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import '../models/classified_post.dart';
import '../models/geo_location.dart';
import '../services/classified_post_service.dart';
import '../services/geo_location_service.dart';
import '../services/api_service.dart';
import '../utils/url_launcher_utils.dart';
import '../widgets/geo_selector_dialog.dart';
import '../widgets/skeleton_loader.dart';
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
  List<ClassifiedPost> _descriptionPosts = [];
  
  bool _isLoading = false;
  bool _isNearbyLoading = false;
  bool _isDescriptionLoading = false;
  bool _searchError = false;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  Timer? _debounce;
  
  // AdsyAI Bot state
  bool _aiUserChoice = false;
  bool _aiSearching = false;
  bool _aiSearchDeclined = false;
  List<Map<String, dynamic>> _aiResults = [];
  String? _aiErrorMessage;

  @override
  void initState() {
    super.initState();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);
    _geoService = GeoLocationService(baseUrl: ApiService.baseUrl);
    _initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _handleRefresh() async {
    // Refresh all data
    await Future.wait([
      _loadCategoryDetails(),
      _filterSearch(page: 1),
      _fetchNearbyAds(),
      if (_searchQuery.isNotEmpty) _fetchDescriptionResults(),
    ]);
  }

  Future<void> _fetchDescriptionResults() async {
    if (_location == null || _searchQuery.isEmpty) return;
    
    setState(() => _isDescriptionLoading = true);
    
    try {
      final results = await _postService.searchByDescription(
        categoryId: widget.categoryId,
        searchQuery: _searchQuery,
        location: _location!,
      );
      
      if (mounted) {
        setState(() {
          // Filter out posts that are already in main results (title matches)
          final mainPostIds = _posts.map((p) => p.id).toSet();
          _descriptionPosts = results.where((post) {
            // Only show if not already in main results AND actually matches in description
            final notInMain = !mainPostIds.contains(post.id);
            final matchesDesc = post.instructions?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
            return notInMain && matchesDesc;
          }).toList();
          _isDescriptionLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDescriptionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _categoryDetails?.title ?? 'Classified Ads',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _searchQuery = '';
                  _descriptionPosts = [];
                  _filterSearch();
                }
              });
            },
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Location breadcrumb
          if (_location != null) _buildLocationBreadcrumb(),
          
          // Search bar (collapsible)
          if (_isSearchActive) _buildSearchBar(),
          
          // Results count
          if (!_isLoading && _posts.isNotEmpty) _buildResultsCount(),
          
          // Content
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? SkeletonLoader.gridView(itemCount: 6, crossAxisCount: 2)
                : RefreshIndicator(
                    color: const Color(0xFF10B981),
                    onRefresh: _handleRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Search results
                        if (_posts.isNotEmpty) ...[
                          _buildPostsList(_posts),
                          
                          // Pagination
                          if (_totalPages > 1) _buildPagination(),
                          
                          const SizedBox(height: 16),
                        ],
                        
                        // Empty state
                        if (_searchError) _buildEmptyState(),
                        
                        // Nearby Location Ads Section
                        if (_location != null && !_location!.allOverBangladesh) ...[
                          if (_nearbyPosts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              color: const Color(0xFFECFDF5),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Nearby Location Ads',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ),
                            _buildPostsList(_nearbyPosts, isNearby: true),
                          ] else if (_isNearbyLoading) ...[
                            const SizedBox(height: 16),
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                ),
                              ),
                            ),
                          ],
                        ],
                        
                        // Description Matches Section
                        if (_searchQuery.isNotEmpty && _descriptionPosts.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDescriptionMatchesSection(),
                        ] else if (_searchQuery.isNotEmpty && _isDescriptionLoading) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                              ),
                            ),
                          ),
                        ],
                        
                        // AdsyAI Bot Section
                        if (_location != null && ((_location!.city != null && _location!.city!.isNotEmpty) || _location!.allOverBangladesh)) ...[
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                            color: const Color(0xFFF9FAFB),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: const [
                                  Text(
                                    'AdsyAI Bot',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.smart_toy,
                                    size: 24,
                                    color: Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildAdsyAIBot(),
                        ],
                        
                        const SizedBox(height: 80),
                      ],
                    ),
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/classified-post-form',
            arguments: {
              'categoryId': _categoryDetails?.id ?? widget.categoryId,
            },
          );
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Post Ads',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        elevation: 3,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }
  
  Widget _buildResultsCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '$_totalCount results',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            Icons.location_on_rounded,
            color: Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _location!.displayLocation,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
                letterSpacing: -0.1,
              ),
            ),
          ),
          InkWell(
            onTap: _showLocationSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 3),
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search ads...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) {
                  _searchQuery = value;
                  // Cancel previous timer
                  _debounce?.cancel();
                  // Start new timer for debounce (500ms delay)
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _filterSearch();
                      _fetchDescriptionResults();
                    }
                  });
                },
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _filterSearch();
                  _fetchDescriptionResults();
                },
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _filterSearch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Search',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.1,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 75,
                  height: 75,
                  color: const Color(0xFFF3F4F6),
                  child: post.medias != null && post.medias!.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            final imageUrl = post.medias!.first.image ?? '';
                            print('🖼️ Classified List - Image URL: $imageUrl');
                            return CachedNetworkImage(
                              imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF9CA3AF),
                            size: 28,
                          ),
                            );
                          },
                        )
                      : post.categoryDetails?.image != null
                          ? CachedNetworkImage(
                              imageUrl: post.categoryDetails!.image!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No photo\nuploaded',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[500],
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey[400],
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No photo\nuploaded',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[500],
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price and Time Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Flexible(
                          child: Text(
                            post.displayPrice,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(width: 6),
                        
                        // Time
                        Text(
                          post.getRelativeTime(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            [post.upazila, post.city, post.state]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildAdsyAIBot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          // User hasn't made a choice yet
          if (!_aiUserChoice) ...[
            // Bot Icon
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
            
            // Message
            const Text(
              'আমি AdsyAI Bot 🤖\nআমি কি আপনার জন্য বিভিন্ন ওয়েবসাইট থেকে তথ্য খুঁজে বের করবো?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Yes Button
                ElevatedButton.icon(
                  onPressed: _startAISearch,
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'হা',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // No Button
                OutlinedButton.icon(
                  onPressed: _declineAISearch,
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text(
                    'না',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    side: const BorderSide(
                      color: Color(0xFFEF4444),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Searching
          if (_aiSearching) ...[
            // Animated Bot Icon
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
            
            const Text(
              'আমি AdsyAI Bot 🤖\nআপনার জন্য ইন্টারনেটে বিভিন্ন ওয়েবসাইট এ তথ্য খুঁজছি, একটু অপেক্ষা করুন...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Finding information in ${_location?.displayLocation ?? "your area"}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          
          // Search Declined
          if (_aiSearchDeclined) ...[
            const Icon(
              Icons.smart_toy,
              size: 48,
              color: Color(0xFF6B7280),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'আমি AdsyAI Bot 🤖\nঠিক আছে, আপনি যখন চাইবেন তখন আমি তথ্য খুঁজে দেখাবো।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _aiUserChoice = false;
                  _aiSearchDeclined = false;
                  _aiResults = [];
                  _aiErrorMessage = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
              ),
            ),
          ],
          
          // Results
          if (_aiResults.isNotEmpty) ...[
            const Text(
              'আমি AdsyAI Bot 🤖\nআপনার জন্য ইন্টারনেট থেকে নিচের এই তথ্য গুলো খুঁজে বের করতে সক্ষম হয়েছি:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            ..._aiResults.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name with copy button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. ${result['name'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        _buildCopyButton(result['name'] ?? ''),
                      ],
                    ),
                    if (result['description'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        result['description'].toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                    if (result['address'] != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        value: result['address'].toString(),
                        onCopy: () => _copyToClipboard(result['address'].toString()),
                      ),
                    ],
                    if (result['phone'] != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.phone,
                        value: result['phone'].toString(),
                        onCopy: () => _copyToClipboard(result['phone'].toString()),
                        onTap: () => UrlLauncherUtils.launchExternalUrl('tel:${result['phone']}'),
                      ),
                    ],
                    if (result['email'] != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.email,
                        value: result['email'].toString(),
                        onCopy: () => _copyToClipboard(result['email'].toString()),
                        onTap: () => UrlLauncherUtils.launchExternalUrl('mailto:${result['email']}'),
                      ),
                    ],
                    if (result['website'] != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.language,
                        value: result['website'].toString(),
                        isLink: true,
                        onCopy: () => _copyToClipboard(result['website'].toString()),
                        onTap: () => UrlLauncherUtils.launchExternalUrl(result['website'].toString()),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
          
          // No results
          if (_aiUserChoice && !_aiSearching && !_aiSearchDeclined && _aiResults.isEmpty) ...[
            const Text(
              'আমি AdsyAI Bot 🤖\nদুঃখিত, আপনার জন্য ইন্টারনেট থেকে কোনো তথ্য খুঁজে পাইনি।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            if (_aiErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _aiErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _aiUserChoice = false;
                  _aiSearchDeclined = false;
                  _aiResults = [];
                  _aiErrorMessage = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startAISearch() async {
    final location = _location;
    final businessType = _categoryDetails?.businessType;
    final effectiveBusinessType = (businessType != null && businessType.trim().isNotEmpty)
        ? businessType.trim()
        : (_categoryDetails?.title.trim() ?? '');

    if (location == null || effectiveBusinessType.isEmpty) return;

    setState(() {
      _aiUserChoice = true;
      _aiSearching = true;
      _aiSearchDeclined = false;
      _aiResults = [];
      _aiErrorMessage = null;
    });
    
    // TODO: Replace with actual API call to your AI service
    // Example:
    // final response = await http.get(Uri.parse('$aiLink&country=${_location?.country}&city=${_location?.city}&state=${_location?.state}&business_type=${_categoryDetails?.businessType}'));
    // final data = json.decode(response.body);
    // _aiResults = data['data'] or data['data']['businesses'];
    
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/ai-business-finder/');
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'country': location.country,
          'state': location.allOverBangladesh ? 'All Bangladesh' : (location.state ?? ''),
          'city': location.allOverBangladesh ? 'All Cities' : (location.city ?? ''),
          'upazila': location.allOverBangladesh ? 'All Areas' : (location.upazila ?? ''),
          'business_type': effectiveBusinessType,
        }),
      );

      List<Map<String, dynamic>> businesses = [];
      String? errorMessage;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final dynamic dataNode = decoded['data'];
          final dynamic businessesNode = decoded['businesses'] ??
              (dataNode is Map ? dataNode['businesses'] : null) ??
              (dataNode is Map ? dataNode['data'] : null);

          if (businessesNode is List) {
            businesses = businessesNode
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } else if (decoded is List) {
          businesses = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } else {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            if (decoded['error'] != null) {
              errorMessage = decoded['error']?.toString();
            } else if (decoded['detail'] != null) {
              errorMessage = decoded['detail']?.toString();
            } else if (decoded['message'] != null) {
              errorMessage = decoded['message']?.toString();
            }
          }
        } catch (_) {
          errorMessage = null;
        }

        errorMessage ??= 'Failed to fetch AI results (${response.statusCode})';
      }

      if (!mounted) return;
      setState(() {
        _aiSearching = false;
        _aiResults = businesses;
        _aiErrorMessage = errorMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiSearching = false;
        _aiResults = [];
        _aiErrorMessage = e.toString();
      });
    }
  }

  void _declineAISearch() {
    setState(() {
      _aiUserChoice = true;
      _aiSearching = false;
      _aiSearchDeclined = true;
      _aiResults = [];
      _aiErrorMessage = null;
    });
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  /// Build copy button widget
  Widget _buildCopyButton(String text) {
    return InkWell(
      onTap: () => _copyToClipboard(text),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.copy_rounded,
          size: 16,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  /// Build info row with icon, value, copy and optional tap action
  Widget _buildInfoRow({
    required IconData icon,
    required String value,
    bool isLink = false,
    VoidCallback? onCopy,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isLink ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        if (onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
      ],
    );
  }

  /// Build professional description matches section
  Widget _buildDescriptionMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with gradient
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFEF3C7),
                const Color(0xFFFDE68A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description_rounded,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Found in posts',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Showing ${_descriptionPosts.length} result${_descriptionPosts.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Results container
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: Border.all(
              color: const Color(0xFFFDE68A),
              width: 1,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _descriptionPosts.length,
            separatorBuilder: (context, index) => const Divider(
              height: 16,
              thickness: 1,
              color: Color(0xFFFDE68A),
            ),
            itemBuilder: (context, index) {
              final post = _descriptionPosts[index];
              return _buildDescriptionMatchCard(post);
            },
          ),
        ),
      ],
    );
  }

  /// Build individual description match card
  Widget _buildDescriptionMatchCard(ClassifiedPost post) {
    final snippet = _extractMatchedSnippet(post.instructions, _searchQuery);
    
    // Skip if no match found in description
    if (snippet.isEmpty) return const SizedBox.shrink();
    
    return Material(
      color: Colors.transparent,
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFFEF3C7),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 55,
                  height: 55,
                  color: const Color(0xFFFEF3C7),
                  child: post.medias != null && post.medias!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.medias!.first.image ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF92400E),
                            size: 20,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF92400E),
                          size: 20,
                        ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - small size
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Matched snippet with HTML parsing - small text
                    Container(
                      constraints: const BoxConstraints(maxHeight: 28), // Limit height to ~2 lines
                      child: Html(
                        data: snippet,
                        onLinkTap: (url, attributes, element) {
                          UrlLauncherUtils.launchExternalUrl(url);
                        },
                        style: {
                          "body": Style(
                            fontSize: FontSize(10),
                            lineHeight: LineHeight(1.4),
                            color: const Color(0xFF6B7280),
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          "p": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          "div": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Price and Location - small size
                    Row(
                      children: [
                        Text(
                          post.displayPrice,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 10,
                          color: Color(0xFF92400E),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            [post.city, post.state]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  /// Extract matched text snippet from description
  String _extractMatchedSnippet(String? description, String query) {
    if (description == null || description.isEmpty || query.isEmpty) {
      return '';
    }

    // Strip HTML tags for search matching but keep original HTML for display
    final strippedDesc = description.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final lowerStripped = strippedDesc.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerStripped.indexOf(lowerQuery);

    if (index == -1) return '';

    // Extract context around the match (60 chars before and after for better context)
    final start = (index - 60).clamp(0, strippedDesc.length);
    final end = (index + query.length + 60).clamp(0, strippedDesc.length);
    
    String snippet = strippedDesc.substring(start, end);
    
    // Add ellipsis if truncated
    if (start > 0) snippet = '...$snippet';
    if (end < strippedDesc.length) snippet = '$snippet...';
    
    // Wrap in a paragraph tag for proper HTML rendering
    return '<p>$snippet</p>';
  }

}
