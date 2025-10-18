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
  final String? storeImage;

  const VendorStoreScreen({
    super.key,
    required this.storeUsername,
    this.storeName,
    this.storeImage,
  });

  @override
  State<VendorStoreScreen> createState() => _VendorStoreScreenState();
}

class _VendorStoreScreenState extends State<VendorStoreScreen> {
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isLoadingProducts = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingProducts && _hasMore) {
        _fetchProducts(loadMore: true);
      }
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchStoreDetails(),
      _fetchProducts(),
    ]);
  }

  Future<void> _fetchStoreDetails() async {
    try {
      print('🏪 Fetching store details for: ${widget.storeUsername}');
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/store/${widget.storeUsername}/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('🏪 Store details status: ${response.statusCode}');
      print('🏪 Store details body: ${response.body}');
      
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _storeData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('⚠️ Store endpoint returned ${response.statusCode}, using fallback');
        setState(() {
          _storeData = {
            'store_name': widget.storeName ?? widget.storeUsername,
            'store_username': widget.storeUsername,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching store details: $e');
      if (mounted) {
        setState(() {
          _storeData = {
            'store_name': widget.storeName ?? widget.storeUsername,
            'store_username': widget.storeUsername,
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (loadMore) setState(() => _currentPage++);
    
    try {
      setState(() => _isLoadingProducts = true);
      
      print('🔍 Store Username: ${widget.storeUsername}');
      print('🔍 Store Name: ${widget.storeName}');
      
      // Try multiple endpoints
      final endpoints = [
        '${ApiService.baseUrl}/store/${widget.storeUsername}/products/?page=$_currentPage',
        '${ApiService.baseUrl}/products/?owner__username=${widget.storeUsername}&page=$_currentPage',
        '${ApiService.baseUrl}/products/?owner__store_username=${widget.storeUsername}&page=$_currentPage',
        '${ApiService.baseUrl}/products/?page=$_currentPage&page_size=100', // Fallback: get all products
      ];
      
      http.Response? response;
      String? successfulEndpoint;
      
      for (final endpoint in endpoints) {
        try {
          final uri = Uri.parse(endpoint);
          print('🔍 Trying endpoint: $uri');
          
          response = await http.get(uri, headers: {'Content-Type': 'application/json'});
          
          print('📦 Response status: ${response.statusCode}');
          print('📦 Response body length: ${response.body.length} bytes');
          
          if (response.statusCode == 200) {
            // Check if response actually has products
            final testData = json.decode(response.body);
            int productCount = 0;
            
            if (testData is List) {
              productCount = testData.length;
            } else if (testData is Map) {
              final results = testData['results'] ?? testData['products'] ?? [];
              productCount = results.length;
            }
            
            print('📦 Products in response: $productCount');
            
            // Only accept this endpoint if it has products OR if it's the last endpoint
            if (productCount > 0 || endpoint == endpoints.last) {
              successfulEndpoint = endpoint;
              print('✅ Success with endpoint: $endpoint');
              break;
            } else {
              print('⚠️ Endpoint returned 200 but no products, trying next...');
            }
          }
        } catch (e) {
          print('❌ Error with endpoint $endpoint: $e');
          continue;
        }
      }
      
      if (response == null || response.statusCode != 200) {
        throw Exception('All endpoints failed');
      }
      
      print('📦 Response body: ${response.body}');
      print('📦 Response body length: ${response.body.length} bytes');
      
      if (mounted) {
        final data = json.decode(response.body);
        print('📦 Decoded data type: ${data.runtimeType}');
        print('📦 Decoded data: $data');
        
        List<dynamic> results = [];
        
        // Handle different response structures
        if (data is List) {
          results = data;
          print('📦 Direct array response with ${results.length} items');
        } else if (data is Map) {
          print('📦 Response keys: ${data.keys.toList()}');
          if (data.containsKey('results')) {
            results = data['results'] ?? [];
            print('📦 Paginated response with ${results.length} items');
            print('📦 Total count: ${data['count']}');
          } else if (data.containsKey('products')) {
            results = data['products'] ?? [];
            print('📦 Products key response with ${results.length} items');
          } else {
            print('⚠️ Unknown response structure: ${data.keys}');
          }
        }
        
        final newProducts = results.cast<Map<String, dynamic>>();
        print('✅ Parsed ${newProducts.length} products');
        
        // Filter products by store name if we got all products (fallback endpoint)
        List<Map<String, dynamic>> filteredProducts = newProducts;
        if (successfulEndpoint?.contains('page_size=100') == true && widget.storeName != null) {
          print('🔍 Filtering products by store name: ${widget.storeName}');
          filteredProducts = newProducts.where((product) {
            final ownerDetails = product['owner_details'];
            if (ownerDetails is Map) {
              final storeName = ownerDetails['store_name']?.toString() ?? 
                               ownerDetails['name']?.toString() ?? '';
              return storeName.toLowerCase() == widget.storeName?.toLowerCase();
            }
            return false;
          }).toList();
          print('✅ Filtered to ${filteredProducts.length} products for this store');
        }
        
        // Check if products have is_active field
        if (filteredProducts.isNotEmpty) {
          print('📦 First product sample: ${filteredProducts.first}');
          final activeProducts = filteredProducts.where((p) => p['is_active'] == true).toList();
          print('✅ Active products: ${activeProducts.length} / ${filteredProducts.length}');
        } else {
          print('⚠️ No products found for this store!');
          print('⚠️ Store Name: ${widget.storeName}');
          print('⚠️ Store Username: ${widget.storeUsername}');
        }
        
        setState(() {
          if (loadMore) {
            _products.addAll(filteredProducts);
          } else {
            _products = filteredProducts;
          }
          _hasMore = data is Map ? (data['next'] != null) : false;
          _isLoadingProducts = false;
          _error = null;
        });
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load products: $e';
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _navigateToCheckout(Map<String, dynamic> product) {
    try {
      final cartProduct = Product(
        id: product['id'],
        name: product['name'] ?? 'Product',
        description: product['description'],
        regularPrice: _parseDouble(product['regular_price']),
        salePrice: product['sale_price'] != null ? _parseDouble(product['sale_price']) : null,
        quantity: product['quantity'] as int? ?? 999,
        isFreeDelivery: product['is_free_delivery'] as bool?,
        deliveryFeeInsideDhaka: _parseDouble(product['delivery_fee_inside_dhaka']),
        deliveryFeeOutsideDhaka: _parseDouble(product['delivery_fee_outside_dhaka']),
        imageDetails: product['image_details'] != null
            ? (product['image_details'] as List).map((img) => ProductImage.fromJson(img)).toList()
            : null,
      );

      Navigator.pushNamed(context, '/checkout', arguments: {
        'cartItems': [CartItem(product: cartProduct, quantity: 1)],
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Compact App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black87),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF059669),
                    ],
                  ),
                ),
                child: _storeData?['store_banner'] != null
                    ? CachedNetworkImage(
                        imageUrl: _storeData!['store_banner'],
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.2),
                        colorBlendMode: BlendMode.darken,
                      )
                    : null,
              ),
            ),
          ),

          // Store Info Card
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                        // Store Logo, Name and Message Button Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Store Logo
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 3),
                              ),
                              child: ClipOval(
                                child: _storeData?['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: _storeData!['image'],
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(Icons.store, size: 35, color: Color(0xFF10B981)),
                                      )
                                    : const Icon(Icons.store, size: 35, color: Color(0xFF10B981)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Store Name and Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _storeData?['store_name'] ?? widget.storeName ?? 'Store',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (_storeData?['is_verified'] == true || _storeData?['kyc'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, size: 18, color: Colors.blue),
                                      ],
                                    ],
                                  ),
                                  if (_storeData?['store_username'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${_storeData!['store_username']}',
                                      style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Message Button
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.message_outlined),
                              color: const Color(0xFF10B981),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                        
                        // Description
                        if (_storeData?['store_description'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _storeData!['store_description'],
                            style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 12),
                        
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(Icons.inventory_2, '${_products.length}', 'Products'),
                            _buildStat(Icons.star, _storeData?['rating']?.toString() ?? '4.5', 'Rating'),
                            _buildStat(Icons.people, _storeData?['followers_count']?.toString() ?? '0', 'Followers'),
                          ],
                        ),

                      ],
                    ),
                ),
              ),
            ),
          ),

          // Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Text(
                    'Products',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_products.length}',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
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
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else if (_products.isEmpty && !_isLoadingProducts)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No products available', style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: _products[index],
                    isLoading: false,
                    onBuyNow: () => _navigateToCheckout(_products[index]),
                  ),
                  childCount: _products.length,
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoadingProducts && _products.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
              ),
            ),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
