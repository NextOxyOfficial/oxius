import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class DrawerFeaturedProduct extends StatefulWidget {
  const DrawerFeaturedProduct({super.key});

  @override
  State<DrawerFeaturedProduct> createState() => _DrawerFeaturedProductState();
}

class _DrawerFeaturedProductState extends State<DrawerFeaturedProduct> {
  bool _isLoading = true;
  Map<String, dynamic>? _displayProduct;
  List<Map<String, dynamic>> _allProducts = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/all-products/?limit=20&is_featured=true'),
      );

      print('Featured products response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results'] != null && data['results'] is List) {
          final products = (data['results'] as List)
              .map((p) => Map<String, dynamic>.from(p))
              .toList();
          
          if (mounted) {
            setState(() {
              _allProducts = products;
              _displayProduct = products.isNotEmpty ? products[0] : null;
            });
          }
          
          print('Loaded ${products.length} featured products');
        }
      } else {
        print('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading featured products: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRandomProduct() {
    if (_allProducts.isEmpty) return;
    
    if (_allProducts.length == 1) {
      // Only one product, just keep showing it
      return;
    }
    
    // Get current index
    final currentIndex = _displayProduct != null
        ? _allProducts.indexWhere((p) => p['id'] == _displayProduct!['id'])
        : -1;
    
    // Pick a random different product
    int newIndex;
    do {
      newIndex = _random.nextInt(_allProducts.length);
    } while (newIndex == currentIndex);
    
    setState(() {
      _displayProduct = _allProducts[newIndex];
    });
  }

  int _calculateDiscount(Map<String, dynamic> product) {
    final salePrice = double.tryParse(product['sale_price']?.toString() ?? '0') ?? 0;
    final regularPrice = double.tryParse(product['regular_price']?.toString() ?? '0') ?? 0;
    
    if (regularPrice <= 0 || salePrice <= 0 || salePrice >= regularPrice) return 0;
    
    return ((regularPrice - salePrice) / regularPrice * 100).round();
  }

  String _getProductImage(Map<String, dynamic>? product) {
    if (product == null) return '';
    
    try {
      // Check image_details
      if (product['image_details'] != null) {
        final imageDetails = product['image_details'];
        
        if (imageDetails is List && imageDetails.isNotEmpty) {
          final firstImage = imageDetails[0];
          if (firstImage is Map && firstImage['image'] != null) {
            return firstImage['image'].toString();
          }
          if (firstImage is String) {
            return firstImage;
          }
        }
        
        if (imageDetails is String) {
          return imageDetails;
        }
      }
      
      // Check images array
      if (product['images'] != null) {
        final images = product['images'];
        if (images is List && images.isNotEmpty) {
          final firstImage = images[0];
          if (firstImage is Map && firstImage['image'] != null) {
            return firstImage['image'].toString();
          }
          if (firstImage is String) {
            return firstImage;
          }
        }
      }
      
      // Check direct image field
      if (product['image'] != null) {
        return product['image'].toString();
      }
    } catch (e) {
      print('Error getting product image: $e');
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'FEATURED PRODUCT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 16, color: Colors.grey.shade600),
                onPressed: _showRandomProduct,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  backgroundColor: Colors.grey.shade100,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
        
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isLoading
              ? _buildLoadingState()
              : _displayProduct != null
                  ? _buildProductCard()
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildProductCard() {
    final product = _displayProduct!;
    final salePrice = double.tryParse(product['sale_price']?.toString() ?? '0') ?? 0;
    final regularPrice = double.tryParse(product['regular_price']?.toString() ?? '0') ?? 0;
    final finalPrice = salePrice > 0 ? salePrice : regularPrice;
    final discount = _calculateDiscount(product);
    final imageUrl = _getProductImage(product);

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to product details
        // Navigator.pushNamed(context, '/product-details', arguments: product['slug']);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
              
              // Gradient Overlay & Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and Discount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '৳${finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Product Name
                      Text(
                        product['name'] ?? 'Product',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
