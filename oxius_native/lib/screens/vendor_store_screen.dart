import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../models/cart_item.dart';

class VendorStoreScreen extends StatefulWidget {
  final String storeUsername;
  final String? storeName;

  const VendorStoreScreen({
    super.key,
    required this.storeUsername,
    this.storeName,
  });

  @override
  State<VendorStoreScreen> createState() => _VendorStoreScreenState();
}

class _VendorStoreScreenState extends State<VendorStoreScreen> {
  bool _isLoadingStore = true;
  bool _isLoadingProducts = true;
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize with basic store data immediately
    _storeData = {
      'store_name': widget.storeName ?? widget.storeUsername,
      'store_username': widget.storeUsername,
      'store_description': 'Welcome to our store!',
    };
    _fetchStoreDetails();
    _fetchStoreProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToCheckout(Map<String, dynamic> product) {
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

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingProducts && _hasMore) {
        _fetchStoreProducts(loadMore: true);
      }
    }
  }

  Future<void> _fetchStoreDetails() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/store/${widget.storeUsername}/');
      print('Fetching store details from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Store details response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Store data received: $data');
        if (mounted) {
          setState(() {
            _storeData = data;
            _isLoadingStore = false;
          });
        }
      } else if (response.statusCode == 404) {
        // Store endpoint not found, create mock data from available info
        print('Store endpoint not found (404), using fallback data');
        if (mounted) {
          setState(() {
            _storeData = {
              'store_name': widget.storeName ?? widget.storeUsername,
              'store_username': widget.storeUsername,
              'store_description': 'Welcome to our store!',
            };
            _isLoadingStore = false;
          });
        }
      } else {
        throw Exception('Failed to load store: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading store details: $e');
      if (mounted) {
        setState(() {
          // Use fallback data even on error
          _storeData = {
            'store_name': widget.storeName ?? widget.storeUsername,
            'store_username': widget.storeUsername,
            'store_description': 'Welcome to our store!',
          };
          _isLoadingStore = false;
        });
      }
    }
  }

  Future<void> _fetchStoreProducts({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _currentPage++);
    }

    try {
      setState(() => _isLoadingProducts = true);
      
      final uri = Uri.parse('${ApiService.baseUrl}/store/${widget.storeUsername}/products/?page=$_currentPage');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          final results = (data['results'] ?? []) as List;
          final newProducts = results.cast<Map<String, dynamic>>();
          
          setState(() {
            if (loadMore) {
              _products.addAll(newProducts);
            } else {
              _products = newProducts;
            }
            _hasMore = data['next'] != null;
            _isLoadingProducts = false;
          });
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!loadMore) {
            _error = 'Failed to load products';
          }
          _isLoadingProducts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with Banner
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // Share store
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  // Add to favorites
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildStoreBanner(),
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store Info Section - Always show
          SliverToBoxAdapter(
            child: _buildStoreInfo(),
          ),

          // Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.grey.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Products',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isLoadingProducts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_products.length}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Products Grid
          if (_error != null && _products.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_products.isEmpty && !_isLoadingProducts)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No products available',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return ProductCard(
                      product: _products[index],
                      isLoading: false,
                      onBuyNow: () => _navigateToCheckout(_products[index]),
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),

          // Loading More Indicator
          if (_isLoadingProducts && _products.isNotEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              ),
            ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreBanner() {
    if (_storeData?['store_banner'] != null && _storeData!['store_banner'].toString().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _storeData!['store_banner'],
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.8),
                const Color(0xFF059669).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.8),
            const Color(0xFF059669).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    final isPro = _storeData?['is_pro'] == true || _storeData?['subscription_type'] == 'pro';
    final isVerified = _storeData?['kyc'] == true || _storeData?['is_verified'] == true;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      transform: Matrix4.translationValues(0, -40, 0),
      child: Column(
        children: [
          // Main Store Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Store Logo with elevation
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF10B981), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _storeData?['image'] != null && _storeData!['image'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _storeData!['image'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              child: const Icon(Icons.store, size: 50, color: Color(0xFF10B981)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            child: const Icon(Icons.store, size: 50, color: Color(0xFF10B981)),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Store Name with badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _storeData?['store_name'] ?? widget.storeName ?? 'Store',
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 22, color: Color(0xFF3B82F6)),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Badges Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pro Badge
                    if (isPro)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA000), Color(0xFFFF6F00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'PRO',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'FREE',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),

                if (_storeData?['store_username'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@${_storeData!['store_username']}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                // Store Description
                if (_storeData?['store_description'] != null && _storeData!['store_description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _storeData!['store_description'],
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Contact Buttons
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Message seller
                        },
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: Text(
                          'Message',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Follow store
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Follow',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Store Stats
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.inventory_2_outlined,
                        'Products',
                        '${_products.length}',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildStatItem(
                        Icons.star,
                        'Rating',
                        _storeData?['rating']?.toString() ?? '4.5',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildStatItem(
                        Icons.people,
                        'Followers',
                        _storeData?['followers_count']?.toString() ?? '0',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 26, color: const Color(0xFF10B981)),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
