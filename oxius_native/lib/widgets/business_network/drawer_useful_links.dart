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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Icon(Icons.link, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'USEFUL LINKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        
        // Links Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
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
          // TODO: Navigate to path
          // Navigator.pushNamed(context, path);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to: $path')),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
