import 'package:flutter/material.dart';

class DrawerUsefulLinks extends StatelessWidget {
  const DrawerUsefulLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final links = [
      {'label': 'eShop', 'icon': Icons.shopping_bag_outlined, 'path': '/eshop'},
      {'label': 'Earn Money', 'icon': Icons.attach_money, 'path': '/micro-gigs'},
      {'label': 'Sell', 'icon': Icons.store_outlined, 'path': '/shop-manager'},
      {'label': 'Recharge', 'icon': Icons.phone_android, 'path': '/mobile-recharge'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Text(
            'USEFUL LINKS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.6,
            ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, link['path'] as String);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(link['icon'] as IconData,
                  size: 18, color: const Color(0xFF334155)),
              const SizedBox(height: 5),
              Text(
                link['label'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
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
