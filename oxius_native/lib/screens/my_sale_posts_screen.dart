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
    
    // Initialize tab controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
    
    // Set initial tab based on parameter
    if (widget.initialTab == 'post-sale') {
      _tabController.index = 1;
    }
    
    // Add scroll listener for pagination
    _scrollController?.addListener(_onScroll);
    
    _fetchMyPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController?.dispose();
    super.dispose();
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
      );
      
      if (mounted) {
        setState(() {
          _myPosts = response.results;
          _totalCount = response.count;
          _hasMore = response.next != null;
          _calculateStats();
          _isLoading = false;
        });
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
    _stats['total'] = _totalCount; // Use total count from backend
    _stats['active'] = _myPosts.where((p) => p.isActive).length;
    _stats['sold'] = 0; // TODO: Add sold status to model
    _stats['pending'] = _myPosts.where((p) => !p.isActive).length;
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
          // Stats Section
          _buildStatsSection(),
          
          // Tabs
          Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 6),
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
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    text: 'My Posts (${_myPosts.length})',
                    height: 48,
                  ),
                  const Tab(
                    icon: Icon(Icons.add_circle_outline, size: 16),
                    text: 'Create Post',
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
              children: [
                _buildMyPostsTab(),
                _buildPostSaleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              _stats['total'].toString(),
              Icons.grid_view_rounded,
              const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Active',
              _stats['active'].toString(),
              Icons.trending_up,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Sold',
              _stats['sold'].toString(),
              Icons.sell_outlined,
              const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Pending',
              _stats['pending'].toString(),
              Icons.hourglass_empty,
              const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                  _tabController.animateTo(1);
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
                      // Price
                      Text(
                        _formatPrice(post.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Stats
                      Row(
                        children: [
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
                          Flexible(
                            child: Text(
                              _formatDate(post.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action Row: Activate/Deactivate | Edit | Delete | Status
                      Row(
                        children: [
                          // Activate/Deactivate Button
                          GestureDetector(
                            onTap: () => _togglePostStatus(post),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: post.isActive 
                                    ? Colors.orange.shade50 
                                    : const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: post.isActive 
                                      ? Colors.orange.shade300 
                                      : const Color(0xFF10B981),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    post.isActive ? Icons.toggle_off : Icons.toggle_on,
                                    size: 12,
                                    color: post.isActive ? Colors.orange.shade700 : const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.isActive ? 'Stop' : 'Activate',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: post.isActive ? Colors.orange.shade700 : const Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
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
                              color: post.isActive 
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: post.isActive 
                                    ? const Color(0xFF10B981)
                                    : Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  post.isActive ? Icons.check_circle : Icons.schedule,
                                  size: 10,
                                  color: post.isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  post.isActive ? 'Active' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: post.isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
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

  void _editPost(SalePost post) {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit post: ${post.title}')),
    );
  }

  void _togglePostStatus(SalePost post) async {
    final newStatus = !post.isActive;
    
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
            Text(newStatus ? 'Activating...' : 'Deactivating...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final updatedPost = await _postService.updatePost(
        post.id,
        {'is_active': newStatus},
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
                  newStatus ? 'Post activated successfully' : 'Post deactivated successfully',
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
      final success = await _postService.deletePost(post.id);
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
