import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/eshop_manager_service.dart';
import '../../models/eshop_manager_models.dart';
import '../../services/translation_service.dart';
import '../../widgets/ios_web_redirect_screen.dart';
import 'widgets/store_details_card.dart';
import 'widgets/my_orders_tab.dart';
import 'widgets/my_products_tab.dart';
import 'widgets/add_product_tab.dart';
import 'create_store_screen.dart';

class EshopManagerScreen extends StatefulWidget {
  const EshopManagerScreen({super.key});

  @override
  State<EshopManagerScreen> createState() => _EshopManagerScreenState();
}

class _EshopManagerScreenState extends State<EshopManagerScreen> with SingleTickerProviderStateMixin {
  final TranslationService _translationService = TranslationService();
  String t(String key, {String? fallback}) => _translationService.translate(key, fallback: fallback);

  late TabController _tabController;
  bool _isLoading = true;
  bool _isPro = false;
  bool _hasStore = false;
  
  StoreDetails? _storeDetails;
  List<ShopProduct> _products = [];
  List<ShopOrder> _orders = [];
  int _productLimit = 10;
  int _currentPage = 1;
  bool _hasMoreProducts = false;
  int _totalProducts = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _checkUserStatus();
  }
  
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      print('📦 Tab changed to index: ${_tabController.index}');
      // Refresh data when switching to Orders or Products tab
      if (_tabController.index == 0) {
        print('📦 Refreshing orders on tab switch');
        _loadOrders();
      } else if (_tabController.index == 1) {
        print('📦 Refreshing products on tab switch');
        _loadProducts();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);
    
    final user = AuthService.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    print('🏪 User isPro: ${user.isPro}');
    print('🏪 User storeUsername: ${user.storeUsername}');
    print('🏪 User storeName: ${user.storeName}');
    print('🏪 User productLimit: ${user.productLimit}');

    _isPro = user.isPro;
    _hasStore = user.storeUsername != null && user.storeUsername!.isNotEmpty;
    _productLimit = user.productLimit ?? 10;

    print('🏪 Computed _isPro: $_isPro');
    print('🏪 Computed _hasStore: $_hasStore');

    if (_isPro && _hasStore) {
      await _loadData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    if (user?.storeUsername == null) return;

    // Load data with error handling for each future
    await Future.wait([
      _loadStoreDetails().catchError((e) {
        print('❌ Error loading store details: $e');
      }),
      _loadProducts().catchError((e) {
        print('❌ Error loading products: $e');
      }),
      _loadOrders().catchError((e) {
        print('❌ Error loading orders: $e');
      }),
    ]);
  }

  Future<void> _loadStoreDetails() async {
    try {
      final user = AuthService.currentUser;
      if (user?.storeUsername == null) return;

      final store = await EshopManagerService.getStoreDetails(user!.storeUsername!);
      if (mounted) {
        setState(() => _storeDetails = store);
      }
    } catch (e) {
      print('❌ Error loading store details: $e');
      // Don't rethrow - let other loads continue
    }
  }

  Future<void> _loadProducts({bool loadMore = false}) async {
    try {
      final page = loadMore ? _currentPage + 1 : 1;
      print('📦 Loading products - page: $page, loadMore: $loadMore');
      
      final result = await EshopManagerService.getMyProducts(page: page);
      
      print('📦 Products loaded: ${(result['products'] as List).length}, total: ${result['total']}, hasMore: ${result['hasMore']}');
      
      if (mounted) {
        setState(() {
          if (loadMore) {
            _products.addAll(result['products'] as List<ShopProduct>);
            _currentPage = page;
          } else {
            _products = result['products'] as List<ShopProduct>;
            _currentPage = 1;
          }
          _hasMoreProducts = result['hasMore'] as bool;
          _totalProducts = result['total'] as int;
        });
        print('📦 State updated - _products.length: ${_products.length}, _totalProducts: $_totalProducts');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
      // Don't rethrow - let other loads continue
    }
  }

  Future<void> _loadOrders() async {
    try {
      print('📦 Loading seller orders...');
      print('📦 Current user: ${AuthService.currentUser?.email}');
      final orders = await EshopManagerService.getSellerOrders();
      print('📦 Orders loaded: ${orders.length}');
      
      if (orders.isEmpty) {
        print('⚠️ No orders returned from API');
      } else {
        print('📦 First order: ID=${orders.first.id}, Status=${orders.first.orderStatus}, Total=${orders.first.total}');
      }
      
      if (mounted) {
        setState(() => _orders = orders);
        print('📦 State updated - _orders.length: ${_orders.length}');
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      // Don't rethrow - let other loads continue
    }
  }

  Future<void> _refreshData() async {
    print('🔄 Pull to refresh triggered');
    try {
      await _loadData();
      print('✅ Refresh completed successfully');
    } catch (e) {
      print('❌ Refresh error: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleStoreUpdated() async {
    // Refresh user data to get updated product limit
    await AuthService.refreshUserData();
    
    final user = AuthService.currentUser;
    if (mounted && user != null) {
      setState(() {
        _productLimit = user.productLimit ?? 10;
      });
    }
    
    // Also refresh store details
    await _loadStoreDetails();
  }

  void _handleProductAdded() {
    print('📦 Product added - refreshing products list');
    _loadProducts();
    _tabController.animateTo(1); // Switch to Products tab
  }

  void _handleProductUpdated() {
    print('📦 Product updated - refreshing products list');
    _loadProducts();
  }

  void _handleProductDeleted() {
    print('📦 Product deleted - refreshing products list');
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFF374151),
        ),
        title: Text(
          t('eshop_manager', fallback: 'Shop Manager'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : !_isPro
              ? _buildUpgradePrompt()
              : !_hasStore
                  ? _buildCreateStorePrompt()
                  : _buildManagerContent(isMobile),
    );
  }

  Widget _buildUpgradePrompt() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF8FAFC),
                Colors.grey.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isDesktop
              ? Row(
                  children: [
                    // Left premium badge section
                    Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.purple.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PREMIUM ACCESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade100,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Right content section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Premium Access Required',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isIOSPlatform
                                  ? 'Pro membership is required to access the Shop Manager. Visit our website for more details.'
                                  : 'Upgrade to Pro to access the Shop Manager and start selling your products.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!isIOSPlatform)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/upgrade-to-pro');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Upgrade to Pro',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top premium badge section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.purple.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PREMIUM ACCESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade100,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Bottom content section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      const Text(
                        'Premium Access Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isIOSPlatform
                            ? 'Pro membership is required to access the Shop Manager. Visit our website for more details.'
                            : 'Upgrade to Pro to access the Shop Manager and start selling your products.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isIOSPlatform)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/upgrade-to-pro');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Upgrade to Pro',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
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
  }

  Widget _buildCreateStorePrompt() {
    // If user already has products, they likely have a store - bypass to manager
    if (_products.isNotEmpty || _orders.isNotEmpty) {
      return _buildManagerContent(MediaQuery.of(context).size.width < 768);
    }

    return CreateStoreScreen(
      onStoreCreated: () async {
        // Refresh user status after store creation
        await _checkUserStatus();
      },
    );
  }

  Widget _buildManagerContent(bool isMobile) {
    final currentProductCount = _totalProducts > 0 ? _totalProducts : _products.length;
    final remainingSlots = (_productLimit - currentProductCount).clamp(0, _productLimit);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF10B981),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Details Card
              if (_storeDetails != null)
                StoreDetailsCard(
                  storeDetails: _storeDetails!,
                  products: _products,
                  orders: _orders,
                  productLimit: _productLimit,
                  totalProducts: _totalProducts,
                  onStoreUpdated: _handleStoreUpdated,
                ),
              
              const SizedBox(height: 12),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF10B981),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF10B981),
                      unselectedLabelColor: const Color(0xFF6B7280),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                          text: 'Orders (${_orders.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.inventory_2_rounded, size: 20),
                          text: 'Products (${_totalProducts > 0 ? _totalProducts : _products.length})',
                        ),
                        Tab(
                          icon: Icon(
                            remainingSlots > 0
                                ? Icons.add_circle_rounded
                                : Icons.lock_rounded,
                            size: 20,
                          ),
                          text: 'Add Product',
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          MyOrdersTab(
                            orders: _orders,
                            onRefresh: _loadOrders,
                          ),
                          MyProductsTab(
                            products: _products,
                            productLimit: _productLimit,
                            totalProducts: currentProductCount,
                            onRefresh: _loadProducts,
                            onProductUpdated: _handleProductUpdated,
                            onProductDeleted: _handleProductDeleted,
                            hasMore: _hasMoreProducts,
                            onLoadMore: () => _loadProducts(loadMore: true),
                          ),
                          AddProductTab(
                            products: _products,
                            productLimit: _productLimit,
                            totalProducts: currentProductCount,
                            onProductAdded: _handleProductAdded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
