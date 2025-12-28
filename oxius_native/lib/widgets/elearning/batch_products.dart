import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/elearning_service.dart';
import '../../models/cart_item.dart';
import '../product_card.dart';

class BatchProducts extends StatefulWidget {
  final String? selectedBatch;

  const BatchProducts({
    super.key,
    this.selectedBatch,
  });

  @override
  State<BatchProducts> createState() => _BatchProductsState();
}

class _BatchProductsState extends State<BatchProducts> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedBatch != null) {
      _loadProducts();
    }
  }

  @override
  void didUpdateWidget(BatchProducts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBatch != oldWidget.selectedBatch) {
      if (widget.selectedBatch != null) {
        _loadProducts();
      } else {
        setState(() {
          _products = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (widget.selectedBatch == null) return;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final products = await ElearningService.fetchBatchProducts(
        widget.selectedBatch!,
        limit: 50,
      );

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products';
        _loading = false;
      });
    }
  }

  // Randomize products for display
  List<Map<String, dynamic>> get _randomizedProducts {
    if (_products.isEmpty) return [];
    final shuffled = List<Map<String, dynamic>>.from(_products);
    shuffled.shuffle(Random());
    return shuffled;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedBatch == null) return const SizedBox.shrink();
    if (!_loading && _error == null && _products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.selectedBatch} ব্যাচের গুরুত্বপূর্ণ বই ও শিক্ষা সামগ্রী',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.selectedBatch!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Loading state
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),

          // Error state
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadProducts,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),

          // Products horizontal scroll
          if (!_loading && _error == null && _products.isNotEmpty)
            SizedBox(
              height: 340,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _randomizedProducts.length,
                itemBuilder: (context, index) {
                  final product = _randomizedProducts[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ProductCard(
                      product: product,
                      isLoading: false,
                      onBuyNow: () {
                        _navigateToCheckout(context, product);
                      },
                    ),
                  );
                },
              ),
            ),

          // View all link
          if (!_loading && _error == null && _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to all products
                    Navigator.pushNamed(context, '/eshop');
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Products'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade600,
                  ),
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
