import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import 'profile_screen.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import 'notifications_screen.dart';
import 'create_post_screen.dart';
import 'shorts_player_screen.dart';
import 'activity_history_screen.dart';
import '../inbox_screen.dart';
import '../workspace/workspace_screen.dart';
import '../settings_screen.dart';
import '../verification_screen.dart';

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
  bool _isProfileLoading = true;
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
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isProfileLoading = true);
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
        _isProfileLoading = false;
        _mediaRefreshTick = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isProfileLoading = false);
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
    final fullName = [firstName, lastName].where((value) => value.isNotEmpty).join(' ');
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
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () => _loadProfileSummary(refreshAuth: true),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                      onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
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
                      label: 'AdsyConnect',
                      subtitle: 'Messages and conversations',
                      gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InboxScreen()),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.work_outline_rounded,
                      label: 'Workspace',
                      subtitle: 'Post your about expertise and get order',
                      gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WorkspaceScreen()),
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
                      onTap: () => Navigator.pushNamed(context, '/micro-gigs'),
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
                      label: 'Settings',
                      subtitle: 'App preferences',
                      gradient: const [Color(0xFF78716C), Color(0xFF57534E)],
                      onTap: () => _openSettings(context),
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
                currentIndex: 3,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 142,
                  width: double.infinity,
                  child: bannerUrl.isNotEmpty
                      ? Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildHeaderBannerFallback(),
                        )
                      : _buildHeaderBannerFallback(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.16),
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
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
                Positioned(
                  left: 14,
                  bottom: -34,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isPro
                          ? const LinearGradient(colors: [Color(0xFFFACC15), Color(0xFFF59E0B)])
                          : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                    ),
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
                              )
                            : _buildAvatarPlaceholder(name),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 42, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 88),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                if (isVerified)
                                  const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 18),
                                if (isPro)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFACC15),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (profession.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                profession,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildHeaderStat('Posts', _resolvedPostCount())),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderStat('Followers', _resolvedFollowersCount())),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderStat('Following', _resolvedFollowingCount())),
                    ],
                  ),
                  if (_resolvedDiamondBalance() > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.diamond_outlined, size: 18, color: Color(0xFFDB2777)),
                          const SizedBox(width: 8),
                          Text(
                            '${_resolvedDiamondBalance()} Diamonds',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9D174D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
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
    final profileUrl = '${AppConfig.mediaBaseUrl}/business-network/profile/${user.id}';
    Share.share(
      'Check out my profile on Oxius: $profileUrl',
      subject: 'My Oxius Profile',
    );
  }

  void _showQrCode(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return;
    final profileUrl = '${AppConfig.mediaBaseUrl}/business-network/profile/${user.id}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'My Profile QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan to view my profile',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 120,
                      color: const Color(0xFF1E293B),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profileUrl,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: profileUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile link copied!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('Copy Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareProfile(context);
                },
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text('Share Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
      child: Row(
        children: [
          _buildQuickActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Create Post',
            gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Add Funds',
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
              borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
        margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFD97706),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete KYC Verification',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlock all features and start earning',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF92400E).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
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
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
            strokeWidth: 2,
          ),
        );
      },
    );

    try {
      final result = await BusinessNetworkService.getShortsFeed(
        startPage: 1,
        pageSize: 12,
        pageWindow: 3,
      );
      if (!context.mounted) return;
      final posts = (result['posts'] as List<BusinessNetworkPost>?) ?? <BusinessNetworkPost>[];

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No shorts yet'),
            backgroundColor: Colors.orange,
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open shorts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNavTap(BuildContext context, int index) {
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
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/business-network',
            (route) => route.settings.name == '/',
          );
          break;
        case 1:
          if (AuthService.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          } else {
            Navigator.pushNamed(context, '/login');
          }
          break;
        case 3:
          break;
        case 4:
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}
