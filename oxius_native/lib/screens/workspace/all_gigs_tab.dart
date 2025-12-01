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
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search gigs...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadGigs(refresh: true);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _loadGigs(refresh: true);
                  },
                ),
                const SizedBox(height: 10),
                // Category Filter
                SizedBox(
                  height: 36,
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
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
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
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? categoryId : null);
          _loadGigs(refresh: true);
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: const Color(0xFF8B5CF6),
        side: BorderSide(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(gig['image_url'] ?? gig['image']),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: user?['avatar'] != null
                              ? CachedNetworkImageProvider(_getImageUrl(user!['avatar']))
                              : null,
                          child: user?['avatar'] == null
                              ? Text(
                                  (user?['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  user?['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?['kyc'] == true)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified, size: 14, color: Colors.blue),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Title
                    Expanded(
                      child: Text(
                        gig['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
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
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '৳$price',
                          style: const TextStyle(
                            fontSize: 14,
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
