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
      width: 288, // w-72 = 288px
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Spacer for alignment
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Menu Section
                      DrawerMenu(currentRoute: currentRoute),
                      
                      const SizedBox(height: 28),
                      
                      // Gold Sponsor Section
                      DrawerGoldSponsor(isLoggedIn: user != null),
                      
                      const SizedBox(height: 28),
                      
                      // News Section
                      const DrawerNews(),
                      
                      const SizedBox(height: 28),
                      
                      // Hashtags Section
                      const DrawerHashtags(),
                      
                      const SizedBox(height: 28),
                      
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
      ),
    );
  }
}
