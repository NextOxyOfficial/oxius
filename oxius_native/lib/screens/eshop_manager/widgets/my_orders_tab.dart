import 'package:flutter/material.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';
import '../../../services/translation_service.dart';
import 'edit_order_sheet.dart';

class MyOrdersTab extends StatefulWidget {
  final List<ShopOrder> orders;
  final List<ShopProduct> products;
  final Future<void> Function() onRefresh;

  const MyOrdersTab({
    super.key,
    required this.orders,
    this.products = const [],
    required this.onRefresh,
  });

  @override
  State<MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<MyOrdersTab> {
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) => _i18n.translate(key, fallback: fallback);

  String _selectedFilter = 'all';

  List<ShopOrder> get _filteredOrders {
    if (_selectedFilter == 'all') return widget.orders;
    return widget.orders.where((order) => order.orderStatus == _selectedFilter).toList();
  }

  int get _pendingCount => widget.orders.where((o) => o.orderStatus == 'pending').length;
  int get _processingCount => widget.orders.where((o) => o.orderStatus == 'processing').length;
  int get _deliveredCount => widget.orders.where((o) => o.orderStatus == 'delivered').length;

  void _showEditOrder(ShopOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditOrderSheet(
        order: order,
        products: widget.products,
        onSaved: () async => widget.onRefresh(),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    debugPrint('📦 Updating order $orderId to status: $newStatus');

    final result = await EshopManagerService.updateOrderStatus(
      orderId: orderId,
      status: newStatus,
    );

    if (result['success'] == true) {
      // Update local state immediately for instant feedback
      setState(() {
        final index = widget.orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          final order = widget.orders[index];
          widget.orders[index] = ShopOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            orderStatus: newStatus, // Updated status
            total: order.total,
            paymentMethod: order.paymentMethod,
            shippingAddress: order.shippingAddress,
            customerName: order.customerName,
            customerEmail: order.customerEmail,
            customerPhone: order.customerPhone,
            createdAt: order.createdAt,
            updatedAt: DateTime.now(),
            items: order.items,
          );
        }
      });
      
      _showSnackBar('${_t('eshop_order_status_updated_to', 'অর্ডার স্ট্যাটাস আপডেট হয়েছে')} ${_getStatusLabel(newStatus)}');
      // Also refresh from backend to ensure consistency
      widget.onRefresh();
    } else {
      _showSnackBar(_t('eshop_order_status_update_failed', 'অর্ডার স্ট্যাটাস আপডেট করা যায়নি'), isError: true);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return _t('eshop_status_pending', 'পেন্ডিং');
      case 'processing':
        return _t('eshop_status_processing', 'প্রসেসিং');
      case 'delivered':
        return _t('eshop_status_delivered', 'ডেলিভারড');
      case 'cancelled':
        return _t('eshop_status_cancelled', 'ক্যান্সেল');
      default:
        return status;
    }
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
                _buildFilterChip('all', _t('eshop_filter_all', 'সব'), widget.orders.length),
                const SizedBox(width: 6),
                _buildFilterChip('pending', _t('eshop_status_pending', 'পেন্ডিং'), _pendingCount),
                const SizedBox(width: 6),
                _buildFilterChip('processing', _t('eshop_status_processing', 'প্রসেসিং'), _processingCount),
                const SizedBox(width: 6),
                _buildFilterChip('delivered', _t('eshop_status_delivered', 'ডেলিভারড'), _deliveredCount),
              ],
            ),
          ),
        ),

        // Orders List
        Expanded(
          child: AdsyRefreshIndicator(
            onRefresh: widget.onRefresh,
            color: const Color(0xFF10B981),
            child: _filteredOrders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyState(),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
                    itemCount: _filteredOrders.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index]);
                    },
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
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade300,
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
            Icons.shopping_bag_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? _t('eshop_no_orders_yet', 'এখনো কোনো অর্ডার নেই')
                : '${_getStatusLabel(_selectedFilter)} ${_t('eshop_no_orders_of_status', 'অর্ডার নেই')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('eshop_orders_appear_hint', 'কাস্টমার কিনলে অর্ডার এখানে দেখা যাবে'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(ShopOrder order) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: order number + status
              Row(
                children: [
                  Text(
                    '${_t('eshop_order_hash', 'অর্ডার')} #${order.orderNumber ?? order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(order.orderStatus),
                ],
              ),
              const SizedBox(height: 8),

              // Body content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Name and Date in same row
                  Row(
                  children: [
                    if (order.customerName != null) ...[
                      const Icon(Icons.person_rounded, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.customerName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),

                // Items
                if (order.items != null && order.items!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...order.items!.take(2).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${item.productName} (x${item.quantity})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF374151),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (order.items!.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        '+${order.items!.length - 2} ${_t('eshop_more_items', 'আরও')}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
              ),

              const SizedBox(height: 10),

              // Total and action buttons row
              Row(
                children: [
                // Total Amount
                const Icon(Icons.attach_money_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  '৳${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Spacer(),
                // Edit Order Items Button (icon only)
                InkWell(
                  onTap: () => _showEditOrder(order),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        size: 16, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 6),
                // Details Button
                InkWell(
                  onTap: () => _showOrderDetails(order),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _t('eshop_details', 'ডিটেইলস'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Change Status Button (Compact)
                InkWell(
                  onTap: () => _showStatusSelector(order),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _t('eshop_status', 'স্ট্যাটাস'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        icon = Icons.schedule_rounded;
        break;
      case 'processing':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        icon = Icons.autorenew_rounded;
        break;
      case 'delivered':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        icon = Icons.cancel_rounded;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }


  void _showOrderDetails(ShopOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
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
                      Icons.receipt_long_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('eshop_order_details', 'অর্ডার ডিটেইলস'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_t('eshop_order_hash', 'অর্ডার')} #${order.orderNumber ?? order.id.substring(0, 8)}',
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
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Text(
                          '${_t('eshop_status', 'স্ট্যাটাস')}:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(order.orderStatus),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer Information
                    _buildDetailSection(
                      _t('eshop_customer_information', 'কাস্টমার ইনফরমেশন'),
                      Icons.person_rounded,
                      [
                        if (order.customerName != null)
                          _buildDetailRow(_t('eshop_name', 'নাম'), order.customerName!),
                        if (order.customerEmail != null)
                          _buildDetailRow(_t('eshop_email', 'ইমেইল'), order.customerEmail!),
                        if (order.customerPhone != null)
                          _buildDetailRow(_t('eshop_phone', 'ফোন'), order.customerPhone!),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Shipping Address
                    if (order.shippingAddress != null)
                      _buildDetailSection(
                        _t('eshop_shipping_address', 'শিপিং ঠিকানা'),
                        Icons.location_on_rounded,
                        [
                          _buildDetailRow(_t('eshop_address', 'ঠিকানা'), order.shippingAddress!),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Order Items
                    _buildDetailSection(
                      '${_t('eshop_order_items', 'অর্ডার আইটেম')} (${order.items?.length ?? 0})',
                      Icons.shopping_bag_rounded,
                      [
                        if (order.items != null && order.items!.isNotEmpty)
                          ...order.items!.map((item) => _buildOrderItem(item)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Payment & Total
                    _buildDetailSection(
                      _t('eshop_payment_information', 'পেমেন্ট ইনফরমেশন'),
                      Icons.payment_rounded,
                      [
                        _buildDetailRow(_t('eshop_payment_method', 'পেমেন্ট মেথড'), order.paymentMethod ?? _t('eshop_na', 'নেই')),
                        _buildDetailRow(
                          _t('eshop_total_amount', 'টোটাল অ্যামাউন্ট'),
                          '৳${order.total.toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dates
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(_t('eshop_order_date', 'অর্ডার ডেট'), _formatDate(order.createdAt)),
                          if (order.updatedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(_t('eshop_last_updated', 'লাস্ট আপডেট'), _formatDate(order.updatedAt!)),
                          ],
                        ],
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

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                color: isHighlighted ? const Color(0xFF10B981) : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Product Icon (since productImage is not available in OrderItem)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_t('eshop_qty', 'কোয়ান্টিটি')}: ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '৳${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Total
          Text(
            '৳${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusSelector(ShopOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
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
                    Icons.swap_horiz_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('eshop_change_order_status', 'অর্ডার স্ট্যাটাস আপডেট'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_t('eshop_order_hash', 'অর্ডার')} #${order.orderNumber ?? order.id.substring(0, 8)}',
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
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),

            // Status Options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusOption(
                    context,
                    order,
                    'pending',
                    _t('eshop_status_pending', 'পেন্ডিং'),
                    _t('eshop_status_pending_desc', 'অর্ডার অ্যাকসেপ্ট করার অপেক্ষায়'),
                    Icons.schedule_rounded,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusOption(
                    context,
                    order,
                    'processing',
                    _t('eshop_status_processing', 'প্রসেসিং'),
                    _t('eshop_status_processing_desc', 'অর্ডার রেডি করা হচ্ছে'),
                    Icons.autorenew_rounded,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusOption(
                    context,
                    order,
                    'delivered',
                    _t('eshop_status_delivered', 'ডেলিভারড'),
                    _t('eshop_status_delivered_desc', 'অর্ডার ডেলিভারি হয়ে গেছে'),
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusOption(
                    context,
                    order,
                    'cancelled',
                    _t('eshop_status_cancelled', 'ক্যান্সেল'),
                    _t('eshop_status_cancelled_desc', 'অর্ডার ক্যান্সেল করা হয়েছে'),
                    Icons.cancel_rounded,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    ShopOrder order,
    String statusValue,
    String statusLabel,
    String description,
    IconData icon,
    Color color,
  ) {
    final isCurrentStatus = order.orderStatus == statusValue;

    return InkWell(
      onTap: isCurrentStatus
          ? null
          : () {
              Navigator.pop(context);
              _updateOrderStatus(order.id, statusValue);
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentStatus ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrentStatus ? color : Colors.grey.shade200,
            width: isCurrentStatus ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrentStatus ? color : const Color(0xFF111827),
                        ),
                      ),
                      if (isCurrentStatus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _t('eshop_current', 'এখন'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrentStatus)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${_t('eshop_today_at', 'আজকে')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return _t('eshop_yesterday', 'গতকাল');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${_t('eshop_days_ago', 'দিন আগে')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
