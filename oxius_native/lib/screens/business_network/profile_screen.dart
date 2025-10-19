import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<BusinessNetworkPost> _userPosts = [];
  List<BusinessNetworkPost> _savedPosts = [];
  bool _isFollowing = false;
  bool _followLoading = false;
  int _currentNavIndex = 3; // Profile tab is index 3
  bool _isLoadingSaved = false;
  bool _isContactInfoExpanded = false;
  
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  final List<Tab> _tabs = const [
    Tab(text: 'Posts'),
    Tab(text: 'Media'),
    Tab(text: 'Saved'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Load saved posts when Saved tab is selected
        if (_currentTabIndex == 2 && _savedPosts.isEmpty && !_isLoadingSaved) {
          _loadSavedPosts();
        }
      }
    });
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user profile data
      final userData = await BusinessNetworkService.getUserProfile(widget.userId);
      
      // Load user posts
      final postsResult = await BusinessNetworkService.getUserPosts(widget.userId);
      
      if (mounted) {
        setState(() {
          _userData = userData;
          _userPosts = postsResult['posts'] as List<BusinessNetworkPost>;
          _isFollowing = userData?['is_following'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSavedPosts() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || widget.userId != currentUser.id) {
      // Only load saved posts for own profile
      return;
    }

    setState(() => _isLoadingSaved = true);

    try {
      final savedPosts = await BusinessNetworkService.getSavedPosts();
      
      if (mounted) {
        setState(() {
          _savedPosts = savedPosts;
          _isLoadingSaved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading saved posts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    
    setState(() => _followLoading = true);
    
    try {
      final success = _isFollowing
          ? await BusinessNetworkService.unfollowUser(widget.userId)
          : await BusinessNetworkService.followUser(widget.userId);
      
      if (success && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          // Update follower count
          if (_userData != null) {
            final currentCount = _userData!['followers_count'] ?? 0;
            _userData!['followers_count'] = _isFollowing ? currentCount + 1 : currentCount - 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _followLoading = false);
      }
    }
  }

  Future<void> _handleProfilePictureUpload() async {
    try {
      // Show options: Camera or Gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF3B82F6)),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading profile picture...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // TODO: Upload to server
      // final success = await BusinessNetworkService.uploadProfilePicture(File(image.path));
      
      // For now, just show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture upload feature coming soon!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: BusinessNetworkHeader(
        onMenuTap: () => Navigator.pop(context),
        onSearchTap: () {
          // TODO: Implement search
        },
        onQRCodeTap: () {
          // TODO: Show QR code modal
        },
        onProfileTap: () {
          // Already on profile page
        },
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: const Color(0xFF3B82F6),
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      children: [
                        // Profile Header
                        _buildProfileHeader(isOwnProfile),
                        
                        const SizedBox(height: 16),
                        
                        // Tabs
                        _buildTabs(),
                        
                        // Tab Content
                        _buildTabContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 768
          ? BusinessNetworkBottomNavBar(
              currentIndex: _currentNavIndex,
              onTap: _handleNavTap,
              unreadCount: 0,
            )
          : null,
    );
  }

  void _handleNavTap(int index) {
    if (index == _currentNavIndex) return; // Already on profile
    
    setState(() => _currentNavIndex = index);
    
    switch (index) {
      case 0:
        // Recent - Navigate back to feed
        Navigator.pop(context);
        break;
      case 1:
        // Notifications
        // TODO: Navigate to notifications
        break;
      case 2:
        // Create Post
        // TODO: Navigate to create post
        break;
      case 3:
        // Profile - Already here
        break;
      case 4:
        // AdsyClub / Home
        // TODO: Navigate to home
        break;
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Name and Badges at Top
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  _userData?['first_name'] != null && _userData?['last_name'] != null
                      ? '${_userData!['first_name']} ${_userData!['last_name']}'
                      : _userData?['username'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_userData?['kyc'] == true) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
              ],
              if (_userData?['is_pro'] == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Pro',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          // Profession
          if (_userData?['profession'] != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _userData!['profession'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Centered Profile Picture
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade300,
                      Colors.indigo.shade400,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: _userData?['image'] != null
                        ? Image.network(
                            _userData!['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
              ),
              if (isOwnProfile)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: InkWell(
                    onTap: _handleProfilePictureUpload,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Posts', _userData?['post_count'] ?? 0),
              Container(
                width: 1,
                height: 32,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildStatItem('Followers', _userData?['followers_count'] ?? 0),
              Container(
                width: 1,
                height: 32,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildStatItem('Following', _userData?['following_count'] ?? 0),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // QR Code Button (Centered)
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Show QR code modal
            },
            icon: const Icon(Icons.qr_code, size: 16),
            label: const Text(
              'QR Code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          
          // Diamond Balance (for own profile)
          if (isOwnProfile && _userData?['diamond_balance'] != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond, color: Colors.pink.shade500, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_userData!['diamond_balance']} Diamonds',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Show diamond top-up modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade500,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                      const Text(
                        'Top Up',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          
          const SizedBox(height: 12),
          
          // Follow/Edit Profile Button (Full Width)
          if (!isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _followLoading ? null : _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing
                      ? Colors.grey.shade200
                      : const Color(0xFF3B82F6),
                  foregroundColor: _isFollowing
                      ? Colors.black87
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _followLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFollowing ? Icons.check : Icons.person_add,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          
          // Bio Section
          if (_userData?['about'] != null || isOwnProfile) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 10),
            Text(
              _userData?['about'] ?? 'No bio provided',
              style: TextStyle(
                fontSize: 13,
                color: _userData?['about'] != null ? Colors.black87 : Colors.grey.shade500,
                fontStyle: _userData?['about'] != null ? FontStyle.normal : FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          // Contact Info (without bottom divider)
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs,
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(bottom: 80),
      child: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Posts Tab
          _buildPostsTab(),
          
          // Media Tab
          _buildMediaTab(),
          
          // Saved Tab
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_userPosts.isEmpty) {
      return _buildEmptyState('No posts yet', Icons.post_add);
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: _userPosts[index],
          onLikeToggle: () {
            // TODO: Handle like toggle
          },
          onCommentAdded: (comment) {
            // TODO: Handle comment added
          },
          onPostDeleted: () {
            setState(() {
              _userPosts.removeAt(index);
            });
          },
        );
      },
    );
  }

  Widget _buildMediaTab() {
    // Collect all media from user posts
    final allMedia = <PostMedia>[];
    for (var post in _userPosts) {
      allMedia.addAll(post.media);
    }
    
    if (allMedia.isEmpty) {
      return _buildEmptyState('No media yet', Icons.photo_library);
    }
    
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: allMedia.length,
        itemBuilder: (context, index) {
          final media = allMedia[index];
          return InkWell(
            onTap: () {
              _showMediaViewer(allMedia, index);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  media.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade500,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMediaViewer(List<PostMedia> mediaList, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      mediaList[index].image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 64,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${initialIndex + 1} / ${mediaList.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedTab() {
    final currentUser = AuthService.currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;
    
    // Only show saved posts for own profile
    if (!isOwnProfile) {
      return _buildEmptyState('Saved posts are private', Icons.lock_outline);
    }
    
    if (_isLoadingSaved) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        ),
      );
    }
    
    if (_savedPosts.isEmpty) {
      return _buildEmptyState('No saved posts', Icons.bookmark_border);
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      itemCount: _savedPosts.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: _savedPosts[index],
          onLikeToggle: () {
            // Refresh saved posts if needed
          },
          onCommentAdded: (comment) {
            // Handle comment added
          },
          onPostDeleted: () {
            setState(() {
              _savedPosts.removeAt(index);
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final hasContactInfo = _userData?['city'] != null ||
        _userData?['state'] != null ||
        _userData?['company'] != null ||
        _userData?['email'] != null ||
        _userData?['phone'] != null ||
        _userData?['date_joined'] != null ||
        _userData?['website'] != null ||
        _userData?['whatsapp_link'] != null ||
        _userData?['instagram_link'] != null;

    if (!hasContactInfo) return const SizedBox.shrink();

    final hasAdditionalInfo = _userData?['email'] != null ||
        _userData?['phone'] != null ||
        _userData?['website'] != null ||
        _userData?['whatsapp_link'] != null ||
        _userData?['instagram_link'] != null ||
        _userData?['date_joined'] != null;

    final userName = _userData?['first_name'] ?? _userData?['username'] ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        
        // Always visible: Location, Company, and Joined Date
        if (_userData?['city'] != null || _userData?['state'] != null)
          _buildContactItem(
            Icons.location_on,
            '${_userData?['city'] ?? ''}${_userData?['city'] != null && _userData?['state'] != null ? ', ' : ''}${_userData?['state'] ?? ''}',
            Colors.blue.shade500,
          ),
        
        if (_userData?['company'] != null)
          _buildContactItem(
            Icons.business,
            _userData!['company'],
            Colors.purple.shade500,
          ),
        
        // Joined Date (always visible)
        if (_userData?['date_joined'] != null)
          _buildContactItem(
            Icons.calendar_today,
            'Joined ${_formatTimeAgo(_userData!['date_joined'])}',
            Colors.green.shade500,
          ),
        
        // Expandable section for additional details
        if (_isContactInfoExpanded == true) ...[
          // Email
          if (_userData?['email'] != null)
            _buildContactItem(
              Icons.email,
              _userData!['email'],
              Colors.orange.shade600,
            ),
          
          // Phone
          if (_userData?['phone'] != null)
            _buildContactItem(
              Icons.phone,
              _userData!['phone'],
              Colors.red.shade500,
            ),
          
          // Website
          if (_userData?['website'] != null && _userData!['website'].toString().isNotEmpty)
            _buildContactItem(
              Icons.link,
              _userData!['website'],
              Colors.blue.shade600,
            ),
          
          // WhatsApp
          if (_userData?['whatsapp_link'] != null && _userData!['whatsapp_link'].toString().isNotEmpty)
            _buildContactItem(
              Icons.message,
              _userData!['whatsapp_link'],
              Colors.green.shade600,
            ),
          
          // Instagram
          if (_userData?['instagram_link'] != null && _userData!['instagram_link'].toString().isNotEmpty)
            _buildContactItem(
              Icons.camera_alt,
              _userData!['instagram_link'],
              Colors.pink.shade600,
            ),
        ],
        
        // "See more about [Name]" button
        if (hasAdditionalInfo) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              setState(() {
                _isContactInfoExpanded = !(_isContactInfoExpanded ?? false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                (_isContactInfoExpanded ?? false)
                    ? 'Show less' 
                    : 'See more about $userName...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    if (_userData == null) return const SizedBox.shrink();
    
    // Only show website link
    if (_userData!['website'] == null || _userData!['website'].toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade200, height: 1),
        const SizedBox(height: 12),
        // Website - Show full URL with visit icon
        _buildWebsiteLink(
          _userData!['website'],
          Colors.blue.shade600,
        ),
      ],
    );
  }

  Widget _buildWebsiteLink(String url, Color color) {
    // Format URL for display (remove http/https and trailing slash)
    String displayUrl = url
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // TODO: Open website URL
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.link, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayUrl,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    String label,
    Color color,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else {
        return 'Recently';
      }
    } catch (e) {
      return '';
    }
  }
}
