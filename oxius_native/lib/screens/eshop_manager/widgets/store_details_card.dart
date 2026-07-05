import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';
import '../../../services/translation_service.dart';
import '../../../widgets/ios_web_redirect_screen.dart';
import 'buy_slots_bottom_sheet.dart';
import '../../../services/auth_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class StoreDetailsCard extends StatefulWidget {
  final StoreDetails storeDetails;
  final List<ShopProduct> products;
  final List<ShopOrder> orders;
  final int productLimit;
  final int totalProducts;
  final VoidCallback onStoreUpdated;

  const StoreDetailsCard({
    super.key,
    required this.storeDetails,
    required this.products,
    required this.orders,
    required this.productLimit,
    required this.totalProducts,
    required this.onStoreUpdated,
  });

  @override
  State<StoreDetailsCard> createState() => _StoreDetailsCardState();
}

class _StoreDetailsCardState extends State<StoreDetailsCard> {
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) => _i18n.translate(key, fallback: fallback);

  // Store details are always fully shown now (no collapse).
  final bool _isExpanded = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _copied = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.storeDetails.storeName);
    _addressController =
        TextEditingController(text: widget.storeDetails.storeAddress ?? '');
    _descriptionController =
        TextEditingController(text: widget.storeDetails.storeDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(_t('eshop_store_name_required', 'স্টোরের নাম দিতে হবে'),
          isError: true);
      return;
    }

    if (_nameController.text.trim().length < 2) {
      _showSnackBar(
          _t('eshop_store_name_min_length',
              'স্টোরের নাম কমপক্ষে ২ অক্ষরের হতে হবে'),
          isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final result = await EshopManagerService.updateStoreInfo(
      storeUsername: widget.storeDetails.storeUsername,
      storeName: _nameController.text.trim(),
      storeAddress: _addressController.text.trim(),
      storeDescription: _descriptionController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      setState(() => _isEditing = false);
      _showSnackBar(_t('eshop_store_updated', 'স্টোর আপডেট হয়ে গেছে'));
      widget.onStoreUpdated();
    } else {
      _showSnackBar(
          result['message'] ??
              _t('eshop_store_update_failed', 'স্টোর আপডেট করা যায়নি'),
          isError: true);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.storeDetails.storeName;
      _addressController.text = widget.storeDetails.storeAddress ?? '';
      _descriptionController.text = widget.storeDetails.storeDescription ?? '';
    });
  }

  void _copyToClipboard() {
    final url =
        'https://adsyclub.com/eshop/${widget.storeDetails.storeUsername}';
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      AdsyToast.error(context, message);
    } else {
      AdsyToast.success(context, message);
    }
  }

  String _getLastOrderDate() {
    if (widget.orders.isEmpty) {
      return _t('eshop_no_orders_yet', 'এখনও কোনো অর্ডার নেই');
    }

    final sortedOrders = [...widget.orders];
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final lastOrder = sortedOrders.first.createdAt;
    final now = DateTime.now();
    final difference = now.difference(lastOrder);

    if (difference.inDays == 0) {
      return _t('eshop_last_order_today', 'আজকে');
    } else if (difference.inDays == 1) {
      return _t('eshop_last_order_yesterday', 'গতকাল');
    } else if (difference.inDays < 7) {
      return _t('eshop_last_order_days_ago', '${difference.inDays} দিন আগে');
    } else {
      return '${lastOrder.day}/${lastOrder.month}/${lastOrder.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use totalProducts from backend if available, otherwise use loaded products count
    final actualProductCount = widget.totalProducts > 0
        ? widget.totalProducts
        : widget.products.length;
    final remainingSlots = widget.productLimit - actualProductCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (non-collapsible — details are always shown)
          Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('eshop_my_store_details', 'আমার স্টোরের ডিটেইলস'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _t('eshop_editing', 'এডিট করছেন'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (!_isEditing) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                  if (_isEditing) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _isSaving ? null : _saveChanges,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: AdsyLoadingIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFF10B981)),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded,
                                      color: Color(0xFF10B981), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _t('eshop_save', 'সেভ'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _isSaving ? null : _cancelEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (!_isEditing) _buildStoreOverview(),
                  // Store Name
                  _buildInfoRow(
                    icon: Icons.store_rounded,
                    label: _t('eshop_shop_name', 'স্টোরের নাম'),
                    isRequired: true,
                    child: _isEditing
                        ? TextField(
                            controller: _nameController,
                            enabled: !_isSaving,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: _t('eshop_enter_shop_name',
                                  'স্টোরের নাম লিখুন'),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFF10B981)),
                              ),
                            ),
                          )
                        : Text(
                            widget.storeDetails.storeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Store URL
                  _buildInfoRow(
                    icon: Icons.link_rounded,
                    label: _t('eshop_store_url', 'স্টোর URL'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'adsyclub.com/eshop/',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  widget.storeDetails.storeUsername,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _copyToClipboard,
                          child: Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            size: 16,
                            color: _copied
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 2),
                      child: Text(
                        _t('eshop_url_cannot_change',
                            'URL চেঞ্জ করা যাবে না'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Store Address
                  _buildInfoRow(
                    icon: Icons.location_on_rounded,
                    label: _t('eshop_shop_address', 'স্টোরের ঠিকানা'),
                    child: _isEditing
                        ? TextField(
                            controller: _addressController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: _t('eshop_enter_shop_address',
                                  'স্টোরের ঠিকানা লিখুন'),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFF10B981)),
                              ),
                            ),
                          )
                        : Text(
                            widget.storeDetails.storeAddress ??
                                _t('eshop_not_set', 'দেওয়া হয়নি'),
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.storeDetails.storeAddress != null
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  _buildInfoRow(
                    icon: Icons.description_rounded,
                    label: _t('eshop_description', 'ডিসক্রিপশন'),
                    child: _isEditing
                        ? TextField(
                            controller: _descriptionController,
                            enabled: !_isSaving,
                            maxLines: 3,
                            maxLength: 500,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: _t('eshop_enter_description',
                                  'ছোট একটা ডিসক্রিপশন লিখুন...'),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFF10B981)),
                              ),
                            ),
                          )
                        : Text(
                            widget.storeDetails.storeDescription ??
                                _t('eshop_no_description',
                                    'কোনো ডিসক্রিপশন নেই'),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  widget.storeDetails.storeDescription != null
                                      ? const Color(0xFF111827)
                                      : const Color(0xFF9CA3AF),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _t('eshop_store_active', 'স্টোর অ্যাক্টিভ'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Text(
                  _t('eshop_slots_label', 'স্লট: '),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '$actualProductCount/${widget.productLimit}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: remainingSlots <= 0
                        ? const Color(0xFFEF4444)
                        : remainingSlots <= 2
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                  ),
                ),
                if (remainingSlots <= 3 && !isIOSPlatform) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      if (isIOSPlatform) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IOSWebRedirectScreen(
                              title: _t('eshop_product_slots', 'প্রোডাক্ট স্লট'),
                              description: _t('eshop_feature_unavailable',
                                  'এই ফিচারটা অ্যাপের এই ভার্সনে নেই।'),
                              webPath: 'shop-manager',
                              hideWebRedirect: true,
                            ),
                          ),
                        );
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BuySlotsBottomSheet(
                          currentProductCount: actualProductCount,
                          productLimit: widget.productLimit,
                          onPurchaseSuccess: widget.onStoreUpdated,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            size: 11,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _t('eshop_buy_more', 'আরও কিনুন'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                const Text(
                  '|',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD1D5DB),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_t('eshop_last_order', 'লাস্ট অর্ডার')}: ${_getLastOrderDate()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'জানু', 'ফেব', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্ট', 'অক্টো', 'নভে', 'ডিসে'
    ];
    return '${d.day} ${months[(d.month - 1).clamp(0, 11)]} ${d.year}';
  }

  Widget _ovTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // Professional store overview — status, slots, orders, revenue, membership
  // and Pro renewal date, always visible at the top of the details.
  Widget _buildStoreOverview() {
    final actualProductCount = widget.totalProducts > 0
        ? widget.totalProducts
        : widget.products.length;
    final orders = widget.orders.length;
    final revenue = widget.orders
        .where((o) => o.orderStatus == 'delivered')
        .fold<double>(0, (s, o) => s + o.total);
    final active = widget.storeDetails.isActive;
    final renewal = AuthService.currentUser?.proValidity;
    const divider = Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFECEFF3)),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          Row(children: [
            _ovTile(
                _t('eshop_ov_store_status', 'স্টোর স্ট্যাটাস'),
                active
                    ? _t('eshop_ov_active', 'অ্যাক্টিভ')
                    : _t('eshop_ov_inactive', 'ইনঅ্যাক্টিভ'),
                active ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
            _ovTile(
                _t('eshop_ov_product_slots', 'প্রোডাক্ট স্লট'),
                '$actualProductCount / ${widget.productLimit}',
                const Color(0xFF6366F1)),
          ]),
          divider,
          Row(children: [
            _ovTile(_t('eshop_ov_total_orders', 'টোটাল অর্ডার'),
                '$orders টি', const Color(0xFF2563EB)),
            _ovTile(_t('eshop_ov_total_income', 'টোটাল ইনকাম'),
                '৳${revenue.toStringAsFixed(0)}', const Color(0xFF059669)),
          ]),
          divider,
          Row(children: [
            _ovTile(
                _t('eshop_ov_joined_date', 'জয়েন করেছেন'),
                _fmtDate(widget.storeDetails.createdAt),
                const Color(0xFF475569)),
            _ovTile(_t('eshop_ov_renew_date', 'রিনিউ ডেট'), _fmtDate(renewal),
                const Color(0xFFB45309)),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
