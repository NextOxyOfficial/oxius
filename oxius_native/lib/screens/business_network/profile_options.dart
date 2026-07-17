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
    return _mediaUrl(_stringValue(_profileData?['store_banner']));
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
        backgroundColor: const Color(0xFFF1F5F9),
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
      child: Column(
        children: [
          // Banner + avatar stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              SizedBox(
                height: 130,
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
              // Back & share buttons
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      _buildGlassButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _buildGlassButton(
                        icon: Icons.share_outlined,
                        onTap: () => _shareProfile(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Centered large avatar
              Positioned(
                bottom: -60,
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
          // Profile info below banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 74, 16, 16),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;
                return _buildMenuItemWidget(item, isLast: isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item, {required bool isLast}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
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
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.logout();
              final rootNavigator = FCMService.navigatorKey.currentState ??
                  Navigator.of(context, rootNavigator: true);
              rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
