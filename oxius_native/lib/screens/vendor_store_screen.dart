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
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _categories = [];

  bool _isLoadingStore = true;
  bool _isLoadingProducts = true;

  String? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
        final data = json.decode(response.body);
        print('🏪 Store data keys: ${data.keys.toList()}');
        print('🏪 Store description: ${data['store_description']}');
        print('🏪 Description: ${data['description']}');
        
        // Get description from products if not in store data
        if ((data['store_description'] == null || data['store_description'].toString().isEmpty) &&
            (data['description'] == null || data['description'].toString().isEmpty)) {
          print('⚠️ No description in store data, will check products later');
        }
        
        setState(() {
          _storeData = data;
          _isLoadingStore = false;
        });
      } else {
        print('⚠️ Store endpoint returned ${response.statusCode}, using fallback');
        setState(() {
          _storeData = {
            'store_name': widget.storeName ?? widget.storeUsername,
            'store_username': widget.storeUsername,
          };
          _isLoadingStore = false;
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
          _isLoadingStore = false;
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
            _allProducts.addAll(filteredProducts);
          } else {
            _allProducts = filteredProducts;
          }
          
          // Extract store description from first product if not available
          if ((_storeData?['store_description'] == null || _storeData!['store_description'].toString().isEmpty) &&
              (_storeData?['description'] == null || _storeData!['description'].toString().isEmpty) &&
              _allProducts.isNotEmpty) {
            final firstProduct = _allProducts.first;
            final ownerDetails = firstProduct['owner_details'];
            if (ownerDetails is Map && ownerDetails['store_description'] != null) {
              _storeData = {...?_storeData, 'store_description': ownerDetails['store_description']};
              print('✅ Got description from product owner_details');
            }
          }
          
          _extractCategories();
          _applyFilters();
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

  void _extractCategories() {
    final Map<String, Map<String, dynamic>> categoryMap = {};
    
    try {
      for (final product in _allProducts) {
        if (product['is_active'] != true) continue;
        
        final categoryDetails = product['category_details'];
        if (categoryDetails != null) {
          if (categoryDetails is List && categoryDetails.isNotEmpty) {
            for (final cat in categoryDetails) {
              if (cat is Map && cat['id'] != null && cat['name'] != null) {
                categoryMap[cat['id'].toString()] = {
                  'id': cat['id'],
                  'name': cat['name'],
                };
              }
            }
          } else if (categoryDetails is Map && categoryDetails['id'] != null && categoryDetails['name'] != null) {
            categoryMap[categoryDetails['id'].toString()] = {
              'id': categoryDetails['id'],
              'name': categoryDetails['name'],
            };
          }
        }
      }
      
      _categories = categoryMap.values.toList();
      print('📂 Extracted ${_categories.length} categories');
    } catch (e) {
      print('❌ Error extracting categories: $e');
      _categories = [];
    }
  }

  void _applyFilters() {
    try {
      List<Map<String, dynamic>> filtered = _allProducts.where((p) => p['is_active'] == true).toList();
      
      // Apply category filter
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        filtered = filtered.where((product) {
          final categoryDetails = product['category_details'];
          if (categoryDetails is List && categoryDetails.isNotEmpty) {
            return categoryDetails.any((cat) => 
              cat is Map && cat['id'] != null && cat['id'].toString() == _selectedCategoryId
            );
          } else if (categoryDetails is Map && categoryDetails['id'] != null) {
            return categoryDetails['id'].toString() == _selectedCategoryId;
          }
          return false;
        }).toList();
        print('🔍 Filtered to ${filtered.length} products for category: $_selectedCategoryId');
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          final description = product['description']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
        print('🔍 Search filtered to ${filtered.length} products for query: $_searchQuery');
      }
      
      _products = filtered;
    } catch (e) {
      print('❌ Error applying filters: $e');
      _products = _allProducts.where((p) => p['is_active'] == true).toList();
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSearchVisible) {
          setState(() {
            _isSearchVisible = false;
            _searchController.clear();
            _onSearchChanged('');
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
          // Compact App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!_isSearchVisible) ...[
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _isSearchVisible = true;
                    });
                  },
                ),
              ] else ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {
                              _isSearchVisible = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                        errorWidget: (context, url, error) => Container(
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
                        ),
                        placeholder: (context, url) => Container(
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
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Store Info Card
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                        // Store Logo, Name and Message Button Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Store Logo
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 2),
                              ),
                              child: ClipOval(
                                child: _storeData?['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: _storeData!['image'],
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(Icons.store, size: 35, color: Color(0xFF10B981)),
                                      )
                                    : const Icon(Icons.store, size: 28, color: Color(0xFF10B981)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                            // Store Name and Description
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (_storeData?['is_verified'] == true || _storeData?['kyc'] == true) ...[
                                        const SizedBox(width: 3),
                                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                                      ],
                                    ],
                                  ),
                                  if (_storeData?['store_description'] != null && _storeData!['store_description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _storeData!['store_description'],
                                      style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else if (_storeData?['description'] != null && _storeData!['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _storeData!['description'],
                                      style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        
                        // Stats and Message Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(Icons.inventory_2, '${_allProducts.where((p) => p['is_active'] == true).length}', 'Products'),
                            _buildStatWithSubtext(
                              Icons.star, 
                              _storeData?['rating']?.toString() ?? '4.5', 
                              'Rating',
                              '(${_storeData?['reviews_count']?.toString() ?? '0'} reviews)'
                            ),
                            // Message Button
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.message_outlined, size: 18),
                                    color: const Color(0xFF10B981),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Message',
                                  style: GoogleFonts.roboto(
                                    fontSize: 9,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
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

          // Category Filter
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 45,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    _buildCategoryChip('All', null),
                    ..._categories.map((cat) => _buildCategoryChip(
                      cat['name'] ?? 'Category',
                      cat['id'].toString(),
                    )),
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
                  childAspectRatio: 0.60,
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
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatWithSubtext(IconData icon, String value, String label, String subtext) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF10B981)),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              subtext,
              style: GoogleFonts.roboto(
                fontSize: 8,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 9,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(categoryId),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
        checkmarkColor: const Color(0xFF10B981),
        labelStyle: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
