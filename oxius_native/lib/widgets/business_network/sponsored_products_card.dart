import 'package:flutter/material.dart';
import '../../widgets/product_card.dart';
import '../../models/cart_item.dart';

class SponsoredProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  
  const SponsoredProductsCard({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final displayProducts = isMobile ? products.take(2).toList() : products.take(3).toList();

    if (displayProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sponsored Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          // Products grid - Using existing ProductCard widget
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              childAspectRatio: 0.61,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: displayProducts.length,
            itemBuilder: (context, index) {
              final product = displayProducts[index];
              return ProductCard(
                product: product,
                isLoading: false,
                onBuyNow: () {
                  _navigateToCheckout(context, product);
                },
              );
            },
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
        regularPrice: _parseDouble(product['regular_price'] ?? product['price']),
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
                .map((img) => ProductImage.fromJson(img as Map<String, dynamic>))
                .toList()
            : null,
      );

      final cartItem = CartItem(
        product: cartProduct,
        quantity: 1,
      );

      Navigator.pushNamed(
        context,
        '/checkout',
        arguments: {
          'cartItems': [cartItem],
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to proceed to checkout. $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
