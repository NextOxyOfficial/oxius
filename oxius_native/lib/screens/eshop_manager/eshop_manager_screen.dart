import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/eshop_manager_service.dart';
import '../../models/eshop_manager_models.dart';
import '../../services/translation_service.dart';
import '../../widgets/ios_web_redirect_screen.dart';
import 'widgets/store_details_card.dart';
import 'widgets/my_orders_tab.dart';
import 'widgets/my_products_tab.dart';
import 'widgets/add_product_tab.dart';
import 'widgets/store_reviews_tab.dart';
import '../../services/review_service.dart';
import 'create_store_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class EshopManagerScreen extends StatefulWidget {
  const EshopManagerScreen({super.key});

  @override
  State<EshopManagerScreen> createState() => _EshopManagerScreenState();
}

class _EshopManagerScreenState extends State<EshopManagerScreen> {
  final TranslationService _translationService = TranslationService();
  String t(String key, {String? fallback}) =>
      _translationService.translate(key, fallback: fallback);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Drawer-driven sections: 0 = Dashboard, 1 = Products, 2 = Orders, 3 = Add.
  int _section = 0;
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
  int _reviewCount = 0;

  int get _currentProductCount =>
      _totalProducts > 0 ? _totalProducts : _products.length;
  int get _remainingSlots =>
      (_productLimit - _currentProductCount).clamp(0, _productLimit);

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  // Switch the visible section from the drawer, then refresh its data.
  void _selectSection(int index) {
    setState(() => _section = index);
    if (index == 1) {
      _loadProducts();
    } else if (index == 2) {
      _loadOrders();
    }
  }

  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);

    if (AuthService.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Pull the LATEST Pro/store status from the server first. Without this, a
    // seller who just became Pro (or bought a store) kept seeing the "Upgrade
    // to Pro" prompt because the cached user still said is_pro=false.
    try {
      await AuthService.refreshUserData();
    } catch (_) {
      // Network hiccup — fall back to the cached user below.
    }
    if (!mounted) return;

    final user = AuthService.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    debugPrint('🏪 User isPro: ${user.isPro}');
    debugPrint('🏪 User storeUsername: ${user.storeUsername}');
    debugPrint('🏪 User storeName: ${user.storeName}');
    debugPrint('🏪 User productLimit: ${user.productLimit}');

    _isPro = user.isPro;
    _hasStore = user.storeUsername != null && user.storeUsername!.isNotEmpty;
    _productLimit = user.productLimit ?? 10;

    debugPrint('🏪 Computed _isPro: $_isPro');
    debugPrint('🏪 Computed _hasStore: $_hasStore');

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
        debugPrint('❌ Error loading store details: $e');
      }),
      _loadProducts().catchError((e) {
        debugPrint('❌ Error loading products: $e');
      }),
      _loadOrders().catchError((e) {
        debugPrint('❌ Error loading orders: $e');
      }),
      _loadReviewCount().catchError((e) {
        debugPrint('❌ Error loading review count: $e');
      }),
    ]);
  }

  Future<void> _loadReviewCount() async {
    final count = await ReviewService.getStoreReviewsCount();
    if (mounted) setState(() => _reviewCount = count);
  }

  Future<void> _loadStoreDetails() async {
    try {
      final user = AuthService.currentUser;
      if (user?.storeUsername == null) return;

      final store =
          await EshopManagerService.getStoreDetails(user!.storeUsername!);
      if (mounted) {
        setState(() => _storeDetails = store);
      }
    } catch (e) {
      debugPrint('❌ Error loading store details: $e');
      // Don't rethrow - let other loads continue
    }
  }

  Future<void> _loadProducts({bool loadMore = false}) async {
    try {
      final page = loadMore ? _currentPage + 1 : 1;
      debugPrint('📦 Loading products - page: $page, loadMore: $loadMore');

      final result = await EshopManagerService.getMyProducts(page: page);

      debugPrint(
          '📦 Products loaded: ${(result['products'] as List).length}, total: ${result['total']}, hasMore: ${result['hasMore']}');

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
        debugPrint(
            '📦 State updated - _products.length: ${_products.length}, _totalProducts: $_totalProducts');
      }
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      // Don't rethrow - let other loads continue
    }
  }

  Future<void> _loadOrders() async {
    try {
      debugPrint('📦 Loading seller orders...');
      debugPrint('📦 Current user: ${AuthService.currentUser?.email}');
      final orders = await EshopManagerService.getSellerOrders();
      debugPrint('📦 Orders loaded: ${orders.length}');

      if (orders.isEmpty) {
        debugPrint('⚠️ No orders returned from API');
      } else {
        debugPrint(
            '📦 First order: ID=${orders.first.id}, Status=${orders.first.orderStatus}, Total=${orders.first.total}');
      }

      if (mounted) {
        setState(() => _orders = orders);
        debugPrint('📦 State updated - _orders.length: ${_orders.length}');
      }
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      // Don't rethrow - let other loads continue
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Pull to refresh triggered');
    try {
      await _loadData();
      debugPrint('✅ Refresh completed successfully');
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
      // Show error message to user
      if (mounted) {
        AdsyToast.error(
            context, t('eshop_refresh_failed', fallback: 'রিফ্রেশ করা যায়নি'));
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
    debugPrint('📦 Product added - refreshing products list');
    _loadProducts();
    setState(() => _section = 1); // Show the Products section
  }

  void _handleProductUpdated() {
    debugPrint('📦 Product updated - refreshing products list');
    _loadProducts();
  }

  void _handleProductDeleted() {
    debugPrint('📦 Product deleted - refreshing products list');
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final inManager = !_isLoading && _isPro && _hasStore;

    // Back returns to the Dashboard from any sub-section first, and only exits
    // the screen when already on the Dashboard — so moving between menus no
    // longer drops the user out of the manager entirely.
    return PopScope(
      canPop: !inManager || _section == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) setState(() => _section = 0);
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      endDrawer: inManager ? _buildEshopDrawer() : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () {
            if (inManager && _section != 0) {
              setState(() => _section = 0);
            } else {
              Navigator.pop(context);
            }
          },
          color: const Color(0xFF374151),
        ),
        title: Text(
          inManager
              ? _sectionTitle()
              : t('eshop_manager', fallback: 'Shop Manager'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (inManager)
            IconButton(
              icon: const Icon(Icons.menu_rounded,
                  size: 24, color: Color(0xFF374151)),
              tooltip: t('eshop_menu', fallback: 'মেনু'),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          const SizedBox(width: 4),
        ],
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
              child: AdsyLoadingIndicator(
                color: Color(0xFF10B981),
              ),
            )
          : !_isPro
              ? _buildUpgradePrompt()
              : !_hasStore
                  ? _buildCreateStorePrompt()
                  : _buildManagerContent(isMobile),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    final benefits = <(IconData, String, String)>[
      (
        Icons.storefront_rounded,
        t('eshop_benefit_store', fallback: 'নিজের অনলাইন স্টোর'),
        t('eshop_benefit_store_sub', fallback: 'নিজের নামে সাজানো স্টোর পেজ')
      ),
      (
        Icons.inventory_2_rounded,
        t('eshop_benefit_products', fallback: 'প্রোডাক্ট লিস্টিং'),
        t('eshop_benefit_products_sub',
            fallback: 'ছবি, দাম, স্টক সহ প্রোডাক্ট যোগ করুন')
      ),
      (
        Icons.shopping_bag_rounded,
        t('eshop_benefit_orders', fallback: 'অর্ডার ম্যানেজমেন্ট'),
        t('eshop_benefit_orders_sub',
            fallback: 'অর্ডার গ্রহণ, স্ট্যাটাস আপডেট আর এডিট')
      ),
      (
        Icons.reviews_rounded,
        t('eshop_benefit_reviews', fallback: 'রিভিউ ও রিপ্লাই'),
        t('eshop_benefit_reviews_sub',
            fallback: 'কাস্টমার রিভিউতে উত্তর দিন')
      ),
      (
        Icons.insights_rounded,
        t('eshop_benefit_dashboard', fallback: 'সেলস ড্যাশবোর্ড'),
        t('eshop_benefit_dashboard_sub',
            fallback: 'বিক্রি আর ইনকামের হিসাব একনজরে')
      ),
      (
        Icons.verified_rounded,
        t('eshop_benefit_badge', fallback: 'ভেরিফায়েড প্রো ব্যাজ'),
        t('eshop_benefit_badge_sub', fallback: 'স্টোরে বিশ্বস্ততার ছাপ')
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEEF3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isIOSPlatform
                            ? t('eshop_unavailable_badge',
                                fallback: 'UNAVAILABLE')
                            : t('eshop_premium_access_badge',
                                fallback: 'প্রিমিয়াম অ্যাক্সেস'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIOSPlatform
                          ? t('eshop_manager_unavailable_title',
                              fallback: 'Shop Manager Unavailable')
                          : t('eshop_premium_hero_title',
                              fallback: 'প্রো সেলার হয়ে বিক্রি শুরু করুন'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIOSPlatform
                          ? t('eshop_manager_unavailable_desc',
                              fallback:
                                  'The Shop Manager is not available in this version of the app.')
                          : t('eshop_premium_hero_sub',
                              fallback:
                                  'শপ ম্যানেজার আনলক করে নিজের প্রোডাক্ট বিক্রি করুন'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isIOSPlatform) ...[
                      Text(
                        t('eshop_premium_whats_included',
                            fallback: 'প্রো-তে যা যা পাবেন'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...benefits.map((b) => _benefitRow(b.$1, b.$2, b.$3)),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/upgrade-to-pro'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t('eshop_upgrade_to_pro',
                                    fallback: 'প্রো-তে আপগ্রেড করুন'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 17),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(
                              t('eshop_premium_trust',
                                  fallback:
                                      'সিকিউর পেমেন্ট • যেকোনো সময় রিনিউ'),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFF059669)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.35)),
              ],
            ),
          ),
        ],
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

  // Each section now gets the FULL body height — no cramped fixed-height tab
  // view. Navigation moved to the drawer, freeing the whole screen for content.
  Widget _buildManagerContent(bool isMobile) {
    switch (_section) {
      case 1:
        return MyProductsTab(
          products: _products,
          productLimit: _productLimit,
          totalProducts: _currentProductCount,
          onRefresh: _loadProducts,
          onProductUpdated: _handleProductUpdated,
          onProductDeleted: _handleProductDeleted,
          hasMore: _hasMoreProducts,
          onLoadMore: () => _loadProducts(loadMore: true),
        );
      case 2:
        return MyOrdersTab(
          orders: _orders,
          products: _products,
          onRefresh: _loadOrders,
        );
      case 3:
        return AddProductTab(
          products: _products,
          productLimit: _productLimit,
          totalProducts: _currentProductCount,
          onProductAdded: _handleProductAdded,
        );
      case 5:
        return StoreReviewsTab(
          onCountChanged: (c) {
            if (mounted && c != _reviewCount) {
              setState(() => _reviewCount = c);
            }
          },
        );
      case 0:
      default:
        return _buildDashboard();
    }
  }

  String _sectionTitle() {
    switch (_section) {
      case 1:
        return t('eshop_my_products', fallback: 'আমার প্রোডাক্ট');
      case 2:
        return t('eshop_my_orders', fallback: 'আমার অর্ডার');
      case 3:
        return t('eshop_new_product', fallback: 'নতুন প্রোডাক্ট');
      case 5:
        return t('eshop_reviews', fallback: 'রিভিউ');
      default:
        return t('eshop_dashboard', fallback: 'ড্যাশবোর্ড');
    }
  }

  // Store editing now opens FROM the dashboard as a bottom sheet — the full
  // editable card (logo/banner/name/description/address) is reused as-is.
  void _openStoreEditor() {
    if (_storeDetails == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 40),
                  child: StoreDetailsCard(
                    storeDetails: _storeDetails!,
                    products: _products,
                    orders: _orders,
                    productLimit: _productLimit,
                    totalProducts: _totalProducts,
                    onStoreUpdated: _handleStoreUpdated,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Professional seller dashboard ──
  Widget _buildDashboard() {
    final totalProducts = _currentProductCount;
    final outOfStock = _products
        .where((p) => p.status == 'out-of-stock' || p.stock <= 0)
        .length;
    final inactive = _products
        .where((p) => p.status == 'inactive' && p.stock > 0)
        .length;
    final activeProducts =
        (totalProducts - outOfStock - inactive).clamp(0, totalProducts);
    final totalOrders = _orders.length;
    final pendingOrders =
        _orders.where((o) => o.orderStatus == 'pending').length;
    final revenue = _orders
        .where((o) => o.orderStatus == 'delivered')
        .fold<double>(0, (s, o) => s + o.total);

    return AdsyRefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF10B981),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dashQuickActions(),
            const SizedBox(height: 16),
            _dashStoreHeader(),
            const SizedBox(height: 18),
            _dashLabel(t('eshop_overview', fallback: 'ওভারভিউ')),
            // 2×2 stats in one quiet card with hairline dividers.
            Container(
              decoration: _dashCardDeco(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCard(
                              t('eshop_total_products',
                                  fallback: 'টোটাল প্রোডাক্ট'),
                              '$totalProducts',
                              const Color(0xFF6366F1),
                              onTap: () => _selectSection(1)),
                        ),
                        Container(width: 1, color: const Color(0xFFF1F5F9)),
                        Expanded(
                          child: _statCard(
                              t('eshop_total_orders', fallback: 'টোটাল অর্ডার'),
                              '$totalOrders',
                              const Color(0xFF10B981),
                              onTap: () => _selectSection(2)),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCard(
                              t('eshop_pending_orders',
                                  fallback: 'পেন্ডিং অর্ডার'),
                              '$pendingOrders',
                              const Color(0xFFD97706),
                              onTap: () => _selectSection(2)),
                        ),
                        Container(width: 1, color: const Color(0xFFF1F5F9)),
                        Expanded(
                          child: _statCard(
                              t('eshop_total_income', fallback: 'টোটাল ইনকাম'),
                              '৳${revenue.toStringAsFixed(0)}',
                              const Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _dashLabel(
                t('eshop_product_status', fallback: 'প্রোডাক্ট স্ট্যাটাস')),
            _dashProductStatus(activeProducts, outOfStock, totalProducts),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _dashLabel(
                        t('eshop_recent_orders', fallback: 'রিসেন্ট অর্ডার'))),
                if (_orders.isNotEmpty)
                  GestureDetector(
                    onTap: () => _selectSection(2),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 8),
                      child: Text(t('eshop_view_all', fallback: 'সব দেখুন'),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669))),
                    ),
                  ),
              ],
            ),
            _dashRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _dashLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.1)),
    );
  }

  Widget _dashStoreHeader() {
    final store = _storeDetails;
    final name = store?.storeName ??
        (AuthService.currentUser?.storeName ??
            t('eshop_my_store', fallback: 'আমার স্টোর'));
    final uname = store?.storeUsername ??
        (AuthService.currentUser?.storeUsername ?? '');
    final active = store?.isActive ?? true;
    const green = Color(0xFF059669);
    const dark = Color(0xFF0F172A);
    const slate = Color(0xFF64748B);
    final desc = (store?.storeDescription ?? '').trim();
    final address = (store?.storeAddress ?? '').trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openStoreEditor,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: _dashCardDeco(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
              children: [
                // Store avatar — the REAL uploaded logo when there is one,
                // else the shop icon.
                Builder(builder: (_) {
                  final logo =
                      AppConfig.getAbsoluteUrl(store?.storeLogo ?? '');
                  if (logo.isEmpty) {
                    return Image.asset(
                      'assets/images/icons/shop.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          size: 44,
                          color: green),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      logo,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/icons/shop.png',
                        width: 54,
                        height: 54,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_rounded,
                            size: 44,
                            color: green),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + verified
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: dark,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3)),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              color: green, size: 16),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                          uname.isNotEmpty
                              ? '@$uname'
                              : t('eshop_pro_seller', fallback: 'প্রো সেলার'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: slate,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 9),
                      // Inline status · pro seller
                      Row(
                        children: [
                          Icon(
                            active
                                ? Icons.check_circle_rounded
                                : Icons.do_not_disturb_on_rounded,
                            size: 14,
                            color: active ? green : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                              active
                                  ? t('eshop_active', fallback: 'অ্যাক্টিভ')
                                  : t('eshop_inactive',
                                      fallback: 'ইনঅ্যাক্টিভ'),
                              style: TextStyle(
                                  color: active ? green : slate,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // PRO badge to the left of the "pro seller" label.
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('PRO',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3)),
                          ),
                          const SizedBox(width: 5),
                          Text(
                              t('eshop_pro_seller', fallback: 'প্রো সেলার'),
                              style: const TextStyle(
                                  color: slate,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Edit affordance — opens the full store editor sheet.
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: slate, size: 15),
                ),
              ],
                ),
                // Store details inline on the dashboard (the old "স্টোর"
                // section): description, address, public URL and key dates —
                // informative at a glance, editable via the pencil.
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                if (desc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF475569),
                          height: 1.45),
                    ),
                  ),
                if (address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13.5, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Public store link + one-tap copy.
                if (uname.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(
                                  text: 'adsyclub.com/eshop/',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B))),
                              TextSpan(
                                  text: uname,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: green)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: 'https://adsyclub.com/eshop/$uname'));
                            AdsyToast.success(
                                context,
                                t('eshop_link_copied',
                                    fallback: 'স্টোর লিংক কপি হয়েছে'));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.copy_rounded,
                                size: 14, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                // Key facts: joined date · product slots · pro renewal.
                Row(
                  children: [
                    _dashMetaTile(
                        t('eshop_ov_joined_date', fallback: 'জয়েন করেছেন'),
                        _dashDate(store?.createdAt)),
                    _dashMetaTile(
                        t('eshop_ov_product_slots',
                            fallback: 'প্রোডাক্ট স্লট'),
                        '$_currentProductCount / $_productLimit'),
                    _dashMetaTile(
                        t('eshop_ov_renew_date', fallback: 'রিনিউ ডেট'),
                        _dashDate(AuthService.currentUser?.proValidity)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dashDate(DateTime? d) =>
      d == null ? '—' : '${d.day}/${d.month}/${d.year}';

  // One shared card look for every dashboard section — quiet, native-app
  // style (rounded, hairline border, no shadows or gradients).
  BoxDecoration _dashCardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      );

  // Small fact tile for the store-details block (label over value).
  Widget _dashMetaTile(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155))),
        ],
      ),
    );
  }

  // Flat stat cell — sits inside the hairline-divided overview grid.
  Widget _statCard(String label, String value, Color color,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashProductStatus(int active, int outOfStock, int total) {
    final inactive = (total - active - outOfStock).clamp(0, total);
    // Counts only — no progress bar (user request), same card language as
    // the rest of the dashboard.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: _dashCardDeco(),
      child: Row(
        children: [
          _statusPill(t('eshop_active', fallback: 'অ্যাক্টিভ'), active,
              const Color(0xFF10B981)),
          _statusPill(t('eshop_out_of_stock', fallback: 'স্টক আউট'),
              outOfStock, const Color(0xFFDC2626)),
          _statusPill(t('eshop_inactive', fallback: 'ইনঅ্যাক্টিভ'), inactive,
              const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _statusPill(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 16.5, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _dashRecentOrders() {
    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        alignment: Alignment.center,
        decoration: _dashCardDeco(),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 34, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
                t('eshop_no_orders_yet',
                    fallback: 'এখনো কোনো অর্ডার আসেনি'),
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }
    final recent = _orders.take(3).toList();
    return Container(
      decoration: _dashCardDeco(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < recent.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _recentOrderRow(recent[i]),
          ],
        ],
      ),
    );
  }

  Widget _recentOrderRow(ShopOrder o) {
    final (Color c, String label) = _orderStatusStyle(o.orderStatus);
    final ref = o.orderNumber ??
        (o.id.length > 6 ? o.id.substring(0, 6) : o.id);
    return InkWell(
      onTap: () => _selectSection(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: c, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.customerName ?? t('eshop_customer', fallback: 'ক্রেতা'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 2),
                  Text('#$ref',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('৳${o.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669))),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: c)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _orderStatusStyle(String status) {
    switch (status) {
      case 'delivered':
        return (
          const Color(0xFF059669),
          t('eshop_status_delivered', fallback: 'ডেলিভারড')
        );
      case 'processing':
        return (
          const Color(0xFF2563EB),
          t('eshop_status_processing', fallback: 'প্রসেসিং')
        );
      case 'shipped':
        return (
          const Color(0xFF7C3AED),
          t('eshop_status_shipped', fallback: 'শিপড')
        );
      case 'cancelled':
        return (
          const Color(0xFFDC2626),
          t('eshop_status_cancelled', fallback: 'ক্যান্সেল')
        );
      default:
        return (
          const Color(0xFFD97706),
          t('eshop_status_pending', fallback: 'পেন্ডিং')
        );
    }
  }

  // Flat quick-action strip — single bordered band with hairline separators.
  Widget _dashQuickActions() {
    return Container(
      decoration: _dashCardDeco(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _quickAction(
                  Icons.inventory_2_rounded,
                  t('eshop_product', fallback: 'প্রোডাক্ট'),
                  const Color(0xFF6366F1),
                  () => _selectSection(1)),
            ),
            Container(width: 1, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _quickAction(
                  Icons.shopping_bag_rounded,
                  t('eshop_order', fallback: 'অর্ডার'),
                  const Color(0xFF10B981),
                  () => _selectSection(2)),
            ),
            Container(width: 1, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: _quickAction(
                  _remainingSlots > 0
                      ? Icons.add_circle_rounded
                      : Icons.lock_rounded,
                  t('eshop_add_new', fallback: 'নতুন যোগ'),
                  const Color(0xFF2563EB),
                  () => _selectSection(3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 7),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer navigation — professional, organised, gives content full space ──
  Widget _buildEshopDrawer() {
    return Drawer(
      width: 290,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AuthService.currentUser?.storeName ??
                              t('eshop_my_store', fallback: 'আমার স্টোর'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(t('eshop_pro_seller', fallback: 'প্রো সেলার'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(0, Icons.dashboard_rounded,
                t('eshop_dashboard', fallback: 'ড্যাশবোর্ড')),
            _drawerItem(1, Icons.inventory_2_rounded,
                t('eshop_my_products', fallback: 'আমার প্রোডাক্ট'),
                badge: '$_currentProductCount'),
            _drawerItem(2, Icons.shopping_bag_rounded,
                t('eshop_my_orders', fallback: 'আমার অর্ডার'),
                badge: '${_orders.length}'),
            _drawerItem(
                3,
                _remainingSlots > 0
                    ? Icons.add_circle_rounded
                    : Icons.lock_rounded,
                t('eshop_new_product', fallback: 'নতুন প্রোডাক্ট')),
            // NOTE: no separate "স্টোর" item — store details live on the
            // Dashboard now (edit opens from there).
            _drawerItem(5, Icons.reviews_rounded,
                t('eshop_reviews', fallback: 'রিভিউ'),
                badge: _reviewCount > 0 ? '$_reviewCount' : null),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                '$_currentProductCount / $_productLimit ${t('eshop_slots_used', fallback: 'প্রোডাক্ট স্লট ইউজড')}',
                style: const TextStyle(
                    fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String label, {String? badge}) {
    final selected = _section == index;
    const accent = Color(0xFF059669);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? const Color(0xFFECFDF5) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            _scaffoldKey.currentState?.closeEndDrawer();
            if (index != _section) _selectSection(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 22,
                    color: selected ? accent : const Color(0xFF64748B)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? accent : const Color(0xFF374151),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? accent : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
