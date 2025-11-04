import 'package:flutter/material.dart';
import 'dart:async';
import '../services/eshop_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../widgets/mobile_banner.dart';
import '../widgets/hot_deals_section.dart';
import '../widgets/product_card.dart';
import '../widgets/mobile_sticky_nav.dart';
import '../widgets/product_skeleton_loader.dart';
import '../models/cart_item.dart';

class EshopScreen extends StatefulWidget {
  const EshopScreen({super.key});

  @override
  State<EshopScreen> createState() => _EshopScreenState();
}

class _EshopScreenState extends State<EshopScreen> with TickerProviderStateMixin {
  final TranslationService _translationService = TranslationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSearchActive = false;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  bool _showSuggestions = false;
  bool _showCategoryFilter = false;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _searchSuggestions = [];
  List<String> _trendingSearches = ['Electronics', 'Fashion', 'Home & Garden', 'Sports'];
  List<Map<String, dynamic>> _allCategories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _hasHandledNavigationArgs = false;
  
  String? _eshopLogoUrl;
  String _lastSearchQuery = '';
  int _currentPage = 1;
  Timer? _debounceTimer;
  Timer? _saveSearchTimer;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadInitialData();
    _loadSearchHistory();
    _loadEshopLogo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle category filter from navigation arguments only once
    if (!_hasHandledNavigationArgs) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['categoryId'] != null) {
        final categoryId = args['categoryId'].toString();
        setState(() {
          _selectedCategoryId = categoryId;
          _selectedCategoryName = null; // Will be set when categories load
          _hasHandledNavigationArgs = true;
        });
        // Find category name after categories are loaded
        _findCategoryName(categoryId);
      } else {
        _hasHandledNavigationArgs = true;
      }
    }
  }

  Future<void> _findCategoryName(String categoryId) async {
    // Wait for categories to load if not loaded yet
    int attempts = 0;
    while (_allCategories.isEmpty && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    if (_allCategories.isNotEmpty) {
      final category = _allCategories.firstWhere(
        (cat) => cat['id'].toString() == categoryId,
        orElse: () => {},
      );
      if (mounted && category.isNotEmpty) {
        setState(() {
          _selectedCategoryName = category['name']?.toString();
        });
      }
    }
  }

  Future<void> _loadEshopLogo() async {
    try {
      print('EshopScreen: Loading dynamic eShop logo...');
      final logoUrl = await EshopService.getEshopLogo();
      print('EshopScreen: Received logo URL: $logoUrl');
      if (mounted) {
        setState(() {
          _eshopLogoUrl = logoUrl;
        });
        print('EshopScreen: Logo URL set in state: $_eshopLogoUrl');
      }
    } catch (e) {
      print('EshopScreen: Error loading eshop logo: $e');
    }
  }

  void _navigateToCheckout(Map<String, dynamic> product) {
    try {
      print('🛒 Starting checkout navigation for product: ${product['id']}');

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
        regularPrice: _parseDouble(product['regular_price'] ?? product['price'] ?? 0),
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

      print('✅ Product created successfully: ${cartProduct.name}');

      // Create cart item with quantity 1
      final cartItem = CartItem(
        product: cartProduct,
        quantity: 1,
      );

      print('✅ Cart item created successfully');

      // Navigate to checkout
      Navigator.pushNamed(
        context,
        '/checkout',
        arguments: {
          'cartItems': [cartItem],
        },
      );

      print('✅ Navigation to checkout completed');
    } catch (e, stackTrace) {
      print('❌ Error in checkout navigation: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Product data: $product');

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
          .where((img) => img is Map<String, dynamic>)
          .map((img) => ProductImage.fromJson(img as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error parsing image details: $e');
      return null;
    }
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMoreResults || _isSearchActive) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Load more when 200 pixels from bottom
    if (currentScroll >= maxScroll - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      print('EshopScreen: Loading search history...');
      final history = await EshopService.getSearchHistory();
      print('EshopScreen: Received ${history.length} search history items: $history');
      
      if (mounted) {
        setState(() {
          _recentSearches = history;
          // For testing: If no history from backend, add some mock data
          if (_recentSearches.isEmpty) {
            print('EshopScreen: No search history from backend, using empty list');
          }
        });
        print('EshopScreen: Updated state with ${_recentSearches.length} recent searches');
      }
    } catch (e) {
      print('EshopScreen: Error loading search history: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _saveSearchTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await EshopService.fetchProductCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
      
      // Load initial products to display (reduced from 20 to 12 for faster load)
      final products = await EshopService.fetchEshopProducts(
        page: 1, 
        pageSize: 12,
        categoryId: _selectedCategoryId,
      );
      
      setState(() {
        _products = products;
        _isLoading = false;
        _hasMoreResults = products.length == 12;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreResults) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      final products = await EshopService.fetchEshopProducts(page: nextPage, pageSize: 12);
      
      setState(() {
        _products.addAll(products);
        _currentPage = nextPage;
        _hasMoreResults = products.length == 12;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      print('Error loading more products: $e');
    }
  }

  void _activateSearch() async {
    print('EshopScreen: Activating search. Recent searches count: ${_recentSearches.length}');
    setState(() {
      _isSearchActive = true;
      _isSearching = true;
    });
    _searchAnimationController.forward();
    
    // Load products to display
    try {
      List<Map<String, dynamic>> productsToShow;
      
      if (_recentSearches.isNotEmpty) {
        // If there's recent search history, load products based on most recent search
        final recentKeyword = _recentSearches.first;
        print('EshopScreen: Loading products based on recent search: "$recentKeyword"');
        productsToShow = await EshopService.searchProducts(recentKeyword);
        print('EshopScreen: Search returned ${productsToShow.length} products');
      } else {
        // No search history, load random products
        print('EshopScreen: No search history, loading random products');
        productsToShow = await EshopService.fetchEshopProducts(page: 1, pageSize: 10);
        print('EshopScreen: Fetch returned ${productsToShow.length} products');
      }
      
      if (mounted) {
        final finalProducts = productsToShow.take(10).toList();
        print('EshopScreen: Setting ${finalProducts.length} products to display');
        setState(() {
          _searchResults = finalProducts;
          _isSearching = false;
        });
        print('EshopScreen: State updated. _searchResults.length = ${_searchResults.length}');
      }
    } catch (e, stackTrace) {
      print('EshopScreen: Error loading products: $e');
      print('EshopScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isSearching = false;
          // Try to load any available products as fallback
          _searchResults = _products.take(10).toList();
        });
        print('EshopScreen: Fallback - using ${_searchResults.length} products from main list');
      }
    }
    
    // Focus on search input after animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _deactivateSearch() {
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
      _searchResults.clear();
    });
    _searchAnimationController.reverse();
    FocusScope.of(context).unfocus();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timers
    _debounceTimer?.cancel();
    _saveSearchTimer?.cancel();
    
    // Update suggestions immediately for better UX
    if (query.trim().isNotEmpty) {
      _updateSearchSuggestions(query);
    } else {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }
    
    // Debounce search by 800ms - wait for user to finish typing
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (query.trim().isNotEmpty && query.trim().length >= 3) {
        _performSearch(query);
      }
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
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });
    
    try {
      final results = await EshopService.searchProducts(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasMoreResults = results.length >= 20;
          _lastSearchQuery = query;
        });
        
        // Save search keyword after 15 seconds of viewing results
        // This ensures user actually looked at results and found them useful
        // Only save if query is meaningful (3+ characters) and has results
        _saveSearchTimer?.cancel();
        if (results.isNotEmpty && query.trim().length >= 3) {
          _saveSearchTimer = Timer(const Duration(seconds: 15), () {
            // Only save if user is still on the same search and not already in recent searches
            if (_lastSearchQuery == query && mounted && !_recentSearches.contains(query.trim())) {
              _saveSearchKeyword(query);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _saveSearchKeyword(String query) async {
    try {
      print('Saving search keyword: "$query"');
      await EshopService.saveSearchHistory(query);
      
      // Reload search history to show the new keyword
      await _loadSearchHistory();
      
      // Show subtle feedback that keyword was saved
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark_added, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('"$query" saved to recent searches'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      
      print('Search keyword saved and history reloaded. Recent searches: $_recentSearches');
    } catch (e) {
      print('Error saving search keyword: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade400, Colors.orange.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Custom Header with gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade400, Colors.orange.shade500],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: _buildHeader(),
                  ),
                  
                  // Content with rounded top
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: _isSearchActive 
                            ? _buildSearchOverlay()
                            : _buildMainContent(),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Mobile Sticky Navigation at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MobileStickyNav(
                  currentRoute: 'eShop',
                  scrollController: _scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          
          // Title or Search Field
          Expanded(
            child: _isSearchActive
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && value.trim().length >= 3) {
                        _debounceTimer?.cancel();
                        _performSearch(value);
                      }
                    },
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                : GestureDetector(
                    onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
                    child: _eshopLogoUrl != null && _eshopLogoUrl!.isNotEmpty
                        ? Image.network(
                            _eshopLogoUrl!,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Text(
                              'eShop',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'eShop',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
          ),
          
          // Search Icon
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _searchResults.clear();
                  _searchSuggestions.clear();
                  _showSuggestions = false;
                  _isSearching = false;
                }
              });
            },
            tooltip: _isSearchActive ? 'Close Search' : 'Search',
          ),
          
          // Filter Icon
          if (!_isSearchActive)
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              icon: Icon(
                _selectedCategoryId != null ? Icons.filter_alt : Icons.filter_list_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Filter by Category',
              itemBuilder: (context) {
                return [
                  // All Categories option
                  PopupMenuItem<String>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.apps_rounded,
                          size: 18,
                          color: _selectedCategoryId == null 
                              ? Colors.pink.shade400 
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'All Products',
                          style: TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        if (_selectedCategoryId == null)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.pink.shade400,
                          ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Category options
                  ..._allCategories.map((category) {
                    final categoryId = category['id'].toString();
                    final categoryName = category['name']?.toString() ?? 'Unknown';
                    final isSelected = _selectedCategoryId == categoryId;
                    
                    return PopupMenuItem<String>(
                      value: categoryId,
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 18,
                            color: isSelected 
                                ? Colors.pink.shade400 
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.pink.shade400,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ];
              },
              onSelected: (value) {
                if (value == null) {
                  setState(() {
                    _selectedCategoryId = null;
                    _selectedCategoryName = null;
                  });
                } else {
                  final category = _allCategories.firstWhere(
                    (cat) => cat['id'].toString() == value,
                    orElse: () => {},
                  );
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedCategoryName = category['name']?.toString();
                  });
                }
                _loadInitialData();
              },
            ),
        ],
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _isSearching 
                        ? 'Searching...'
                        : '${_searchResults.length} results for "${_searchController.text}"',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Search Content
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                    ),
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

  Widget _buildSearchDefault() {
    print('EshopScreen: Building search default. Recent searches: ${_recentSearches.length}, Display products: ${_searchResults.length}, isSearching: $_isSearching');
    
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      );
    }
    
    // Single scrollable view with searches and products together
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.take(5).map((search) {
                return InkWell(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          search,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
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
            Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Suggested Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: _searchResults[index],
                  isLoading: false,
                  onBuyNow: () => _navigateToCheckout(_searchResults[index]),
                );
              },
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Start typing to search products',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
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
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords or check spelling',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // 1. Dynamic eShop Banner - 4px padding
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: MobileBannerWidget(
              autoplayInterval: 5000,
              autoplayEnabled: true,
              endpoint: '/eshop-banner/',
            ),
          ),
          
          // 2. Hot Deals Section - compact spacing
          const HotDealsSection(),
          const SizedBox(height: 12),
          
          // 3. Product Cards Section
          _buildProductsGrid(),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No products available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // All Products Title
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.inventory_2_rounded, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                _selectedCategoryName ?? 'All Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final availableWidth = constraints.maxWidth;
              final idealWidth = (availableWidth - spacing) / 2;
              final displayProducts = _products;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.57,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
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
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You\'ve reached the end',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
 r       
        // Bottom spacing to prevent overflow
        const SizedBox(height: 80),
      ],
    );
  }

}