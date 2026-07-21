import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oxius_native/utils/image_utils.dart';
import '../screens/product_details_screen.dart';
import '../config/app_config.dart';
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';

// Marketplace card palette (screenshot-matched): white surface, green price,
// red discount pill, amber stars.
const _cardGreen = Color(0xFF16A34A);
const _cardDark = Color(0xFF111827);
const _cardSlate50 = Color(0xFFF8FAFC);
const _cardSlate400 = Color(0xFF94A3B8);
const _cardSlate500 = Color(0xFF64748B);
const _cardAmber = Color(0xFFF59E0B);
const _cardRed = Color(0xFFEF4444);

class ProductCardLayout {
  /// Height of the text block under the square image: rating row + store row
  /// + 2-line name + price/buy row. Grows with the system text scale so
  /// nothing clips on large-font devices.
  static double detailsHeight(double screenWidth, {double textScale = 1.0}) {
    final double base;
    if (screenWidth < 360) {
      base = 122.0;
    } else if (screenWidth > 600) {
      base = 134.0;
    } else {
      base = 126.0;
    }
    final ts = textScale.clamp(1.0, 1.6);
    return base + (ts - 1.0) * 88.0;
  }

  static double cardHeight({
    required double cardWidth,
    required double screenWidth,
    double textScale = 1.0,
  }) {
    return cardWidth + detailsHeight(screenWidth, textScale: textScale);
  }

  static SliverGridDelegate buildGridDelegate({
    required double availableWidth,
    required double screenWidth,
    int crossAxisCount = 2,
    double crossAxisSpacing = 8,
    double mainAxisSpacing = 8,
    double textScale = 1.0,
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
      mainAxisExtent: cardHeight(
        cardWidth: cardWidth,
        screenWidth: screenWidth,
        textScale: textScale,
      ),
    );
  }

  static double horizontalCardWidth(double screenWidth) {
    if (screenWidth < 360) return 172.0;
    if (screenWidth > 600) return 212.0;
    return 188.0;
  }

  static double horizontalCardHeight(
    double screenWidth, {
    double? cardWidth,
    double textScale = 1.0,
  }) {
    final width = cardWidth ?? horizontalCardWidth(screenWidth);
    return cardHeight(
      cardWidth: width,
      screenWidth: screenWidth,
      textScale: textScale,
    );
  }
}

/// The app's main product card — clean marketplace look: big rounded image
/// with discount pill, then rating stars, category, name and price
/// (struck-through regular + green sale). A compact dark Buy pill on the
/// price row keeps the quick Buy Now flow.
class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = product;
    final title = (p['name'] ?? p['title'] ?? 'Product').toString();
    final regular = p['regular_price'] ?? p['price'];
    final sale = p['sale_price'];
    final imageUrl = _getProductImageUrl(p);
    final discount = _calcDiscount(sale, regular);
    final hasDiscount = discount > 0;
    final isFreeDelivery = p['is_free_delivery'] == true;
    final rating = _rating(p);
    final reviews = _reviews(p);
    final owner = p['owner_details'] is Map<String, dynamic>
        ? p['owner_details'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final storeName =
        (owner['store_name'] ?? owner['name'] ?? '').toString().trim();
    final storeVerified =
        owner['kyc'] == true || owner['is_verified'] == true;
    final storePro = owner['is_pro'] == true;

    final navigationCallback = onTap ??
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        };

    return GestureDetector(
      onTap: navigationCallback,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Image: rounded, discount pill, free-delivery, wishlist ──
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cardSlate50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl.isNotEmpty
                        ? AppImage.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 30, color: _cardSlate400),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined,
                                size: 30, color: _cardSlate400),
                          ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _cardRed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-$discount%',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (isFreeDelivery)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _cardGreen.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            'FREE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Rating stars + count (REAL data — unrated shows outlines) ──
          Row(
            children: [
              ...List.generate(5, (i) {
                final filled = i < rating.round();
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 14,
                  color: _cardAmber,
                );
              }),
              if (reviews > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '($reviews)',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: _cardSlate500),
                ),
              ],
            ],
          ),

          // ── Store name + verified/pro badges ──
          if (storeName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _cardSlate500,
                    ),
                  ),
                ),
                if (storeVerified) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.verified,
                      size: 12, color: Color(0xFF2563EB)),
                ],
                if (storePro) ...[
                  const SizedBox(width: 3),
                  const AdsyProBadge(),
                ],
              ],
            ),
          ],

          // ── Name (2-line clamp) ──
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: _cardDark,
            ),
          ),

          // ── Price row + quick-buy bag ──
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (hasDiscount) ...[
                      Flexible(
                        child: Text(
                          '৳${_formatPrice(regular)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: _cardSlate400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        '৳${_formatPrice(hasDiscount ? sale : regular)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _cardGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Quick Buy Now — plain dark icon + label, no background.
              GestureDetector(
                onTap: isLoading ? null : onBuyNow,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 14, color: _cardDark),
                      const SizedBox(width: 3),
                      Text(
                        'Buy',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _cardDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _rating(Map<String, dynamic> p) {
    final r = p['average_rating'] ?? p['rating'];
    return double.tryParse('${r ?? ''}') ?? 0;
  }

  int _reviews(Map<String, dynamic> p) {
    final r = p['total_reviews'] ?? p['reviews_count'] ?? p['review_count'];
    return int.tryParse('${r ?? ''}') ?? 0;
  }

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
    return s;
  }

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

    // Use AppConfig to get the correct base URL (localhost in debug,
    // production in release).
    final baseUrl = AppConfig.mediaBaseUrl;

    // Handle Django media URLs
    if (url.startsWith('/media/') || url.startsWith('media/')) {
      return '$baseUrl${url.startsWith('/') ? url : '/$url'}';
    }
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
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
