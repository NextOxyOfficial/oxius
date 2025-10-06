import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isLoading;
  final VoidCallback onBuyNow;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isLoading,
    required this.onBuyNow,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final title = p['name'] ?? p['title'] ?? 'Product';
    final regular = p['regular_price'] ?? p['price'];
    final sale = p['sale_price'];
    final imageUrl = _getProductImageUrl(p);
    final discount = _calcDiscount(sale, regular);
    final isFreeDelivery = p['is_free_delivery'] == true;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Material(
          color: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section - Square aspect ratio like eshop_section
                  Expanded(
                    flex: 2,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    headers: const {
                                      'User-Agent': 'Mozilla/5.0 (compatible; Flutter/3.0)',
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: Colors.grey.shade400,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 32,
                                          color: Colors.purple.shade300,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 32,
                                      color: Colors.purple.shade300,
                                    ),
                                  ),
                          ),
                        ),

                        // Discount Badge - Top Left (like eshop_section)
                        if (discount > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flash_on, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$discount% OFF',
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Free Delivery Badge - Bottom Left (like eshop_section)
                        if (isFreeDelivery)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_shipping, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'FREE DELIVERY',
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Quick View overlay (hover) - Like eshop_section
                        Positioned.fill(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: _hovered ? 1 : 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.0),
                              child: Center(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  onPressed: () {
                                    if (widget.onTap != null) widget.onTap!();
                                  },
                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                  label: const Text('Quick View'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details - Using same padding as eshop_section: fromLTRB(8, 8, 8, 0)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Section - Moved to top (Vue: mb-2) - EXACT MATCH
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '৳',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _formatPrice(sale ?? regular),
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (sale != null && _toNum(sale) != null && regular != null && _toNum(regular) != null && _toNum(sale)! < _toNum(regular)!)
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '৳',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _formatPrice(regular),
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            color: Colors.grey.shade400,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Product Title - Moved above store name (Vue: mb-2) - EXACT MATCH
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),

                          // Store Link - Moved below product name (Vue: mb-3) - EXACT MATCH
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.storefront_outlined, size: 12, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getStoreName(p),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Full Width Buy Now Button (Vue styling) - EXACT MATCH
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.isLoading ? null : widget.onBuyNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF374151), // Vue: bg-gray-700
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size.fromHeight(40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              child: widget.isLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Processing...',
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.shopping_cart_outlined, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Buy Now',
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  int _calcDiscount(dynamic sale, dynamic regular) {
    final saleNum = _toNum(sale);
    final regularNum = _toNum(regular);
    
    if (saleNum == null || regularNum == null || regularNum <= 0 || saleNum >= regularNum) {
      return 0;
    }
    
    return ((regularNum - saleNum) / regularNum * 100).round();
  }

  String _formatPrice(dynamic v) {
    final n = _toNum(v);
    if (n == null) return '';
    final s = n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return s; // currency symbol added in Text
  }

  // Helper methods
  String _getProductImageUrl(Map<String, dynamic> product) {
    // Try image_details first (ProductMediaSerializer)
    if (product['image_details'] != null && product['image_details'] is List) {
      final imageDetails = product['image_details'] as List;
      if (imageDetails.isNotEmpty) {
        final firstImage = imageDetails.first;
        if (firstImage is Map && firstImage['image'] != null) {
          return _makeAbsoluteUrl(firstImage['image'].toString());
        }
      }
    }
    
    // Try direct image field
    if (product['image'] != null && product['image'].toString().isNotEmpty) {
      return _makeAbsoluteUrl(product['image'].toString());
    }
    
    // Try featured_image field
    if (product['featured_image'] != null && product['featured_image'].toString().isNotEmpty) {
      return _makeAbsoluteUrl(product['featured_image'].toString());
    }
    
    return '';
  }
  
  String _makeAbsoluteUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // If it's already an absolute URL, check if it's using the old domain
      if (url.contains('adsyclub.com')) {
        // Replace old domain with current backend domain
        return url.replaceFirst('adsyclub.com', 'oxius.vercel.app');
      }
      return url;
    }
    
    // Handle Django media URLs
    const baseUrl = 'https://oxius.vercel.app'; // Your current backend URL
    if (url.startsWith('/media/') || url.startsWith('media/')) {
      return '$baseUrl${url.startsWith('/') ? url : '/$url'}';
    }
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  String _getStoreName(Map<String, dynamic> product) {
    // Try owner_details first
    if (product['owner_details'] != null && product['owner_details'] is Map) {
      final ownerDetails = product['owner_details'] as Map;
      if (ownerDetails['store_name'] != null && ownerDetails['store_name'].toString().isNotEmpty) {
        return ownerDetails['store_name'].toString();
      }
      if (ownerDetails['name'] != null && ownerDetails['name'].toString().isNotEmpty) {
        return ownerDetails['name'].toString();
      }
    }
    
    // Try direct fields
    if (product['store_name'] != null && product['store_name'].toString().isNotEmpty) {
      return product['store_name'].toString();
    }
    if (product['owner'] != null && product['owner'].toString().isNotEmpty) {
      return product['owner'].toString();
    }
    
    return 'AdsyClub Store';
  }

  double? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', ''));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}