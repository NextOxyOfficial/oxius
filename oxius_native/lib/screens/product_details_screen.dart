import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/eshop_service.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/url_launcher_utils.dart';
import '../models/cart_item.dart';
import '../widgets/product_card.dart';
import 'vendor_store_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with SingleTickerProviderStateMixin {
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _emerald = Color(0xFF059669);
  static const _indigo = Color(0xFF6366F1);

  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  bool _isLoadingStoreProducts = false;
  
  Map<String, dynamic>? _productDetails;
  List<Map<String, dynamic>> _similarProducts = [];
  List<Map<String, dynamic>> _storeProducts = [];
  
  // Pagination for similar products
  int _similarProductsPage = 1;
  bool _hasMoreSimilarProducts = true;
  bool _isLoadingMoreSimilarProducts = false;
  
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _scrollController.addListener(_handlePageScroll);
    _loadProductDetails();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handlePageScroll);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    if (!_scrollController.hasClients || _isLoadingMoreSimilarProducts || !_hasMoreSimilarProducts) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMoreSimilarProducts();
    }
  }

  void _handleBuyNow() {
    final product = _productDetails ?? widget.product;

    final stock = _parseInt(product['quantity'], fallback: 0);
    if (stock > 0 && _quantity > stock) {
      setState(() => _quantity = stock);
    }
    
    // Convert product map to Product object
    final cartProduct = Product(
      id: product['id'], // Can be int or String (UUID)
      name: product['name'] ?? product['title'] ?? 'Product',
      description: product['description'],
      regularPrice: _parseDouble(product['regular_price'] ?? product['price']),
      salePrice: product['sale_price'] != null 
          ? _parseDouble(product['sale_price']) 
          : null,
      quantity: _parseInt(product['quantity'], fallback: 999),
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

    // Create cart item with selected quantity
    final cartItem = CartItem(
      product: cartProduct,
      quantity: _quantity,
    );

    // Navigate to checkout
    Navigator.pushNamed(
      context,
      '/checkout',
      arguments: {
        'cartItems': [cartItem],
      },
    );
  }

  // Helper method for product cards (uses quantity 1)
  void _handleBuyNowForProduct(Map<String, dynamic> product) {
    try {
      // Convert product map to Product object
      final cartProduct = Product(
        id: product['id'],
        name: product['name'] ?? product['title'] ?? 'Product',
        description: product['description'],
        regularPrice: _parseDouble(product['regular_price'] ?? product['price']),
        salePrice: product['sale_price'] != null 
            ? _parseDouble(product['sale_price']) 
            : null,
        quantity: _parseInt(product['quantity'], fallback: 999),
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

      // Create cart item with quantity 1
      final cartItem = CartItem(
        product: cartProduct,
        quantity: 1,
      );

      // Navigate to checkout
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

  int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> get _activeProduct => _productDetails ?? widget.product;

  String? _resolveStoreIdentity(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    if (ownerDetails is Map) {
      final candidates = [
        ownerDetails['store_username'],
        ownerDetails['username'],
        ownerDetails['user_id'],
        ownerDetails['id'],
      ];

      for (final candidate in candidates) {
        final value = candidate?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  String? _resolvePrimaryCategorySlug(Map<String, dynamic> product) {
    final details = product['category_details'];
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map) {
        final value = first['slug']?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return product['category_slug']?.toString();
  }

  String? _resolvePrimaryCategoryId(Map<String, dynamic> product) {
    final details = product['category_details'];
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map) {
        final value = first['id']?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    final category = product['category'];
    if (category is List && category.isNotEmpty) {
      final value = category.first?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return product['category']?.toString();
  }

  Future<void> _openStore(String? storeUsername, String storeName) async {
    if (storeUsername == null || storeUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store information is not available for this product.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorStoreScreen(
          storeUsername: storeUsername,
          storeName: storeName,
        ),
      ),
    );
  }

  Future<void> _openProductDetails(
    Map<String, dynamic> product, {
    bool replaceCurrent = true,
  }) async {
    final route = MaterialPageRoute(
      builder: (context) => ProductDetailsScreen(
        product: Map<String, dynamic>.from(product),
      ),
    );

    if (replaceCurrent) {
      await Navigator.of(context).pushReplacement(route);
      return;
    }

    await Navigator.of(context).push(route);
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final fetchedDetails = await EshopService.fetchProductDetails(
        productId: widget.product['id'],
        slug: widget.product['slug']?.toString(),
      );

      _productDetails = fetchedDetails ?? widget.product;
      
      // Load similar products and store products in parallel
      await Future.wait([
        _loadSimilarProducts(),
        _loadStoreProducts(),
      ]);
    } catch (_) {
      _productDetails = widget.product;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSimilarProducts() async {
    setState(() {
      _similarProductsPage = 1;
      _hasMoreSimilarProducts = true;
    });
    
    try {
      final product = _activeProduct;
      final categorySlug = _resolvePrimaryCategorySlug(product);
      final categoryId = _resolvePrimaryCategoryId(product);

      final products = await EshopService.fetchEshopProducts(
        page: 1,
        pageSize: 12,
        categorySlug: categorySlug,
        categoryId: categorySlug == null ? categoryId : null,
      );
      
      setState(() {
        // Filter out current product
        final currentProductId = _activeProduct['id']?.toString();
        _similarProducts = products
            .where((p) => p['id']?.toString() != currentProductId)
            .toList();
        _hasMoreSimilarProducts = products.length == 12;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _similarProducts = [];
          _hasMoreSimilarProducts = false;
        });
      }
    }
  }

  Future<void> _loadMoreSimilarProducts() async {
    if (_isLoadingMoreSimilarProducts || !_hasMoreSimilarProducts) return;
    
    setState(() => _isLoadingMoreSimilarProducts = true);
    
    try {
      final nextPage = _similarProductsPage + 1;
      final product = _activeProduct;
      final categorySlug = _resolvePrimaryCategorySlug(product);
      final categoryId = _resolvePrimaryCategoryId(product);

      final products = await EshopService.fetchEshopProducts(
        page: nextPage,
        pageSize: 12,
        categorySlug: categorySlug,
        categoryId: categorySlug == null ? categoryId : null,
      );
      
      setState(() {
        // Filter out current product and add to list
        final currentProductId = _activeProduct['id']?.toString();
        final newProducts = products
            .where((p) => p['id']?.toString() != currentProductId)
            .toList();
        _similarProducts.addAll(newProducts);
        _similarProductsPage = nextPage;
        _hasMoreSimilarProducts = products.length == 12;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _hasMoreSimilarProducts = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreSimilarProducts = false);
      }
    }
  }

  Future<void> _loadStoreProducts() async {
    setState(() => _isLoadingStoreProducts = true);
    
    try {
      final storeIdentity = _resolveStoreIdentity(_activeProduct);
      if (storeIdentity == null || storeIdentity.isEmpty) {
        if (mounted) {
          setState(() => _storeProducts = []);
        }
        return;
      }

      final result = await EshopService.fetchStoreProducts(
        storeIdentity: storeIdentity,
        page: 1,
        pageSize: 10,
      );
      final products = List<Map<String, dynamic>>.from(result['products'] as List? ?? []);

      if (mounted) {
        final currentProductId = _activeProduct['id']?.toString();
        setState(() {
          _storeProducts = products
              .where((p) => p['id']?.toString() != currentProductId)
              .take(6)
              .toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _storeProducts = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStoreProducts = false);
      }
    }
  }

  String _getImageUrl(int index) {
    try {
      final imageDetails = _productDetails?['image_details'];
      if (imageDetails is List && imageDetails.length > index) {
        return AppConfig.getAbsoluteUrl(imageDetails[index]['image']?.toString());
      }
      return AppConfig.getAbsoluteUrl(_productDetails?['image']?.toString());
    } catch (e) {
      return '';
    }
  }

  int get _imageCount {
    try {
      final imageDetails = _productDetails?['image_details'];
      if (imageDetails is List) {
        return imageDetails.length;
      }
      return 1;
    } catch (e) {
      return 1;
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

  String _formatPrice(dynamic v) {
    final n = _toNum(v);
    if (n == null) return '';
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  int _calcDiscount(dynamic sale, dynamic regular) {
    final s = _toNum(sale);
    final r = _toNum(regular);
    if (s == null || r == null) return 0;
    if (r <= 0 || s >= r) return 0;
    return (((r - s) / r) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _slate50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.grey.shade200),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    final product = _productDetails ?? widget.product;
    final title = product['name'] ?? product['title'] ?? 'Product';
    final sale = product['sale_price'];
    final regular = product['regular_price'] ?? product['price'];
    final discount = _calcDiscount(sale, regular);
    final isFreeDelivery = product['is_free_delivery'] == true;
    final shortDescription = product['short_description'] ?? '';

    final stock = int.tryParse((product['quantity'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: _slate50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 380,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827), size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: AppFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share_rounded, color: Color(0xFF111827), size: 18),
                ),
                onPressed: () async {
                  final product = _activeProduct;
                  final productTitle = product['name'] ?? product['title'] ?? 'Product';
                  final productSlug = product['slug'] ?? product['id'];
                  final shareText = 'Check out this product: $productTitle\n\nView on AdsyClub: https://adsyclub.com/products/$productSlug';
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    await Share.share(shareText);
                  } catch (_) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Unable to share this product right now.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildImageGallery(product),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade200),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 84),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductSummary(
                    title: title.toString(),
                    sale: sale,
                    regular: regular,
                    discount: discount,
                    isFreeDelivery: isFreeDelivery,
                    shortDescription: shortDescription.toString(),
                    stock: stock,
                    product: product,
                  ),
                  const SizedBox(height: 10),
                  _buildStoreInfo(product),
                  const SizedBox(height: 10),
                  _buildDescriptionTabs(product),
                  const SizedBox(height: 10),
                  _buildStoreProducts(product),
                  if (_similarProducts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildSimilarProducts(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(stock: stock),
    );
  }

  Widget _buildProductSummary({
    required String title,
    required dynamic sale,
    required dynamic regular,
    required int discount,
    required bool isFreeDelivery,
    required String shortDescription,
    required int stock,
    required Map<String, dynamic> product,
  }) {
    final hasDiscount = sale != null && _toNum(sale) != null && regular != null && _toNum(regular) != null && _toNum(sale)! < _toNum(regular)!;
    final views = _parseInt(product['views']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\u09f3${_formatPrice(sale ?? regular)}',
                style: AppFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                  height: 1,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 8),
                Text(
                  '\u09f3${_formatPrice(regular)}',
                  style: AppFonts.roboto(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-$discount%',
                    style: AppFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stock > 0 ? Icons.check_circle : Icons.info_outline,
                    size: 14,
                    color: stock > 0 ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stock > 0 ? 'In Stock' : 'Out of Stock',
                    style: AppFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: stock > 0 ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaPill(
                icon: Icons.inventory_2_outlined,
                label: stock > 0 ? '$stock available' : 'Out of stock',
                color: stock > 0 ? _emerald : Colors.red,
              ),
              if (isFreeDelivery)
                _buildMetaPill(
                  icon: Icons.local_shipping_outlined,
                  label: 'Free delivery',
                  color: _emerald,
                ),
              if (views > 0)
                _buildMetaPill(
                  icon: Icons.visibility_outlined,
                  label: '$views views',
                  color: _indigo,
                ),
            ],
          ),
          if (isFreeDelivery) ...[
            const SizedBox(height: 2),
          ],
          if (shortDescription.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              shortDescription,
              style: AppFonts.roboto(
                fontSize: 13,
                color: _slate500,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: _slate200, height: 1),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({required int stock}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _slate200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Quantity Selector
              Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      child: Container(
                        width: 36,
                        height: 44,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: _quantity > 1 ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          vertical: BorderSide(color: const Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Text(
                        '$_quantity',
                        style: AppFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: (stock <= 0 || _quantity < stock) ? () => setState(() => _quantity++) : null,
                      child: Container(
                        width: 36,
                        height: 44,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: (stock <= 0 || _quantity < stock) ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Buy Now Button
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: stock > 0 ? _handleBuyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _emerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      stock > 0 ? 'Buy Now' : 'Unavailable',
                      style: AppFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(Map<String, dynamic> product) {
    // Get the AppBar height to add as top padding
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: EdgeInsets.only(top: appBarHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, double.infinity);
          final height = constraints.maxHeight.clamp(0.0, double.infinity);
          final galleryHeight = height > 0 ? height : width;

          return SizedBox(
            width: width,
            height: galleryHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main Image
                PageView.builder(
                  itemCount: _imageCount,
                  onPageChanged: (index) {
                    setState(() => _selectedImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = _getImageUrl(index);
                    return Container(
                      color: const Color(0xFFF9FAFB),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                            ),
                    );
                  },
                ),

                // Image Counter
                if (_imageCount > 1)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_selectedImageIndex + 1}/$_imageCount',
                        style: AppFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreInfo(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ?? ownerDetails['name']?.toString() ?? 'Store')
        : 'Store';
    
    final isVerified = ownerDetails is Map ? (ownerDetails['kyc'] == true || ownerDetails['is_verified'] == true) : false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 22,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            storeName,
                            style: AppFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Color(0xFF3B82F6),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View store',
                      style: AppFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openStore(_resolveStoreIdentity(product), storeName),
                style: TextButton.styleFrom(
                  foregroundColor: _emerald,
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Visit',
                      style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: _slate200, height: 1),
        ],
      ),
    );
  }

  Widget _buildDescriptionTabs(Map<String, dynamic> product) {
    final description = product['description']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Product details'),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _slate200),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1F2937),
            unselectedLabelColor: const Color(0xFF9CA3AF),
            indicatorColor: const Color(0xFF059669),
            indicatorWeight: 2,
            labelStyle: AppFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Delivery'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: description.isNotEmpty
                    ? Html(
                        data: description,
                        onLinkTap: (url, attributes, element) {
                          UrlLauncherUtils.launchExternalUrl(url);
                        },
                        style: {
                          '*': Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(13),
                            color: const Color(0xFF4B5563),
                            lineHeight: const LineHeight(1.6),
                          ),
                        },
                      )
                    : Text(
                        'No description available',
                        style: AppFonts.roboto(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
              ),
              _buildDeliveryTab(product),
              _buildReviewsTab(product),
            ],
          ),
        ),
        Divider(color: _slate200, height: 1),
      ],
    );
  }

  Widget _buildDeliveryTab(Map<String, dynamic> product) {
    final feeInsideDhaka = product['delivery_fee_inside_dhaka']?.toString() ?? '100';
    final feeOutsideDhaka = product['delivery_fee_outside_dhaka']?.toString() ?? '150';
    final isFreeDelivery = product['is_free_delivery'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFreeDelivery)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    'Free delivery available',
                    style: AppFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          _buildDeliveryRow('Inside Dhaka', '৳$feeInsideDhaka'),
          _buildDeliveryRow('Outside Dhaka', '৳$feeOutsideDhaka'),
          _buildDeliveryRow('Estimated Time', '3-5 business days'),
        ],
      ),
    );
  }

  Widget _buildDeliveryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: AppFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(Map<String, dynamic> product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.rate_review_outlined,
            size: 40,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: AppFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to review',
            style: AppFonts.roboto(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showWriteReviewDialog(product),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
            ),
            child: Text(
              'Write a review',
              style: AppFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWriteReviewDialog(Map<String, dynamic> product) async {
    final ownerDetails = product['owner_details'];
    final ownerId = ownerDetails is Map ? ownerDetails['id']?.toString() : null;
    final currentUserId = AuthService.currentUser?.id;
    
    if (ownerId != null && ownerId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You cannot write a review for your own product.',
            style: AppFonts.roboto(fontSize: 13),
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    int rating = 0;
    bool hasComment = false;
    final titleController = TextEditingController();
    final commentController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, modalSetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _slate200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.rate_review, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Write a Review',
                            style: AppFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _slate800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Your Rating',
                      style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            modalSetState(() {
                              rating = index + 1;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                          iconSize: 30,
                          icon: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: 'Review Title (Optional)',
                        labelStyle: AppFonts.roboto(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        counterStyle: AppFonts.roboto(fontSize: 10),
                      ),
                      style: AppFonts.roboto(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLength: 1000,
                      onChanged: (value) {
                        modalSetState(() {
                          hasComment = value.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Your Review',
                        labelStyle: AppFonts.roboto(fontSize: 12),
                        hintText: 'Share your experience...',
                        hintStyle: AppFonts.roboto(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        counterStyle: AppFonts.roboto(fontSize: 10),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      style: AppFonts.roboto(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _slate800,
                              side: BorderSide(color: _slate200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: AppFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: rating > 0 && hasComment
                                ? () {
                                    Navigator.pop(sheetContext);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Thank you for your review!',
                                          style: AppFonts.roboto(fontSize: 13),
                                        ),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Submit',
                              style: AppFonts.roboto(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    titleController.dispose();
    commentController.dispose();
  }

  Widget _buildSimilarProducts() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('You may also like'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 360;
              final isLargeScreen = screenWidth > 600;
              final detailsHeight = isSmallScreen ? 132.0 : isLargeScreen ? 148.0 : 140.0;
              const crossAxisCount = 2;
              const crossAxisSpacing = 8.0;
              const mainAxisSpacing = 8.0;
              final totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
              final available = (constraints.maxWidth - totalSpacing).clamp(0.0, double.infinity);
              final cellWidth = (available / crossAxisCount).clamp(0.0, double.infinity);
              final cardHeight = cellWidth > 0 ? cellWidth + detailsHeight : 260.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  mainAxisExtent: cardHeight,
                ),
                itemCount: _similarProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: _similarProducts[index],
                    isLoading: false,
                    onBuyNow: () => _handleBuyNowForProduct(_similarProducts[index]),
                    onTap: () => _openProductDetails(_similarProducts[index]),
                  );
                },
              );
            },
          ),
          if (_isLoadingMoreSimilarProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Divider(color: _slate200, height: 1),
        ],
      ),
    );
  }

  Widget _buildStoreProducts(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ?? 'Store')
        : 'Store';

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('More from $storeName'),
          const SizedBox(height: 12),
          if (_isLoadingStoreProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              ),
            )
          else if (_storeProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No other products',
                style: AppFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _storeProducts.length,
              separatorBuilder: (_, __) => Divider(color: _slate100, height: 1),
              itemBuilder: (context, index) {
                return _buildInlineProductRow(
                  product: _storeProducts[index],
                  onTap: () => _openProductDetails(_storeProducts[index]),
                  onBuyNow: () => _handleBuyNowForProduct(_storeProducts[index]),
                );
              },
            ),
          const SizedBox(height: 8),
          Divider(color: _slate200, height: 1),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _slate800,
        ),
      ),
    );
  }

  Widget _buildInlineProductRow({
    required Map<String, dynamic> product,
    required VoidCallback onTap,
    required VoidCallback onBuyNow,
  }) {
    final title = product['name']?.toString() ?? product['title']?.toString() ?? 'Product';
    final sale = product['sale_price'];
    final regular = product['regular_price'] ?? product['price'];
    final price = sale ?? regular;
    final storeName = _resolveStoreName(product);
    final imageUrl = _resolveProductImage(product);
    final hasDiscount = sale != null && _toNum(sale) != null && regular != null && _toNum(regular) != null && _toNum(sale)! < _toNum(regular)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 74,
                          height: 74,
                          color: _slate100,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_outlined,
                                    size: 28,
                                    color: _slate500,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: _slate500,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onTap,
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _slate800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.roboto(
                                fontSize: 12,
                                color: _slate500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '৳${_formatPrice(price)}',
                                  style: AppFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _emerald,
                                  ),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '৳${_formatPrice(regular)}',
                                    style: AppFonts.roboto(
                                      fontSize: 12,
                                      color: _slate500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onBuyNow,
            style: TextButton.styleFrom(
              foregroundColor: _emerald,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Text(
              'Buy',
              style: AppFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveStoreName(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    if (ownerDetails is Map) {
      final storeName = ownerDetails['store_name']?.toString();
      if (storeName != null && storeName.isNotEmpty) {
        return storeName;
      }

      final ownerName = ownerDetails['name']?.toString();
      if (ownerName != null && ownerName.isNotEmpty) {
        return ownerName;
      }
    }

    return 'AdsyClub Store';
  }

  String _resolveProductImage(Map<String, dynamic> product) {
    final imageDetails = product['image_details'];
    if (imageDetails is List && imageDetails.isNotEmpty) {
      final first = imageDetails.first;
      if (first is Map && first['image'] != null) {
        return AppConfig.getAbsoluteUrl(first['image']?.toString());
      }
    }

    return AppConfig.getAbsoluteUrl(
      product['image']?.toString() ?? product['featured_image']?.toString(),
    );
  }

}
