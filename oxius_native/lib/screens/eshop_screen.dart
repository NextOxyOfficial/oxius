import 'package:flutter/material.dart';
import '../services/eshop_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../widgets/mobile_banner.dart';
import '../widgets/hot_deals_section.dart';

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
  bool _hasMoreResults = false;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _trendingSearches = ['Electronics', 'Fashion', 'Home & Garden', 'Sports'];
  
  int _currentPage = 1;
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
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load initial products to display
      final products = await EshopService.fetchEshopProducts(page: 1, pageSize: 20);
      
      setState(() {
        _products = products;
        _isLoading = false;
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

  void _activateSearch() {
    setState(() {
      _isSearchActive = true;
    });
    _searchAnimationController.forward();
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final results = await EshopService.searchProducts(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasMoreResults = results.length >= 20;
      });
      
      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: _isSearchActive 
                    ? _buildSearchOverlay()
                    : _buildMainContent(),
              ),
            ],
          ),
          
          // Category Sidebar Overlay - Removed since category filtering is not needed
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // Back/Menu Button
              _isSearchActive
                  ? IconButton(
                      onPressed: _deactivateSearch,
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 24,
                    )
                  : IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 24,
                    ),
              
              const SizedBox(width: 8),
              
              // Logo or Title
              if (!_isSearchActive) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AdsyClub',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'eShop',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Search Button
                IconButton(
                  onPressed: _activateSearch,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ] else
                // Search Input (when active)
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                                icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    ? _buildSearchDefault()
                    : _searchResults.isEmpty
                        ? _buildNoResults()
                        : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchDefault() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
              children: _recentSearches.map((search) {
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
            const SizedBox(height: 24),
          ],
          
          // Trending Searches
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.orange.shade500, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Trending Searches',
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
            children: _trendingSearches.map((trend) {
              return InkWell(
                onTap: () {
                  _searchController.text = trend;
                  _performSearch(trend);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Note: Hot products are now shown in the main content via HotArrivalsSection
          // You can add other search-specific content here if needed
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_searchResults[index]);
      },
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // 1. eShop Banner (using existing MobileBannerWidget)
          const Padding(
            padding: EdgeInsets.all(16),
            child: MobileBannerWidget(
              autoplayInterval: 5000,
              autoplayEnabled: true,
              endpoint: '/eshop-banner/',
            ),
          ),
          
          // 2. Hot Deals Section (existing widget)
          const HotDealsSection(),
          const SizedBox(height: 16),
          
          // 3. Product Cards Section - Show existing product cards
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_products[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return InkWell(
      onTap: () {
        // Navigate to product details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to ${product['name'] ?? 'Product'}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: product['image'] != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          product['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Product Name',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '৳${product['price'] ?? '0'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        if (product['original_price'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '৳${product['original_price']}',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}