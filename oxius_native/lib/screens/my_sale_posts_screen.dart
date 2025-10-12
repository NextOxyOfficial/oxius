import 'package:flutter/material.dart';
import '../services/sale_post_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/sale_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// My Sale Posts Screen - View and manage user's sale posts
/// This screen has 2 tabs: My Posts & Post Sale
class MySalePostsScreen extends StatefulWidget {
  final String? initialTab; // 'my-posts' or 'post-sale'

  const MySalePostsScreen({
    Key? key,
    this.initialTab,
  }) : super(key: key);

  @override
  State<MySalePostsScreen> createState() => _MySalePostsScreenState();
}

class _MySalePostsScreenState extends State<MySalePostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SalePostService _postService;
  ScrollController? _scrollController;
  
  List<SalePost> _myPosts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMore = true;
  String? _currentStatusFilter;
  Map<String, int> _stats = {
    'total': 0,
    'active': 0,
    'sold': 0,
    'pending': 0,
  };

  @override
  void initState() {
    super.initState();
    _postService = SalePostService(baseUrl: ApiService.baseUrl);
    _scrollController = ScrollController();
    
    // Initialize tab controller with 4 filter tabs
    _tabController = TabController(length: 4, vsync: this);
    
    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    
    // Add scroll listener for pagination
    _scrollController?.addListener(_onScroll);
    
    // Fetch initial data and stats
    _fetchMyPosts();
    _fetchAllStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    print('Tab changed to index: $index');
    // Set the status filter based on tab index
    String? newFilter;
    switch (index) {
      case 0:
        newFilter = null; // All
        break;
      case 1:
        newFilter = 'active';
        break;
      case 2:
        newFilter = 'sold';
        break;
      case 3:
        newFilter = 'pending';
        break;
    }
    
    // Only fetch if filter actually changed
    if (newFilter != _currentStatusFilter) {
      setState(() {
        _currentStatusFilter = newFilter;
      });
      print('Fetching posts with filter: $_currentStatusFilter');
      _fetchMyPosts(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController != null && 
        _scrollController!.position.pixels >= _scrollController!.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _fetchMyPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _myPosts.clear();
        _hasMore = true;
      });
    }
    
    setState(() => _isLoading = true);

    try {
      final response = await _postService.fetchMyPosts(
        page: _currentPage,
        pageSize: 20,
        status: _currentStatusFilter,
      );
      
      if (mounted) {
        setState(() {
          _myPosts = response.results;
          _totalCount = response.count;
          _hasMore = response.next != null;
          _calculateStats();
          _isLoading = false;
        });
        // Refresh stats when fetching posts
        if (refresh) {
          _fetchAllStats();
        }
      }
    } catch (e) {
      print('Error fetching my posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final response = await _postService.fetchMyPosts(
        page: nextPage,
        pageSize: 20,
        status: _currentStatusFilter,
      );

      if (mounted) {
        setState(() {
          _myPosts.addAll(response.results);
          _currentPage = nextPage;
          _totalCount = response.count;
          _hasMore = response.next != null;
          _calculateStats();
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more posts: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _calculateStats() {
    // When viewing filtered results, we need to fetch counts for all statuses
    // For now, calculate from current page - ideally should call API for accurate counts
    if (_currentStatusFilter == null) {
      // On "All" tab, we have all posts
      _stats['total'] = _totalCount;
      _stats['active'] = _myPosts.where((p) => p.status == 'active').length;
      _stats['sold'] = _myPosts.where((p) => p.status == 'sold').length;
      _stats['pending'] = _myPosts.where((p) => p.status == 'pending').length;
    } else {
      // On filtered tabs, totalCount represents filtered count
      // Keep previous stats but update the current filter's count
      switch (_currentStatusFilter) {
        case 'active':
          _stats['active'] = _totalCount;
          break;
        case 'sold':
          _stats['sold'] = _totalCount;
          break;
        case 'pending':
          _stats['pending'] = _totalCount;
          break;
      }
    }
  }
  
  Future<void> _fetchAllStats() async {
    // Fetch counts for each status to display in tabs
    try {
      final allResponse = await _postService.fetchMyPosts(page: 1, pageSize: 1, status: null);
      final activeResponse = await _postService.fetchMyPosts(page: 1, pageSize: 1, status: 'active');
      final soldResponse = await _postService.fetchMyPosts(page: 1, pageSize: 1, status: 'sold');
      final pendingResponse = await _postService.fetchMyPosts(page: 1, pageSize: 1, status: 'pending');
      
      if (mounted) {
        setState(() {
          _stats['total'] = allResponse.count;
          _stats['active'] = activeResponse.count;
          _stats['sold'] = soldResponse.count;
          _stats['pending'] = pendingResponse.count;
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981); // Green
      case 'pending':
        return Colors.orange; // Orange
      case 'sold':
        return Colors.blue; // Blue
      case 'expired':
        return Colors.red; // Red
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'sold':
        return Icons.shopping_bag;
      case 'expired':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'sold':
        return 'Sold';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##,###');
    return '৳${formatter.format(price)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'My Sale Posts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sale');
            },
            icon: const Icon(Icons.storefront_outlined, size: 20),
            tooltip: 'Marketplace',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              foregroundColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.all_inclusive, size: 16),
                    text: 'All (${_stats['total']})',
                    height: 48,
                  ),
                  Tab(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    text: 'Active (${_stats['active']})',
                    height: 48,
                  ),
                  Tab(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    text: 'Sold (${_stats['sold']})',
                    height: 48,
                  ),
                  Tab(
                    icon: const Icon(Icons.schedule, size: 16),
                    text: 'Pending (${_stats['pending']})',
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildMyPostsTab(), // All
                _buildMyPostsTab(), // Active
                _buildMyPostsTab(), // Sold
                _buildMyPostsTab(), // Pending
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create-sale-post');
          if (result == true) {
            // Refresh the list after creating a post
            _fetchMyPosts(refresh: true);
          }
        },
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMyPostsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.add_shopping_cart_outlined,
                    size: 50,
                    color: const Color(0xFF10B981).withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Posts Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start selling by creating your first post',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildPostSaleModal(),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(
                  'Create First Post',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchMyPosts(refresh: true),
      color: const Color(0xFF10B981),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 20),
        itemCount: _myPosts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _myPosts.length) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(0xFF10B981),
                strokeWidth: 3,
              ),
            );
          }
          return _buildPostCard(_myPosts[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(SalePost post) {
    final imageUrl = post.images != null && post.images!.isNotEmpty
        ? post.images![0].image
        : 'https://via.placeholder.com/300x200?text=No+Image';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/sale/detail',
              arguments: {'slug': post.slug, 'id': post.id},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Image
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade50,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade50,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              
                // Details
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
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Price, View Count, and Date in same row
                      Row(
                        children: [
                          // Price on the left
                          Text(
                            _formatPrice(post.price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const Spacer(),
                          // View Count and Date on the right
                          Icon(Icons.remove_red_eye_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            '${post.viewsCount}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(post.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action Row: Mark as Sold | Edit | Delete | Status
                      Row(
                        children: [
                          // Mark as Sold Button (only for active posts)
                          if (post.status == 'active') ...[
                            GestureDetector(
                              onTap: () => _markAsSold(post),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag,
                                      color: Colors.blue.shade700,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Mark Sold',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Edit Button
                          GestureDetector(
                            onTap: () => _editPost(post),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.blue.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue.shade700,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Delete Button
                          GestureDetector(
                            onTap: () => _deletePost(post),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade700,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(post.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _getStatusColor(post.status),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(post.status),
                                  size: 10,
                                  color: _getStatusColor(post.status),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _getStatusText(post.status),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _getStatusColor(post.status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildPostSaleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF10B981).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create New Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Share what you want to sell',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Features List
          _buildFeatureItem(
            icon: Icons.camera_alt_outlined,
            title: 'Upload Photos',
            description: 'Add clear images of your product',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            icon: Icons.description_outlined,
            title: 'Product Details',
            description: 'Describe your item in detail',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            icon: Icons.attach_money,
            title: 'Set Price',
            description: 'Choose your selling price',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            icon: Icons.location_on_outlined,
            title: 'Add Location',
            description: 'Let buyers know where you are',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 20),
          
          // Coming Soon Notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 32,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'re working on this feature',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSaleModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: _buildPostSaleTab(),
    );
  }

  void _editPost(SalePost post) {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit post: ${post.title}')),
    );
  }

  void _togglePostStatus(SalePost post) async {
    // Toggle between 'active' and 'pending' status
    // If post is 'active', set to 'pending' (deactivate)
    // If post is 'pending', set to 'active' (activate)
    final newStatus = post.status == 'active' ? 'pending' : 'active';
    final isActivating = newStatus == 'active';
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(isActivating ? 'Activating...' : 'Deactivating...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final updatedPost = await _postService.updatePost(
        post.slug,
        {'status': newStatus},
      );

      if (updatedPost != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  isActivating ? 'Post activated successfully' : 'Post deactivated successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh the list
        _fetchMyPosts(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text(
                  'Failed to update post status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _markAsSold(SalePost post) async {
    print('Attempting to mark post as sold. Slug: ${post.slug}, Status: ${post.status}');
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Marking as sold...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final updatedPost = await _postService.markAsSold(post.slug);
      print('Mark as sold result: ${updatedPost != null ? "Success" : "Failed"}');

      if (updatedPost != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text(
                  'Post marked as sold successfully',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh the list
        _fetchMyPosts(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text(
                  'Failed to mark post as sold',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _deletePost(SalePost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _postService.deletePost(post.slug);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Post deleted successfully',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _fetchMyPosts(refresh: true);
      }
    }
  }
}
