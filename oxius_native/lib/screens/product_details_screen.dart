import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/eshop_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/url_launcher_utils.dart';
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
    print('===== LOADING STORE PRODUCTS =====');
    print('Product ID: ${widget.product['id']}');
    print('Product Title: ${widget.product['title']}');
    
    setState(() => _isLoadingStoreProducts = true);
    
    try {
      // Get store username from owner_details
      final ownerDetails = widget.product['owner_details'];
      print('Owner Details Type: ${ownerDetails.runtimeType}');
      print('Owner Details Content: $ownerDetails');
      
      String? storeUsername;
      
      if (ownerDetails is Map<String, dynamic>) {
        // Check multiple possible username fields
        final storeUsernameField = ownerDetails['store_username']?.toString();
        final usernameField = ownerDetails['username']?.toString();
        final userIdField = ownerDetails['user_id']?.toString();
        final idField = ownerDetails['id']?.toString();
        
        print('Available owner fields:');
        print('  store_username: $storeUsernameField');
        print('  username: $usernameField');
        print('  user_id: $userIdField');
        print('  id: $idField');
        print('  All keys: ${ownerDetails.keys.toList()}');
        
        storeUsername = storeUsernameField ?? usernameField ?? userIdField ?? idField;
      }
      
      if (storeUsername == null || storeUsername.isEmpty) {
        print('❌ ERROR: No store username/ID found in product owner_details');
        print('Owner details full structure: $ownerDetails');
        setState(() {
          _storeProducts = [];
          _isLoadingStoreProducts = false;
        });
        return;
      }
      
      print('✅ Using store identifier: $storeUsername');
      
      // Try multiple endpoints like VendorStoreScreen does
      final endpoints = [
        '${ApiService.baseUrl}/store/$storeUsername/products/?page=1&page_size=10',
        '${ApiService.baseUrl}/products/?owner__username=$storeUsername&page=1&page_size=10',
        '${ApiService.baseUrl}/products/?owner__store_username=$storeUsername&page=1&page_size=10',
      ];
      
      List<Map<String, dynamic>> products = [];
      bool foundProducts = false;
      
      for (final endpoint in endpoints) {
        try {
          print('🔍 Trying endpoint: $endpoint');
          
          final uri = Uri.parse(endpoint);
          final response = await http.get(
            uri,
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          print('📦 Response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Parse response
            List<dynamic> rawProducts = [];
            if (data is List) {
              rawProducts = data;
            } else if (data is Map) {
              rawProducts = data['results'] ?? data['products'] ?? [];
            }
            
            print('📦 Products found: ${rawProducts.length}');
            
            if (rawProducts.isNotEmpty) {
              // Transform products
              products = rawProducts.map((p) {
                if (p is Map) {
                  return Map<String, dynamic>.from(p);
                }
                return <String, dynamic>{};
              }).toList();
              
              foundProducts = true;
              print('✅ Success! Using endpoint: $endpoint');
              break;
            } else {
              print('⚠️ Endpoint returned 0 products, trying next...');
            }
          } else {
            print('⚠️ Endpoint returned ${response.statusCode}, trying next...');
          }
        } catch (e) {
          print('❌ Error with endpoint $endpoint: $e');
        }
      }
      
      if (!foundProducts) {
        print('⚠️ WARNING: No products found after trying all endpoints for: $storeUsername');
      }
      
      setState(() {
        // Filter out current product
        final currentProductId = widget.product['id'];
        print('Current product ID to exclude: $currentProductId');
        
        final filteredProducts = products.where((p) {
          final productId = p['id'];
          final shouldInclude = productId != currentProductId;
          if (!shouldInclude) {
            print('Excluding current product: $productId');
          }
          return shouldInclude;
        }).toList();
        
        print('📊 Statistics:');
        print('  Total from API: ${products.length}');
        print('  After filtering current: ${filteredProducts.length}');
        
        // Show products (up to 6)
        _storeProducts = filteredProducts.take(6).toList();
        
        print('✅ Final products to display: ${_storeProducts.length}');
        
        if (_storeProducts.isNotEmpty) {
          print('Product titles: ${_storeProducts.map((p) => p['title']).take(3).join(', ')}...');
        }
      });
    } catch (e) {
      print('Error loading store products: $e');
      setState(() {
        _storeProducts = [];
      });
    } finally {
      setState(() => _isLoadingStoreProducts = false);
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
    final shortDescription = product['short_description'] ?? '';

    final stock = int.tryParse((product['quantity'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                    style: GoogleFonts.roboto(
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
                icon: const Icon(Icons.share_rounded, color: Color(0xFF111827), size: 20),
                onPressed: () async {
                  final product = _productDetails ?? widget.product;
                  final productTitle = product['name'] ?? product['title'] ?? 'Product';
                  final productSlug = product['slug'] ?? product['id'];
                  final shareText = 'Check out this product: $productTitle\n\nView on AdsyClub: https://adsyclub.com/products/$productSlug';

                  try {
                    await Share.share(shareText);
                  } catch (e) {
                    print('Error sharing: $e');
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
                ),
                Container(height: 8, color: const Color(0xFFF3F4F6)),
                _buildStoreInfo(product),
                Container(height: 8, color: const Color(0xFFF3F4F6)),
                _buildDescriptionTabs(product),
                Container(height: 8, color: const Color(0xFFF3F4F6)),
                _buildStoreProducts(product),
                Container(height: 8, color: const Color(0xFFF3F4F6)),
                if (_similarProducts.isNotEmpty) _buildSimilarProducts(),
                const SizedBox(height: 80),
              ],
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
  }) {
    final hasDiscount = sale != null && _toNum(sale) != null && regular != null && _toNum(regular) != null && _toNum(sale)! < _toNum(regular)!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          // Price Row with Stock on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '\u09f3${_formatPrice(sale ?? regular)}',
                style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
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
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Stock badge on right
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
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: stock > 0 ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isFreeDelivery) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 14, color: const Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  'Free Delivery',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
          if (shortDescription.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shortDescription,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({required int stock}) {
    return Container(
      color: Colors.white,
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
                        style: GoogleFonts.roboto(
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
                    onPressed: _handleBuyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Buy Now',
                      style: GoogleFonts.roboto(
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
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_selectedImageIndex + 1}/$_imageCount',
                        style: GoogleFonts.roboto(
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Store Icon
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
          // Store Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        storeName,
                        style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Visit Button
          TextButton(
            onPressed: () {
              final storeUsername = ownerDetails is Map 
                  ? (ownerDetails['store_username']?.toString() ?? ownerDetails['username']?.toString())
                  : null;
              
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
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Visit',
                  style: GoogleFonts.roboto(
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
    );
  }

  Widget _buildDescriptionTabs(Map<String, dynamic> product) {
    final description = product['description']?.toString() ?? '';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Header
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFFE5E7EB))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1F2937),
              unselectedLabelColor: const Color(0xFF9CA3AF),
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 2,
              labelStyle: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.roboto(
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
          // Tab Content
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Description Tab
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
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                ),
                // Delivery Tab
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
                    style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to review',
            style: GoogleFonts.roboto(
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
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(Map<String, dynamic> product) {
    // Check if user is the owner of the product
    final ownerDetails = product['owner_details'];
    final ownerId = ownerDetails is Map ? ownerDetails['id']?.toString() : null;
    // TODO: Get current user ID from auth service
    final currentUserId = AuthService.currentUser?.id;
    
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

  Widget _buildSimilarProducts() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You may also like',
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 360;
              final isLargeScreen = screenWidth > 600;
              
              // Calculate responsive details height based on screen size
              final detailsHeight = isSmallScreen ? 120.0 : isLargeScreen ? 140.0 : 132.0;
              
              const crossAxisCount = 2;
              const crossAxisSpacing = 6.0;
              const mainAxisSpacing = 6.0;
              final totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
              final available = (constraints.maxWidth - totalSpacing).clamp(0.0, double.infinity);
              final cellWidth = (available / crossAxisCount).clamp(0.0, double.infinity);
              
              // ProductCard uses square image + details block
              final childAspectRatio = cellWidth > 0 ? (cellWidth / (cellWidth + detailsHeight)) : 0.55;
              
              return GridView.builder(
                controller: _similarProductsScrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                ),
                itemCount: _similarProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: _similarProducts[index],
                    isLoading: false,
                    onBuyNow: () => _handleBuyNowForProduct(_similarProducts[index]),
                    onTap: () {
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'More from $storeName',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 360;
              final isLargeScreen = screenWidth > 600;
              
              // Calculate responsive height based on screen size
              // Card width (140) + details height
              final detailsHeight = isSmallScreen ? 120.0 : isLargeScreen ? 140.0 : 130.0;
              final cardHeight = 140.0 + detailsHeight;
              
              return SizedBox(
                height: cardHeight,
                child: _isLoadingStoreProducts
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                        ),
                      )
                    : _storeProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No other products',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _storeProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 140,
                                child: ProductCard(
                                  product: _storeProducts[index],
                                  isLoading: false,
                                  onBuyNow: () => _handleBuyNowForProduct(_storeProducts[index]),
                                  onTap: () {
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
              );
            },
          ),
        ],
      ),
    );
  }

}
