import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../utils/network_error_handler.dart';
import '../../services/notification_service.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/workspace_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/business_network/qr_code_modal.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/diamond_purchase_bottom_sheet.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import '../adsy_connect_chat_interface.dart';
import '../workspace/gig_detail_screen.dart';
import 'profile_options.dart';

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
  List<Map<String, dynamic>> _userGigs = [];
  bool _isFollowing = false;
  bool _followLoading = false;
  int _currentNavIndex = 3; // Profile tab is index 3
  int _unreadNotificationCount = 0;
  bool _isLoadingSaved = false;
  bool _isLoadingGigs = false;
  bool _isContactInfoExpanded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WorkspaceService _workspaceService = WorkspaceService();
  
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  final List<Tab> _tabs = const [
    Tab(text: 'Posts'),
    Tab(text: 'My Workspace'),
    Tab(text: 'Media'),
    Tab(text: 'Saved'),
  ];

  /// Mask phone number based on privacy setting
  String _maskPhoneNumber(String phone, bool? isPublic) {
    if (isPublic == true) return phone;
    
    // Show first 3 digits and last 2 digits, mask the rest
    if (phone.length <= 5) return phone;
    
    final first = phone.substring(0, 3);
    final last = phone.substring(phone.length - 2);
    final masked = 'X' * (phone.length - 5);
    
    return '$first$masked$last';
  }
  
  /// Mask email based on privacy setting
  String _maskEmail(String email, bool? isPublic) {
    if (isPublic == true) return email;
    
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    // Show first 2 characters of username, mask the rest
    if (username.length <= 2) {
      return '${username}XXX@$domain';
    }
    
    final visiblePart = username.substring(0, 2);
    final masked = 'X' * (username.length - 2);
    
    return '$visiblePart$masked@$domain';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadProfileData();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    if (!AuthService.isAuthenticated) return;
    
    try {
      final result = await NotificationService.getNotifications(page: 1);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = result['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  void _handleTabChange() {
    // Update immediately when tab changes
    if (_tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      // Load gigs when My Workspace tab is selected (index 1)
      if (_currentTabIndex == 1 && _userGigs.isEmpty && !_isLoadingGigs) {
        _loadUserGigs();
      }
      // Load saved posts when Saved tab is selected (index 3)
      if (_currentTabIndex == 3 && _savedPosts.isEmpty && !_isLoadingSaved) {
        _loadSavedPosts();
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
          final posts = postsResult['posts'] as List<BusinessNetworkPost>;
          _isFollowing = userData['is_following'] ?? false;
          
          // Update all posts to reflect current follow status
          _userPosts = posts.map((post) {
            return post.copyWith(
              user: BusinessNetworkUser(
                id: post.user.id,
                uuid: post.user.uuid,
                name: post.user.name,
                avatar: post.user.avatar,
                image: post.user.image,
                isVerified: post.user.isVerified,
                bio: post.user.bio,
                username: post.user.username,
                firstName: post.user.firstName,
                lastName: post.user.lastName,
                isFollowing: _isFollowing, // Set to profile follow status
              ),
            );
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Use NetworkErrorHandler for professional error display
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          onRetry: () => _loadProfileData(),
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
        // Use NetworkErrorHandler for professional error display
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          onRetry: () => _loadSavedPosts(),
        );
      }
    }
  }

  Future<void> _loadUserGigs() async {
    setState(() => _isLoadingGigs = true);

    try {
      final result = await _workspaceService.fetchUserGigs(widget.userId);
      
      if (mounted) {
        setState(() {
          _userGigs = result['results'] as List<Map<String, dynamic>>;
          _isLoadingGigs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGigs = false);
        // Use NetworkErrorHandler for professional error display
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          onRetry: () => _loadUserGigs(),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    
    setState(() => _followLoading = true);
    
    try {
      final wasFollowing = _isFollowing; // Store original state
      
      print('=== Toggle Follow ===');
      print('User ID: ${widget.userId}');
      print('Was Following: $wasFollowing');
      
      final success = wasFollowing
          ? await BusinessNetworkService.unfollowUser(widget.userId)
          : await BusinessNetworkService.followUser(widget.userId);
      
      print('Success: $success');
      
      if (success && mounted) {
        setState(() {
          _isFollowing = !wasFollowing;
          // Update follower count using original state
          if (_userData != null) {
            final currentCount = _userData!['followers_count'] ?? 0;
            _userData!['followers_count'] = wasFollowing ? currentCount - 1 : currentCount + 1;
          }
          
          // Update all posts to reflect new follow status
          _userPosts = _userPosts.map((post) {
            return post.copyWith(
              user: BusinessNetworkUser(
                id: post.user.id,
                uuid: post.user.uuid,
                name: post.user.name,
                avatar: post.user.avatar,
                image: post.user.image,
                isVerified: post.user.isVerified,
                bio: post.user.bio,
                username: post.user.username,
                firstName: post.user.firstName,
                lastName: post.user.lastName,
                isFollowing: _isFollowing, // Update to new follow status
              ),
            );
          }).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Following ${_userData?['name']}' : 'Unfollowed ${_userData?['name']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${wasFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Use NetworkErrorHandler for professional error display
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          customMessage: 'Unable to update follow status',
          onRetry: () => _toggleFollow(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _followLoading = false);
      }
    }
  }

  Future<void> _openChatWithUser() async {
    if (_userData == null) return;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get or create chatroom with the profile user
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(widget.userId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Open chat bottom sheet
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: AdsyConnectChatInterface(
                chatroomId: chatroom['id'].toString(),
                userId: widget.userId,
                userName: _userData!['first_name'] != null && _userData!['last_name'] != null
                    ? '${_userData!['first_name']} ${_userData!['last_name']}'
                    : _userData!['username'] ?? 'User',
                userAvatar: _userData?['image'] ?? _userData?['profile_picture'] ?? _userData?['avatar'],
                profession: _userData!['profession'],
                isOnline: false,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        // Use NetworkErrorHandler for professional error display
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          customMessage: 'Unable to open chat',
        );
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
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Upload to server (pass XFile directly for cross-platform support)
      final success = await BusinessNetworkService.uploadProfilePicture(image);
      
      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Reload profile data to show new image
          _loadProfileData();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Use NetworkErrorHandler for professional error display
        NetworkErrorHandler.showErrorSnackbar(
          context, 
          e,
          customMessage: 'Unable to upload profile picture',
        );
      }
    }
  }

  void _showProfilePictureViewer() {
    if (_userData?['image'] == null) return;
    
    final userName = _userData?['first_name'] != null && _userData?['last_name'] != null
        ? '${_userData!['first_name']} ${_userData!['last_name']}'
        : _userData?['username'] ?? 'User';
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen image with zoom
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    _userData!['image'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Header with close button and name
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: BusinessNetworkHeader(
        onMenuTap: () {
          if (isMobile) {
            // Delay to ensure Scaffold is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scaffoldKey.currentState != null) {
                _scaffoldKey.currentState!.openDrawer();
              }
            });
          } else {
            Navigator.pop(context);
          }
        },
        onSearchTap: () {
          // TODO: Implement search
        },
        onProfileTap: () {
          // Already on profile page
        },
      ),
      drawer: isMobile ? BusinessNetworkDrawer(currentRoute: '/business-network/profile/${widget.userId}') : null,
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
                        
                        // Gold Sponsors Slider
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: GoldSponsorsSlider(),
                        ),
                        
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
              isLoggedIn: AuthService.isAuthenticated,
              onTap: _handleNavTap,
              unreadCount: _unreadNotificationCount,
            )
          : null,
    );
  }

  void _handleNavTap(int index) {
    if (index == _currentNavIndex && index != 3) return; // Already on profile
    
    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/business-network',
          (route) => route.settings.name == '/',
        );
        break;
      case 1:
        // Notifications
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        ).then((_) {
          // Refresh notification count when returning
          _loadUnreadNotificationCount();
        });
        break;
      case 2:
        // Create Post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        );
        break;
      case 3:
        // Profile - Already here
        if (AuthService.isAuthenticated) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileOptionsScreen(),
            ),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub / Home - Navigate to main home screen
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
    }
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header skeleton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Avatar skeleton
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                // Name skeleton
                Container(
                  height: 20,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Username skeleton
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) => Column(
                    children: [
                      Container(
                        height: 18,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 16),
                // Button skeleton
                Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          
          // Posts skeleton
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Post content
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Name, Badges and Profession - Compact Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name with badges
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _userData?['first_name'] != null && _userData?['last_name'] != null
                                ? '${_userData!['first_name']} ${_userData!['last_name']}'
                                : _userData?['username'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_userData?['kyc'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ],
                        if (_userData?['is_pro'] == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pro',
                              style: TextStyle(
                                fontSize: 10,
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
                      const SizedBox(height: 2),
                      Text(
                        _userData!['profession'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Compact Profile Picture with tap to view
          GestureDetector(
            onTap: () => _showProfilePictureViewer(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade300,
                        Colors.indigo.shade400,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: _userData?['image'] != null
                          ? Image.network(
                              _userData!['image'],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                ),
                if (isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _handleProfilePictureUpload,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Compact Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Posts', _userData?['post_count'] ?? 0),
              Container(
                width: 1,
                height: 28,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStatItem('Followers', _userData?['followers_count'] ?? 0, onTap: () => _showFollowersFollowingSheet('followers')),
              Container(
                width: 1,
                height: 28,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStatItem('Following', _userData?['following_count'] ?? 0, onTap: () => _showFollowersFollowingSheet('following')),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons - Pill Style (matching Vue design)
          _buildActionButtonsRow(isOwnProfile),
          
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
                    DiamondPurchaseBottomSheet.show(
                      context,
                      onPurchaseSuccess: () {
                        setState(() {
                          _loadProfileData();
                        });
                      },
                    );
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

  Widget _buildStatItem(String label, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: onTap != null ? const Color(0xFF8B5CF6) : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons row with pill-style design (matching Vue)
  Widget _buildActionButtonsRow(bool isOwnProfile) {
    final isLoggedIn = AuthService.currentUser != null;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(50),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR Code Button
          _buildPillButton(
            icon: Icons.qr_code_2_rounded,
            label: 'QR Code',
            onTap: () {
              if (_userData != null) {
                showDialog(
                  context: context,
                  builder: (context) => QrCodeModal(user: _userData!),
                );
              }
            },
            showBorder: true,
          ),
          
          // Chat Button (only for other profiles when logged in)
          if (!isOwnProfile && isLoggedIn) ...[
            _buildPillButton(
              customIcon: Image.asset(
                'assets/images/chat_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.teal.shade600);
                },
              ),
              label: 'Chat',
              labelFirst: true,
              onTap: () => _openChatWithUser(),
              showBorder: true,
            ),
          ],
          
          // Follow/Following Button (only for other profiles when logged in)
          if (!isOwnProfile && isLoggedIn)
            _buildPillButton(
              icon: _isFollowing ? Icons.check_rounded : Icons.person_add_outlined,
              label: _isFollowing ? 'Following' : 'Follow',
              onTap: _followLoading ? null : _toggleFollow,
              isLoading: _followLoading,
              isActive: !_isFollowing,
              showBorder: false,
            ),
        ],
      ),
    );
  }

  /// Build individual pill button
  Widget _buildPillButton({
    IconData? icon,
    Widget? customIcon,
    String? label,
    VoidCallback? onTap,
    bool showBorder = false,
    bool isLoading = false,
    bool isActive = false,
    bool labelFirst = false,
  }) {
    final labelWidget = label != null
        ? Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          )
        : null;

    final iconWidget = isLoading
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
            ),
          )
        : customIcon ?? (icon != null
            ? Icon(
                icon,
                size: 18,
                color: Colors.grey.shade700,
              )
            : null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(right: BorderSide(color: Colors.grey.shade200))
              : null,
          color: isActive ? const Color(0xFFF3F4F6) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (labelFirst && labelWidget != null) ...[
              labelWidget,
              if (iconWidget != null) const SizedBox(width: 5),
            ],
            if (iconWidget != null) iconWidget,
            if (!labelFirst && labelWidget != null) ...[
              const SizedBox(width: 5),
              labelWidget,
            ],
          ],
        ),
      ),
    );
  }

  void _showFollowersFollowingSheet(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FollowersFollowingSheet(
        userId: widget.userId,
        type: type,
        onUserTap: (userId) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
          );
        },
      ),
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
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
          
          // My Workspace Tab
          _buildWorkspaceTab(),
          
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

  Widget _buildWorkspaceTab() {
    if (_isLoadingGigs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      );
    }
    
    if (_userGigs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Gigs Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user hasn\'t created any gigs yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _userGigs.length,
      itemBuilder: (context, index) {
        final gig = _userGigs[index];
        return _buildGigCard(gig);
      },
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final title = gig['title'] ?? 'Untitled Gig';
    final price = gig['price']?.toString() ?? '0';
    final currency = gig['currency'] ?? 'BDT';
    final thumbnail = gig['thumbnail'];
    final rating = (gig['average_rating'] ?? 0.0).toDouble();
    final ordersCount = gig['orders_count'] ?? 0;

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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 55,
                  height: 55,
                  child: thumbnail != null
                      ? Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.work_outline, color: Colors.grey[400], size: 24),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.work_outline, color: Colors.grey[400], size: 24),
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
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // Stats row
                    Row(
                      children: [
                        // Rating
                        const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Orders
                        Text(
                          '$ordersCount sold',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Price
                        Text(
                          '$currency $price',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
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
        if ((_userData?['city'] != null && _userData!['city'].toString().trim().isNotEmpty) || 
            (_userData?['state'] != null && _userData!['state'].toString().trim().isNotEmpty))
          _buildContactItem(
            Icons.location_on,
            '${_userData?['city'] ?? ''}${_userData?['city'] != null && _userData?['state'] != null ? ', ' : ''}${_userData?['state'] ?? ''}',
            Colors.blue.shade500,
          ),
        
        if (_userData?['company'] != null && _userData!['company'].toString().trim().isNotEmpty)
          _buildContactItem(
            Icons.business,
            _userData!['company'],
            Colors.purple.shade500,
          ),
        
        // Email (with privacy masking)
        if (_userData?['email'] != null && _userData!['email'].toString().trim().isNotEmpty)
          _buildContactItem(
            Icons.email,
            _maskEmail(_userData!['email'], _userData?['email_public']),
            Colors.orange.shade600,
          ),
        
        // Phone (with privacy masking)
        if (_userData?['phone'] != null && _userData!['phone'].toString().trim().isNotEmpty)
          _buildContactItem(
            Icons.phone,
            _maskPhoneNumber(_userData!['phone'], _userData?['phone_public']),
            Colors.red.shade500,
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
                _isContactInfoExpanded = !_isContactInfoExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _isContactInfoExpanded
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

class _FollowersFollowingSheet extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final Function(String userId) onUserTap;

  const _FollowersFollowingSheet({
    required this.userId,
    required this.type,
    required this.onUserTap,
  });

  @override
  State<_FollowersFollowingSheet> createState() => _FollowersFollowingSheetState();
}

class _FollowersFollowingSheetState extends State<_FollowersFollowingSheet> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    final result = widget.type == 'followers'
        ? await BusinessNetworkService.getUserFollowers(widget.userId, page: _page)
        : await BusinessNetworkService.getUserFollowing(widget.userId, page: _page);
    
    if (mounted) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(result['results'] ?? []);
        _hasMore = result['next'] != null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    _page++;
    
    final result = widget.type == 'followers'
        ? await BusinessNetworkService.getUserFollowers(widget.userId, page: _page)
        : await BusinessNetworkService.getUserFollowing(widget.userId, page: _page);
    
    if (mounted) {
      setState(() {
        _users.addAll(List<Map<String, dynamic>>.from(result['results'] ?? []));
        _hasMore = result['next'] != null;
      });
    }
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'http://127.0.0.1:8000$url';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle + Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.type == 'followers' ? 'Followers' : 'Following',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${_users.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // User List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3B82F6)),
                    ),
                  )
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              widget.type == 'followers' ? 'No followers yet' : 'Not following anyone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _users.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _users.length) {
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF3B82F6)),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          final user = _users[index];
                          // API returns follower_details/following_details
                          final userData = widget.type == 'followers' 
                              ? user['follower_details'] ?? user['follower'] ?? user 
                              : user['following_details'] ?? user['following'] ?? user;
                          
                          // Get user image
                          final String? userImage = userData['image']?.toString();
                          final bool hasImage = userImage != null && userImage.isNotEmpty;
                          
                          // Get display name
                          String displayName = 'Unknown';
                          if (userData['first_name'] != null && userData['first_name'].toString().isNotEmpty) {
                            displayName = userData['first_name'].toString();
                            if (userData['last_name'] != null && userData['last_name'].toString().isNotEmpty) {
                              displayName += ' ${userData['last_name']}';
                            }
                          } else if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
                            displayName = userData['name'].toString();
                          } else if (userData['username'] != null && userData['username'].toString().isNotEmpty) {
                            displayName = userData['username'].toString();
                          }
                          
                          // Get profession/headline
                          final String? profession = userData['profession']?.toString() ?? userData['headline']?.toString();
                          
                          return InkWell(
                            onTap: () => widget.onUserTap(userData['id']?.toString() ?? ''),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    backgroundImage: hasImage
                                        ? NetworkImage(_getImageUrl(userImage))
                                        : null,
                                    child: !hasImage
                                        ? Text(
                                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF6B7280),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  // Name & Profession
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.1,
                                                  color: Color(0xFF1F2937),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (userData['kyc'] == true)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 3),
                                                child: Icon(Icons.verified_rounded, size: 14, color: Color(0xFF3B82F6)),
                                              ),
                                            if (userData['is_pro'] == true)
                                              Container(
                                                margin: const EdgeInsets.only(left: 3),
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                                              ),
                                          ],
                                        ),
                                        if (profession != null && profession.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            profession,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Arrow
                                  Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
