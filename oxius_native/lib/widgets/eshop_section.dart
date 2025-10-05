import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/eshop_service.dart';
import 'hot_deals_section.dart';
import 'hot_arrivals_section.dart';
import 'mobile_banner.dart';

class EshopSection extends StatefulWidget {
  const EshopSection({super.key});

  @override
  State<EshopSection> createState() => _EshopSectionState();
}

class _EshopSectionState extends State<EshopSection> {
  final TranslationService _translationService = TranslationService();
  final Set<String> _loadingButtons = <String>{};
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _displayProducts = [];
  bool _loadingProducts = false;
  bool _initialized = false;
  final Set<String> _buyLoading = <String>{};

  // Pick up to [maxItems] random unique items from the list
  List<Map<String, dynamic>> _pickRandom(List<Map<String, dynamic>> list, int maxItems) {
    if (list.isEmpty) return [];
    final rng = Random();
    final indices = List<int>.generate(list.length, (i) => i);
    for (int i = indices.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    final take = min(maxItems, indices.length);
    return List<Map<String, dynamic>>.generate(take, (i) => list[indices[i]]);
  }

  @override
  void initState() {
    super.initState();
    _translationService.addListener(_onTranslationsChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleButtonClick(String buttonId) {
    setState(() {
      _loadingButtons.add(buttonId);
    });
    
    // Navigate to eShop page (placeholder)
    // TODO: Implement navigation to /eshop
    
    // Remove loading state after navigation simulation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _loadingButtons.remove(buttonId);
        });
      }
    });
  }

  Future<void> _bootstrap() async {
    print('DEBUG: eShop Bootstrap called, initialized: $_initialized');
    if (_initialized) return;
    _initialized = true;
    print('DEBUG: Starting eShop bootstrap process...');
    await _loadProducts();
    print('DEBUG: eShop Bootstrap completed');
  }

  Future<void> _loadProducts() async {
    print('DEBUG: Loading eShop products...');
    setState(() { _loadingProducts = true; });
    
    try {
      // Fetch from backend
      final products = await EshopService.fetchEshopProducts(
        page: 1,
        pageSize: 10,
      );
      
      print('DEBUG: eShop API returned ${products.length} products');
      
      if (!mounted) return;
      setState(() {
        _products = products;
        _displayProducts = _pickRandom(products, 10);
        _loadingProducts = false;
      });
      print('DEBUG: eShop products state updated, total: ${_products.length}');
    } catch (e, stackTrace) {
      print('DEBUG: Error loading eShop products: $e');
      print('DEBUG: Stack trace: $stackTrace');
      
      // Leave products empty on error
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          // eShop Header
          _buildHeader(isMobile),
          const SizedBox(height: 16),
          
          // 1. eShop Banner (using MobileBannerWidget with eshop-banner endpoint)
          const MobileBannerWidget(
            autoplayInterval: 5000,
            autoplayEnabled: true,
            endpoint: '/eshop-banner/',
          ),
          const SizedBox(height: 16),
          
          // 2. Hot Deals Section (Special Offers)
          const HotDealsSection(),
          const SizedBox(height: 16),
          
          // 3. Hot Arrivals Section (New & Hot)
          const HotArrivalsSection(),
          const SizedBox(height: 16),
          
          // 4. Product Grid
          _buildProductsGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)], // Purple to Blue gradient
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        _translationService.t('eshop', fallback: 'eShop'),
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 4,
                      width: isMobile ? 60 : 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)], // Purple to Blue gradient
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isMobile) {
    final isLoading = _loadingButtons.contains('browse-eshop');
    
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)], // Purple to Blue gradient
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white24,
          onTap: isLoading ? null : () => _handleButtonClick('browse-eshop'),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 22,
              vertical: isMobile ? 8 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Icon(Icons.shopping_bag, color: Colors.white, size: 18),
                ),
                if (!isLoading) ...[
                  const SizedBox(width: 8),
                  Text(
                    _translationService.t('browse_eshop', fallback: 'Browse eShop'),
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(bool isMobile) {
    if (_loadingProducts) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _translationService.t('no_products_found', fallback: 'No products found'),
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Show exactly 2 rows of 5 random items (up to 10 products), each row scrolls horizontally
    final items = _displayProducts.isNotEmpty ? _displayProducts : _products.take(10).toList();
    final row1 = items.take(5).toList();
    final row2 = items.length > 5 ? items.sublist(5, items.length.clamp(5, 10)) : <Map<String, dynamic>>[];

    const spacing = 4.0;
    return LayoutBuilder(
      builder: (context, constraints) {
  final availableWidth = constraints.maxWidth;
  // Ideal width to fit 2 cards across properly with some spacing
  final idealWidth = (availableWidth - spacing * 3) / 2;
        // Keep sensible min/max widths so cards don't get too small or too large
        final cardWidth = idealWidth.clamp(160.0, 200.0);
        // Allocate enough room for details + bottom breathing space below the button
        const detailsMinHeight = 160.0;
        final cardHeight = cardWidth + detailsMinHeight;        
        Widget buildRow(List<Map<String, dynamic>> data) {
          return SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(width: spacing),
              itemBuilder: (context, idx) {
                final product = data[idx];
                final id = (product['id'] ?? idx).toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: cardWidth,
                  child: _EshopProductCard(
                    product: product,
                    isLoading: _buyLoading.contains(id),
                    width: cardWidth,
                    height: cardHeight,
                    onBuyNow: () async {
                      setState(() => _buyLoading.add(id));
                      await Future.delayed(const Duration(milliseconds: 800));
                      if (!mounted) return;
                      setState(() => _buyLoading.remove(id));
                    },
                    onTap: () {
                      debugPrint('Product tapped: ${product['id']}');
                    },
                  ),
                );
              },
            ),
          );
        }

        return Column(
          children: [
            if (row1.isNotEmpty) buildRow(row1),
            const SizedBox(height: 16),
            if (row2.isNotEmpty) buildRow(row2),
          ],
        );
      },
    );
  }

}

// --- Product Card (Flutter implementation aligned with Vue product-card.vue) ---
class _EshopProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isLoading;
  final VoidCallback onBuyNow;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const _EshopProductCard({
    required this.product,
    required this.isLoading,
    required this.onBuyNow,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  State<_EshopProductCard> createState() => _EshopProductCardState();
}

class _EshopProductCardState extends State<_EshopProductCard> {
  bool _hovered = false;

  String _getImage(Map<String, dynamic> p) {
    try {
      // Check image field first (transformed data)
      if (p['image'] is String && p['image'].toString().isNotEmpty) {
        return p['image'].toString();
      }
      
      // Check image_details array
      final imgDetails = p['image_details'];
      if (imgDetails is List && imgDetails.isNotEmpty) {
        final first = imgDetails.first;
        if (first is Map && first['image'] != null) {
          final url = first['image'].toString();
          if (url.isNotEmpty) return url;
        }
      }
      
      // Check medias array (fallback)
      if (p['medias'] is List && (p['medias'] as List).isNotEmpty) {
        final first = (p['medias'] as List).first;
        if (first is Map && first['image'] != null) {
          final url = first['image'].toString();
          if (url.isNotEmpty) return url;
        }
      }
      
      return '';
    } catch (e) {
      print('Error getting image: $e');
      return '';
    }
  }

  num? _toNum(dynamic v) {
    if (v == null) return null;
    try {
      if (v is num) return v;
      return num.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  int _calcDiscount(dynamic sale, dynamic regular) {
    final s = _toNum(sale);
    final r = _toNum(regular);
    if (s == null || r == null) return 0;
    if (r <= 0 || s >= r) return 0;
    return (((r - s) / r) * 100).round();
  }

  String _formatPrice(dynamic v) {
    final n = _toNum(v);
    if (n == null) return '';
    final s = n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return s; // currency symbol added in Text
  }

  String _getStoreName(Map<String, dynamic> p) {
    try {
      print('DEBUG _getStoreName: Product keys: ${p.keys.toList()}');
      
      // Since the data is already transformed in the service, use the simplified structure
      final ownerDetails = p['owner_details'];
      print('DEBUG _getStoreName: owner_details type: ${ownerDetails.runtimeType}');
      print('DEBUG _getStoreName: owner_details value: $ownerDetails');
      
      if (ownerDetails is Map<String, dynamic>) {
        print('DEBUG _getStoreName: owner_details keys: ${ownerDetails.keys.toList()}');
        final storeName = ownerDetails['store_name']?.toString() ?? 
                         ownerDetails['name']?.toString() ?? 
                         'Store';
        print('DEBUG _getStoreName: Final storeName: "$storeName"');
        return storeName.trim().isNotEmpty ? storeName.trim() : 'Store';
      }
      
      print('DEBUG _getStoreName: owner_details is not a Map, returning Store');
      return 'Store';
    } catch (e) {
      print('DEBUG _getStoreName: Error getting store name: $e');
      return 'Store';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final sale = p['sale_price'];
    final regular = p['regular_price'] ?? p['price'];
    final discount = _calcDiscount(sale, regular);
    final isFreeDelivery = p['is_free_delivery'] == true;
    final title = (p['name'] ?? p['title'] ?? '---').toString();
    final imageUrl = _getImage(p);

    final imageHeight = widget.width; // square image

    return SizedBox(
      width: widget.width,
      height: widget.height,
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
              // Image section (square like pt-[100%])
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: Stack(
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 32,
                              color: Colors.purple.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Discount badge (top-left)
                    if (regular != null && discount > 0)
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

                    // Free delivery badge (bottom-left)
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

                    // Quick View overlay (hover)
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
                                // TODO: Implement quick view modal
                                debugPrint('Quick View: ${p['id']}');
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

              // Details
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Price Section - Moved to top (Vue: mb-2)
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

                      // Product Title - Moved above store name (Vue: mb-2)
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

                      // Store Link - Moved below product name (Vue: mb-3)
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

                      // Full Width Buy Now Button (Vue styling)
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
            ],
          ),
        ),
        ),
      ),
    );
  }
}