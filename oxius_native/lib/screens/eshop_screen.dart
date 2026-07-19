import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/eshop_service.dart';
import '../utils/image_utils.dart';
import '../utils/network_error_handler.dart';
import '../widgets/mobile_banner.dart';
import '../widgets/hot_deals_section.dart';
import '../widgets/product_card.dart';
import '../widgets/mobile_sticky_nav.dart';
import '../widgets/product_skeleton_loader.dart';
import '../models/cart_item.dart';
import 'vendor_store_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

// Clean marketplace palette — matches the vendor store page.
const _green = Color(0xFF22C55E);
const _greenDark = Color(0xFF16A34A);
const _dark = Color(0xFF111827);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);

class EshopScreen extends StatefulWidget {
  const EshopScreen({super.key});

  @override
  State<EshopScreen> createState() => _EshopScreenState();
}

class _EshopScreenState extends State<EshopScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  bool _isSearchActive = false;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  bool _showBackToTop = false;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _searchSuggestions = [];
  final List<String> _trendingSearches = [
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports'
  ];
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _bestSelling = [];
  List<Map<String, dynamic>> _topStores = [];
  // Top stores: content-sized cards in an auto-sliding horizontal list —
  // the next store always peeks right beside the current one.
  final ScrollController _storesScrollController = ScrollController();
  Timer? _storesAutoTimer;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategorySlug;

  int _currentPage = 1;
  Timer? _debounceTimer;
  Timer? _saveSearchTimer;
  final Completer<void> _categoriesCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && !_isSearchActive) _activateSearch();
    });
    _loadCategories();
    _loadInitialData();
    _loadSearchHistory();
    _loadShowcaseSections();
  }

  /// Best-selling rail + top-stores slider (independent of the main list).
  Future<void> _loadShowcaseSections() async {
    final results = await Future.wait([
      EshopService.fetchBestSellingProducts(limit: 8),
      EshopService.fetchTopStores(limit: 10),
    ]);
    if (!mounted) return;
    setState(() {
      _bestSelling = results[0];
      _topStores = results[1];
    });
    _startStoresAutoSlide();
  }

  void _startStoresAutoSlide() {
    _storesAutoTimer?.cancel();
    if (_topStores.length <= 1) return;
    _storesAutoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_storesScrollController.hasClients) return;
      final pos = _storesScrollController.position;
      if (pos.maxScrollExtent <= 0) return;
      final step = pos.viewportDimension * 0.6;
      double target;
      if (pos.pixels >= pos.maxScrollExtent - 8) {
        target = 0; // loop back to the first store
      } else {
        target = (pos.pixels + step).clamp(0.0, pos.maxScrollExtent);
      }
      _storesScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle category filter from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['categoryId'] != null) {
      final categoryId = args['categoryId'].toString();
      // Always update if category changed, regardless of previous handling
      if (_selectedCategoryId != categoryId) {
        setState(() {
          _selectedCategoryId = categoryId;
          _selectedCategoryName = null; // Will be set when categories load
          _selectedCategorySlug = null; // Will be set when categories load
        });
        // Await category details (slug) BEFORE loading products so the API
        // call includes the correct category_slug param on the first try.
        _findCategoryDetails(categoryId).then((_) {
          if (mounted) _loadInitialData();
        });
      }
    }
  }

  bool _categoryIdMatches(dynamic left, dynamic right) {
    return left?.toString() == right?.toString();
  }

  Future<void> _findCategoryDetails(String categoryId) async {
    if (_allCategories.isEmpty) {
      // Wait for _loadCategories() to complete instead of busy-wait polling
      await _categoriesCompleter.future;
    }
    _applyCategoryFromLoaded(categoryId);
  }

  /// Looks up name+slug from already-loaded _allCategories and updates state.
  void _applyCategoryFromLoaded(String categoryId) {
    final category = _allCategories.firstWhere(
      (cat) => _categoryIdMatches(cat['id'], categoryId),
      orElse: () => {},
    );
    if (mounted && category.isNotEmpty) {
      setState(() {
        _selectedCategoryName = category['name']?.toString();
        _selectedCategorySlug = category['slug']?.toString();
      });
      debugPrint(
          '🏷️ Category resolved: $_selectedCategoryName (slug: $_selectedCategorySlug)');
    } else {
      debugPrint('⚠️ Category $categoryId not found in loaded category list');
    }
  }

  /// Apply a category filter to the existing screen without pushing a new
  /// route. Used by in-page category sources (HotDealsSection, dropdown).
  void _applyCategoryFilterInPlace(String categoryId) {
    final category = _allCategories.firstWhere(
      (cat) => _categoryIdMatches(cat['id'], categoryId),
      orElse: () => {},
    );
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = category['name']?.toString();
      _selectedCategorySlug = category['slug']?.toString();
    });
    // Scroll to top so the filtered list is visible immediately.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _loadInitialData();
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedCategorySlug = null;
    });
    _loadInitialData();
  }

  void _navigateToCheckout(Map<String, dynamic> product) {
    try {
      debugPrint('🛒 Starting checkout navigation for product: ${product['id']}');

      // Validate required fields
      if (product['id'] == null) {
        throw Exception('Product ID is required');
      }
      if (product['name'] == null && product['title'] == null) {
        throw Exception('Product name/title is required');
      }

      // Convert product map to Product object with safe parsing
      final cartProduct = Product(
        id: product['id'],
        name: product['name'] ?? product['title'] ?? 'Product',
        description: product['description'] ?? '',
        regularPrice:
            _parseDouble(product['regular_price'] ?? product['price'] ?? 0),
        salePrice: product['sale_price'] != null
            ? _parseDouble(product['sale_price'])
            : null,
        quantity: _parseInt(product['quantity'] ?? 999),
        isFreeDelivery: product['is_free_delivery'] as bool? ?? false,
        deliveryFeeInsideDhaka: product['delivery_fee_inside_dhaka'] != null
            ? _parseDouble(product['delivery_fee_inside_dhaka'])
            : null,
        deliveryFeeOutsideDhaka: product['delivery_fee_outside_dhaka'] != null
            ? _parseDouble(product['delivery_fee_outside_dhaka'])
            : null,
        imageDetails: _parseImageDetails(product['image_details']),
      );

      debugPrint('✅ Product created successfully: ${cartProduct.name}');

      // Create cart item with quantity 1
      final cartItem = CartItem(
        product: cartProduct,
        quantity: 1,
      );

      debugPrint('✅ Cart item created successfully');

      // Navigate to checkout
      Navigator.pushNamed(
        context,
        '/checkout',
        arguments: {
          'cartItems': [cartItem],
        },
      );

      debugPrint('✅ Navigation to checkout completed');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in checkout navigation: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Product data: $product');

      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to proceed to checkout. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _navigateToCheckout(product),
            ),
          ),
        );
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<ProductImage>? _parseImageDetails(dynamic imageDetails) {
    try {
      if (imageDetails == null) return null;
      if (imageDetails is! List) return null;

      return imageDetails
          .whereType<Map<String, dynamic>>()
          .map((img) => ProductImage.fromJson(img))
          .toList();
    } catch (e) {
      debugPrint('Error parsing image details: $e');
      return null;
    }
  }

  void _onScroll() {
    final showTop = _scrollController.hasClients &&
        _scrollController.position.pixels > 600;
    if (showTop != _showBackToTop) {
      setState(() => _showBackToTop = showTop);
    }

    if (_isLoadingMore || !_hasMoreResults || _isSearchActive) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Load more when 200 pixels from bottom
    if (currentScroll >= maxScroll - 200) {
      _loadMoreProducts();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  String _normalizeSearchQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _sameSearchQuery(String a, String b) {
    return _normalizeSearchQuery(a).toLowerCase() ==
        _normalizeSearchQuery(b).toLowerCase();
  }

  List<String> _dedupeRecentSearches(Iterable<String> searches) {
    final seen = <String>{};
    final deduped = <String>[];

    for (final raw in searches) {
      final query = _normalizeSearchQuery(raw);
      if (query.length < 3) continue;

      final key = query.toLowerCase();
      if (seen.add(key)) {
        deduped.add(query);
      }

      if (deduped.length >= 10) break;
    }

    return deduped;
  }

  Future<void> _loadSearchHistory() async {
    try {
      debugPrint('EshopScreen: Loading search history...');
      final history = await EshopService.getSearchHistory();
      debugPrint(
          'EshopScreen: Received ${history.length} search history items: $history');

      if (mounted) {
        setState(() {
          _recentSearches = _dedupeRecentSearches(history);
        });
        debugPrint(
            'EshopScreen: Updated state with ${_recentSearches.length} recent searches');
      }
    } catch (e) {
      debugPrint('EshopScreen: Error loading search history: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _saveSearchTimer?.cancel();
    _storesAutoTimer?.cancel();
    _storesScrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await EshopService.fetchProductCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
        if (_selectedCategoryId != null) {
          _applyCategoryFromLoaded(_selectedCategoryId!);
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      // Unblock any waiter (e.g. _findCategoryDetails) regardless of success/failure
      if (!_categoriesCompleter.isCompleted) _categoriesCompleter.complete();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });

      // Derive slug from already-loaded categories when state hasn't been set yet
      // (e.g. when called before _findCategoryDetails completes).
      String? resolvedSlug = _selectedCategorySlug;
      if (resolvedSlug == null &&
          _selectedCategoryId != null &&
          _allCategories.isNotEmpty) {
        final cat = _allCategories.firstWhere(
          (c) => _categoryIdMatches(c['id'], _selectedCategoryId),
          orElse: () => {},
        );
        resolvedSlug = cat['slug']?.toString();
      }

      debugPrint(
          '🔄 Loading products for category: $_selectedCategoryId (${_selectedCategoryName ?? "All"}, slug: $resolvedSlug)');
      final products = await EshopService.fetchEshopProducts(
        page: 1,
        pageSize: 12,
        categoryId: _selectedCategoryId,
        categorySlug: resolvedSlug,
      );

      debugPrint('✅ Loaded ${products.length} products');
      setState(() {
        _products = products;
        _isLoading = false;
        _hasMoreResults = products.length == 12;
      });
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        NetworkErrorHandler.showErrorSnackbar(context, e);
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreResults) return;

    debugPrint(
        '📄 Loading more products - Page: ${_currentPage + 1}, Category: $_selectedCategoryId (slug: $_selectedCategorySlug)');
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final products = await EshopService.fetchEshopProducts(
        page: nextPage,
        pageSize: 12,
        categoryId: _selectedCategoryId,
        categorySlug: _selectedCategorySlug, // Pass category slug for filtering
      );

      debugPrint('✅ Loaded ${products.length} more products');
      setState(() {
        _products.addAll(products);
        _currentPage = nextPage;
        _hasMoreResults = products.length == 12;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      debugPrint('❌ Error loading more products: $e');
    }
  }

  void _activateSearch() async {
    debugPrint(
        'EshopScreen: Activating search. Recent searches count: ${_recentSearches.length}');
    setState(() {
      _isSearchActive = true;
      _isSearching = true;
    });

    // Load products to display
    try {
      List<Map<String, dynamic>> productsToShow;

      if (_recentSearches.isNotEmpty) {
        // If there's recent search history, load products based on most recent search
        final recentKeyword = _recentSearches.first;
        debugPrint(
            'EshopScreen: Loading products based on recent search: "$recentKeyword"');
        productsToShow = await EshopService.searchProducts(recentKeyword);
        debugPrint('EshopScreen: Search returned ${productsToShow.length} products');
      } else {
        // No search history, load random products
        debugPrint('EshopScreen: No search history, loading random products');
        productsToShow =
            await EshopService.fetchEshopProducts(page: 1, pageSize: 10);
        debugPrint('EshopScreen: Fetch returned ${productsToShow.length} products');
      }

      if (mounted) {
        final finalProducts = productsToShow.take(10).toList();
        debugPrint(
            'EshopScreen: Setting ${finalProducts.length} products to display');
        setState(() {
          _searchResults = finalProducts;
          _isSearching = false;
        });
        debugPrint(
            'EshopScreen: State updated. _searchResults.length = ${_searchResults.length}');
      }
    } catch (e, stackTrace) {
      debugPrint('EshopScreen: Error loading products: $e');
      debugPrint('EshopScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isSearching = false;
          // Try to load any available products as fallback
          _searchResults = _products.take(10).toList();
        });
        debugPrint(
            'EshopScreen: Fallback - using ${_searchResults.length} products from main list');
      }
    }
  }

  void _deactivateSearch() {
    _searchFocus.unfocus();
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
      _searchResults.clear();
      _searchSuggestions.clear();
      _isSearching = false;
    });
  }


  void _onSearchChanged(String query) {
    // Cancel previous timers
    _debounceTimer?.cancel();
    _saveSearchTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchSuggestions.clear();
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    if (query.trim().length < 3) {
      // Query too short to search — clear stale results from a longer previous query
      // so the user doesn't see irrelevant results while still typing.
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _searchSuggestions.clear();
      });
      return;
    }

    // 3+ chars: show suggestions immediately and debounce the API call
    _updateSearchSuggestions(query);

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _performSearch(query);
    });
  }

  void _updateSearchSuggestions(String query) {
    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();

    // Add matching recent searches
    for (var search in _recentSearches) {
      if (search.toLowerCase().contains(lowerQuery) && suggestions.length < 5) {
        suggestions.add(search);
      }
    }

    // Add matching trending searches
    for (var trend in _trendingSearches) {
      if (trend.toLowerCase().contains(lowerQuery) &&
          !suggestions.contains(trend) &&
          suggestions.length < 5) {
        suggestions.add(trend);
      }
    }

    setState(() {
      _searchSuggestions = suggestions;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await EshopService.searchProducts(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasMoreResults = results.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        AdsyToast.error(context, 'সার্চে সমস্যা হয়েছে');
      }
    }
  }

  /// Persist a user-intent search and keep the latest unique query at the top.
  Future<void> _commitSearchToHistory(String rawQuery) async {
    final query = _normalizeSearchQuery(rawQuery);
    if (query.length < 3) return;
    try {
      final saved = await EshopService.saveSearchHistory(query);
      if (!mounted) return;
      if (!saved) return;
      setState(() {
        _recentSearches = _dedupeRecentSearches([query, ..._recentSearches]);
      });
    } catch (e) {
      debugPrint('EshopScreen: Failed to commit search history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedCategoryId == null && !_isSearchActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // First back press closes search / clears the category filter;
        // a subsequent press pops the screen.
        if (_isSearchActive) {
          _deactivateSearch();
        } else if (_selectedCategoryId != null) {
          _clearCategoryFilter();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        endDrawer: _buildCategoryDrawer(),
        floatingActionButton: _showBackToTop && !_isSearchActive
            ? Padding(
                padding: const EdgeInsets.only(bottom: 64),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: FloatingActionButton(
                    onPressed: _scrollToTop,
                    backgroundColor: _dark,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isSearchActive
                        ? _buildSearchOverlay()
                        : _buildMainContent(),
                  ),
                ],
              ),

              // Mobile Sticky Navigation at bottom — SafeArea handles iOS
              // home indicator and Android gesture / 3-button nav bar insets.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: MobileStickyNav(
                    currentRoute: 'eShop',
                    scrollController: _scrollController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: back + search pill + category filter (vendor-page style) ─────

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
            icon: const Icon(Icons.arrow_back_rounded, color: _dark, size: 22),
            tooltip: 'Back',
            onPressed: () {
              if (_isSearchActive) {
                _deactivateSearch();
              } else if (_selectedCategoryId != null) {
                _clearCategoryFilter();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
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
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.length >= 3) {
                    _debounceTimer?.cancel();
                    _performSearch(trimmed);
                    _commitSearchToHistory(trimmed);
                  }
                },
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search on eShop',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: _slate400,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  suffixIcon: _isSearchActive
                      ? IconButton(
                          onPressed: _deactivateSearch,
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
          // Category filter — opens the categories drawer.
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(
                    color:
                        _selectedCategoryId != null ? _greenDark : _slate200),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                _selectedCategoryId != null
                    ? Icons.filter_alt_rounded
                    : Icons.filter_list_rounded,
                color: _selectedCategoryId != null ? _greenDark : _dark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Categories drawer (informative, extensible) ──────────────────────────

  Widget _buildCategoryDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      width: 296,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_allCategories.length}টি ক্যাটাগরি থেকে বেছে নিন',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: _slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: _slate500, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(color: _slate100, height: 16),

            // All Products
            _drawerTile(
              selected: _selectedCategoryId == null,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grid_view_rounded,
                    size: 18, color: _greenDark),
              ),
              title: 'All Products',
              subtitle: 'সব পণ্য একসাথে দেখুন',
              onTap: () {
                Navigator.pop(context);
                if (_selectedCategoryId != null) _clearCategoryFilter();
              },
            ),

            // Category list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _allCategories.length,
                itemBuilder: (context, i) {
                  final c = _allCategories[i];
                  final id = c['id'].toString();
                  final img = c['image']?.toString() ?? '';
                  final selected = _selectedCategoryId == id;
                  return _drawerTile(
                    selected: selected,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _slate100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: img.isNotEmpty
                          ? AppImage.network(
                              img,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                  color: _slate400),
                            )
                          : const Icon(Icons.category_outlined,
                              size: 18, color: _slate400),
                    ),
                    title: c['name']?.toString() ?? '',
                    onTap: () {
                      Navigator.pop(context);
                      if (selected) {
                        _clearCategoryFilter();
                      } else {
                        _applyCategoryFilterInPlace(id);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required bool selected,
    required Widget leading,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _green.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: _green) : null,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? _greenDark : _dark,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _slate500,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: _greenDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search Results Header
          if (_searchController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
              alignment: Alignment.centerLeft,
              child: Text(
                _isSearching
                    ? 'Searching...'
                    : '${_searchResults.length} results for "${_searchController.text}"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _slate500,
                ),
              ),
            ),
          ],

          // Search Content
          Expanded(
            child: _isSearching
                ? const Center(
                    child: AdsyLoadingIndicator(color: _green),
                  )
                : _searchController.text.isEmpty
                    ? _buildSearchDefault() // Show recent searches and trending when search box is empty
                    : _searchResults.isEmpty
                        ? _buildNoResults() // Show no results when search returned nothing
                        : _buildSearchResults(), // Show search results
          ),
        ],
      ),
    );
  }

  /// Delete a single search term from history (optimistic: removes locally first).
  Future<void> _deleteSearchItem(String query) async {
    final previousSearches = List<String>.from(_recentSearches);
    setState(() {
      _recentSearches =
          _recentSearches.where((s) => !_sameSearchQuery(s, query)).toList();
    });
    try {
      final deleted = await EshopService.deleteSearchHistoryItem(query);
      if (!deleted && mounted) {
        setState(() {
          _recentSearches = previousSearches;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentSearches = previousSearches;
        });
      }
      debugPrint('EshopScreen: Failed to delete search item: $e');
    }
  }

  /// Clear all search history.
  Future<void> _clearAllSearchHistory() async {
    final previousSearches = List<String>.from(_recentSearches);
    setState(() {
      _recentSearches = [];
    });
    try {
      final cleared = await EshopService.clearSearchHistory();
      if (!cleared && mounted) {
        setState(() {
          _recentSearches = previousSearches;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentSearches = previousSearches;
        });
      }
      debugPrint('EshopScreen: Failed to clear search history: $e');
    }
  }

  Widget _buildSearchDefault() {
    debugPrint(
        'EshopScreen: Building search default. Recent searches: ${_recentSearches.length}, Display products: ${_searchResults.length}, isSearching: $_isSearching');

    if (_isSearching) {
      return const Center(
        child: AdsyLoadingIndicator(color: _green),
      );
    }

    // Single scrollable view with searches and products together
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear search history'),
                        content: const Text('Remove all recent searches?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _clearAllSearchHistory();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.take(10).map((search) {
                return InkWell(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 12, top: 6, bottom: 6, right: 6),
                    decoration: BoxDecoration(
                      color: _slate100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 14, color: _slate400),
                        const SizedBox(width: 4),
                        Text(
                          search,
                          style: GoogleFonts.inter(
                            color: _dark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _deleteSearchItem(search),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: _slate200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 11,
                              color: _slate500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 8),

          // Products section (if available)
          if (_searchResults.isNotEmpty) ...[
            Text(
              'Suggested Products',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _dark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: ProductCardLayout.buildGridDelegate(
                  availableWidth: constraints.maxWidth,
                  screenWidth: MediaQuery.of(context).size.width,
                  textScale: MediaQuery.textScalerOf(context).scale(1.0),
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: _searchResults[index],
                    isLoading: false,
                    onBuyNow: () =>
                        _navigateToCheckout(_searchResults[index]),
                  );
                },
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Start typing to search products',
                  style: GoogleFonts.inter(
                    color: _slate500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: _slate200,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords or check spelling',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _slate500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
        gridDelegate: ProductCardLayout.buildGridDelegate(
          availableWidth: constraints.maxWidth,
          screenWidth: MediaQuery.of(context).size.width,
          textScale: MediaQuery.textScalerOf(context).scale(1.0),
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return ProductCard(
            product: _searchResults[index],
            isLoading: false,
            onBuyNow: () => _navigateToCheckout(_searchResults[index]),
            // onTap removed to use default navigation from ProductCard
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const ProductSkeletonLoader(itemCount: 6),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    final browsing = _selectedCategoryId == null;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (browsing) ...[
            // 1. Dynamic eShop Banner
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: MobileBannerWidget(
                autoplayInterval: 5000,
                autoplayEnabled: true,
                endpoint: '/eshop-banner/',
              ),
            ),

            // 2. Special offers (category quick filters)
            // Pass in-place filter callback so tapping a deal updates the
            // existing screen instead of pushing a new route on top.
            HotDealsSection(onCategorySelected: _applyCategoryFilterInPlace),

            // 3. Best selling products rail
            if (_bestSelling.isNotEmpty) ...[
              _sectionHeader('Best Selling'),
              _buildBestSellingRail(),
            ],
          ],

          // 4. Categories rail — stays visible while filtered so the user
          // can switch or clear without leaving the page.
          if (_allCategories.isNotEmpty) ...[
            _sectionHeader('Categories'),
            _buildCategoryRail(),
          ],

          if (browsing && _topStores.isNotEmpty) ...[
            // 5. Top stores slider
            _sectionHeader('Top Stores'),
            _buildTopStoresRail(),
          ],

          // 6. Product Cards Section
          _buildProductsGrid(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: _dark,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ── Best selling rail ────────────────────────────────────────────────────

  Widget _buildBestSellingRail() {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cardWidth = ProductCardLayout.horizontalCardWidth(screenWidth);
    return SizedBox(
      height: ProductCardLayout.horizontalCardHeight(
        screenWidth,
        cardWidth: cardWidth,
        textScale: textScale,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _bestSelling.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: cardWidth,
          child: ProductCard(
            product: _bestSelling[i],
            isLoading: false,
            onBuyNow: () => _navigateToCheckout(_bestSelling[i]),
          ),
        ),
      ),
    );
  }

  // ── Categories rail (image cards, vendor-page style) ─────────────────────

  Widget _buildCategoryRail() {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = _allCategories[i];
          final id = c['id'].toString();
          final img = c['image']?.toString() ?? '';
          final selected = _selectedCategoryId == id;
          return GestureDetector(
            onTap: () {
              if (selected) {
                _clearCategoryFilter();
              } else {
                _applyCategoryFilterInPlace(id);
              }
            },
            child: SizedBox(
              width: 82,
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: _slate100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? _greenDark : _slate200,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: img.isNotEmpty
                        ? AppImage.network(
                            img,
                            fit: BoxFit.cover,
                            errorWidget: const Center(
                              child: Icon(Icons.category_outlined,
                                  color: _slate400),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.category_outlined,
                                color: _slate400),
                          ),
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

  // ── Top stores slider ────────────────────────────────────────────────────

  Widget _buildTopStoresRail() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        controller: _storesScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _topStores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = _topStores[i];
          final logo = (s['image'] ?? s['store_logo'] ?? '').toString();
          final name = (s['store_name'] ?? '').toString();
          final products = int.tryParse('${s['product_count'] ?? ''}') ?? 0;
          return GestureDetector(
            onTap: () {
              final username = s['store_username']?.toString() ?? '';
              if (username.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorStoreScreen(
                    storeUsername: username,
                    storeName: name,
                    storeImage: logo.isNotEmpty ? logo : null,
                  ),
                ),
              );
            },
            // Card hugs its content (border grows with the name); a max
            // width keeps very long names on a 2-line clamp.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 264),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _slate200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Store profile image (BN profile photo / settings
                      // upload).
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _slate100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: logo.isNotEmpty
                            ? AppImage.network(
                                logo,
                                fit: BoxFit.cover,
                                errorWidget: const Center(
                                  child: Icon(Icons.storefront_rounded,
                                      size: 20, color: _slate400),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.storefront_rounded,
                                    size: 20, color: _slate400),
                              ),
                      ),
                      const SizedBox(width: 10),
                      // Name + products on the right; Flexible so the border
                      // wraps content but long names still clamp.
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: name,
                                children: [
                                  if (s['kyc'] == true)
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 3),
                                        child: Icon(Icons.verified,
                                            size: 13,
                                            color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: _dark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$products Products',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: _slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No products available',
            style: GoogleFonts.inter(fontSize: 14, color: _slate500),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Section header (vendor-page style): title + Clear when filtered.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedCategoryName ?? 'All Products',
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
              if (_selectedCategoryId != null)
                GestureDetector(
                  onTap: _clearCategoryFilter,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final displayProducts = _products;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: ProductCardLayout.buildGridDelegate(
                  availableWidth: constraints.maxWidth,
                  screenWidth: MediaQuery.of(context).size.width,
          textScale: MediaQuery.textScalerOf(context).scale(1.0),
        ),
                itemCount: displayProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: displayProducts[index],
                    isLoading: false,
                    onBuyNow: () => _navigateToCheckout(displayProducts[index]),
                    // onTap removed to use default navigation from ProductCard
                  );
                },
              );
            },
          ),
        ),

        // Skeleton loader for pagination
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ProductSkeletonLoader(itemCount: 4),
          ),

        // End of results indicator
        if (!_hasMoreResults && _products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _greenDark,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'You\'ve reached the end',
                  style: GoogleFonts.inter(
                    color: _slate500,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Bottom spacing to prevent overflow
        const SizedBox(height: 80),
      ],
    );
  }
}
