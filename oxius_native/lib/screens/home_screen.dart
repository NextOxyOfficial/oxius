import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/header.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/hero_banner.dart';
import '../widgets/search_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const MobileDrawer(),
      body: CustomScrollView(
        slivers: [
          const AppHeader(),
          const HeroBanner(),
          const SearchWidget(),
          _buildQuickActions(context),
          _buildMobileServicesGrid(context),
        ],
      ),
    );
  }

  // Quick Actions Section
  Widget _buildQuickActions(BuildContext context) {
    final quickActions = [
      {'icon': Icons.payment, 'label': 'Mobile Recharge', 'color': Colors.blue},
      {'icon': Icons.business, 'label': 'Business Network', 'color': Colors.green},
      {'icon': Icons.shopping_cart, 'label': 'E-Shop', 'color': Colors.orange},
      {'icon': Icons.school, 'label': 'Courses', 'color': Colors.purple},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Quick Actions',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickActions.map((action) {
                  return _buildQuickActionItem(
                    context,
                    action['icon'] as IconData,
                    action['label'] as String,
                    action['color'] as Color,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label coming soon!'),
            backgroundColor: color,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Mobile Services Grid (Mobile view only)
  Widget _buildMobileServicesGrid(BuildContext context) {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 768) {
            return const SizedBox.shrink(); // Hide on desktop
          }

          final services = [
            'Business Network', 'News Feed', 'E-Shop', 'Sale Listings',
            'Mobile Recharge', 'Courses', 'Reviews', 'Support',
            'Subscription', 'Global Popup', 'Cities', 'Base Services'
          ];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'All Services',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return _buildMobileServiceButton(context, services[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileServiceButton(BuildContext context, String serviceName) {
    final serviceIcons = {
      'Business Network': Icons.network_check,
      'News Feed': Icons.newspaper,
      'E-Shop': Icons.shopping_cart,
      'Sale Listings': Icons.sell,
      'Mobile Recharge': Icons.payment,
      'Courses': Icons.school,
      'Reviews': Icons.rate_review,
      'Support': Icons.support_agent,
      'Subscription': Icons.subscriptions,
      'Global Popup': Icons.notifications,
      'Cities': Icons.location_city,
      'Base Services': Icons.miscellaneous_services,
    };

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$serviceName coming soon!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              serviceIcons[serviceName] ?? Icons.apps,
              color: const Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            serviceName,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}