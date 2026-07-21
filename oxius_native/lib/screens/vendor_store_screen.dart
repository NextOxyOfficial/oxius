import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/app_config.dart';
import '../models/cart_item.dart';
import '../models/store_review.dart';
import '../services/eshop_service.dart';
import '../services/review_service.dart';
import '../utils/network_error_handler.dart';
import '../widgets/common/adsy_share_sheet.dart';
import '../widgets/product_card.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';
import 'package:oxius_native/widgets/common/adsy_back_to_top.dart';

// Clean marketplace palette (screenshot-matched): white surfaces, green
// accent, near-black text.
const _green = Color(0xFF22C55E);
const _greenDark = Color(0xFF16A34A);
const _dark = Color(0xFF111827);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

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
  bool _isStoreSubscriptionExpired = false;

  String? _selectedCategoryId;
  String _searchQuery = '';
  String? _error;
  String? _storeSubscriptionExpiredMessage;

  // 0 = Home, 1 = Best Seller, 2 = Categories, 3 = About
  int _tab = 0;

  // Public store reviews (About tab).
  List<dynamic> _storeReviews = [];
  int _reviewsTotal = 0;
  bool _reviewsLoading = false;
  bool _reviewsLoaded = false;

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
        _isStoreSubscriptionExpired = false;
        _storeSubscriptionExpiredMessage = null;
      });
    }

    await Future.wait([
      _fetchStoreDetails(),
      _fetchProducts(loadMore: false),
    ]);

    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  Future<void> _fetchStoreDetails() async {
    if (mounted) setState(() => _isLoadingStore = true);

    try {
      final store = await EshopService.fetchStoreDetails(widget.storeUsername);
      if (!mounted) return;
      setState(() {
        _storeData = store ??
            {
              'store_name': widget.storeName ?? widget.storeUsername,
              'store_username': widget.storeUsername,
              'image': widget.storeImage,
            };
        _isLoadingStore = false;
      });
    } on StoreSubscriptionExpiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _storeData = null;
        _products = [];
        _allProducts = [];
        _categories = [];
        _hasMore = false;
        _isLoadingStore = false;
        _isLoadingProducts = false;
        _isStoreSubscriptionExpired = true;
        _storeSubscriptionExpiredMessage = e.message;
      });
    }
  }

  Future<void> _fetchProducts({required bool loadMore}) async {
    if (_isStoreSubscriptionExpired) {
      if (mounted) setState(() => _isLoadingProducts = false);
      return;
    }
    if (_isLoadingProducts && loadMore) return;

    final nextPage = loadMore ? _currentPage + 1 : 1;

    if (mounted) {
      setState(() {
        _isLoadingProducts = true;
        if (!loadMore) _error = null;
      });
    }

    try {
      final response = await EshopService.fetchStoreProducts(
        storeIdentity: widget.storeUsername,
        page: nextPage,
      );
      final newProducts =
          (response['products'] as List<dynamic>).cast<Map<String, dynamic>>();

      if (!mounted) return;

      setState(() {
        _currentPage = nextPage;
        _hasMore = response['hasMore'] == true;
        if (loadMore) {
          _allProducts.addAll(newProducts);
        } else {
          _allProducts = newProducts;
        }

        // Backfill store fields missing from the store endpoint with the
        // owner's data carried on products (BN profile image included).
        if (_allProducts.isNotEmpty) {
          final ownerDetails = _allProducts.first['owner_details'];
          if (ownerDetails is Map<String, dynamic>) {
            final updates = <String, dynamic>{};
            for (final key in ['store_description', 'store_logo', 'image']) {
              final current = _storeData?[key]?.toString().trim() ?? '';
              final incoming = ownerDetails[key]?.toString().trim() ?? '';
              if (current.isEmpty && incoming.isNotEmpty) {
                updates[key] = incoming;
              }
            }
            if (updates.isNotEmpty) {
              _storeData = {...?_storeData, ...updates};
            }
          }
        }

        _extractCategories();
        _applyFilters();
        _isLoadingProducts = false;
      });
    } on StoreSubscriptionExpiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _hasMore = false;
        _allProducts = [];
        _products = [];
        _categories = [];
        _error = null;
        _isStoreSubscriptionExpired = true;
        _storeSubscriptionExpiredMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
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
    // Category id → {id, name, image} — the image comes from the first
    // product carrying that category, so the Categories grid has real photos.
    final categoryMap = <String, Map<String, dynamic>>{};

    for (final product in _allProducts) {
      if (product['is_active'] != true) continue;

      final categoryDetails = product['category_details'];
      if (categoryDetails is List) {
        for (final category in categoryDetails) {
          if (category is Map &&
              category['id'] != null &&
              category['name'] != null) {
            final key = category['id'].toString();
            if (!categoryMap.containsKey(key)) {
              categoryMap[key] = {
                'id': category['id'],
                'name': category['name'],
                'image': category['image']?.toString().isNotEmpty == true
                    ? category['image'].toString()
                    : _productImage(product),
              };
            }
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
        final description =
            product['description']?.toString().toLowerCase() ?? '';
        return name.contains(normalizedQuery) ||
            description.contains(normalizedQuery);
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
      // Tapping the selected category again clears the filter.
      _selectedCategoryId =
          _selectedCategoryId == categoryId ? null : categoryId;
      _applyFilters();
    });
  }

  Future<void> _loadStoreReviews() async {
    if (_reviewsLoading || _reviewsLoaded) return;
    setState(() => _reviewsLoading = true);
    final res =
        await ReviewService.getPublicStoreReviews(widget.storeUsername);
    if (!mounted) return;
    setState(() {
      _storeReviews = res['reviews'] as List<dynamic>;
      _reviewsTotal = res['total'] as int;
      _reviewsLoading = false;
      _reviewsLoaded = true;
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

  // ── Store helpers ────────────────────────────────────────────────────────

  String _storeName() {
    return _storeData?['store_name']?.toString().trim().isNotEmpty == true
        ? _storeData!['store_name'].toString().trim()
        : (widget.storeName?.trim().isNotEmpty == true
            ? widget.storeName!.trim()
            : widget.storeUsername);
  }

  String _storeDescription() {
    final description = _storeData?['store_description']?.toString().trim();
    if (description != null && description.isNotEmpty) return description;
    final fallback = _storeData?['description']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return 'Curated products from this vendor store.';
  }

  String? _storeBanner() {
    final banner = _storeData?['store_banner']?.toString();
    if (banner != null && banner.isNotEmpty) return banner;
    return null;
  }

  String? _storeLogo() {
    // BN profile image first — the same photo the owner shows on Business
    // Network — then the store logo, then whatever the opener passed in.
    for (final raw in [
      _storeData?['image'],
      _storeData?['store_logo'],
      widget.storeImage,
    ]) {
      final v = raw?.toString().trim() ?? '';
      if (v.isEmpty) continue;
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
      return '${AppConfig.mediaBaseUrl}${v.startsWith('/') ? v : '/$v'}';
    }
    return null;
  }

  bool _isVerifiedStore() {
    return _storeData?['is_verified'] == true || _storeData?['kyc'] == true;
  }

  int get _activeCount =>
      _allProducts.where((item) => item['is_active'] == true).length;

  // ── Product helpers ──────────────────────────────────────────────────────

  String _productImage(Map<String, dynamic> product) {
    String raw = '';
    if (product['image_details'] is List &&
        (product['image_details'] as List).isNotEmpty) {
      final first = (product['image_details'] as List).first;
      if (first is Map && first['image'] != null) {
        raw = first['image'].toString();
      }
    }
    if (raw.isEmpty) raw = product['image']?.toString() ?? '';
    if (raw.isEmpty) raw = product['featured_image']?.toString() ?? '';
    if (raw.isEmpty) return '';
    // Django returns relative /media/ paths — make them absolute or the
    // showcase/category images silently fail to load.
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = AppConfig.mediaBaseUrl;
    return '$base${raw.startsWith('/') ? raw : '/$raw'}';
  }

  double _productRating(Map<String, dynamic> p) {
    final r = p['average_rating'] ?? p['rating'];
    final parsed = double.tryParse('${r ?? ''}');
    return parsed ?? 0;
  }

  int _productReviews(Map<String, dynamic> p) {
    final r = p['total_reviews'] ?? p['reviews_count'] ?? p['review_count'];
    return int.tryParse('${r ?? ''}') ?? 0;
  }

  int _productSales(Map<String, dynamic> p) {
    final s = p['sales_count'] ?? p['order_count'] ?? p['sold_count'];
    return int.tryParse('${s ?? ''}') ?? 0;
  }

  /// Actives ranked for the Best Seller rail: sales → rating → reviews.
  List<Map<String, dynamic>> get _bestSellers {
    final actives =
        _allProducts.where((p) => p['is_active'] == true).toList();
    actives.sort((a, b) {
      final bySales = _productSales(b).compareTo(_productSales(a));
      if (bySales != 0) return bySales;
      final byRating = _productRating(b).compareTo(_productRating(a));
      if (byRating != 0) return byRating;
      return _productReviews(b).compareTo(_productReviews(a));
    });
    return actives;
  }

  void _shareStore() {
    AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: _storeName(),
        description: _storeDescription(),
        url: 'https://adsyclub.com/eshop/${widget.storeUsername}',
        imageUrl: _storeLogo(),
        subject: '${_storeName()} — AdsyClub eShop',
        eyebrow: 'eShop Store',
      ),
    );
  }

  /// Store QR bottom sheet — the code encodes the public store URL, so
  /// scanning it (AdsyPay scanner or any camera) lands on this store.
  void _showStoreQr() {
    final storeUrl = 'https://adsyclub.com/eshop/${widget.storeUsername}';
    final logo = _storeLogo();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              // Store identity
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: logo != null && logo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: logo,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                                color: _green,
                                size: 24),
                          )
                        : const Icon(Icons.storefront_rounded,
                            color: _green, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _storeName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // The QR itself
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _slate200),
                ),
                child: QrImageView(
                  data: storeUrl,
                  version: QrVersions.auto,
                  size: 196,
                  gapless: true,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: _dark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: _dark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'স্ক্যান করলেই এই স্টোরে চলে আসবে',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _slate500,
                ),
              ),
              const SizedBox(height: 16),
              // Share the store link right from the QR sheet.
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    _shareStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/icons/share.png',
                    width: 16,
                    height: 16,
                    color: Colors.white,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.ios_share_rounded,
                        size: 16),
                  ),
                  label: Text(
                    'স্টোর শেয়ার করুন',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        _isLoadingStore && _isLoadingProducts && _allProducts.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            AdsyRefreshIndicator(
          color: _green,
          onRefresh: () => _loadData(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search bar stays pinned at the top while scrolling.
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTopBarDelegate(
                  height: 58,
                  child: _buildTopBar(),
                ),
              ),
              if (isInitialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: AdsyLoadingIndicator(color: _green)),
                )
              else if (_isStoreSubscriptionExpired)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildStateCard(
                    icon: Icons.lock_outline_rounded,
                    title: 'স্টোরটি এখন দেখা যাচ্ছে না',
                    subtitle: _storeSubscriptionExpiredMessage ??
                        EshopService.defaultStoreSubscriptionExpiredMessage,
                    actionLabel: 'Refresh',
                    onTap: () => _loadData(refresh: true),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildIdentityRow()),
                SliverToBoxAdapter(child: _buildIconTabs()),
                ..._buildTabSlivers(),
                if (_isLoadingProducts && _products.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child:
                          Center(child: AdsyLoadingIndicator(color: _green)),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ],
          ),
            ),
            // Universal back-to-top.
            AdsyBackToTop(controller: _scrollController),
          ],
        ),
      ),
    );
  }

  // ── Top bar: back + search + bag ─────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _slate100)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _dark, size: 22),
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _slate100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search on ${_storeName().toLowerCase()}',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: _slate400,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: _slate500),
                        )
                      : const Icon(Icons.search_rounded,
                          size: 20, color: _slate500),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Shop → main eShop.
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/eshop'),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: _slate200),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/icons/shop.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      color: _greenDark,
                      size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Identity: logo + name + verified + share ─────────────────────────────

  Widget _buildIdentityRow() {
    final logo = _storeLogo();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _slate100,
            ),
            clipBehavior: Clip.antiAlias,
            child: logo != null && logo.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: _slate400,
                        size: 24),
                  )
                : const Icon(Icons.storefront_rounded,
                    color: _slate400, size: 24),
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
                        _storeName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (_isVerifiedStore()) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          size: 16, color: Color(0xFF2563EB)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$_activeCount Products',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _slate500,
                      ),
                    ),
                    if (_isRefreshing) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: AdsyLoadingIndicator(
                            strokeWidth: 2, color: _green),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Store QR — scanning it opens this store in the app.
          InkWell(
            onTap: _showStoreQr,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: _slate200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  color: _dark, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Share (chat + social + copy — the AdsyShareSheet).
          InkWell(
            onTap: _shareStore,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: _slate200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/share.png',
                  width: 17,
                  height: 17,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.ios_share_rounded,
                      color: _dark,
                      size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon tab bar ─────────────────────────────────────────────────────────

  Widget _buildIconTabs() {
    const icons = [
      Icons.grid_view_rounded, // Home
      Icons.star_border_rounded, // Best seller
      Icons.dashboard_customize_outlined, // Categories
      Icons.info_outline_rounded, // About
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _slate100, width: 1.5)),
      ),
      child: Row(
        children: List.generate(icons.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _tab = i);
                if (i == 3) _loadStoreReviews();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Icon(
                      icons[i],
                      size: 22,
                      color: active ? _greenDark : _slate400,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2.5,
                    width: active ? 34 : 0,
                    decoration: BoxDecoration(
                      color: _greenDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab bodies ───────────────────────────────────────────────────────────

  List<Widget> _buildTabSlivers() {
    switch (_tab) {
      case 1: // Best Seller — full grid, ranked
        return [
          SliverToBoxAdapter(
              child: _sectionHeader('Best Seller', seeAll: false)),
          _buildProductsGrid(_bestSellers),
        ];
      case 2: // Categories — image grid + filtered results below
        return [
          SliverToBoxAdapter(
              child: _sectionHeader('Categories', seeAll: false)),
          _buildCategoriesGrid(),
          if (_selectedCategoryId != null) ...[
            SliverToBoxAdapter(
              child: _sectionHeader(
                _selectedCategoryName(),
                seeAll: true,
                seeAllLabel: 'Clear',
                onSeeAll: () => _onCategorySelected(_selectedCategoryId),
              ),
            ),
            _buildProductsGrid(_products),
          ],
        ];
      case 3: // About + Reviews
        return [SliverToBoxAdapter(child: _buildAboutSection())];
      case 0: // Home: best-seller rail + banner + categories + products
      default:
        return [
          if (_searchQuery.isEmpty && _selectedCategoryId == null) ...[
            if (_bestSellers.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _sectionHeader('Best Seller',
                    seeAll: true, onSeeAll: () => setState(() => _tab = 1)),
              ),
              SliverToBoxAdapter(child: _buildBestSellerRail()),
            ],
            SliverToBoxAdapter(child: _buildStoreBannerCard()),
          ],
          // Categories stay visible while a category filter is active so the
          // user can switch/clear without leaving the page.
          if (_searchQuery.isEmpty && _categories.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _sectionHeader('Categories',
                  seeAll: true, onSeeAll: () => setState(() => _tab = 2)),
            ),
            SliverToBoxAdapter(child: _buildCategoryRail()),
          ],
          SliverToBoxAdapter(
            child: _sectionHeader(
              _selectedCategoryId != null
                  ? _selectedCategoryName()
                  : (_searchQuery.isNotEmpty ? 'Search Results' : 'Products'),
              seeAll: _selectedCategoryId != null || _searchQuery.isNotEmpty,
              seeAllLabel: 'Clear',
              onSeeAll: _clearFilters,
            ),
          ),
          _buildProductsGrid(_products),
        ];
    }
  }

  String _selectedCategoryName() {
    final match = _categories.firstWhere(
      (c) => c['id']?.toString() == _selectedCategoryId,
      orElse: () => {'name': 'Filtered Products'},
    );
    return match['name']?.toString() ?? 'Filtered Products';
  }

  /// Horizontal category slider on Home (image + name), "See all" → tab 2.
  Widget _buildCategoryRail() {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = _categories[i];
          final img = c['image']?.toString() ?? '';
          final selected = _selectedCategoryId == c['id']?.toString();
          return GestureDetector(
            onTap: () => _onCategorySelected(c['id']?.toString()),
            child: SizedBox(
              width: 82,
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? _greenDark : _slate100,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: img.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.category_outlined,
                                color: _slate400),
                          )
                        : const Icon(Icons.category_outlined,
                            color: _slate400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.25,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? _greenDark : _dark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title,
      {bool seeAll = false, String seeAllLabel = 'See all', VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _dark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (seeAll)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                seeAllLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Best-seller rail (horizontal screenshot-style cards) ─────────────────

  Widget _buildBestSellerRail() {
    final items = _bestSellers.take(8).toList();
    return SizedBox(
      height: 278,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildShowcaseCard(items[i]),
      ),
    );
  }

  Widget _buildShowcaseCard(Map<String, dynamic> p) {
    final image = _productImage(p);
    final regular = _parseDouble(p['regular_price'] ?? p['price']);
    final sale =
        p['sale_price'] != null ? _parseDouble(p['sale_price']) : null;
    final hasDiscount = sale != null && sale > 0 && sale < regular;
    final discountPct =
        hasDiscount ? (((regular - sale) / regular) * 100).round() : 0;
    final rating = _productRating(p);
    final reviews = _productReviews(p);
    final owner = p['owner_details'] is Map<String, dynamic>
        ? p['owner_details'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final ownerStoreName =
        (owner['store_name'] ?? owner['name'] ?? _storeName())
            .toString()
            .trim();
    final storeVerified = owner['kyc'] == true ||
        owner['is_verified'] == true ||
        _isVerifiedStore();
    final storePro = owner['is_pro'] == true;

    return GestureDetector(
      onTap: () => _navigateToCheckout(p),
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge.
            Stack(
              children: [
                Container(
                  height: 168,
                  width: 168,
                  decoration: BoxDecoration(
                    color: _slate50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: _slate400),
                        )
                      : const Icon(Icons.image_outlined, color: _slate400),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-$discountPct%',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Rating stars + count (real data — unrated shows outlines).
            Row(
              children: [
                ...List.generate(5, (i) {
                  final filled = i < rating.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: _amber,
                  );
                }),
                if (reviews > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($reviews)',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _slate500),
                  ),
                ],
              ],
            ),
            if (ownerStoreName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      ownerStoreName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _slate500,
                      ),
                    ),
                  ),
                  if (storeVerified) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.verified,
                        size: 12, color: Color(0xFF2563EB)),
                  ],
                  if (storePro) ...[
                    const SizedBox(width: 3),
                    const AdsyProBadge(),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 2),
            Text(
              p['name']?.toString() ?? 'Product',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: _dark,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                if (hasDiscount) ...[
                  Text(
                    '৳${regular.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: _slate400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  '৳${(hasDiscount ? sale : regular).toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _greenDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Store banner (promo card) ────────────────────────────────────────────

  Widget _buildStoreBannerCard() {
    final banner = _storeBanner();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Container(
        height: 132,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: banner != null
            ? CachedNetworkImage(
                imageUrl: banner,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _promoFallback(),
              )
            : _promoFallback(),
      ),
    );
  }

  /// Placeholder shown until the vendor uploads a banner from settings:
  /// plain gray surface with a dashed border and a short store motivation
  /// line in the middle.
  Widget _promoFallback() {
    return CustomPaint(
      // Foreground: the child's gray fill would otherwise paint over the
      // dashed border.
      foregroundPainter: const _DashedBorderPainter(
        color: Color(0xFFCBD5E1), // slate-300 — visible on the gray fill
        radius: 18,
      ),
      child: Container(
        color: _slate50,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_rounded, color: _slate400, size: 22),
            const SizedBox(height: 6),
            Text(
              '${_storeName()} এ আপনাকে স্বাগতম',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'সেরা মানের পণ্য, বিশ্বস্ত সেবা — নিশ্চিন্তে কেনাকাটা করুন',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Categories grid (image cards) ────────────────────────────────────────

  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No categories yet',
              style: GoogleFonts.inter(fontSize: 13, color: _slate500),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final c = _categories[i];
            final img = c['image']?.toString() ?? '';
            final selected = _selectedCategoryId == c['id']?.toString();
            return GestureDetector(
              onTap: () => _onCategorySelected(c['id']?.toString()),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: _slate50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? _greenDark : _slate100,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: img.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: img,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.category_outlined,
                                      color: _slate400),
                                )
                              : const Icon(Icons.category_outlined,
                                  color: _slate400),
                        ),
                        if (selected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: _greenDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 13, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? _greenDark : _dark,
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _categories.length,
        ),
      ),
    );
  }

  // ── About tab ────────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreBannerCard(),
          const SizedBox(height: 16),
          Text(
            'About ${_storeName()}',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _storeDescription(),
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.6,
              color: _slate500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _slate100),
            ),
            child: Row(
              children: [
                _aboutStat('$_activeCount', 'Products'),
                Container(width: 1, height: 30, color: _slate200),
                _aboutStat('${_categories.length}', 'Categories'),
                Container(width: 1, height: 30, color: _slate200),
                _aboutStat('@${widget.storeUsername}', 'Store ID'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Reviews ──
          Text(
            _reviewsTotal > 0 ? 'Reviews ($_reviewsTotal)' : 'Reviews',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 10),
          if (_reviewsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AdsyLoadingIndicator(color: _green)),
            )
          else if (_storeReviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No reviews yet — be the first to review a product!',
                style:
                    GoogleFonts.inter(fontSize: 12.5, color: _slate500),
              ),
            )
          else
            ..._storeReviews.map((r) => _buildReviewCard(r as StoreReview)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(StoreReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: _slate100,
                backgroundImage: (r.reviewerImage ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(r.reviewerImage!)
                    : null,
                child: (r.reviewerImage ?? '').isEmpty
                    ? Text(
                        r.reviewerName.isNotEmpty
                            ? r.reviewerName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _slate500),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _dark),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < r.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: _amber,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          r.formattedDate,
                          style: GoogleFonts.inter(
                              fontSize: 10.5, color: _slate400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (r.isVerifiedPurchase)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Verified',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _greenDark),
                  ),
                ),
            ],
          ),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: GoogleFonts.inter(
                  fontSize: 12.5, height: 1.5, color: _slate500),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            r.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _slate400),
          ),
        ],
      ),
    );
  }

  Widget _aboutStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: _slate500),
          ),
        ],
      ),
    );
  }

  // ── Products grid (existing ProductCard for the buy flow) ────────────────

  Widget _buildProductsGrid(List<Map<String, dynamic>> items) {
    if (_error != null && items.isEmpty) {
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

    if (items.isEmpty && !_isLoadingProducts) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          const crossAxisCount = 2;
          const crossAxisSpacing = 10.0;
          const mainAxisSpacing = 10.0;

          return SliverGrid(
            gridDelegate: ProductCardLayout.buildGridDelegate(
              availableWidth: constraints.crossAxisExtent,
              screenWidth: screenWidth,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              textScale: MediaQuery.textScalerOf(context).scale(1.0),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(
                product: items[index],
                isLoading: false,
                onBuyNow: () => _navigateToCheckout(items[index]),
              ),
              childCount: items.length,
            ),
          );
        },
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
                  color: _green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: _greenDark),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _dark,
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
                  backgroundColor: _greenDark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
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

/// Pins the vendor top bar (back + search + shop) while the page scrolls.
class _StickyTopBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _StickyTopBarDelegate({required this.height, required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyTopBarDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

/// Dashed rounded-rect border for the banner placeholder.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double strokeWidth = 1.4;
  static const double dashLength = 6;
  static const double gapLength = 5;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
