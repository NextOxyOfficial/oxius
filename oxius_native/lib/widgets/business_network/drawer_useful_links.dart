import 'package:flutter/material.dart';

class DrawerUsefulLinks extends StatelessWidget {
  const DrawerUsefulLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final links = [
      {'label': 'eShop', 'icon': Icons.shopping_bag_outlined, 'path': '/eshop', 'color': const Color(0xFF3B82F6)},
      {'label': 'Earn Money', 'icon': Icons.attach_money, 'path': '/micro-gigs', 'color': const Color(0xFF10B981)},
      {'label': 'Sell', 'icon': Icons.store_outlined, 'path': '/shop-manager', 'color': const Color(0xFFF59E0B)},
      {'label': 'Recharge', 'icon': Icons.phone_android, 'path': '/mobile-recharge', 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: Row(
            children: [
              Icon(Icons.link, size: 11, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'USEFUL LINKS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              for (int i = 0; i < links.length; i++) ...[
                Expanded(child: _buildLinkTile(context, links[i])),
                if (i < links.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTile(BuildContext context, Map<String, Object> link) {
    final color = link['color'] as Color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, link['path'] as String);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(link['icon'] as IconData, size: 16, color: color),
              const SizedBox(height: 3),
              Text(
                link['label'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
