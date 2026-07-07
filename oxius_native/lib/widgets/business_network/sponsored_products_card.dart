import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/cart_item.dart';
import '../../config/app_config.dart';
import '../../widgets/common/adsy_toast.dart';

/// Sponsored products as a horizontal carousel — same visual language as the
/// other feed discovery rows (workspace gigs / micro gigs) so the feed reads
/// as one consistent system.
class SponsoredProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const SponsoredProductsCard({
    super.key,
    required this.products,
  });

  static const _accent = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final items = products.take(10).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — mirrors FeedDiscoveryCard
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 15, color: _accent),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'স্পনসর্ড প্রোডাক্ট',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/eshop'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text('সব দেখুন',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accent)),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: _accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Horizontal product tiles
          SizedBox(
            height: 208,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _ProductTile(
                product: items[i],
                onBuy: () => _navigateToCheckout(context, items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCheckout(BuildContext context, Map<String, dynamic> product) {
    try {
      final cartProduct = Product(
        id: product['id'],
        name: product['name'] ?? product['title'] ?? 'Product',
        description: product['description'],
        regularPrice:
            _parseDouble(product['regular_price'] ?? product['price']),
        salePrice: product['sale_price'] != null
            ? _parseDouble(product['sale_price'])
            : null,
        quantity: product['quantity'] as int? ?? 999,
        isFreeDelivery: product['is_free_delivery'] as bool?,
        deliveryFeeInsideDhaka: product['delivery_fee_inside_dhaka'] != null
            ? _parseDouble(product['delivery_fee_inside_dhaka'])
            : null,
        deliveryFeeOutsideDhaka: product['delivery_fee_outside_dhaka'] != null
            ? _parseDouble(product['delivery_fee_outside_dhaka'])
            : null,
        imageDetails: product['image_details'] != null
            ? (product['image_details'] as List)
                .map((img) =>
                    ProductImage.fromJson(img as Map<String, dynamic>))
                .toList()
            : null,
      );

      final cartItem = CartItem(product: cartProduct, quantity: 1);

      Navigator.pushNamed(
        context,
        '/checkout',
        arguments: {
          'cartItems': [cartItem],
        },
      );
    } catch (e) {
      AdsyToast.error(context, 'চেকআউটে যাওয়া যায়নি');
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onBuy;

  const _ProductTile({required this.product, required this.onBuy});

  String _imageUrl() {
    final details = product['image_details'];
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map && first['image'] != null) {
        final raw = first['image'].toString();
        if (raw.isNotEmpty) {
          return raw.startsWith('http')
              ? raw
              : '${AppConfig.mediaBaseUrl}$raw';
        }
      }
    }
    final raw = (product['image'] ?? '').toString();
    if (raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${AppConfig.mediaBaseUrl}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? product['title'] ?? '').toString();
    final regular = SponsoredProductsCard._parseDouble(
        product['regular_price'] ?? product['price']);
    final sale = product['sale_price'] != null
        ? SponsoredProductsCard._parseDouble(product['sale_price'])
        : null;
    final hasSale = sale != null && sale > 0 && sale < regular;
    final price = hasSale ? sale : regular;
    final img = _imageUrl();

    return GestureDetector(
      onTap: onBuy,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 150,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (img.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        memCacheWidth: 320,
                        placeholder: (c, u) =>
                            Container(color: const Color(0xFFF1F5F9)),
                        errorWidget: (c, u, e) => _iconTile(),
                      )
                    else
                      _iconTile(),
                    if (hasSale)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '-${(100 - (sale / regular * 100)).round()}%',
                            style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.25,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '৳${price.toStringAsFixed(0)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: SponsoredProductsCard._accent,
                          ),
                        ),
                      ),
                      if (hasSale) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '৳${regular.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'কিনুন',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SponsoredProductsCard._accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconTile() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
          child: Icon(Icons.shopping_bag_outlined,
              size: 28, color: Color(0xFF94A3B8))),
    );
  }
}
