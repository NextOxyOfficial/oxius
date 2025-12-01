import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/workspace_service.dart';
import '../../services/api_service.dart';
import 'gig_detail_screen.dart';

class AllGigsTab extends StatefulWidget {
  const AllGigsTab({super.key});

  @override
  State<AllGigsTab> createState() => _AllGigsTabState();
}

class _AllGigsTabState extends State<AllGigsTab> {
  final WorkspaceService _workspaceService = WorkspaceService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _gigs = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _selectedCategory;
  String _searchQuery = '';
  final String _ordering = '-created_at';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadGigs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGigs();
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _workspaceService.fetchCategories();
    if (mounted) {
      setState(() => _categories = categories);
    }
  }

  Future<void> _loadGigs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await _workspaceService.fetchGigs(
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ordering: _ordering,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _gigs = result['results'];
          } else {
            _gigs.addAll(result['results']);
          }
          _hasMore = result['next'] != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreGigs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final result = await _workspaceService.fetchGigs(
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ordering: _ordering,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          _gigs.addAll(result['results']);
          _hasMore = result['next'] != null;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadGigs(refresh: true),
      child: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search gigs...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadGigs(refresh: true);
                              },
                              child: Icon(Icons.clear, size: 16, color: Colors.grey[400]),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(minWidth: 32),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                      _loadGigs(refresh: true);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // Category Filter
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', null),
                      ..._categories.map((cat) => _buildFilterChip(
                        cat['label'] ?? cat['name'] ?? '',
                        cat['value']?.toString() ?? cat['id']?.toString(),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gigs Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _gigs.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _gigs.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _gigs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _buildGigCard(_gigs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId) {
    final isSelected = _selectedCategory == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCategory = isSelected ? null : categoryId);
          _loadGigs(refresh: true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final user = gig['user'] as Map<String, dynamic>?;
    final rating = (gig['rating'] ?? 0).toDouble();
    final price = gig['price']?.toString() ?? '0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GigDetailScreen(gigId: gig['id'].toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(gig['image_url'] ?? gig['image']),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey, size: 20),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: user?['avatar'] != null
                              ? CachedNetworkImageProvider(_getImageUrl(user!['avatar']))
                              : null,
                          child: user?['avatar'] == null
                              ? Text(
                                  (user?['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 8),
                                )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  user?['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?['kyc'] == true)
                                const Padding(
                                  padding: EdgeInsets.only(left: 3),
                                  child: Icon(Icons.verified, size: 12, color: Colors.blue),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Title
                    Expanded(
                      child: Text(
                        gig['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Rating and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '৳$price',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No gigs found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
