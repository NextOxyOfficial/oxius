import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import 'profile_screen.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import 'notifications_screen.dart';
import 'create_post_screen.dart';
import '../settings_screen.dart';
import '../verification_screen.dart';

class ProfileOptionsScreen extends StatelessWidget {
  const ProfileOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final user = AuthService.currentUser;
    final String name = user?.displayName ?? 'Guest';
    final String? avatarUrl = user?.profilePicture;
    final String fullAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty
        ? AppConfig.getAbsoluteUrl(avatarUrl)
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildTopIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  _buildTopIconButton(
                    icon: Icons.attach_money_rounded,
                    onTap: () {
                      Navigator.pushNamed(context, '/deposit-withdraw');
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildTopIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // User Profile Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: fullAvatarUrl.isNotEmpty
                          ? Image.network(
                              fullAvatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarPlaceholder(name);
                              },
                            )
                          : _buildAvatarPlaceholder(name),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and View Profile
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            _navigateToProfile(context);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        // TODO: Edit profile
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Verification Banner
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerificationScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: user?.isVerified == true
                            ? const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        user?.isVerified == true
                            ? Icons.verified_rounded
                            : Icons.verified_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.isVerified == true
                                ? 'KYC Verified'
                                : 'Verify your account KYC',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            user?.isVerified == true
                                ? 'Your account is verified'
                                : 'to start earning',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 22,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      onTap: () {
                        _navigateToProfile(context);
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () {
                        // TODO: Navigate to History
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.people_outline_rounded,
                      label: 'Subscriber',
                      onTap: () {
                        // TODO: Navigate to Subscriber
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.subscriptions_outlined,
                      label: 'Subscription',
                      onTap: () {
                        // TODO: Navigate to Subscription
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.location_on_outlined,
                      label: 'Rent',
                      onTap: () {
                        // TODO: Navigate to Rent
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.bookmark_outline_rounded,
                      label: 'Watch later',
                      onTap: () {
                        // TODO: Navigate to Watch later
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFEF4444),
                      label: 'Liked Video',
                      onTap: () {
                        // TODO: Navigate to Liked Video
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.crop_square_rounded,
                      label: 'Active User Panel',
                      onTap: () {
                        // TODO: Navigate to Active User Panel
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      onTap: () {
                        // TODO: Logout
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? BusinessNetworkBottomNavBar(
              currentIndex: 3,
              isLoggedIn: AuthService.isAuthenticated,
              unreadCount: 0,
              onTap: (index) {
                if (index == 2) {
                  if (AuthService.isAuthenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
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
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                      break;
                    case 3:
                      break;
                    case 4:
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                      break;
                  }
                }
              },
            )
          : null,
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
    return Container(
      color: const Color(0xFF3B82F6).withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3B82F6),
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
      );
    }
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: iconColor ?? Colors.grey.shade700,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
