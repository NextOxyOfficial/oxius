import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/business_network/business_network_header.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class BusinessNetworkScreen extends StatefulWidget {
  const BusinessNetworkScreen({super.key});

  @override
  State<BusinessNetworkScreen> createState() => _BusinessNetworkScreenState();
}

class _BusinessNetworkScreenState extends State<BusinessNetworkScreen> {
  List<BusinessNetworkPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _lastCreatedAt;
  int _currentNavIndex = 0;
  String? _errorMessage;
  
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
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
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: BusinessNetworkHeader(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onSearchTap: () {
          // TODO: Implement search
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
      drawer: isMobile ? _buildDrawer() : null,
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
                        itemCount: _posts.length + 1, // +1 for loading/end indicator
                        itemBuilder: (context, index) {
                          // Show loading or end indicator after all posts
                          if (index >= _posts.length) {
                            if (_isLoadingMore) {
                              return _buildLoadingMoreIndicator();
                            } else if (!_hasMore && _posts.isNotEmpty) {
                              return _buildEndOfFeedIndicator();
                            }
                            return const SizedBox(height: 80);
                          }
                          
                          // Show post card
                          return PostCard(
                            post: _posts[index],
                            onLikeToggle: () => _handleLikeToggle(index),
                            onCommentAdded: (comment) => _handleCommentAdded(index, comment),
                            onPostDeleted: () => _handlePostDeleted(index),
                          );
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
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 32, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Business Network',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: Color(0xFF3B82F6)),
            title: const Text('Recent'),
            onTap: () {
              Navigator.pop(context);
              _handleNavTap(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Color(0xFF3B82F6)),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              _handleNavTap(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF3B82F6)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              _handleNavTap(2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _handleNavTap(int index) {
    setState(() => _currentNavIndex = index);
    
    switch (index) {
      case 0:
        // Recent - already on this screen
        _refreshPosts();
        break;
      case 1:
        // Notifications
        // TODO: Navigate to notifications
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
          );
        }
        break;
      case 4:
        // AdsyClub / Home - Navigate to public homepage
        // Pop all routes to go back to home
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
    }
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
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
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
