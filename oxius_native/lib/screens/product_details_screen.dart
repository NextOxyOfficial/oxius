import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/eshop_service.dart';
import '../widgets/product_card.dart';
import '../models/cart_item.dart';
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
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  bool _isLoadingSimilarProducts = false;
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
  final ScrollController _similarProductsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _similarProductsScrollController.addListener(_onSimilarProductsScroll);
    _loadProductDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _similarProductsScrollController.removeListener(_onSimilarProductsScroll);
    _similarProductsScrollController.dispose();
    super.dispose();
  }

  void _handleBuyNow() {
    final product = _productDetails ?? widget.product;
    
    // Convert product map to Product object
    final cartProduct = Product(
      id: product['id'], // Can be int or String (UUID)
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

  void _onSimilarProductsScroll() {
    if (_isLoadingMoreSimilarProducts || !_hasMoreSimilarProducts) return;
    
    final maxScroll = _similarProductsScrollController.position.maxScrollExtent;
    final currentScroll = _similarProductsScrollController.position.pixels;
    
    // Load more when 200 pixels from bottom
    if (currentScroll >= maxScroll - 200) {
      _loadMoreSimilarProducts();
    }
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    
    try {
      // In a real app, you might fetch detailed product info from API
      // For now, we'll use the passed product data
      _productDetails = widget.product;
      
      // Load similar products and store products in parallel
      await Future.wait([
        _loadSimilarProducts(),
        _loadStoreProducts(),
      ]);
    } catch (e) {
      print('Error loading product details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSimilarProducts() async {
    setState(() {
      _isLoadingSimilarProducts = true;
      _similarProductsPage = 1;
      _hasMoreSimilarProducts = true;
    });
    
    try {
      // Fetch products from the same category (12 per page for grid layout)
      final products = await EshopService.fetchEshopProducts(page: 1, pageSize: 12);
      
      setState(() {
        // Filter out current product
        _similarProducts = products.where((p) => p['id'] != widget.product['id']).toList();
        _hasMoreSimilarProducts = products.length == 12;
      });
    } catch (e) {
      print('Error loading similar products: $e');
    } finally {
      setState(() => _isLoadingSimilarProducts = false);
    }
  }

  Future<void> _loadMoreSimilarProducts() async {
    if (_isLoadingMoreSimilarProducts || !_hasMoreSimilarProducts) return;
    
    setState(() => _isLoadingMoreSimilarProducts = true);
    
    try {
      final nextPage = _similarProductsPage + 1;
      final products = await EshopService.fetchEshopProducts(page: nextPage, pageSize: 12);
      
      setState(() {
        // Filter out current product and add to list
        final newProducts = products.where((p) => p['id'] != widget.product['id']).toList();
        _similarProducts.addAll(newProducts);
        _similarProductsPage = nextPage;
        _hasMoreSimilarProducts = products.length == 12;
      });
    } catch (e) {
      print('Error loading more similar products: $e');
    } finally {
      setState(() => _isLoadingMoreSimilarProducts = false);
    }
  }

  Future<void> _loadStoreProducts() async {
    setState(() => _isLoadingStoreProducts = true);
    
    try {
      // Fetch products from the same store/owner
      final products = await EshopService.fetchEshopProducts(page: 1, pageSize: 10);
      
      setState(() {
        // Filter out current product
        _storeProducts = products.where((p) => p['id'] != widget.product['id']).take(6).toList();
      });
    } catch (e) {
      print('Error loading store products: $e');
    } finally {
      setState(() => _isLoadingStoreProducts = false);
    }
  }

  String _getImageUrl(int index) {
    try {
      final imageDetails = _productDetails?['image_details'];
      if (imageDetails is List && imageDetails.length > index) {
        return imageDetails[index]['image']?.toString() ?? '';
      }
      return _productDetails?['image']?.toString() ?? '';
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
        backgroundColor: const Color(0xFFF9FAFB),
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
    final description = product['description'] ?? '';
    final shortDescription = product['short_description'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937), size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Color(0xFF1F2937), size: 20),
                onPressed: () async {
                  final product = _productDetails ?? widget.product;
                  final title = product['name'] ?? product['title'] ?? 'Product';
                  final productId = product['id'];
                  final shareText = 'Check out this product: $title\n\nView on AdsyClub: https://oxius.vercel.app/eshop/product/$productId';
                  
                  try {
                    // Using share_plus package
                    await Share.share(shareText);
                  } catch (e) {
                    print('Error sharing: $e');
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade200),
            ),
          ),

          // Product Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  _buildImageGallery(product),

                  const SizedBox(height: 4),

                  // Product Info
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: const Color(0xFF1F2937),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Price Section
                      Row(
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '৳',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatPrice(sale ?? regular),
                                  style: GoogleFonts.roboto(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (sale != null && _toNum(sale) != null && regular != null && _toNum(regular) != null && _toNum(sale)! < _toNum(regular)!) ...[
                            const SizedBox(width: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '৳',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _formatPrice(regular),
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Short Description
                      if (shortDescription.isNotEmpty) ...[
                        Text(
                          shortDescription,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Quantity Selector
                      _buildQuantitySelector(),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Store Information
                _buildStoreInfo(product),

                const SizedBox(height: 4),

                // Description Tabs
                _buildDescriptionTabs(product),

                const SizedBox(height: 4),

                // More from Store
                if (_storeProducts.isNotEmpty) _buildStoreProducts(product),

                const SizedBox(height: 4),

                // Similar Products
                if (_similarProducts.isNotEmpty) _buildSimilarProducts(),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(Map<String, dynamic> product) {
    final isFreeDelivery = product['is_free_delivery'] == true;
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Main Image
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _imageCount,
                  onPageChanged: (index) {
                    setState(() => _selectedImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = _getImageUrl(index);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                );
                              },
                            )
                          : Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                    );
                  },
                ),
                
                // Free Delivery Badge at Bottom Right
                if (isFreeDelivery)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'FREE DELIVERY',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

          // Image Indicators
          if (_imageCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _imageCount,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _selectedImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _selectedImageIndex == index
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                    color: _quantity > 1 ? Colors.grey.shade700 : Colors.grey.shade400,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      _quantity.toString(),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add, size: 18),
                    color: Colors.grey.shade700,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to checkout with current product
                  _handleBuyNow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Buy Now',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreInfo(Map<String, dynamic> product) {
    final ownerDetails = product['owner_details'];
    final storeName = ownerDetails is Map
        ? (ownerDetails['store_name']?.toString() ?? ownerDetails['name']?.toString() ?? 'Store')
        : 'Store';
    
        // Extract owner details
    final isPro = ownerDetails is Map ? (ownerDetails['is_pro'] == true || ownerDetails['subscription_type'] == 'pro') : false;
    final isVerified = ownerDetails is Map ? (ownerDetails['kyc'] == true || ownerDetails['is_verified'] == true) : false;
    
    // Extract address information - try multiple fields
    final upazila = ownerDetails is Map ? (ownerDetails['upazila']?.toString() ?? '') : '';
    final city = ownerDetails is Map ? (ownerDetails['city']?.toString() ?? '') : '';
    final state = ownerDetails is Map ? (ownerDetails['state']?.toString() ?? '') : '';
    final country = ownerDetails is Map ? (ownerDetails['country']?.toString() ?? '') : '';
    final storeAddress = ownerDetails is Map ? (ownerDetails['store_address']?.toString() ?? '') : '';
    
    // Build address from individual fields or use store_address as fallback
    String address = [upazila, city, state, country].where((s) => s.isNotEmpty).join(', ');
    if (address.isEmpty && storeAddress.isNotEmpty) {
      address = storeAddress;
    }
    
    print('Constructed Address: $address');
    
    // Extract and format member since date
    final dateJoined = ownerDetails is Map ? ownerDetails['date_joined']?.toString() : null;
    String memberSince = '';
    if (dateJoined != null && dateJoined.isNotEmpty) {
      try {
        final date = DateTime.parse(dateJoined);
        final month = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ][date.month - 1];
        memberSince = '$month ${date.year}';
      } catch (e) {
        print('Error parsing date: $e');
        memberSince = '';
      }
    }
    
    print('Member Since: $memberSince');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Store Card with Icon, Name, Badges, and Visit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Logo/Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.storefront,
                        size: 32,
                        color: Colors.orange.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Store Info and Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Name
                        Text(
                          storeName,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Badges Row - Pro/Free and Verified/Unverified
                        Row(
                          children: [
                            // Pro/Free Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPro ? const Color(0xFFFFA000) : Colors.grey.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPro)
                                    const Icon(Icons.star, size: 10, color: Colors.white),
                                  if (isPro) const SizedBox(width: 3),
                                  Text(
                                    isPro ? 'Pro' : 'Free',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Verified/Unverified Badge
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          isVerified ? Icons.verified : Icons.info_outline,
                                          color: isVerified ? const Color(0xFF3B82F6) : const Color(0xFFFB923C),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isVerified ? 'Verified Store' : 'Unverified Store',
                                            style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      isVerified
                                          ? 'This store has been verified by our team. You can trust this seller for safe and reliable transactions.'
                                          : 'This store has not completed the verification process yet. Please exercise caution when making purchases.',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF10B981),
                                        ),
                                        child: Text(
                                          'Got it',
                                          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isVerified ? const Color(0xFF3B82F6) : const Color(0xFFFB923C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified ? Icons.verified : Icons.info_outline,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isVerified ? 'Verified' : 'Unverified',
                                      style: GoogleFonts.roboto(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                  ),
                  const SizedBox(width: 8),
                  // Visit Store Button
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to store
                      final storeUsername = ownerDetails is Map 
                          ? (ownerDetails['store_username']?.toString() ?? ownerDetails['username']?.toString())
                          : null;
                      
                      print('Visit Store button pressed');
                      print('Store Username: $storeUsername');
                      
                      if (storeUsername != null && storeUsername.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorStoreScreen(
                              storeUsername: storeUsername,
                              storeName: storeName,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Store username not available',
                              style: GoogleFonts.roboto(fontSize: 13),
                            ),
                            backgroundColor: Colors.orange.shade700,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    label: Text(
                      'Visit Store',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contact Information Section - Always visible
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Address - show data or placeholder
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address.isNotEmpty ? address : 'Kushtia Sadar, Kushtia, Khulna, Bangladesh',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Member Since - show data or placeholder
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        memberSince.isNotEmpty ? 'Member since $memberSince' : 'Member since July 2025',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionTabs(Map<String, dynamic> product) {
    final description = product['description']?.toString() ?? '';
    final deliveryInfo = product['delivery_information']?.toString() ?? '';
    final feeInsideDhaka = product['delivery_fee_inside_dhaka']?.toString() ?? '';
    final feeOutsideDhaka = product['delivery_fee_outside_dhaka']?.toString() ?? '';
    final isFreeDelivery = product['is_free_delivery'] == true;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF10B981),
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Delivery Info'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Description Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    description.isNotEmpty ? description : 'No description available',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ),
                // Delivery Information Tab
                _buildDeliveryTab(product),
                // Reviews Tab
                _buildReviewsTab(product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab(Map<String, dynamic> product) {
    final deliveryInfo = product['delivery_information']?.toString() ?? '';
    final feeInsideDhaka = product['delivery_fee_inside_dhaka']?.toString() ?? '100';
    final feeOutsideDhaka = product['delivery_fee_outside_dhaka']?.toString() ?? '150';
    final isFreeDelivery = product['is_free_delivery'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipping Information Header
          Row(
            children: [
              Icon(Icons.local_shipping, color: const Color(0xFF10B981), size: 16),
              const SizedBox(width: 6),
              Text(
                'Shipping Information',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Delivery Options
          _buildDeliveryOption(
            'Inside Dhaka',
            '৳$feeInsideDhaka',
            Icons.location_city,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildDeliveryOption(
            'Outside Dhaka',
            '৳$feeOutsideDhaka',
            Icons.location_on,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildDeliveryOption(
            'Delivery Time',
            '3-5 business days',
            Icons.access_time,
            Colors.purple,
          ),
          
          // Free Delivery Badge
          if (isFreeDelivery) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free Delivery on this product!',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color.shade700, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color.shade600, size: 16),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(Map<String, dynamic> product) {
    // TODO: Fetch reviews from API
    final hasReviews = false; // Replace with actual data
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Reviews',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _showWriteReviewDialog(product);
                },
                icon: const Icon(Icons.rate_review, size: 14),
                label: Text(
                  'Write Review',
                  style: GoogleFonts.roboto(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // No Reviews State
          if (!hasReviews)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.star_border_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to review this product',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showWriteReviewDialog(product);
                      },
                      icon: const Icon(Icons.rate_review, size: 14),
                      label: Text(
                        'Write a Review',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // TODO: Add reviews list when available
        ],
      ),
    );
  }

  void _showWriteReviewDialog(Map<String, dynamic> product) {
    // Check if user is the owner of the product
    final ownerDetails = product['owner_details'];
    final ownerId = ownerDetails is Map ? ownerDetails['id']?.toString() : null;
    // TODO: Get current user ID from auth service
    final currentUserId = 'current_user_id'; // Replace with actual user ID
    
    // Check if this is the user's own product
    if (ownerId != null && ownerId == currentUserId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                'Cannot Review',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'You cannot write a review for your own product.',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.roboto(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    int rating = 0;
    bool hasComment = false;
    final titleController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              const Icon(Icons.rate_review, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Write a Review',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rating',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 28,
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Review Title (Optional)',
                      labelStyle: GoogleFonts.roboto(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      counterStyle: GoogleFonts.roboto(fontSize: 10),
                      isDense: true,
                    ),
                    style: GoogleFonts.roboto(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLength: 1000,
                    onChanged: (value) {
                      setState(() {
                        hasComment = value.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Your Review',
                      labelStyle: GoogleFonts.roboto(fontSize: 12),
                      hintText: 'Share your experience...',
                      hintStyle: GoogleFonts.roboto(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                      counterStyle: GoogleFonts.roboto(fontSize: 10),
                      isDense: true,
                    ),
                    maxLines: 3,
                    style: GoogleFonts.roboto(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.roboto(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: rating > 0 && hasComment
                  ? () {
                      // TODO: Submit review to API
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Thank you for your review!',
                            style: GoogleFonts.roboto(fontSize: 13),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Products',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            controller: _similarProductsScrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _similarProducts.length + (_isLoadingMoreSimilarProducts ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= _similarProducts.length) {
                // Loading indicator
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                );
              }
              
              return ProductCard(
                product: _similarProducts[index],
                isLoading: false,
                onBuyNow: () => _handleBuyNowForProduct(_similarProducts[index]),
                onTap: () {
                  // Navigate to product details and reload
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        product: _similarProducts[index],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoadingMoreSimilarProducts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading more...',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_hasMoreSimilarProducts && _similarProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No more products',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade500,
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEC4899).withOpacity(0.12),  // Pink
            const Color(0xFFF43F5E).withOpacity(0.15),  // Rose/Red
            const Color(0xFFEF4444).withOpacity(0.12),  // Red
            const Color(0xFFEC4899).withOpacity(0.08),  // Pink again
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEC4899),  // Pink
                      Color(0xFFF43F5E),  // Rose
                      Color(0xFFEF4444),  // Red
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'More from $storeName',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 272,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _storeProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: _storeProducts[index],
                    isLoading: false,
                    onBuyNow: () => _handleBuyNowForProduct(_storeProducts[index]),
                    onTap: () {
                      // Navigate to product details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            product: _storeProducts[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
