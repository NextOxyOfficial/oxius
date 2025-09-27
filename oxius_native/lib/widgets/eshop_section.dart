import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/eshop_service.dart';
import 'ads_scroll.dart';

class EshopSection extends StatefulWidget {
  const EshopSection({super.key});

  @override
  State<EshopSection> createState() => _EshopSectionState();
}

class _EshopSectionState extends State<EshopSection> {
  final TranslationService _translationService = TranslationService();
  final Set<String> _loadingButtons = <String>{};
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = false;
  bool _initialized = false;

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
      // Try to fetch from backend first
      final products = await EshopService.fetchEshopProducts(
        page: 1,
        pageSize: 10,
      );
      
      // If backend fails, use mock data
      final finalProducts = products.isEmpty ? EshopService.getMockProducts() : products;
      print('DEBUG: eShop API returned ${finalProducts.length} products');
      
      if (!mounted) return;
      setState(() {
        _products = finalProducts;
        _loadingProducts = false;
      });
      print('DEBUG: eShop products state updated, total: ${_products.length}');
    } catch (e, stackTrace) {
      print('DEBUG: Error loading eShop products: $e');
      print('DEBUG: Stack trace: $stackTrace');
      
      // Use mock data as fallback
      if (!mounted) return;
      setState(() {
        _products = EshopService.getMockProducts();
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
          _buildHeader(isMobile),
          const SizedBox(height: 16),
          
          const SizedBox(height: 8),
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

    // Simple grid placeholder - show first 6 products
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 0.75 : 0.8,
      ),
      itemCount: _products.length.clamp(0, 6), // show up to 6 for initial view
      itemBuilder: (context, idx) {
        final product = _products[idx];
        final title = (product['title'] ?? '---').toString();
        final price = product['price']?.toString();
        final imageUrl = _getImageSrc(product);
        
        return Material(
          color: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // TODO: Navigate to product detail screen
              print('Product tapped: ${product['id']}');
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Product details
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
                          if (price != null) 
                            Text(
                              '৳$price',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade600,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  (product['location'] ?? product['city'] ?? '').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }

  String _getImageSrc(Map<String, dynamic> product) {
    // Check for medias array first
    if (product['medias'] != null && 
        product['medias'] is List && 
        (product['medias'] as List).isNotEmpty) {
      final media = (product['medias'] as List).first;
      if (media['image'] != null) {
        return media['image'].toString();
      }
    }
    
    // Check for direct image field
    if (product['image'] != null) {
      return product['image'].toString();
    }
    
    return 'https://placehold.co/300x200?text=Product';
  }
}