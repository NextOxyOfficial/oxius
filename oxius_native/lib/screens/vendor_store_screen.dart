import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/cart_item.dart';
import '../services/eshop_service.dart';
import '../utils/network_error_handler.dart';
import '../widgets/product_card.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _slate50 = Color(0xFFF8FAFC);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);

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
  bool _isRefreshing = false;
  bool _hasMore = true;

  String? _selectedCategoryId;
  String _searchQuery = '';
  String? _error;

  int _currentPage = 1;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 260) {
      if (!_isLoadingProducts && _hasMore) {
        _fetchProducts(loadMore: true);
      }
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh && mounted) {
      setState(() {
        _isRefreshing = true;
        _currentPage = 1;
        _hasMore = true;
        _error = null;
      });
    }

    await Future.wait([
      _fetchStoreDetails(),
      _fetchProducts(loadMore: false),
    ]);

    if (!mounted) {
      return;
    }

    setState(() => _isRefreshing = false);
  }

  Future<void> _fetchStoreDetails() async {
    if (mounted) {
      setState(() => _isLoadingStore = true);
    }

    final store = await EshopService.fetchStoreDetails(widget.storeUsername);

    if (!mounted) {
      return;
    }

    setState(() {
      _storeData = store ?? {
        'store_name': widget.storeName ?? widget.storeUsername,
        'store_username': widget.storeUsername,
        'image': widget.storeImage,
      };
      _isLoadingStore = false;
    });
  }

  Future<void> _fetchProducts({required bool loadMore}) async {
    if (_isLoadingProducts && loadMore) {
      return;
    }

    final nextPage = loadMore ? _currentPage + 1 : 1;

    if (mounted) {
      setState(() {
        _isLoadingProducts = true;
        if (!loadMore) {
          _error = null;
        }
      });
    }

    try {
      final response = await EshopService.fetchStoreProducts(
        storeIdentity: widget.storeUsername,
        page: nextPage,
      );
      final newProducts = (response['products'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPage = nextPage;
        _hasMore = response['hasMore'] == true;
        if (loadMore) {
          _allProducts.addAll(newProducts);
        } else {
          _allProducts = newProducts;
        }

        if ((_storeData?['store_description'] == null ||
                _storeData?['store_description'].toString().trim().isEmpty == true) &&
            _allProducts.isNotEmpty) {
          final ownerDetails = _allProducts.first['owner_details'];
          if (ownerDetails is Map<String, dynamic>) {
            final storeDescription =
                ownerDetails['store_description']?.toString().trim() ?? '';
            final storeLogo = ownerDetails['store_logo']?.toString();
            if (storeDescription.isNotEmpty ||
                (storeLogo != null && storeLogo.isNotEmpty)) {
              _storeData = {
                ...?_storeData,
                if (storeDescription.isNotEmpty)
                  'store_description': storeDescription,
                if (storeLogo != null && storeLogo.isNotEmpty) 'store_logo': storeLogo,
              };
            }
          }
        }

        _extractCategories();
        _applyFilters();
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProducts = false;
        _hasMore = false;
        if (!loadMore) {
          _allProducts = [];
          _products = [];
        }
        _error = 'Store products could not be loaded right now.';
      });
    }
  }

  void _extractCategories() {
    final categoryMap = <String, Map<String, dynamic>>{};

    for (final product in _allProducts) {
      if (product['is_active'] != true) {
        continue;
      }

      final categoryDetails = product['category_details'];
      if (categoryDetails is List) {
        for (final category in categoryDetails) {
          if (category is Map && category['id'] != null && category['name'] != null) {
            categoryMap[category['id'].toString()] = {
              'id': category['id'],
              'name': category['name'],
            };
          }
        }
      }
    }

    _categories = categoryMap.values.toList();
  }

  void _applyFilters() {
    var filtered =
        _allProducts.where((product) => product['is_active'] == true).toList();

    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      filtered = filtered.where((product) {
        final categoryDetails = product['category_details'];
        if (categoryDetails is List) {
          return categoryDetails.any(
            (category) =>
                category is Map &&
                category['id']?.toString() == _selectedCategoryId,
          );
        }
        return false;
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final normalizedQuery = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        return name.contains(normalizedQuery) || description.contains(normalizedQuery);
      }).toList();
    }

    _products = filtered;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _applyFilters();
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategoryId = null;
      _applyFilters();
    });
  }

  void _navigateToCheckout(Map<String, dynamic> product) {
    try {
      final cartProduct = Product(
        id: product['id'],
        name: product['name'] ?? 'Product',
        description: product['description'],
        regularPrice: _parseDouble(product['regular_price']),
        salePrice: product['sale_price'] != null
            ? _parseDouble(product['sale_price'])
            : null,
        quantity: product['quantity'] as int? ?? 999,
        isFreeDelivery: product['is_free_delivery'] as bool?,
        deliveryFeeInsideDhaka:
            _parseDouble(product['delivery_fee_inside_dhaka']),
        deliveryFeeOutsideDhaka:
            _parseDouble(product['delivery_fee_outside_dhaka']),
        imageDetails: product['image_details'] != null
            ? (product['image_details'] as List)
                .map((image) => ProductImage.fromJson(image))
                .toList()
            : null,
      );

      Navigator.pushNamed(context, '/checkout', arguments: {
        'cartItems': [CartItem(product: cartProduct, quantity: 1)],
      });
    } catch (e) {
      NetworkErrorHandler.showErrorSnackbar(context, e);
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _storeName() {
    return _storeData?['store_name']?.toString().trim().isNotEmpty == true
        ? _storeData!['store_name'].toString().trim()
        : (widget.storeName?.trim().isNotEmpty == true
            ? widget.storeName!.trim()
            : widget.storeUsername);
  }

  String _storeDescription() {
    final description = _storeData?['store_description']?.toString().trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }

    final fallback = _storeData?['description']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Curated products from this vendor store.';
  }

  String? _storeBanner() {
    final banner = _storeData?['store_banner']?.toString();
    if (banner != null && banner.isNotEmpty) {
      return banner;
    }
    return null;
  }

  String? _storeLogo() {
    final logo = _storeData?['store_logo']?.toString();
    if (logo != null && logo.isNotEmpty) {
      return logo;
    }
    final image = _storeData?['image']?.toString();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    return widget.storeImage;
  }

  bool _isVerifiedStore() {
    return _storeData?['is_verified'] == true || _storeData?['kyc'] == true;
  }

  String _ratingLabel() {
    final ratingValue = _storeData?['rating'];
    if (ratingValue == null) {
      return 'New';
    }
    final parsed = double.tryParse(ratingValue.toString());
    if (parsed == null || parsed <= 0) {
      return 'New';
    }
    return parsed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        _isLoadingStore && _isLoadingProducts && _allProducts.isEmpty;

    return Scaffold(
      backgroundColor: _slate50,
      body: RefreshIndicator(
        color: _indigo,
        onRefresh: () => _loadData(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (isInitialLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: _indigo),
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _buildStoreSummary()),
              SliverToBoxAdapter(child: _buildSearchSection()),
              if (_categories.isNotEmpty)
                SliverToBoxAdapter(child: _buildCategorySection()),
              SliverToBoxAdapter(child: _buildProductsHeader()),
              _buildProductsBody(),
              if (_isLoadingProducts && _products.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: CircularProgressIndicator(color: _indigo),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final banner = _storeBanner();

    return SliverAppBar(
      expandedHeight: 144,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (banner != null)
              CachedNetworkImage(
                imageUrl: banner,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _indigo.withValues(alpha: 0.92),
                    _violet.withValues(alpha: 0.86),
                    _emerald.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'Vendor Store',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSummary() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _slate200),
            boxShadow: [
              BoxShadow(
                color: _indigo.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_indigo, _violet]),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _indigo.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _storeLogo() != null && _storeLogo()!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _storeLogo()!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _storeName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: _emerald,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isVerifiedStore() ? 'Verified Store' : 'Trusted Store',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _storeDescription(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: _slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Products',
                      value:
                          '${_allProducts.where((item) => item['is_active'] == true).length}',
                      icon: Icons.inventory_2_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Categories',
                      value: '${_categories.length}',
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Rating',
                      value: _ratingLabel(),
                      icon: Icons.star_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _slate50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: _indigo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _slate800,
          ),
          decoration: InputDecoration(
            hintText: 'Search in this store',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _slate400,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: _slate500),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.close_rounded, color: _slate500),
                  )
                : null,
            filled: true,
            fillColor: _slate50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _indigo, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            _buildCategoryChip('All', null),
            ..._categories.map(
              (category) => _buildCategoryChip(
                category['name']?.toString() ?? 'Category',
                category['id']?.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(categoryId),
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: _indigo.withValues(alpha: 0.12),
        side: BorderSide(color: isSelected ? _indigo : _slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? _indigo : _slate700,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Products',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _slate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _searchQuery.isNotEmpty
                      ? '${_products.length} matched products'
                      : '${_products.length} active products available',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _slate500,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: _indigo),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsBody() {
    if (_error != null && _products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildStateCard(
          icon: Icons.store_mall_directory_outlined,
          title: 'Products unavailable',
          subtitle: _error!,
          actionLabel: 'Retry',
          onTap: () => _loadData(refresh: true),
        ),
      );
    }

    if (_products.isEmpty && !_isLoadingProducts) {
      final message = _searchQuery.isNotEmpty || _selectedCategoryId != null
          ? 'No products matched the current filters for this store.'
          : 'This vendor has not published any active products yet.';

      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildStateCard(
          icon: Icons.inventory_2_outlined,
          title: 'Nothing to show',
          subtitle: message,
          actionLabel: 'Clear filters',
          onTap: _clearFilters,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.57,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
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
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _slate200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: _indigo),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: _slate500,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: _indigo,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}