import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import 'package:oxius_native/utils/image_utils.dart';
import '../screens/product_details_screen.dart';
import '../config/app_config.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class ProductCardLayout {
  static double detailsHeight(double screenWidth) {
    if (screenWidth < 360) return 112.0;
    if (screenWidth > 600) return 128.0;
    return 120.0;
  }

  static double cardHeight({
    required double cardWidth,
    required double screenWidth,
  }) {
    return cardWidth + detailsHeight(screenWidth);
  }

  static SliverGridDelegate buildGridDelegate({
    required double availableWidth,
    required double screenWidth,
    int crossAxisCount = 2,
    double crossAxisSpacing = 8,
    double mainAxisSpacing = 8,
  }) {
    final totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
    final usableWidth =
        (availableWidth - totalSpacing).clamp(0.0, double.infinity);
    final cardWidth =
        (usableWidth / crossAxisCount).clamp(0.0, double.infinity);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent:
          cardHeight(cardWidth: cardWidth, screenWidth: screenWidth),
    );
  }

  static double horizontalCardWidth(double screenWidth) {
    if (screenWidth < 360) return 172.0;
    if (screenWidth > 600) return 212.0;
    return 188.0;
  }

  static double horizontalCardHeight(double screenWidth, {double? cardWidth}) {
    final width = cardWidth ?? horizontalCardWidth(screenWidth);
    return cardHeight(cardWidth: width, screenWidth: screenWidth);
  }
}

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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    final p = widget.product;
    final title = p['name'] ?? p['title'] ?? 'Product';
    final regular = p['regular_price'] ?? p['price'];
    final sale = p['sale_price'];
    final imageUrl = _getProductImageUrl(p);
    final discount = _calcDiscount(sale, regular);
    final isFreeDelivery = p['is_free_delivery'] == true;

    // Responsive sizing
    final buttonHeight = isSmallScreen
        ? 32.0
        : isLargeScreen
            ? 44.0
            : 36.0;
    final iconSize = isSmallScreen
        ? 12.0
        : isLargeScreen
            ? 16.0
            : 14.0;
    final textSize = isSmallScreen
        ? 11.0
        : isLargeScreen
            ? 14.0
            : 12.0;
    final priceTextSize = isSmallScreen
        ? 14.0
        : isLargeScreen
            ? 18.0
            : 15.0;
    final storeIconSize = isSmallScreen
        ? 14.0
        : isLargeScreen
            ? 18.0
            : 16.0;
    final storeTextSize = isSmallScreen
        ? 9.0
        : isLargeScreen
            ? 12.0
            : 10.0;

    final navigationCallback = widget.onTap ??
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(product: widget.product),
            ),
          );
        };

    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section - Square aspect ratio like eshop_section
            // Wrap image in InkWell for navigation
            InkWell(
              onTap: navigationCallback,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: AspectRatio(
                  aspectRatio: 1.0, // Square image
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: imageUrl.isNotEmpty
                              ? AppImage.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 32,
                                      color: Colors.purple.shade300,
                                    ),
                                  ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on,
                                    size: iconSize - 2, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '$discount% OFF',
                                  style: AppFonts.roboto(
                                    fontSize: textSize - 1,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_shipping,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'FREE DELIVERY',
                                  style: AppFonts.roboto(
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                                onPressed: () {
                                  if (widget.onTap != null) widget.onTap!();
                                },
                                icon: const Icon(Icons.remove_red_eye_outlined,
                                    size: 16),
                                label: const Text('Quick View'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Details - Reduced padding for more compact layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Wrap product info in InkWell (price, title, store)
                    InkWell(
                      onTap: navigationCallback,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Price Section - Reduced bottom margin
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '৳',
                                        style: AppFonts.roboto(
                                          fontSize: textSize - 1,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _formatPrice(sale ?? regular),
                                        style: AppFonts.roboto(
                                          fontSize: priceTextSize,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (sale != null &&
                                    _toNum(sale) != null &&
                                    regular != null &&
                                    _toNum(regular) != null &&
                                    _toNum(sale)! < _toNum(regular)!)
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '৳',
                                          style: AppFonts.roboto(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _formatPrice(regular),
                                          style: AppFonts.roboto(
                                            fontSize: 12,
                                            color: Colors.grey.shade400,
                                            decoration:
                                                TextDecoration.lineThrough,
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
                            margin: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.roboto(
                                fontSize: textSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),

                          // Store Link - Moved below product name (Vue: mb-3) - EXACT MATCH
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF8B5CF6)
                                      ],
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
                                    child: Icon(Icons.storefront_outlined,
                                        size: 10, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _getStoreName(p),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.roboto(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // End of product info InkWell

                    const Spacer(),
                    const SizedBox(height: 2),

                    // Full Width Buy Now Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.isLoading ? null : widget.onBuyNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF374151),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 8 : 10,
                            horizontal: 8,
                          ),
                          minimumSize: Size(double.infinity, buttonHeight),
                        ),
                        child: widget.isLoading
                            ? SizedBox(
                                width: iconSize,
                                height: iconSize,
                                child: const AdsyLoadingIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                      size: iconSize),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Buy Now',
                                      style: AppFonts.roboto(
                                        fontSize: textSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ), // End Buy Now Button
                  ], // End Column children (details column)
                ), // End Column
              ), // End Padding
            ), // End Expanded
          ], // End Column children (main column)
        ), // End Column
      ), // End Container
    ); // End Material
  }

  // Helper methods
  int _calcDiscount(dynamic sale, dynamic regular) {
    final saleNum = _toNum(sale);
    final regularNum = _toNum(regular);

    if (saleNum == null ||
        regularNum == null ||
        regularNum <= 0 ||
        saleNum >= regularNum) {
      return 0;
    }

    return ((regularNum - saleNum) / regularNum * 100).round();
  }

  String _formatPrice(dynamic v) {
    final n = _toNum(v);
    if (n == null) return '';
    final s = n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
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
    if (product['featured_image'] != null &&
        product['featured_image'].toString().isNotEmpty) {
      return _makeAbsoluteUrl(product['featured_image'].toString());
    }

    return '';
  }

  String _makeAbsoluteUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Use AppConfig to get the correct base URL (localhost in debug, production in release)
    final baseUrl = AppConfig.mediaBaseUrl;
    print('ProductCard: Making absolute URL from "$url" using base: $baseUrl');

    // Handle Django media URLs
    if (url.startsWith('/media/') || url.startsWith('media/')) {
      final finalUrl = '$baseUrl${url.startsWith('/') ? url : '/$url'}';
      print('ProductCard: Media URL result: $finalUrl');
      return finalUrl;
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
      if (ownerDetails['store_name'] != null &&
          ownerDetails['store_name'].toString().isNotEmpty) {
        return ownerDetails['store_name'].toString();
      }
      if (ownerDetails['name'] != null &&
          ownerDetails['name'].toString().isNotEmpty) {
        return ownerDetails['name'].toString();
      }
    }

    // Try direct fields
    if (product['store_name'] != null &&
        product['store_name'].toString().isNotEmpty) {
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
