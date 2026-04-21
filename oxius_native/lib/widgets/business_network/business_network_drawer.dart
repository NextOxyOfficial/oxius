import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/business_network/profile_screen.dart';
import 'drawer_menu.dart';
import 'drawer_useful_links.dart';
import 'drawer_gold_sponsor.dart';
import 'drawer_news.dart';
import 'drawer_hashtags.dart';
import 'drawer_featured_product.dart';
import 'drawer_contributors.dart';
import '../ios_web_redirect_screen.dart';

/// Side drawer used across the Business Network screens.
///
/// Redesigned for a tighter, more consistent layout:
///   * Responsive width (85% of screen, capped at 300px).
///   * Modern gradient header with optional compact user card.
///   * Unified section spacing + slim gradient dividers.
class BusinessNetworkDrawer extends StatelessWidget {
  final String? currentRoute;

  const BusinessNetworkDrawer({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive width: ~85% of screen, capped so it never feels too wide.
    final drawerWidth = math.min(screenWidth * 0.85, 300.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Column(
          children: [
            _buildHeader(context, user),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 10, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Menu
                    _section(
                      horizontalPadding: 10,
                      child: DrawerMenu(currentRoute: currentRoute),
                    ),

                    _sectionDivider(),

                    // Useful Links (manages own horizontal padding internally)
                    const DrawerUsefulLinks(),

                    _sectionDivider(),

                    // Gold Sponsor (hidden on iOS for App Store digital-purchase
                    // policy compliance).
                    if (!isIOSPlatform) ...[
                      DrawerGoldSponsor(isLoggedIn: user != null),
                      _sectionDivider(),
                    ],

                    // News (manages own horizontal padding)
                    const DrawerNews(),

                    _sectionDivider(),

                    // Hashtags
                    _section(
                      horizontalPadding: 4,
                      child: const DrawerHashtags(),
                    ),

                    _sectionDivider(),

                    // Featured Product (manages own horizontal padding)
                    const DrawerFeaturedProduct(),

                    _sectionDivider(),

                    // Top Contributors
                    _section(
                      horizontalPadding: 4,
                      child: const DrawerContributors(),
                    ),

                    // Spacer to clear the mobile bottom nav.
                    const SizedBox(height: 72),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button row (title intentionally removed)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 20,
                  color: Colors.white,
                  tooltip: 'Close',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ),
            ),

            // User card (only when logged in)
            if (user != null) _buildUserCard(context, user),

            // Sign-in CTA when logged out
            if (user == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                child: _buildSignInButton(context),
              ),

            if (user != null) const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user) {
    final displayName =
        ((user.firstName ?? '').isNotEmpty || (user.lastName ?? '').isNotEmpty)
            ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
            : user.username;
    final subtitle = (user.profession != null && user.profession!.isNotEmpty)
        ? user.profession!
        : user.email;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
      child: Material(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: user.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF93C5FD),
                            ),
                          ],
                          if (user.isPro) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFFBBF24),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(User user) {
    final img = user.profilePicture;
    final initials = _initials(user);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
        color: Colors.white.withOpacity(0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: img != null && img.isNotEmpty
          ? Image.network(
              img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(initials),
            )
          : _avatarFallback(initials),
    );
  }

  Widget _avatarFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(User user) {
    final first = (user.firstName ?? '').trim();
    final last = (user.lastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (user.username.isNotEmpty) return user.username[0].toUpperCase();
    return 'U';
  }

  Widget _buildSignInButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/login');
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 6),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section helpers
  // ---------------------------------------------------------------------------
  Widget _section({required Widget child, double horizontalPadding = 0}) {
    if (horizontalPadding == 0) return child;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }

  Widget _sectionDivider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade200,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
