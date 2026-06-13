import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/eshop_service.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/url_launcher_utils.dart';
import '../models/cart_item.dart';
import '../widgets/common/adsy_share_sheet.dart';
import '../widgets/product_card.dart';
import 'vendor_store_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _emerald = Color(0xFF059669);
  static const _indigo = Color(0xFF6366F1);
  static const _rose = Color(0xFFEF4444);
  static const _surface = Colors.white;

  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _shortDescExpanded = false;
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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
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
    if (!_scrollController.hasClients ||
        _isLoadingMoreSimilarProducts ||
        !_hasMoreSimilarProducts) {
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
        regularPrice:
            _parseDouble(product['regular_price'] ?? product['price']),
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
                .map(
                    (img) => ProductImage.fromJson(img as Map<String, dynamic>))
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
      AdsyToast.error(context, 'চেকআউটে যাওয়া যায়নি');
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
      AdsyToast.error(
          context, 'Store information is not available for this product.');
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
      final products =
          List<Map<String, dynamic>>.from(result['products'] as List? ?? []);

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

  List<String> get _productImageUrls {
    final product = _activeProduct;
    final urls = <String>[];
    final imageDetails = product['image_details'];

    if (imageDetails is List) {
      for (final entry in imageDetails) {
        if (entry is Map) {
          final imageUrl = AppConfig.getAbsoluteUrl(entry['image']?.toString());
          if (imageUrl.isNotEmpty) {
            urls.add(imageUrl);
          }
        }
      }
    }

    if (urls.isNotEmpty) {
      return urls;
    }

    final primaryImageUrl =
        AppConfig.getAbsoluteUrl(product['image']?.toString());
    if (primaryImageUrl.isNotEmpty) {
      urls.add(primaryImageUrl);
    }

    return urls;
  }

  bool get _hasProductImages => _productImageUrls.isNotEmpty;

  String _getImageUrl(int index) {
    final imageUrls = _productImageUrls;
    if (index >= 0 && index < imageUrls.length) {
      return imageUrls[index];
    }
    return '';
  }

  int get _imageCount => _productImageUrls.length;

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

  Future<void> _shareActiveProduct() async {
    final product = _activeProduct;
    final productTitle = product['name'] ?? product['title'] ?? 'Product';
    final productSlug = (product['slug'] ?? product['id'])?.toString().trim();
    final imageDetails = product['image_details'];
    String? imageUrl;
    if (imageDetails is List && imageDetails.isNotEmpty) {
      final first = imageDetails.first;
      if (first is Map) {
        imageUrl = (first['image'] ?? first['url'])?.toString();
      }
    }

    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: productTitle.toString(),
        description: 'View this product on AdsyClub.',
        url: 'https://adsyclub.com/product-details/$productSlug',
        imageUrl: imageUrl,
        subject: productTitle.toString(),
        eyebrow: 'AdsyClub Shop',
      ),
    );
  }

  Widget _buildChromeActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: _slate800, size: 20),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: child,
        ),
        if (showDivider)
          Container(
            height: 1,
            color: _slate200,
          ),
      ],
    );
  }

  Widget _buildHeroBadge({
    required IconData icon,
    required String label,
    required Color color,
    Color? background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.14),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF1F2937), size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.grey.shade200),
          ),
        ),
        body: const Center(
          child: AdsyLoadingIndicator(
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
    final hasGallery = _hasProductImages;

    final stock = int.tryParse((product['quantity'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: hasGallery,
            expandedHeight: hasGallery ? 404 : null,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 4,
            leadingWidth: 52,
            leading: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _buildChromeActionButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Product details',
                      style: AppFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _slate800,
                      ),
                    ),
                    Text(
                      'Shop item overview',
                      style: AppFonts.roboto(
                        fontSize: 11,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildChromeActionButton(
                  icon: Icons.share_outlined,
                  onTap: _shareActiveProduct,
                ),
              ),
            ],
            flexibleSpace: hasGallery
                ? FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _buildImageGallery(product),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, hasGallery ? 0 : 8, 4, 104),
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
                  const SizedBox(height: 6),
                  _buildStoreInfo(product),
                  const SizedBox(height: 6),
                  _buildDescriptionTabs(product),
                  const SizedBox(height: 6),
                  _buildStoreProducts(product),
                  if (_similarProducts.isNotEmpty) ...[
                    const SizedBox(height: 6),
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
    final hasDiscount = sale != null &&
        _toNum(sale) != null &&
        regular != null &&
        _toNum(regular) != null &&
        _toNum(sale)! < _toNum(regular)!;
    final views = _parseInt(product['views']);

    return _buildSectionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _slate800,
              height: 1.26,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u09f3${_formatPrice(sale ?? regular)}',
                style: AppFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _emerald,
                  height: 1,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '\u09f3${_formatPrice(regular)}',
                    style: AppFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _buildHeroBadge(
                    icon: Icons.bolt_rounded,
                    label: '$discount% OFF',
                    color: _rose,
                    background: const Color(0xFFFFE4E6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMetaPill(
                icon: Icons.inventory_2_outlined,
                label: stock > 0 ? '$stock in stock' : 'Currently unavailable',
                color: stock > 0 ? _emerald : _rose,
              ),
              if (isFreeDelivery)
                _buildMetaPill(
                  icon: Icons.local_shipping_outlined,
                  label: 'Free delivery',
                  color: _emerald,
                ),
              if (views > 0)
                _buildMetaPill(
                  icon: Icons.insights_outlined,
                  label: '$views views',
                  color: _indigo,
                ),
            ],
          ),
          if (shortDescription.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shortDescription,
              // Cap long short-descriptions so a vendor pasting a wall of text
              // can't blow up the layout; the toggle below reveals the rest.
              maxLines: _shortDescExpanded ? null : 3,
              overflow: _shortDescExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: AppFonts.roboto(
                fontSize: 12,
                color: _slate500,
                height: 1.5,
              ),
            ),
            if (shortDescription.trim().length > 140)
              GestureDetector(
                onTap: () => setState(
                    () => _shortDescExpanded = !_shortDescExpanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _shortDescExpanded ? 'কম দেখান' : 'আরও দেখুন',
                    style: AppFonts.roboto(
                      fontSize: 12,
                      color: _emerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({required int stock}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _slate200),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 34,
                          height: 42,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.remove_rounded,
                            size: 17,
                            color: _quantity > 1
                                ? _slate800
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_quantity',
                          style: AppFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _slate800,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: (stock <= 0 || _quantity < stock)
                            ? () => setState(() => _quantity++)
                            : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 34,
                          height: 42,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_rounded,
                            size: 17,
                            color: (stock <= 0 || _quantity < stock)
                                ? _slate800
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: stock > 0 ? _handleBuyNow : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            stock > 0 ? 'Buy Now' : 'Unavailable',
                            style: AppFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(Map<String, dynamic> product) {
    final headerHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
    final topInset = headerHeight + 14;
    final isFreeDelivery = product['is_free_delivery'] == true;

    return Stack(
      children: [
        Positioned.fill(
          top: headerHeight,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE9F1FF), Color(0xFFF6F9FE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: headerHeight,
            color: Colors.white,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(4, topInset, 4, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0.0, double.infinity);
              final height = constraints.maxHeight.clamp(0.0, double.infinity);
              final galleryHeight = height > 0 ? height : width + 40;

              return SizedBox(
                width: width,
                height: galleryHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                          child: PageView.builder(
                            itemCount: _imageCount,
                            onPageChanged: (index) {
                              setState(() => _selectedImageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final imageUrl = _getImageUrl(index);
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 48,
                                                color: Colors.grey.shade300,
                                              ),
                                            );
                                          },
                                        ),
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
                        ),
                      ),
                    ),
                    if (isFreeDelivery)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: _buildHeroBadge(
                          icon: Icons.local_shipping_outlined,
                          label: 'Free delivery',
                          color: _emerald,
                          background: const Color(0xFFECFDF5),
                        ),
                      ),
                    if (_imageCount > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_imageCount, (index) {
                            final isActive = index == _selectedImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isActive ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _indigo
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfo(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ??
            ownerDetails['name']?.toString() ??
            'Store')
        : 'Store';

    final isVerified = ownerDetails is Map
        ? (ownerDetails['kyc'] == true || ownerDetails['is_verified'] == true)
        : false;

    return _buildSectionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Storefront'),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 20,
                    color: _indigo,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                              fontWeight: FontWeight.w700,
                              color: _slate800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 15, color: _indigo),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified seller profile and store catalog',
                      style: AppFonts.roboto(
                        fontSize: 11,
                        color: _slate500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _openStore(_resolveStoreIdentity(product), storeName),
              style: OutlinedButton.styleFrom(
                foregroundColor: _slate800,
                side: BorderSide(color: _slate200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.store_mall_directory_outlined, size: 16),
              label: Text(
                'Open store',
                style: AppFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTabs(Map<String, dynamic> product) {
    final description = product['description']?.toString() ?? '';

    return _buildSectionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('About this product'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: _slate500,
              indicator: BoxDecoration(
                color: _slate800,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Delivery'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _buildDescriptionTabContent(
              product: product,
              description: description,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTabContent({
    required Map<String, dynamic> product,
    required String description,
  }) {
    final tabIndex = _tabController.index;

    if (tabIndex == 1) {
      return _buildDeliveryTab(product);
    }

    if (tabIndex == 2) {
      return _buildReviewsTab(product);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
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
                  fontSize: FontSize(12),
                  color: const Color(0xFF475569),
                  lineHeight: const LineHeight(1.6),
                ),
              },
            )
          : Text(
              'No description available',
              style: AppFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
    );
  }

  Widget _buildDeliveryTab(Map<String, dynamic> product) {
    final feeInsideDhaka =
        product['delivery_fee_inside_dhaka']?.toString() ?? '100';
    final feeOutsideDhaka =
        product['delivery_fee_outside_dhaka']?.toString() ?? '150';
    final isFreeDelivery = product['is_free_delivery'] == true;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFreeDelivery)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Free delivery available',
                    style: AppFonts.roboto(
                      fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 34,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 10),
          Text(
            'No reviews yet',
            style: AppFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to review this product and help other buyers.',
            style: AppFonts.roboto(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showWriteReviewDialog(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: _slate800,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Write a review',
                style: AppFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
      AdsyToast.warning(
          context, 'You cannot write a review for your own product.');
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
                        const Icon(Icons.rate_review,
                            color: Color(0xFF10B981), size: 20),
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
                          constraints: const BoxConstraints.tightFor(
                              width: 40, height: 40),
                          iconSize: 30,
                          icon: Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
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
                                        backgroundColor:
                                            const Color(0xFF10B981),
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
    return _buildSectionCard(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('You may also like'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const crossAxisSpacing = 8.0;
              const mainAxisSpacing = 8.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: ProductCardLayout.buildGridDelegate(
                  availableWidth: constraints.maxWidth,
                  screenWidth: MediaQuery.of(context).size.width,
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
          textScale: MediaQuery.textScalerOf(context).scale(1.0),
        ),
                itemCount: _similarProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: _similarProducts[index],
                    isLoading: false,
                    onBuyNow: () =>
                        _handleBuyNowForProduct(_similarProducts[index]),
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
                  child: AdsyLoadingIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreProducts(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ?? 'Store')
        : 'Store';

    return _buildSectionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('More from $storeName'),
          const SizedBox(height: 8),
          if (_isLoadingStoreProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: AdsyLoadingIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              ),
            )
          else if (_storeProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
              padding: EdgeInsets.zero,
              itemCount: _storeProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                return _buildInlineProductRow(
                  product: _storeProducts[index],
                  onTap: () => _openProductDetails(_storeProducts[index]),
                  onBuyNow: () =>
                      _handleBuyNowForProduct(_storeProducts[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: _indigo,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _slate800,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineProductRow({
    required Map<String, dynamic> product,
    required VoidCallback onTap,
    required VoidCallback onBuyNow,
  }) {
    final title = product['name']?.toString() ??
        product['title']?.toString() ??
        'Product';
    final sale = product['sale_price'];
    final regular = product['regular_price'] ?? product['price'];
    final price = sale ?? regular;
    final storeName = _resolveStoreName(product);
    final imageUrl = _resolveProductImage(product);
    final hasDiscount = sale != null &&
        _toNum(sale) != null &&
        regular != null &&
        _toNum(regular) != null &&
        _toNum(sale)! < _toNum(regular)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 62,
                          height: 62,
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
                      const SizedBox(width: 10),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _slate800,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.roboto(
                                fontSize: 11,
                                color: _slate500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  '৳${_formatPrice(price)}',
                                  style: AppFonts.roboto(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _emerald,
                                  ),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '৳${_formatPrice(regular)}',
                                    style: AppFonts.roboto(
                                      fontSize: 11,
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
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              'Buy',
              style: AppFonts.roboto(
                fontSize: 12,
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
