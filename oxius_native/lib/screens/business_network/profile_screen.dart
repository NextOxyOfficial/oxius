import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../utils/image_compressor.dart';
import '../../utils/network_error_handler.dart';
import '../../services/notification_service.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/fcm_service.dart';
import '../../services/workspace_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/business_network/qr_code_modal.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/feed_composer_card.dart';
import '../../widgets/business_network/diamond_purchase_bottom_sheet.dart';
import '../../widgets/ios_web_redirect_screen.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import '../../widgets/common/adsy_share_sheet.dart';
import '../../widgets/common/adsy_report_sheet.dart';

import 'create_post_screen.dart';
import 'notifications_screen.dart';
import '../adsy_connect_chat_interface.dart';
import '../workspace/gig_detail_screen.dart';
import 'profile_options.dart';
import 'post_media_viewer_screen.dart';
import 'shorts_player_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import '../../utils/url_launcher_utils.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  Map<String, dynamic>? _userData;
  List<BusinessNetworkPost> _userPosts = [];
  List<BusinessNetworkPost> _savedPosts = [];
  List<Map<String, dynamic>> _userGigs = [];
  bool _isFollowing = false;
  bool _followLoading = false;
  bool _isBlockedProfile = false;
  bool _isBlocking = false;
  final int _currentNavIndex = 3; // Profile tab is index 3
  int _unreadNotificationCount = 0;
  bool _isLoadingSaved = false;
  bool _isLoadingGigs = false;
  int _profileImageRefreshTick = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WorkspaceService _workspaceService = WorkspaceService();

  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<String> _tabLabels = const [
    'Posts',
    'My Workspace',
    'Media',
    'Saved',
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

  bool _isOwnProfile() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    if (widget.userId == currentUser.id) return true;

    final userData = _userData;
    if (userData == null) return false;

    final profileId = (userData['id'] ?? '').toString();
    if (profileId.isNotEmpty && profileId == currentUser.id) return true;

    final profileUuid =
        (userData['uuid'] ?? userData['user_id'] ?? '').toString();
    if (profileUuid.isNotEmpty && profileUuid == currentUser.id) return true;

    final profileUsername = (userData['username'] ?? '').toString();
    if (profileUsername.isNotEmpty && profileUsername == currentUser.username) {
      return true;
    }

    return false;
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

  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    final resolved = value is String ? value.trim() : value.toString().trim();
    if (resolved == 'null' || resolved == 'undefined') {
      return '';
    }

    return resolved;
  }

  bool _isFieldVisible(String fieldName, {bool defaultValue = true}) {
    if (_isOwnProfile()) {
      return true;
    }

    final value = _userData?[fieldName];
    return value is bool ? value : defaultValue;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
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
      debugPrint('Error loading notification count: $e');
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
      if (_currentTabIndex == 3 && !_isLoadingSaved) {
        _loadSavedPosts();
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    await _loadProfileData();
    if (!mounted) return;

    // Refresh tab-specific data
    if (_currentTabIndex == 1 && !_isLoadingGigs) {
      await _loadUserGigs();
    }
    if (_currentTabIndex == 3 && !_isLoadingSaved) {
      await _loadSavedPosts();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Session cache: revisiting a profile paints instantly from the last
  /// fetched data while a background refresh replaces it (SWR pattern).
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  Future<void> _loadProfileData() async {
    // 1. Instant paint from cache when we have one.
    final cached = _profileCache[widget.userId];
    if (cached != null && _userData == null) {
      setState(() {
        _userData = cached;
        _isFollowing = cached['is_following'] ?? false;
        _isBlockedProfile = cached['is_blocked_by_me'] ?? false;
        _isLoading = false;
        _isLoadingPosts = true;
      });
    } else if (_userData == null) {
      setState(() {
        _isLoading = true;
        _isLoadingPosts = true;
      });
    } else {
      setState(() => _isLoadingPosts = true);
    }

    // 2. Profile and posts in PARALLEL (was serial: two full round-trips
    //    back to back), and the header renders the moment the profile
    //    arrives instead of waiting for the posts payload too.
    final profileFuture = BusinessNetworkService.getUserProfile(widget.userId);
    final postsFuture = BusinessNetworkService.getUserPosts(widget.userId);

    var profileFailed = false;
    try {
      final userData = await profileFuture;
      _profileCache[widget.userId] = userData;
      if (mounted) {
        setState(() {
          _userData = userData;
          _isFollowing = userData['is_following'] ?? false;
          _isBlockedProfile = userData['is_blocked_by_me'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      profileFailed = true;
      if (mounted) {
        setState(() => _isLoading = false);
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          onRetry: () => _loadProfileData(),
        );
      }
    }

    try {
      final postsResult = await postsFuture;
      if (mounted) {
        setState(() {
          final posts = postsResult['posts'] as List<BusinessNetworkPost>;
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
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
        // Don't double-toast when the profile call already surfaced the error.
        if (!profileFailed) {
          NetworkErrorHandler.showErrorSnackbar(
            context,
            e,
            onRetry: () => _loadProfileData(),
          );
        }
      }
    }
  }

  Future<void> _loadSavedPosts() async {
    if (!_isOwnProfile()) return;

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

      debugPrint('=== Toggle Follow ===');
      debugPrint('User ID: ${widget.userId}');
      debugPrint('Was Following: $wasFollowing');

      final success = wasFollowing
          ? await BusinessNetworkService.unfollowUser(widget.userId)
          : await BusinessNetworkService.followUser(widget.userId);

      debugPrint('Success: $success');

      if (success && mounted) {
        setState(() {
          _isFollowing = !wasFollowing;
          // Update follower count using original state
          if (_userData != null) {
            final currentCount = _userData!['followers_count'] ?? 0;
            _userData!['followers_count'] =
                wasFollowing ? currentCount - 1 : currentCount + 1;
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

        AdsyToast.info(
            context,
            _isFollowing
                ? 'Following ${_userData?['name']}'
                : 'Unfollowed ${_userData?['name']}');
      } else if (mounted) {
        AdsyToast.error(
            context, 'Failed to ${wasFollowing ? 'unfollow' : 'follow'} user');
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

  String _profileDisplayName() {
    final first = _stringValue(_userData?['first_name']);
    final last = _stringValue(_userData?['last_name']);
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    return _stringValue(_userData?['username']).isNotEmpty
        ? _stringValue(_userData?['username'])
        : 'User';
  }

  Future<void> _shareProfile() async {
    final name = _profileDisplayName();
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: '$name on Business Network',
        description: 'View $name on AdsyClub Business Network.',
        url:
            '${AppConfig.mediaBaseUrl}/business-network/profile/${widget.userId}',
        imageUrl: _stringValue(_userData?['image']).isNotEmpty
            ? _stringValue(_userData?['image'])
            : _stringValue(_userData?['profile_picture']),
        subject: '$name on Business Network',
        eyebrow: 'Business Network Profile',
      ),
    );
  }

  void _reportProfileUser() {
    if (_isOwnProfile()) return;
    AdsyReportSheet.show(
      context,
      title: 'Report Profile',
      prompt: 'Why are you reporting this profile?',
      options: const [
        AdsyReportOption(
            label: 'Fake or impersonating account', value: 'fake'),
        AdsyReportOption(label: 'Spam or scam', value: 'spam'),
        AdsyReportOption(
            label: 'Harassment or hate speech', value: 'harassment'),
        AdsyReportOption(label: 'Inappropriate content', value: 'inappropriate'),
        AdsyReportOption(label: 'Other', value: 'other'),
      ],
      successMessage: 'Profile reported. Our team will review it.',
      onSubmit: (option, details) {
        return BusinessNetworkService.reportProfile(
          widget.userId,
          option.value,
          description: details,
        );
      },
    );
  }

  Future<void> _blockProfileUser() async {
    if (_isOwnProfile() || _isBlocking) return;

    final name = _profileDisplayName();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Block $name? You will no longer see their posts in your feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBlocking = true);
    final success = await BusinessNetworkService.blockUser(widget.userId);
    if (!mounted) return;

    setState(() {
      _isBlocking = false;
      if (success) {
        _isBlockedProfile = true;
        _userPosts = [];
        _savedPosts.removeWhere((post) {
          return post.user.uuid == widget.userId ||
              post.user.id.toString() == widget.userId;
        });
      }
    });

    if (success) {
      AdsyToast.success(context, 'User blocked');
    } else {
      AdsyToast.error(context, 'Failed to block user');
    }
  }

  Future<void> _unblockProfileUser() async {
    if (_isOwnProfile() || _isBlocking) return;

    final name = _profileDisplayName();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Unblock $name? You will be able to see each other again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBlocking = true);
    final success = await BusinessNetworkService.unblockUser(widget.userId);
    if (!mounted) return;

    setState(() {
      _isBlocking = false;
      if (success) {
        _isBlockedProfile = false;
      }
    });

    if (success) {
      AdsyToast.success(context, 'User unblocked');
    } else {
      AdsyToast.error(context, 'Failed to unblock user');
    }

    if (success) {
      // Reload the profile so the now-visible posts/feed come back.
      await _loadProfileData();
    }
  }

  void _showProfileOptions(bool isOwnProfile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final profileUrl =
            '${AppConfig.mediaBaseUrl}/business-network/profile/${widget.userId}';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'প্রোফাইল শেয়ার করুন',
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              // Profile link + one-tap copy.
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profileUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: profileUrl));
                          if (!context.mounted) return;
                          AdsyToast.success(context, 'লিংক কপি হয়েছে');
                          Navigator.pop(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text('Copy',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _profileOptionTile(
                icon: Icons.ios_share_rounded,
                color: const Color(0xFF3B82F6),
                title: 'আরও শেয়ার করুন',
                subtitle: 'WhatsApp, Facebook, X, Messenger…',
                onTap: _shareProfile,
              ),
              if (!isOwnProfile && AuthService.isAuthenticated) ...[
                _profileOptionTile(
                  icon: Icons.flag_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Report Profile',
                  subtitle: 'Fake, impersonating or spam account',
                  onTap: _reportProfileUser,
                ),
                _isBlockedProfile
                    ? _profileOptionTile(
                        icon: Icons.lock_open_rounded,
                        color: const Color(0xFF059669),
                        title: 'Unblock User',
                        onTap: _unblockProfileUser,
                      )
                    : _profileOptionTile(
                        icon: Icons.block_rounded,
                        color: const Color(0xFFDC2626),
                        title: 'Block User',
                        danger: true,
                        onTap: _blockProfileUser,
                      ),
              ],
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _profileOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: danger
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF94A3B8))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChatWithUser() async {
    if (_userData == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: AdsyLoadingIndicator(),
        ),
      );

      // Get or create chatroom with the profile user
      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(widget.userId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Open chat (stack-deduplicated)
      if (mounted) {
        AdsyConnectChatInterface.open(
          context,
          chatroomId: chatroom['id'].toString(),
          userId: widget.userId,
          userName: _userData!['first_name'] != null &&
                  _userData!['last_name'] != null
              ? '${_userData!['first_name']} ${_userData!['last_name']}'
              : _userData!['username'] ?? 'User',
          userAvatar: _userData?['image'] ??
              _userData?['profile_picture'] ??
              _userData?['avatar'],
          profession: _userData!['profession'],
          isOnline: false,
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
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              top: false,
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
                    leading:
                        const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                    title: const Text('Take Photo'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library,
                        color: Color(0xFF3B82F6)),
                    title: const Text('Choose from Gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 96,
      );

      if (image == null) return;

      // Let the user crop + rotate to a square before upload.
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'ছবি ঠিক করুন',
            toolbarColor: const Color(0xFF2563EB),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF2563EB),
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'ছবি ঠিক করুন',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: false,
          ),
        ],
      );
      if (cropped == null) return; // user cancelled the crop
      final XFile picked = XFile(cropped.path);

      // Show loading
      if (mounted) {
        AdsyToast.info(context, 'Uploading profile picture...');
      }

      // Compress before upload (fallback to the cropped XFile on failure)
      XFile uploadFile = picked;
      final compressed = await ImageCompressor.compressToBytes(
        picked,
        targetSize: 80 * 1024,
      );
      if (compressed != null) {
        uploadFile = XFile.fromData(
          compressed,
          name: 'profile.jpg',
          mimeType: 'image/jpeg',
        );
      }

      // Upload to server (pass XFile directly for cross-platform support)
      final success =
          await BusinessNetworkService.uploadProfilePicture(uploadFile);

      if (mounted) {
        if (success) {
          setState(() {
            _profileImageRefreshTick = DateTime.now().millisecondsSinceEpoch;
          });
          // Show success message
          AdsyToast.success(context, 'Profile picture updated successfully!');

          // Reload profile data to show new image
          _loadProfileData();
        } else {
          // Show error message
          AdsyToast.error(
              context, 'Failed to upload profile picture. Please try again.');
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

    final userName =
        _userData?['first_name'] != null && _userData?['last_name'] != null
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
                    _getImageUrl(_userData!['image']),
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

  String _getImageUrl(String? url) {
    final absoluteUrl = AppConfig.getAbsoluteUrl(url);
    if (absoluteUrl.isEmpty) return '';
    final separator = absoluteUrl.contains('?') ? '&' : '?';
    return '$absoluteUrl${separator}v=$_profileImageRefreshTick';
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
        // Header avatar → profile OPTIONS, same as the rest of the app.
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileOptionsScreen(),
            ),
          );
        },
      ),
      drawer: isMobile
          ? BusinessNetworkDrawer(
              currentRoute: '/business-network/profile/${widget.userId}')
          : null,
      body: _isLoading
          ? _buildLoadingState()
          : AdsyRefreshIndicator(
              onRefresh: _refreshCurrentTab,
              color: const Color(0xFF3B82F6),
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      children: [
                        // Profile Header
                        _buildProfileHeader(isOwnProfile),

                        const SizedBox(height: 10),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: GoldSponsorsSlider(),
                        ),
                        const SizedBox(height: 10),

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
    final rootNavigator =
        FCMService.navigatorKey.currentState ?? Navigator.of(context);

    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        rootNavigator.pushNamedAndRemoveUntil(
          '/business-network',
          (route) => route.isFirst,
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
        // Create Post — insert the new post at the top of this profile's
        // list so it shows without a reload.
        Navigator.push<BusinessNetworkPost?>(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        ).then((created) {
          if (created != null && mounted && _isOwnProfile()) {
            setState(() => _userPosts.insert(0, created));
          }
        });
        break;
      case 3:
        // Profile — the footer goes to the profile PAGE (the header avatar
        // opens the options screen). If this is already the user's own
        // profile there is nowhere to go.
        if (AuthService.isAuthenticated) {
          final currentUser = AuthService.currentUser;
          if (currentUser != null && !_isOwnProfile()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(userId: currentUser.id),
              ),
            );
          }
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub / Home - Navigate to main home screen
        rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
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
                  children: List.generate(
                      3,
                      (index) => Column(
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
    final profession = _stringValue(_userData?['profession']);
    final about = _stringValue(_userData?['about']);
    final showProfession =
        profession.isNotEmpty && _isFieldVisible('profession_public');
    final showAbout = about.isNotEmpty && _isFieldVisible('about_public');

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
                            _userData?['first_name'] != null &&
                                    _userData?['last_name'] != null
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                    if (showProfession) ...[
                      const SizedBox(height: 2),
                      Text(
                        profession,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Profile options',
                onPressed: () => _showProfileOptions(isOwnProfile),
                icon: const Icon(Icons.more_horiz_rounded),
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
                  width: 164,
                  height: 164,
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
                              _getImageUrl(_userData!['image']),
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
              _buildStatItem('Followers', _userData?['followers_count'] ?? 0,
                  onTap: () => _showFollowersFollowingSheet('followers')),
              Container(
                width: 1,
                height: 28,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStatItem('Following', _userData?['following_count'] ?? 0,
                  onTap: () => _showFollowersFollowingSheet('following')),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons + Diamond (side by side pill row)
          if (_isBlockedProfile)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block_rounded,
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'You blocked this user',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isBlocking ? null : _unblockProfileUser,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isBlocking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Unblock'),
                  ),
                ],
              ),
            )
          else if (isOwnProfile && _userData?['diamond_balance'] != null)
            _buildOwnProfileActionRow()
          else
            _buildActionButtonsRow(isOwnProfile),

          // Bio Section
          if (showAbout || isOwnProfile) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 10),
            Text(
              about.isNotEmpty ? about : 'No bio provided',
              style: TextStyle(
                fontSize: 13,
                color: about.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                fontStyle:
                    about.isNotEmpty ? FontStyle.normal : FontStyle.italic,
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
              color: onTap != null
                  ? const Color(0xFF8B5CF6)
                  : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons row with pill-style design (matching Vue)
  /// Own-profile row: QR Code pill + Diamond balance pill side by side
  Widget _buildOwnProfileActionRow() {
    final diamondBalance = _userData?['diamond_balance'] ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code pill
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(50),
            color: Colors.white,
          ),
          child: _buildPillButton(
            icon: Icons.qr_code_2_rounded,
            label: 'QR Code',
            onTap: () {
              if (_userData != null) {
                QrCodeModal.show(context, _userData!);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        // Diamond balance pill
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.pink.shade100),
            borderRadius: BorderRadius.circular(50),
            color: Colors.white,
          ),
          child: InkWell(
            onTap: !isIOSPlatform
                ? () => DiamondPurchaseBottomSheet.show(
                      context,
                      onPurchaseSuccess: () => setState(_loadProfileData),
                    )
                : null,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.diamond, size: 16, color: Colors.pink.shade400),
                  const SizedBox(width: 5),
                  Text(
                    '$diamondBalance 💎',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (!isIOSPlatform) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.add_circle_outline,
                        size: 14, color: Colors.pink.shade400),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                QrCodeModal.show(context, _userData!);
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
                  return Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: Colors.teal.shade600);
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
              icon: _isFollowing
                  ? Icons.check_rounded
                  : Icons.person_add_outlined,
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
            child: AdsyLoadingIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
            ),
          )
        : customIcon ??
            (icon != null
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
            MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: userId)),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabLabels.length, (index) {
          return Expanded(
            child: _buildProfileTabButton(
              label: _tabLabels[index],
              index: index,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileTabButton({
    required String label,
    required int index,
  }) {
    final isActive = _currentTabIndex == index;

    return InkWell(
      onTap: () => _tabController.animateTo(index),
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isActive ? const Color(0xFFBFDBFE) : Colors.transparent,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color:
                  isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildPostsTab();
      case 1:
        return _buildWorkspaceTab();
      case 2:
        return _buildMediaTab();
      case 3:
        return _buildSavedTab();
      default:
        return _buildPostsTab();
    }
  }

  // ── About sheet: the full Facebook-style profile info, opened from the
  // "See more about ..." link in the header (About is profile detail, not a
  // productivity tab).

  void _showAboutSheet() {
    final userName =
        _stringValue(_userData?['name']).isNotEmpty
            ? _stringValue(_userData?['name'])
            : (_userData?['first_name'] ?? 'this user').toString();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(sheetContext).pop(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 20, color: Color(0xFF475569)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'About $userName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                          children: [_buildAboutContent()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAboutContent() {
    final about = _stringValue(_userData?['about']);
    final profession = _stringValue(_userData?['profession']);
    final company = _stringValue(_userData?['company']);
    final education = _stringValue(_userData?['education']);
    final languages = _stringValue(_userData?['languages']);
    final skills = _stringValue(_userData?['skills']);
    final email = _stringValue(_userData?['email']);
    final phone = _stringValue(_userData?['phone']);
    final website = _stringValue(_userData?['website']);
    final city = _stringValue(_userData?['city']);
    final state = _stringValue(_userData?['state']);

    final socials = <Map<String, dynamic>>[
      {
        'label': 'Facebook',
        'icon': Icons.facebook_rounded,
        'url': _stringValue(_userData?['face_link']),
        'visible': _isFieldVisible('facebook_public'),
      },
      {
        'label': 'Instagram',
        'icon': Icons.camera_alt_outlined,
        'url': _stringValue(_userData?['instagram_link']),
        'visible': _isFieldVisible('instagram_public'),
      },
      {
        'label': 'WhatsApp',
        'icon': Icons.chat_bubble_outline_rounded,
        'url': _whatsAppUrl(_stringValue(_userData?['whatsapp_link'])),
        'visible': _isFieldVisible('whatsapp_public'),
      },
      {
        'label': 'TikTok',
        'icon': Icons.music_note_rounded,
        'url': _stringValue(_userData?['tiktok_link']),
        'visible': _isFieldVisible('tiktok_public'),
      },
      {
        'label': 'YouTube',
        'icon': Icons.play_circle_outline_rounded,
        'url': _stringValue(_userData?['youtube_link']),
        'visible': _isFieldVisible('youtube_public'),
      },
      {
        'label': 'LinkedIn',
        'icon': Icons.work_outline_rounded,
        'url': _stringValue(_userData?['linkedin_link']),
        'visible': _isFieldVisible('linkedin_public'),
      },
    ]
        .where((e) =>
            (e['url'] as String).isNotEmpty && (e['visible'] as bool))
        .toList();

    final sections = <Widget>[];

    if (about.isNotEmpty && _isFieldVisible('about_public')) {
      sections.add(_aboutSection('Bio', [
        _aboutRow(Icons.subject_rounded, about),
      ]));
    }

    final workRows = <Widget>[];
    if (profession.isNotEmpty && _isFieldVisible('profession_public')) {
      workRows.add(_aboutRow(Icons.badge_outlined, profession));
    }
    if (company.isNotEmpty && _isFieldVisible('company_public')) {
      workRows.add(_aboutRow(Icons.business_outlined, company));
    }
    if (workRows.isNotEmpty) sections.add(_aboutSection('Work', workRows));

    if (education.isNotEmpty && _isFieldVisible('education_public')) {
      sections.add(_aboutSection('Education', [
        _aboutRow(Icons.school_outlined, education),
      ]));
    }

    if (languages.isNotEmpty && _isFieldVisible('languages_public')) {
      sections.add(_aboutSection('Languages', [_aboutChips(languages)]));
    }
    if (skills.isNotEmpty && _isFieldVisible('skills_public')) {
      sections.add(_aboutSection('Skills', [_aboutChips(skills)]));
    }

    final contactRows = <Widget>[];
    if (email.isNotEmpty) {
      contactRows.add(_aboutRow(Icons.email_outlined,
          _maskEmail(email, _userData?['email_public'])));
    }
    if (phone.isNotEmpty) {
      contactRows.add(_aboutRow(Icons.phone_outlined,
          _maskPhoneNumber(phone, _userData?['phone_public'])));
    }
    if (website.isNotEmpty && _isFieldVisible('website_public')) {
      contactRows.add(_aboutRow(Icons.language_rounded, website,
          url: website));
    }
    if (contactRows.isNotEmpty) {
      sections.add(_aboutSection('Contact', contactRows));
    }

    if (socials.isNotEmpty) {
      sections.add(_aboutSection(
        'Social Links',
        socials
            .map((e) => _aboutRow(
                  e['icon'] as IconData,
                  e['label'] as String,
                  url: e['url'] as String,
                ))
            .toList(),
      ));
    }

    final placeRows = <Widget>[];
    if (city.isNotEmpty || state.isNotEmpty) {
      placeRows.add(_aboutRow(
          Icons.location_on_outlined,
          '$city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state'));
    }
    if (_userData?['date_joined'] != null) {
      placeRows.add(_aboutRow(Icons.calendar_today_outlined,
          'Joined ${_formatTimeAgo(_userData!['date_joined'])}'));
    }
    if (placeRows.isNotEmpty) {
      sections.add(_aboutSection('Location & Joined', placeRows));
    }

    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'No profile information added yet',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _aboutSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String text, {String? url}) {
    final tappable = url != null && url.isNotEmpty;
    return InkWell(
      onTap:
          tappable ? () => UrlLauncherUtils.launchExternalUrl(url) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color: tappable
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: tappable ? FontWeight.w600 : FontWeight.w400,
                  color: tappable
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            if (tappable)
              const Icon(Icons.open_in_new_rounded,
                  size: 15, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _aboutChips(String commaSeparated) {
    final items = commaSeparated
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: items
            .map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// wa.me url from a raw whatsapp value (number or link).
  String _whatsAppUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? raw : 'https://wa.me/$digits';
  }

  Widget _buildPostsTab() {
    // Own profile gets the same "কী ভাবছেন?" composer as the feed; a created
    // post appears at the top without a reload.
    final composer = _isOwnProfile()
        ? Padding(
            padding: const EdgeInsets.fromLTRB(1, 4, 1, 0),
            child: FeedComposerCard(
              onPostCreated: (post) {
                if (mounted) setState(() => _userPosts.insert(0, post));
              },
            ),
          )
        : const SizedBox.shrink();

    if (_userPosts.isEmpty) {
      if (_isLoadingPosts) {
        // Posts still streaming in — header is already visible above.
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: AdsyLoadingIndicator(strokeWidth: 2.5),
            ),
          ),
        );
      }
      return Column(
        children: [
          composer,
          _buildEmptyState('No posts yet', Icons.post_add),
        ],
      );
    }

    return Column(children: [
      composer,
      _buildPostsList(),
    ]);
  }

  Widget _buildPostsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Match the main feed's near-edge horizontal padding (1px).
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 4),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        return PostCard(
          key: ValueKey('post_${_userPosts[index].id}'),
          post: _userPosts[index],
          onPostUpdated: (updatedPost) {
            setState(() {
              _userPosts[index] = updatedPost;
            });
          },
          onCommentAdded: (comment) {},
          onPostDeleted: () {
            setState(() {
              _userPosts.removeAt(index);
            });
          },
          onUserBlocked: _handleUserBlocked,
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
          final displayUrl =
              media.isVideo ? media.bestThumbnailUrl : media.bestUrl;
          return InkWell(
            onTap: () {
              final parentPost = _findParentPostForMedia(media);
              if (media.isVideo) {
                // Open video in Shorts player
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShortsPlayerScreen(
                      initialPost: parentPost,
                      initialMedia: media,
                    ),
                    fullscreenDialog: true,
                  ),
                );
              } else {
                // Open image in media viewer
                final initialIndex = _findMediaIndexInPost(parentPost, media);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostMediaViewerScreen(
                      post: parentPost,
                      initialIndex: initialIndex,
                    ),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (displayUrl.isNotEmpty)
                      Image.network(
                        displayUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Grey placeholder for failed thumbnails
                          return Container(
                            color: Colors.grey.shade400,
                            child: Center(
                              child: Icon(
                                media.isVideo
                                    ? Icons.play_circle_outline
                                    : Icons.image_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey.shade400,
                        child: Center(
                          child: Icon(
                            media.isVideo
                                ? Icons.play_circle_outline
                                : Icons.image_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 40,
                          ),
                        ),
                      ),
                    if (media.isVideo)
                      Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    // Views count on video thumbnails (Instagram-style,
                    // bottom-left over the dark gradient).
                    if (media.isVideo)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 15, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              _formatViews(media.views),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 3),
                                ],
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
        },
      ),
    );
  }

  String _formatViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  BusinessNetworkPost _findParentPostForMedia(PostMedia media) {
    // Best-effort mapping back to the post that contains this media.
    // Falls back to first post to avoid crashes.
    for (final p in _userPosts) {
      if (media.id != 0) {
        if (p.media.any((m) => m.id == media.id)) return p;
      } else {
        final target = media.bestUrl;
        if (p.media.any((m) => m.bestUrl == target)) return p;
      }
    }
    return _userPosts.isNotEmpty
        ? _userPosts.first
        : BusinessNetworkPost.fromJson({});
  }

  int _findMediaIndexInPost(BusinessNetworkPost post, PostMedia media) {
    if (post.media.isEmpty) return 0;
    if (media.id != 0) {
      final idx = post.media.indexWhere((m) => m.id == media.id);
      if (idx != -1) return idx;
    }
    final target = media.bestUrl;
    final idx = post.media.indexWhere((m) => m.bestUrl == target);
    return idx == -1 ? 0 : idx;
  }

  Widget _buildWorkspaceTab() {
    if (_isLoadingGigs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: AdsyLoadingIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      );
    }

    if (_userGigs.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              color: Colors.black.withValues(alpha: 0.03),
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.work_outline,
                                color: Colors.grey[400], size: 24),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.work_outline,
                              color: Colors.grey[400], size: 24),
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
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFFBBF24)),
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
    final isOwnProfile = currentUser != null && _isOwnProfile();

    // Only show saved posts for own profile
    if (!isOwnProfile) {
      return _buildEmptyState('Saved posts are private', Icons.lock_outline);
    }

    if (_isLoadingSaved) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: AdsyLoadingIndicator(
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
          key: ValueKey('post_${_savedPosts[index].id}'),
          post: _savedPosts[index],
          onPostUpdated: (updatedPost) {
            setState(() {
              _savedPosts[index] = updatedPost;
            });
          },
          onSaveChanged: (postId, isSaved) {
            if (!isSaved) {
              setState(() {
                _savedPosts.removeWhere((p) => p.id == postId);
              });
            }
          },
          onCommentAdded: (comment) {},
          onPostDeleted: () {
            setState(() {
              _savedPosts.removeAt(index);
            });
          },
          onUserBlocked: _handleUserBlocked,
        );
      },
    );
  }

  void _handleUserBlocked(String userId) {
    setState(() {
      _userPosts.removeWhere((post) =>
          post.user.uuid == userId || post.user.id.toString() == userId);
      _savedPosts.removeWhere((post) =>
          post.user.uuid == userId || post.user.id.toString() == userId);
      if (widget.userId == userId) {
        _isBlockedProfile = true;
      }
    });
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    final city = _stringValue(_userData?['city']);
    final state = _stringValue(_userData?['state']);
    final company = _stringValue(_userData?['company']);
    final email = _stringValue(_userData?['email']);
    final phone = _stringValue(_userData?['phone']);
    final website = _stringValue(_userData?['website']);
    final whatsapp = _stringValue(_userData?['whatsapp_link']);
    final instagram = _stringValue(_userData?['instagram_link']);
    final facebook = _stringValue(_userData?['face_link']);

    final showCompany = company.isNotEmpty && _isFieldVisible('company_public');
    final showWebsite = website.isNotEmpty && _isFieldVisible('website_public');
    final showWhatsapp =
        whatsapp.isNotEmpty && _isFieldVisible('whatsapp_public');
    final showInstagram =
        instagram.isNotEmpty && _isFieldVisible('instagram_public');
    final showFacebook =
        facebook.isNotEmpty && _isFieldVisible('facebook_public');

    final hasContactInfo = city.isNotEmpty ||
        state.isNotEmpty ||
        email.isNotEmpty ||
        phone.isNotEmpty ||
        _userData?['date_joined'] != null ||
        showCompany ||
        showWebsite ||
        showWhatsapp ||
        showInstagram ||
        showFacebook;

    if (!hasContactInfo) return const SizedBox.shrink();

    final hasAdditionalInfo = email.isNotEmpty ||
        phone.isNotEmpty ||
        showWebsite ||
        showWhatsapp ||
        showInstagram ||
        showFacebook ||
        _userData?['date_joined'] != null;

    final userName =
        _userData?['first_name'] ?? _userData?['username'] ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Always visible: Location and Joined Date
        if (city.isNotEmpty || state.isNotEmpty)
          _buildContactItem(
            Icons.location_on,
            '$city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state',
            Colors.blue.shade500,
          ),

        if (showCompany)
          _buildContactItem(
            Icons.business,
            company,
            Colors.purple.shade500,
          ),

        // Email (with privacy masking)
        if (email.isNotEmpty)
          _buildContactItem(
            Icons.email,
            _maskEmail(email, _userData?['email_public']),
            Colors.orange.shade600,
          ),

        // Phone (with privacy masking)
        if (phone.isNotEmpty)
          _buildContactItem(
            Icons.phone,
            _maskPhoneNumber(phone, _userData?['phone_public']),
            Colors.red.shade500,
          ),

        // Joined Date (always visible)
        if (_userData?['date_joined'] != null)
          _buildContactItem(
            Icons.calendar_today,
            'Joined ${_formatTimeAgo(_userData!['date_joined'])}',
            Colors.green.shade500,
          ),


        // "See more about [Name]" — opens the full About bottom sheet.
        if (hasAdditionalInfo) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: _showAboutSheet,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See more about $userName',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right_rounded,
                      size: 19, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color color,
      {String? url}) {
    final tappable = url != null && url.isNotEmpty;
    if (tappable) {
      return InkWell(
        onTap: () => UrlLauncherUtils.launchExternalUrl(url),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const Icon(Icons.open_in_new_rounded,
                  size: 14, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      );
    }
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
                fontSize: 15,
                height: 1.35,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
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
  State<_FollowersFollowingSheet> createState() =>
      _FollowersFollowingSheetState();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final result = widget.type == 'followers'
        ? await BusinessNetworkService.getUserFollowers(widget.userId,
            page: _page)
        : await BusinessNetworkService.getUserFollowing(widget.userId,
            page: _page);

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
        ? await BusinessNetworkService.getUserFollowers(widget.userId,
            page: _page)
        : await BusinessNetworkService.getUserFollowing(widget.userId,
            page: _page);

    if (mounted) {
      setState(() {
        _users.addAll(List<Map<String, dynamic>>.from(result['results'] ?? []));
        _hasMore = result['next'] != null;
      });
    }
  }

  String _getImageUrl(String? url) {
    return AppConfig.getAbsoluteUrl(url);
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
                    child: AdsyLoadingIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF3B82F6)),
                    ),
                  )
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              widget.type == 'followers'
                                  ? 'No followers yet'
                                  : 'Not following anyone',
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
                                  child: AdsyLoadingIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF3B82F6)),
                                  ),
                                ),
                              ),
                            );
                          }

                          final user = _users[index];
                          // API returns follower_details/following_details
                          final userData = widget.type == 'followers'
                              ? user['follower_details'] ??
                                  user['follower'] ??
                                  user
                              : user['following_details'] ??
                                  user['following'] ??
                                  user;

                          // Get user image
                          final String? userImage =
                              userData['image']?.toString();
                          final bool hasImage =
                              userImage != null && userImage.isNotEmpty;

                          // Get display name
                          String displayName = 'Unknown';
                          if (userData['first_name'] != null &&
                              userData['first_name'].toString().isNotEmpty) {
                            displayName = userData['first_name'].toString();
                            if (userData['last_name'] != null &&
                                userData['last_name'].toString().isNotEmpty) {
                              displayName += ' ${userData['last_name']}';
                            }
                          } else if (userData['name'] != null &&
                              userData['name'].toString().isNotEmpty) {
                            displayName = userData['name'].toString();
                          } else if (userData['username'] != null &&
                              userData['username'].toString().isNotEmpty) {
                            displayName = userData['username'].toString();
                          }

                          // Get profession/headline
                          final bool showProfession =
                              userData['profession_public'] != false;
                          final String? profession = showProfession
                              ? userData['profession']?.toString() ??
                                  userData['headline']?.toString()
                              : null;

                          return InkWell(
                            onTap: () => widget
                                .onUserTap(userData['id']?.toString() ?? ''),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
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
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : 'U',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                padding:
                                                    EdgeInsets.only(left: 3),
                                                child: Icon(
                                                    Icons.verified_rounded,
                                                    size: 14,
                                                    color: Color(0xFF3B82F6)),
                                              ),
                                            if (userData['is_pro'] == true)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 3),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                          colors: [
                                                        Color(0xFFF59E0B),
                                                        Color(0xFFF97316)
                                                      ]),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                                child: const Text('PRO',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                          ],
                                        ),
                                        if (profession != null &&
                                            profession.isNotEmpty) ...[
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
                                  Icon(Icons.chevron_right_rounded,
                                      size: 18, color: Colors.grey.shade400),
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
