import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/fcm_service.dart';
import 'profile_screen.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import 'notifications_screen.dart';
import 'create_post_screen.dart';
import 'shorts_player_screen.dart';
import 'blocked_users_screen.dart';
import 'post_media_viewer_screen.dart';
import '../inbox_screen.dart';
import '../workspace/workspace_screen.dart';
import '../settings_screen.dart';
import '../verification_screen.dart';
import '../../widgets/business_network/monetization_card.dart';
import '../../widgets/business_network/qr_code_modal.dart';
import '../../widgets/common/adsy_share_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'package:oxius_native/widgets/common/adsy_chat_icon.dart';
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';
import 'package:oxius_native/widgets/common/adsy_dialog.dart';
import '../../utils/adsy_image_upload.dart';

class ProfileOptionsScreen extends StatefulWidget {
  const ProfileOptionsScreen({super.key});

  @override
  State<ProfileOptionsScreen> createState() => _ProfileOptionsScreenState();
}

class _ProfileOptionsScreenState extends State<ProfileOptionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic>? _profileData;
  int _mediaRefreshTick = 0;
  bool _bannerUploading = false;
  double _bannerProgress = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadProfileSummary();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileSummary({bool refreshAuth = false}) async {
    final user = AuthService.currentUser;
    if (user == null) {
      return;
    }


    try {
      if (refreshAuth) {
        await AuthService.refreshUserData();
      }

      final profile = await BusinessNetworkService.getUserProfile(user.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _profileData = profile;
        _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

    }
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

  int _intValue(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(_stringValue(value)) ?? 0;
  }

  String _resolvedName(User? user) {
    final firstName = _stringValue(_profileData?['first_name']);
    final lastName = _stringValue(_profileData?['last_name']);
    final fullName =
        [firstName, lastName].where((value) => value.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return user?.displayName ?? 'Guest';
  }

  String _resolvedProfession(User? user) {
    final profession = _stringValue(_profileData?['profession']);
    if (profession.isNotEmpty) {
      return profession;
    }
    return (user?.profession ?? '').trim();
  }

  String _resolvedAddress(User? user) {
    final address = _stringValue(_profileData?['address']);
    if (address.isNotEmpty) {
      return address;
    }
    return (user?.address ?? '').trim();
  }

  bool _resolvedVerified(User? user) {
    return _profileData?['kyc'] == true || user?.isVerified == true;
  }

  bool _resolvedPro(User? user) {
    return _profileData?['is_pro'] == true || user?.isPro == true;
  }

  String _mediaUrl(String? rawUrl) {
    final absolute = AppConfig.getAbsoluteUrl(rawUrl);
    if (absolute.isEmpty) {
      return '';
    }
    final separator = absolute.contains('?') ? '&' : '?';
    return '$absolute${separator}v=$_mediaRefreshTick';
  }

  String _resolvedAvatarUrl(User? user) {
    final profileImage = _stringValue(_profileData?['image']);
    if (profileImage.isNotEmpty) {
      return _mediaUrl(profileImage);
    }
    return _mediaUrl(user?.profilePicture);
  }

  String _resolvedBannerUrl() {
    // Prefer the dedicated profile banner; fall back to the store banner.
    final profileBanner = _stringValue(_profileData?['banner_image']);
    if (profileBanner.isNotEmpty) return _mediaUrl(profileBanner);
    return _mediaUrl(_stringValue(_profileData?['store_banner']));
  }

  /// Pick → crop (3:1) → compress → upload the profile banner.
  Future<void> _uploadBanner() async {
    final file = await AdsyImageUpload.pick(
      context,
      ratioX: 3,
      ratioY: 1,
      title: 'ব্যানার ঠিক করুন',
      targetKb: 220,
    );
    if (file == null || !mounted) return;
    setState(() {
      _bannerUploading = true;
      _bannerProgress = 0;
    });
    final ok = await BusinessNetworkService.uploadProfileBanner(
      file,
      onProgress: (p) {
        if (mounted) setState(() => _bannerProgress = p);
      },
    );
    if (!mounted) return;
    setState(() => _bannerUploading = false);
    if (ok) {
      AdsyToast.success(context, 'ব্যানার আপডেট হয়েছে');
      await _loadProfileSummary(refreshAuth: true);
    } else {
      AdsyToast.error(context, 'আপলোড করা যায়নি, আবার চেষ্টা করুন');
    }
  }

  /// Full-screen banner preview through the standard BN media viewer.
  void _openBannerViewer(String bannerUrl, String name, String avatarUrl) {
    final user = AuthService.currentUser;
    final post = BusinessNetworkPost(
      id: 0,
      title: '',
      user: BusinessNetworkUser(
        id: 0,
        uuid: user?.id,
        name: name,
        avatar: avatarUrl,
        image: avatarUrl,
        isVerified: _resolvedVerified(user),
        isPro: _resolvedPro(user),
      ),
      content: '',
      media: [PostMedia(id: 0, image: bannerUrl, type: 'image', post: 0)],
      tags: const [],
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      isSaved: false,
      createdAt: '',
      comments: const [],
      postLikes: const [],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostMediaViewerScreen(post: post, initialIndex: 0),
        fullscreenDialog: true,
      ),
    );
  }

  int _resolvedPostCount() => _intValue(_profileData?['post_count']);
  int _resolvedFollowersCount() => _intValue(_profileData?['followers_count']);
  int _resolvedFollowingCount() => _intValue(_profileData?['following_count']);
  int _resolvedDiamondBalance() => _intValue(_profileData?['diamond_balance']);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final user = AuthService.currentUser;
    final String name = _resolvedName(user);
    final String profession = _resolvedProfession(user);
    final String address = _resolvedAddress(user);
    final String avatarUrl = _resolvedAvatarUrl(user);
    final String bannerUrl = _resolvedBannerUrl();
    final bool isVerified = _resolvedVerified(user);
    final bool isPro = _resolvedPro(user);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark icons like every other page. The old `.light` (white icons,
      // meant for a dark cover photo) made the status bar unreadable/white
      // over the typically light banner.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AdsyRefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () => _loadProfileSummary(refreshAuth: true),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                // Premium Gradient Header
                SliverToBoxAdapter(
                  child: _buildPremiumHeader(
                    context,
                    name: name,
                    profession: profession,
                    address: address,
                    avatarUrl: avatarUrl,
                    bannerUrl: bannerUrl,
                    isVerified: isVerified,
                    isPro: isPro,
                    user: user,
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: _buildQuickActions(context),
                ),

                // Small gap
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Content monetization progress / apply / status card
                const SliverToBoxAdapter(child: MonetizationCard()),

                // Verification Banner
                if (!isVerified)
                  SliverToBoxAdapter(
                    child: _buildVerificationBanner(context),
                  ),

                // Menu Sections
                SliverToBoxAdapter(
                  child: _buildMenuSection(
                    context,
                    title: 'Account',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'My Profile',
                        subtitle: 'View and edit your profile',
                        gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        onTap: () => _navigateToProfile(context),
                      ),
                      _MenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Wallet & Transactions',
                        subtitle: 'Manage your funds',
                        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                        onTap: () =>
                            Navigator.pushNamed(context, '/deposit-withdraw'),
                      ),
                      // _MenuItem(
                      //   icon: Icons.history_rounded,
                      //   label: 'Activity History',
                      //   subtitle: 'View your recent activity',
                      //   gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      //   onTap: () => Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => const ActivityHistoryScreen(),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildMenuSection(
                    context,
                    title: 'Features',
                    items: [
                      _MenuItem(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Shorts',
                        subtitle: 'Watch and create short videos',
                        gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                        onTap: () => _openShorts(context),
                      ),
                      _MenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        customIcon: const AdsyChatIcon(size: 22),
                        label: 'AdsyConnect',
                        subtitle: 'Messages and conversations',
                        gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const InboxScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.work_outline_rounded,
                        label: 'Workspace',
                        subtitle: 'Post your about expertise and get order',
                        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WorkspaceScreen()),
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildMenuSection(
                    context,
                    title: 'Earn & Grow',
                    items: [
                      _MenuItem(
                        icon: Icons.monetization_on_outlined,
                        label: 'Earn Money',
                        subtitle: 'Complete tasks and earn rewards',
                        gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                        onTap: () =>
                            Navigator.pushNamed(context, '/micro-gigs'),
                      ),
                      _MenuItem(
                        icon: Icons.paid_outlined,
                        label: 'Content Monetization',
                        subtitle: 'Track your progress and apply to earn',
                        gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        onTap: () =>
                            Navigator.pushNamed(context, '/monetization'),
                      ),
                      _MenuItem(
                        icon: Icons.psychology_outlined,
                        label: 'Mindforce',
                        subtitle: 'Problem solving colaborative network',
                        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        onTap: () => Navigator.pushNamed(context, '/mindforce'),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildMenuSection(
                    context,
                    title: 'Support',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help Center',
                        subtitle: 'FAQs and support',
                        gradient: const [Color(0xFF64748B), Color(0xFF475569)],
                        onTap: () => Navigator.pushNamed(context, '/faq'),
                      ),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings & Privacy',
                        subtitle: 'App preferences',
                        gradient: const [Color(0xFF78716C), Color(0xFF57534E)],
                        onTap: () => _openSettings(context),
                      ),
                      _MenuItem(
                        icon: Icons.block_rounded,
                        label: 'Blocked Users',
                        subtitle: 'Manage people you have blocked',
                        gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                SliverToBoxAdapter(
                  child: _buildLogoutButton(context),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: isMobile
            ? BusinessNetworkBottomNavBar(
                // Not the profile page — no tab should read active here.
                currentIndex: -1,
                isLoggedIn: AuthService.isAuthenticated,
                unreadCount: 0,
                onTap: (index) => _handleNavTap(context, index),
              )
            : null,
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context, {
    required String name,
    required String profession,
    required String address,
    required String avatarUrl,
    required String bannerUrl,
    required bool isVerified,
    required bool isPro,
    User? user,
  }) {
    return Container(
      color: Colors.white,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
          // Banner + action buttons
          Stack(
            children: [
              // Banner — tap opens it full-screen in the BN media viewer.
              GestureDetector(
                onTap: bannerUrl.isNotEmpty
                    ? () => _openBannerViewer(bannerUrl, name, avatarUrl)
                    : null,
                child: SizedBox(
                  height: 158,
                  width: double.infinity,
                  child: bannerUrl.isNotEmpty
                      ? Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildHeaderBannerFallback(),
                        )
                      : _buildHeaderBannerFallback(),
                ),
              ),
              // Share button (back removed — bottom nav handles navigation)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      _buildGlassButton(
                        icon: Icons.share_outlined,
                        onTap: () => _shareProfile(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Uploading overlay: scrim + live percentage over the banner.
              if (_bannerUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'আপলোড হচ্ছে ${(_bannerProgress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _bannerProgress,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Banner upload: plain "Add banner" when empty, a small edit
              // chip when one is already set.
              if (!_bannerUploading)
              Positioned(
                bottom: 28,
                right: 12,
                child: GestureDetector(
                  onTap: _uploadBanner,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bannerUrl.isEmpty
                              ? Icons.add_photo_alternate_outlined
                              : Icons.edit_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          bannerUrl.isEmpty ? 'Add banner' : 'Edit',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // White info sheet — its rounded TOP corners rise 18px over the
          // banner, so the banner peeks through the corner notches (the
          // radius sits on the WHITE, not the banner).
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 78, 16, 8),
              child: Column(
              children: [
                // Name row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF3B82F6), size: 18),
                    ],
                    if (isPro) ...[
                      const SizedBox(width: 6),
                      const AdsyProBadge(),
                    ],
                  ],
                ),
                if (profession.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    profession,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Compact stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat(_resolvedPostCount(), 'Posts'),
                    _buildStatDivider(),
                    _buildStat(_resolvedFollowersCount(), 'Followers',
                        onTap: () =>
                            _showFollowListSheet(context, 'followers')),
                    _buildStatDivider(),
                    _buildStat(_resolvedFollowingCount(), 'Following',
                        onTap: () =>
                            _showFollowListSheet(context, 'following')),
                    if (_resolvedDiamondBalance() > 0) ...[
                      _buildStatDivider(),
                      _buildStat(_resolvedDiamondBalance(), '💎'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ),
            ],
          ),
          // Centered large avatar — floats over the banner seam.
          Positioned(
            top: 84,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarPlaceholder(name),
                        )
                      : _buildAvatarPlaceholder(name),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(int value, String label, {VoidCallback? onTap}) {
    final isClickable = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            Text(
              value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}K'
                  : value.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isClickable
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF94A3B8),
                fontWeight: isClickable ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowListSheet(BuildContext context, String type) {
    final user = AuthService.currentUser;
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(
        userId: user.id,
        type: type,
        onUserTap: (userId) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
          );
        },
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildHeaderBannerFallback() {
    return Container(
      color: const Color(0xFF1E293B),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  void _shareProfile(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return;
    final displayName = [user.firstName, user.lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' ');
    final name = displayName.isNotEmpty ? displayName : user.username;
    final profileUrl =
        '${AppConfig.mediaBaseUrl}/business-network/profile/${user.id}';
    AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: '$name on AdsyClub',
        description: 'Check out my profile on AdsyClub Business Network.',
        url: profileUrl,
        imageUrl: user.profilePicture,
        subject: '$name on AdsyClub',
        eyebrow: 'Business Network Profile',
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionTile(
                icon: Icons.edit_square,
                label: 'Create Post',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreatePostScreen()),
                ),
              ),
              _buildActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add Funds',
                onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
              ),
              _buildActionTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()),
                ),
              ),
              _buildActionTile(
                icon: Icons.qr_code_2_rounded,
                label: 'QR Code',
                onTap: () {
                  if (_profileData != null) {
                    QrCodeModal.show(context, _profileData!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Icon(icon, size: 26, color: const Color(0xFF475569)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VerificationScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xFFFFFBEB),
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined,
                color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Complete KYC to unlock all features',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFD97706), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    // Plain page: a soft band separates sections, rows run full width with
    // hairline dividers — no card boxes.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 8, color: const Color(0xFFF8FAFC)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
        Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            return _buildMenuItemWidget(item, isLast: isLast);
          }).toList(),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item, {required bool isLast}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
          ),
          child: Row(
            children: [
              item.customIcon ??
                  Icon(item.icon, color: const Color(0xFF475569), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Column(
      children: [
        Container(height: 8, color: const Color(0xFFF8FAFC)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded,
                      color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await AdsyDialog.confirm(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed != true || !context.mounted) return;
    AuthService.logout();
    final rootNavigator = FCMService.navigatorKey.currentState ??
        Navigator.of(context, rootNavigator: true);
    rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
    return Container(
      color: const Color(0xFF3B82F6),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    final user = AuthService.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: user.id),
        ),
      ).then((_) => _loadProfileSummary(refreshAuth: true));
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) => _loadProfileSummary(refreshAuth: true));
  }

  Future<void> _openShorts(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: AdsyLoadingIndicator(
            color: Color(0xFF10B981),
            strokeWidth: 2,
          ),
        );
      },
    );

    try {
      // Fast path: a single feed page (usually cached) is enough to find the
      // first video — the player loads the rest itself. Only when page 1 has
      // no videos do we look further (those pages fetch in parallel).
      var result = await BusinessNetworkService.getShortsFeed(
        startPage: 1,
        pageSize: 12,
        pageWindow: 1,
      );
      var posts = (result['posts'] as List<BusinessNetworkPost>?) ??
          <BusinessNetworkPost>[];
      if (posts.isEmpty && (result['hasMore'] as bool? ?? false)) {
        result = await BusinessNetworkService.getShortsFeed(
          startPage: 2,
          pageSize: 12,
          pageWindow: 2,
        );
        posts = (result['posts'] as List<BusinessNetworkPost>?) ??
            <BusinessNetworkPost>[];
      }
      if (!context.mounted) return;

      BusinessNetworkPost? firstPost;
      PostMedia? firstMedia;

      for (final p in posts) {
        final idx = p.media.indexWhere((m) => m.isVideo);
        if (idx >= 0) {
          firstPost = p;
          firstMedia = p.media[idx];
          break;
        }
      }

      if (!context.mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (firstPost == null || firstMedia == null) {
        if (!context.mounted) return;
        AdsyToast.warning(context, 'No shorts yet');
        return;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShortsPlayerScreen(
            initialPost: firstPost!,
            initialMedia: firstMedia!,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (!context.mounted) return;
      AdsyToast.error(context, 'শর্টস খোলা যায়নি');
    }
  }

  void _handleNavTap(BuildContext context, int index) {
    final rootNavigator = FCMService.navigatorKey.currentState ??
        Navigator.of(context, rootNavigator: true);

    if (index == 2) {
      if (AuthService.isAuthenticated) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
      }
    } else {
      switch (index) {
        case 0:
          rootNavigator.pushNamedAndRemoveUntil(
            '/business-network',
            (route) => route.isFirst,
          );
          break;
        case 1:
          if (AuthService.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationsScreen()),
            );
          } else {
            Navigator.pushNamed(context, '/login');
          }
          break;
        case 3:
          // Footer profile goes to the profile PAGE (this options screen is
          // reached from the header avatar, not this tab).
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
          rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
          break;
      }
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  // Optional widget icon (e.g. the AdsyConnect brand icon).
  final Widget? customIcon;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.customIcon,
  });
}
// ─── Followers / Following bottom sheet ─────────────────────────────────────

class _FollowListSheet extends StatefulWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final Function(String) onUserTap;

  const _FollowListSheet({
    required this.userId,
    required this.type,
    required this.onUserTap,
  });

  @override
  State<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<_FollowListSheet> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
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
          Expanded(
            child: _isLoading
                ? Center(
                    child: AdsyLoadingIndicator(
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
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
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: AdsyLoadingIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final item = _users[index];
                          final userData = widget.type == 'followers'
                              ? item['follower_details'] ??
                                  item['follower'] ??
                                  item
                              : item['following_details'] ??
                                  item['following'] ??
                                  item;
                          final String? userImage =
                              userData['image']?.toString();
                          final bool hasImage =
                              userImage != null && userImage.isNotEmpty;
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
                          final String? profession =
                              userData['profession']?.toString() ??
                                  userData['headline']?.toString();
                          return InkWell(
                            onTap: () => widget
                                .onUserTap(userData['id']?.toString() ?? ''),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    backgroundImage: hasImage
                                        ? NetworkImage(
                                            AppConfig.getAbsoluteUrl(userImage))
                                        : null,
                                    child: !hasImage
                                        ? Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6B7280),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (profession != null &&
                                            profession.isNotEmpty)
                                          Text(
                                            profession,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Colors.grey.shade300, size: 18),
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
