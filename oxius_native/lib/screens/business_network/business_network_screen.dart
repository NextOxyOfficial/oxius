import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_suggestions_service.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import '../../widgets/business_network/user_suggestions_card.dart';
import '../../widgets/business_network/sponsored_products_card.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class BusinessNetworkScreen extends StatefulWidget {
  const BusinessNetworkScreen({super.key});

  @override
  State<BusinessNetworkScreen> createState() => _BusinessNetworkScreenState();
}

class _BusinessNetworkScreenState extends State<BusinessNetworkScreen> {
  List<BusinessNetworkPost> _posts = [];
  List<Map<String, dynamic>> _sponsoredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _lastCreatedAt;
  int _currentNavIndex = 0;
  String? _errorMessage;
  
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadSponsoredProducts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSponsoredProducts() async {
    try {
      final products = await UserSuggestionsService.getSponsoredProducts(limit: 20);
      if (mounted) {
        setState(() {
          _sponsoredProducts = products;
        });
      }
    } catch (e) {
      print('Error loading sponsored products: $e');
    }
  }

  List<Map<String, dynamic>> _getRandomProducts(int count) {
    if (_sponsoredProducts.isEmpty) return [];
    
    final shuffled = List<Map<String, dynamic>>.from(_sponsoredProducts)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  int _calculateTotalItems() {
    int total = _posts.length + 1; // +1 for gold sponsors at top
    
    // Add user suggestions cards (every 10th post)
    final suggestionsCount = (_posts.length / 10).floor();
    total += suggestionsCount;
    
    // Add sponsored product cards (every 5th post)
    final productsCount = (_posts.length / 5).floor();
    total += productsCount;
    
    // +1 for loading/end indicator
    total += 1;
    
    return total;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await BusinessNetworkService.getPosts(page: 1, pageSize: 5);
    
    if (mounted) {
      setState(() {
        _posts = result['posts'] as List<BusinessNetworkPost>;
        _hasMore = result['hasMore'] as bool;
        _isLoading = false;
        
        // Check for errors
        if (result.containsKey('error')) {
          if (result['error'] == 'unauthorized') {
            _errorMessage = 'Please log in to view business network posts';
          } else {
            _errorMessage = 'Failed to load posts. Please try again.';
          }
        }
        
        if (_posts.isNotEmpty) {
          _lastCreatedAt = _posts.last.createdAt;
        }
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    _currentPage++;
    final result = await BusinessNetworkService.getPosts(
      page: _currentPage,
      pageSize: 5,
      olderThan: _lastCreatedAt,
    );
    
    if (mounted) {
      final newPosts = result['posts'] as List<BusinessNetworkPost>;
      setState(() {
        if (newPosts.isNotEmpty) {
          _posts.addAll(newPosts);
          _lastCreatedAt = newPosts.last.createdAt;
        }
        _hasMore = result['hasMore'] as bool;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    _currentPage = 1;
    _lastCreatedAt = null;
    await _loadPosts();
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    ).then((newPost) {
      if (newPost != null && newPost is BusinessNetworkPost) {
        setState(() {
          _posts.insert(0, newPost);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: BusinessNetworkHeader(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onSearchTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
            ),
          );
        },
        onQRCodeTap: () {
          // TODO: Show QR code modal
        },
        onProfileTap: () {
          final currentUser = AuthService.currentUser;
          if (currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: currentUser.id),
              ),
            );
          }
        },
      ),
      drawer: isMobile ? const BusinessNetworkDrawer(currentRoute: '/business-network') : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672), // max-w-3xl (768px - padding)
          child: RefreshIndicator(
            onRefresh: _refreshPosts,
            color: const Color(0xFF3B82F6),
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _posts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(4, 8, 4, isMobile ? 80 : 16),
                        itemCount: _calculateTotalItems(),
                        itemBuilder: (context, index) {
                          return _buildFeedItem(index);
                        },
                      ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? BusinessNetworkBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                if (index == 2) {
                  // Create post button
                  _openCreatePost();
                } else {
                  _handleNavTap(index);
                }
              },
              unreadCount: 0, // TODO: Get actual unread count from notifications
            )
          : null,
      floatingActionButton: !isMobile
          ? FloatingActionButton(
              onPressed: _openCreatePost,
              backgroundColor: const Color(0xFF3B82F6),
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      ),
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Recent - already on this screen, refresh
        setState(() => _currentNavIndex = 0);
        _refreshPosts();
        break;
      case 1:
        // Notifications
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        ).then((_) {
          // Reset index when coming back
          if (mounted) setState(() => _currentNavIndex = 0);
        });
        break;
      case 3:
        // Profile
        final currentUser = AuthService.currentUser;
        if (currentUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: currentUser.id),
            ),
          ).then((_) {
            // Reset index when coming back
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        } else {
          // Navigate to login if not authenticated
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub / Home - Navigate to main home screen
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
    }
  }

  Widget _buildFeedItem(int index) {
    // Show Gold Sponsors at the top (index 0)
    if (index == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: GoldSponsorsSlider(),
      );
    }

    // Calculate actual post position considering injected cards
    int currentPostCount = 0;
    int currentIndex = 1; // Start after gold sponsors
    
    for (int i = 0; i < _posts.length; i++) {
      // Check if we should inject user suggestions (every 10th post)
      if (i > 0 && i % 10 == 0) {
        if (currentIndex == index) {
          return const UserSuggestionsCard();
        }
        currentIndex++;
      }
      
      // Check if we should inject sponsored products (every 5th post)
      if (i > 0 && i % 5 == 0 && i % 10 != 0) { // Don't overlap with suggestions
        if (currentIndex == index) {
          return SponsoredProductsCard(
            products: _getRandomProducts(3),
          );
        }
        currentIndex++;
      }
      
      // Show the post
      if (currentIndex == index) {
        return PostCard(
          post: _posts[i],
          onLikeToggle: () => _handleLikeToggle(i),
          onCommentAdded: (comment) => _handleCommentAdded(i, comment),
          onPostDeleted: () => _handlePostDeleted(i),
        );
      }
      currentIndex++;
      currentPostCount++;
    }
    
    // Show loading or end indicator after all posts
    if (_isLoadingMore) {
      return _buildLoadingMoreIndicator();
    } else if (!_hasMore && _posts.isNotEmpty) {
      return _buildEndOfFeedIndicator();
    }
    
    return const SizedBox(height: 80);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Posts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.business_center,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreatePost,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Column(
      children: List.generate(2, (index) => _buildSkeletonPost()),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              _buildShimmerBox(40, 40, borderRadius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(12, 120),
                    const SizedBox(height: 6),
                    _buildShimmerBox(10, 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content skeleton
          _buildShimmerBox(14, double.infinity),
          const SizedBox(height: 6),
          _buildShimmerBox(14, double.infinity),
          const SizedBox(height: 6),
          _buildShimmerBox(14, 200),
          
          const SizedBox(height: 12),
          
          // Image skeleton
          _buildShimmerBox(180, double.infinity, borderRadius: 8),
          
          const SizedBox(height: 12),
          
          // Actions skeleton
          Row(
            children: [
              _buildShimmerBox(28, 60, borderRadius: 6),
              const SizedBox(width: 12),
              _buildShimmerBox(28, 60, borderRadius: 6),
              const Spacer(),
              _buildShimmerBox(28, 60, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double height, double width, {double? borderRadius}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1.0, 0.0),
          end: Alignment(1.0, 0.0),
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
      ),
    );
  }

  Widget _buildEndOfFeedIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ve seen all posts',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _handleLikeToggle(int index) async {
    final post = _posts[index];
    final success = await BusinessNetworkService.toggleLike(post.id, post.isLiked);
    
    if (success && mounted) {
      setState(() {
        _posts[index] = post.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
      });
    }
  }

  void _handleCommentAdded(int index, BusinessNetworkComment comment) {
    if (mounted) {
      setState(() {
        final post = _posts[index];
        _posts[index] = post.copyWith(
          commentsCount: post.commentsCount + 1,
          comments: [...post.comments, comment],
        );
      });
    }
  }

  void _handlePostDeleted(int index) {
    if (mounted) {
      setState(() {
        _posts.removeAt(index);
      });
    }
  }
}
