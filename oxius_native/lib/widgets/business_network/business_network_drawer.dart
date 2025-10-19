import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'drawer_menu.dart';
import 'drawer_gold_sponsor.dart';
import 'drawer_news.dart';
import 'drawer_hashtags.dart';
import 'drawer_contributors.dart';

class BusinessNetworkDrawer extends StatelessWidget {
  final String? currentRoute;
  
  const BusinessNetworkDrawer({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    
    return Drawer(
      width: 280,
      child: Container(
        color: const Color(0xFFFAFAFA),
        child: Column(
          children: [
            // Compact Header with gradient
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.indigo.shade600,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business_center,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Business Network',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        iconSize: 22,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Scrollable content with reduced padding
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Menu Section
                    DrawerMenu(currentRoute: currentRoute),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    
                    // Gold Sponsor Section
                    DrawerGoldSponsor(isLoggedIn: user != null),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    
                    // News Section
                    const DrawerNews(),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    
                    // Hashtags Section
                    const DrawerHashtags(),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),
                    
                    // Top Contributors Section
                    const DrawerContributors(),
                    
                    const SizedBox(height: 80), // Bottom padding for mobile nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
