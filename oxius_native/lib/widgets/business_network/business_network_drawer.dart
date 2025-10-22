import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'drawer_menu.dart';
import 'drawer_useful_links.dart';
import 'drawer_gold_sponsor.dart';
import 'drawer_news.dart';
import 'drawer_hashtags.dart';
import 'drawer_featured_product.dart';
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
      width: 288,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Modern Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E40AF),
                    Color(0xFF3B82F6),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Modern Logo Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          size: 24,
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
            
            // Scrollable content with modern spacing
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Menu Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DrawerMenu(currentRoute: currentRoute),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildModernDivider(),
                    const SizedBox(height: 20),
                    
                    // Useful Links Section
                    const DrawerUsefulLinks(),
                    
                    const SizedBox(height: 20),
                    _buildModernDivider(),
                    const SizedBox(height: 20),
                    
                    // Gold Sponsor Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DrawerGoldSponsor(isLoggedIn: user != null),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildModernDivider(),
                    const SizedBox(height: 20),
                    
                    // News Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const DrawerNews(),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildModernDivider(),
                    const SizedBox(height: 20),
                    
                    // Hashtags Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const DrawerHashtags(),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildModernDivider(),
                    const SizedBox(height: 20),
                    
                    // Featured Product Section
                    const DrawerFeaturedProduct(),
                    
                    const SizedBox(height: 20),
                    _buildModernDivider(),
                    const SizedBox(height: 20),
                    
                    // Top Contributors Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const DrawerContributors(),
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding for mobile nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
