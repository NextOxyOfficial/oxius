import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../../../services/translation_service.dart';
import '../../product_details_screen.dart';

class MyProductsTab extends StatefulWidget {
  final List<ShopProduct> products;
  final int productLimit;
  final int totalProducts;
  final Future<void> Function() onRefresh;
  final VoidCallback onProductUpdated;
  final VoidCallback onProductDeleted;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;

  const MyProductsTab({
    super.key,
    required this.products,
    required this.productLimit,
    required this.totalProducts,
    required this.onRefresh,
    required this.onProductUpdated,
    required this.onProductDeleted,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  State<MyProductsTab> createState() => _MyProductsTabState();
}

class _MyProductsTabState extends State<MyProductsTab> {
  String _selectedFilter = 'all';
  bool _isProcessing = false;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;

    setState(() => _isLoadingMore = true);
    await widget.onLoadMore!();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  List<ShopProduct> get _filteredProducts {
    if (_selectedFilter == 'all') return widget.products;
    return widget.products.where((p) => p.status == _selectedFilter).toList();
  }

  int get _activeCount =>
      widget.products.where((p) => p.status == 'active').length;
  int get _inactiveCount =>
      widget.products.where((p) => p.status == 'inactive').length;
  int get _outOfStockCount =>
      widget.products.where((p) => p.status == 'out-of-stock').length;

  void _showEditDialog(ShopProduct product) {
    final nameController = TextEditingController(text: product.name);
    final descController =
        TextEditingController(text: product.description ?? '');
    final priceController =
        TextEditingController(text: product.price.toString());
    final stockController =
        TextEditingController(text: product.stock.toString());
    String selectedStatus = product.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('eshop_edit_product', 'প্রোডাক্ট এডিট'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _t('eshop_edit_product_subtitle',
                                  'প্রোডাক্টের ডিটেইলস আর স্ট্যাটাস আপডেট করুন'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Status Toggle
                      Text(
                        _t('eshop_product_status', 'প্রোডাক্ট স্ট্যাটাস'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatusChip(
                            'active',
                            _t('eshop_status_active', 'অ্যাক্টিভ'),
                            Icons.check_circle_rounded,
                            selectedStatus == 'active',
                            () =>
                                setSheetState(() => selectedStatus = 'active'),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            'inactive',
                            _t('eshop_status_inactive', 'ইনঅ্যাক্টিভ'),
                            Icons.cancel_rounded,
                            selectedStatus == 'inactive',
                            () => setSheetState(
                                () => selectedStatus = 'inactive'),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(
                            'out-of-stock',
                            _t('eshop_status_out_of_stock', 'স্টক আউট'),
                            Icons.inventory_2_rounded,
                            selectedStatus == 'out-of-stock',
                            () => setSheetState(
                                () => selectedStatus = 'out-of-stock'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Product Name
                      _buildTextField(
                          _t('eshop_product_name', 'প্রোডাক্টের নাম'),
                          nameController,
                          required: true),
                      const SizedBox(height: 16),

                      // Description
                      _buildTextField(
                          _t('eshop_description', 'ডিসক্রিপশন'), descController,
                          maxLines: 3),
                      const SizedBox(height: 16),

                      // Price & Stock
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _t('eshop_price_taka', 'প্রাইস (৳)'),
                              priceController,
                              keyboardType: TextInputType.number,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              _t('eshop_stock', 'স্টক'),
                              stockController,
                              keyboardType: TextInputType.number,
                              required: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                _t('eshop_cancel', 'ক্যান্সেল'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      if (nameController.text.trim().isEmpty) {
                                        _showSnackBar(
                                            _t('eshop_name_required',
                                                'প্রোডাক্টের নাম দিতে হবে'),
                                            isError: true);
                                        return;
                                      }

                                      setState(() => _isProcessing = true);

                                      debugPrint(
                                          '📝 Updating product: ${product.id}');
                                      debugPrint('📝 New status: $selectedStatus');
                                      debugPrint(
                                          '📝 New name: ${nameController.text.trim()}');
                                      debugPrint(
                                          '📝 New price: ${priceController.text}');
                                      debugPrint(
                                          '📝 New stock: ${stockController.text}');

                                      final result = await EshopManagerService
                                          .updateProduct(
                                        productId: product.id,
                                        name: nameController.text.trim(),
                                        description: descController.text.trim(),
                                        price: double.tryParse(
                                            priceController.text),
                                        stock:
                                            int.tryParse(stockController.text),
                                        status: selectedStatus,
                                      );

                                      debugPrint(
                                          '📝 Update result: ${result['success']}');
                                      debugPrint(
                                          '📝 Update message: ${result['message']}');

                                      setState(() => _isProcessing = false);

                                      if (!mounted || !context.mounted) {
                                        return;
                                      }

                                      if (result['success'] == true) {
                                        Navigator.pop(context);
                                        _showSnackBar(_t(
                                            'eshop_product_updated',
                                            'প্রোডাক্ট আপডেট হয়ে গেছে'));
                                        final updatedStock =
                                            selectedStatus == 'out-of-stock'
                                                ? 0
                                                : int.tryParse(
                                                        stockController.text) ??
                                                    product.stock;
                                        final updatedStatus =
                                            selectedStatus == 'inactive'
                                                ? 'inactive'
                                                : updatedStock <= 0
                                                    ? 'out-of-stock'
                                                    : 'active';
                                        // Update local state immediately
                                        setState(() {
                                          final index = widget.products
                                              .indexWhere(
                                                  (p) => p.id == product.id);
                                          if (index != -1) {
                                            // Update the product in the list
                                            widget.products[index] =
                                                ShopProduct(
                                              id: product.id,
                                              name: nameController.text.trim(),
                                              description:
                                                  descController.text.trim(),
                                              price: double.tryParse(
                                                      priceController.text) ??
                                                  product.price,
                                              stock: updatedStock,
                                              status: updatedStatus,
                                              image: product.image,
                                              imageDetails:
                                                  product.imageDetails,
                                              featuredImage:
                                                  product.featuredImage,
                                              categoryId: product.categoryId,
                                              categoryName:
                                                  product.categoryName,
                                              createdAt: product.createdAt,
                                              updatedAt: DateTime.now(),
                                              sellerId: product.sellerId,
                                              sellerName: product.sellerName,
                                              views: product.views,
                                            );
                                          }
                                        });
                                        // Also refresh from backend
                                        widget.onProductUpdated();
                                      } else {
                                        _showSnackBar(
                                            result['message'] ??
                                                _t('eshop_update_failed',
                                                    'আপডেট করা যায়নি'),
                                            isError: true);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: AdsyLoadingIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.save_rounded,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          _t('eshop_save_changes',
                                              'সেভ করুন'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String value,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (value) {
      case 'active':
        bgColor =
            isSelected ? const Color(0xFF10B981) : const Color(0xFFD1FAE5);
        textColor = isSelected ? Colors.white : const Color(0xFF065F46);
        borderColor = const Color(0xFF10B981);
        break;
      case 'inactive':
        bgColor =
            isSelected ? const Color(0xFFEF4444) : const Color(0xFFFEE2E2);
        textColor = isSelected ? Colors.white : const Color(0xFF991B1B);
        borderColor = const Color(0xFFEF4444);
        break;
      case 'out-of-stock':
        bgColor =
            isSelected ? const Color(0xFFF59E0B) : const Color(0xFFFEF3C7);
        textColor = isSelected ? Colors.white : const Color(0xFF92400E);
        borderColor = const Color(0xFFF59E0B);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        borderColor = Colors.grey.shade400;
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? borderColor : borderColor.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: textColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(ShopProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Text(
              _t('eshop_delete_product', 'প্রোডাক্ট ডিলিট'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          _t('eshop_delete_confirm',
                  'আপনি কি "{name}" ডিলিট করতে চান? এটা আর ফেরত আনা যাবে না।')
              .replaceFirst('{name}', product.name),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('eshop_cancel', 'ক্যান্সেল')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isProcessing = true);

              final success =
                  await EshopManagerService.deleteProduct(product.id);

              setState(() => _isProcessing = false);

              if (success) {
                _showSnackBar(
                    _t('eshop_product_deleted', 'প্রোডাক্ট ডিলিট হয়ে গেছে'));
                widget.onProductDeleted();
              } else {
                _showSnackBar(
                    _t('eshop_delete_failed', 'প্রোডাক্ট ডিলিট করা যায়নি'),
                    isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: Text(_t('eshop_delete', 'ডিলিট')),
          ),
        ],
      ),
    );
  }

  void _openProduct(ShopProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: {
            'id': product.id,
            'name': product.name,
          },
        ),
      ),
    );
  }

  Future<void> _toggleActive(ShopProduct product) async {
    final makeActive = product.status == 'inactive';
    final newStatus = makeActive ? 'active' : 'inactive';

    // Optimistic local update
    final index = widget.products.indexWhere((p) => p.id == product.id);
    if (index == -1) return;
    final displayStatus = makeActive
        ? (product.stock <= 0 ? 'out-of-stock' : 'active')
        : 'inactive';
    setState(() {
      widget.products[index] = ShopProduct(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        stock: product.stock,
        status: displayStatus,
        image: product.image,
        imageDetails: product.imageDetails,
        featuredImage: product.featuredImage,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        views: product.views,
      );
    });

    final result = await EshopManagerService.updateProduct(
      productId: product.id,
      status: newStatus,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      _showSnackBar(makeActive
          ? _t('eshop_product_activated', 'প্রোডাক্ট অ্যাক্টিভ করা হয়েছে')
          : _t('eshop_product_deactivated', 'প্রোডাক্ট ইনঅ্যাক্টিভ করা হয়েছে'));
      widget.onProductUpdated();
    } else {
      // Revert on failure
      setState(() => widget.products[index] = product);
      _showSnackBar(
          result['message'] ?? _t('eshop_update_failed', 'আপডেট করা যায়নি'),
          isError: true);
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      AdsyToast.error(context, message);
    } else {
      AdsyToast.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', _t('eshop_filter_all', 'সব'),
                    widget.products.length),
                const SizedBox(width: 6),
                _buildFilterChip('active',
                    _t('eshop_status_active', 'অ্যাক্টিভ'), _activeCount),
                const SizedBox(width: 6),
                _buildFilterChip('inactive',
                    _t('eshop_status_inactive', 'ইনঅ্যাক্টিভ'), _inactiveCount),
                const SizedBox(width: 6),
                _buildFilterChip('out-of-stock',
                    _t('eshop_status_out_of_stock', 'স্টক আউট'),
                    _outOfStockCount),
              ],
            ),
          ),
        ),

        // Products List
        Expanded(
          child: AdsyRefreshIndicator(
            onRefresh: widget.onRefresh,
            color: const Color(0xFF10B981),
            child: _filteredProducts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: _buildEmptyState(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          return _buildProductListItem(
                              _filteredProducts[index]);
                        },
                      ),
                    ),
                    if (_isLoadingMore)
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: AdsyLoadingIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF10B981)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _t('eshop_loading_more',
                                  'আরও প্রোডাক্ট লোড হচ্ছে...'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? _t('eshop_no_products_yet', 'এখনো কোনো প্রোডাক্ট নেই')
                : _t('eshop_no_products_in_filter',
                        'এই ফিল্টারে কোনো প্রোডাক্ট নেই')
                    .replaceFirst('{filter}', _selectedFilter),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('eshop_add_products_hint',
                'বিক্রি শুরু করতে প্রোডাক্ট অ্যাড করুন'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(ShopProduct product) {
    final imageUrl = product.featuredImage ??
        (product.imageDetails?.isNotEmpty == true
            ? product.imageDetails!.first.image
            : product.image);

    final isActive = product.status != 'inactive';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openProduct(product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: AdsyLoadingIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF10B981)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 28),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_outlined, size: 28),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge & Name & Active toggle
                    Row(
                      children: [
                        _buildStatusBadge(product.status),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openProduct(product),
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Transform.scale(
                            scale: 0.7,
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: isActive,
                              onChanged: (_) => _toggleActive(product),
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF10B981),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price & Stock & Views
                    Row(
                    children: [
                      Text(
                        '৳${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_rounded,
                                size: 10, color: Color(0xFF6B7280)),
                            const SizedBox(width: 3),
                            Text(
                              '${product.stock}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_rounded,
                                size: 10, color: Color(0xFF6B7280)),
                            const SizedBox(width: 3),
                            Text(
                              '${product.views}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Actions
                  Row(
                    children: [
                      _actionButton(
                        icon: Icons.edit_outlined,
                        label: _t('eshop_edit', 'এডিট'),
                        color: const Color(0xFF059669),
                        onTap: () => _showEditDialog(product),
                      ),
                      const SizedBox(width: 4),
                      _actionButton(
                        icon: Icons.delete_outline,
                        label: _t('eshop_delete', 'ডিলিট'),
                        color: const Color(0xFFDC2626),
                        onTap: () => _showDeleteDialog(product),
                      ),
                      const Spacer(),
                      _actionButton(
                        icon: Icons.visibility_outlined,
                        label: _t('eshop_view', 'দেখুন'),
                        color: const Color(0xFF2563EB),
                        onTap: () => _openProduct(product),
                      ),
                    ],
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


  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'inactive':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      case 'out-of-stock':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status == 'out-of-stock'
            ? _t('eshop_status_out_of_stock', 'স্টক আউট')
            : status == 'active'
                ? _t('eshop_status_active', 'অ্যাক্টিভ')
                : status == 'inactive'
                    ? _t('eshop_status_inactive', 'ইনঅ্যাক্টিভ')
                    : status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
          ),
        ),
      ],
    );
  }
}
