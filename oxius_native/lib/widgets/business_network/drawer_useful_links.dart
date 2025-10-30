import 'package:flutter/material.dart';

class DrawerUsefulLinks extends StatelessWidget {
  const DrawerUsefulLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final links = [
      {'label': 'eShop', 'icon': Icons.shopping_bag_outlined, 'path': '/eshop'},
      {'label': 'Earn Money', 'icon': Icons.attach_money, 'path': '/#micro-gigs'},
      {'label': 'Sell Products', 'icon': Icons.store_outlined, 'path': '/shop-manager'},
      {'label': 'Mobile Recharge', 'icon': Icons.phone_android, 'path': '/mobile-recharge'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Row(
            children: [
              Icon(Icons.link, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'USEFUL LINKS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        
        // Links Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 2.0,
            children: links.map((link) {
              return _buildLinkCard(
                context,
                link['label'] as String,
                link['icon'] as IconData,
                link['path'] as String,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCard(BuildContext context, String label, IconData icon, String path) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer first
          Navigator.pushNamed(context, path);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
