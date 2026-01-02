import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';
import 'buy_slots_bottom_sheet.dart';

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
  bool _isExpanded = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _copied = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.storeDetails.storeName);
    _addressController = TextEditingController(text: widget.storeDetails.storeAddress ?? '');
    _descriptionController = TextEditingController(text: widget.storeDetails.storeDescription ?? '');
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
      _showSnackBar('Store name is required', isError: true);
      return;
    }

    if (_nameController.text.trim().length < 2) {
      _showSnackBar('Store name must be at least 2 characters', isError: true);
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
      _showSnackBar('Store updated successfully');
      widget.onStoreUpdated();
    } else {
      _showSnackBar(result['message'] ?? 'Failed to update store', isError: true);
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
    final url = 'https://adsyclub.com/eshop/${widget.storeDetails.storeUsername}';
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getLastOrderDate() {
    if (widget.orders.isEmpty) return 'No orders yet';
    
    final sortedOrders = [...widget.orders];
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final lastOrder = sortedOrders.first.createdAt;
    final now = DateTime.now();
    final difference = now.difference(lastOrder);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastOrder.day}/${lastOrder.month}/${lastOrder.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use totalProducts from backend if available, otherwise use loaded products count
    final actualProductCount = widget.totalProducts > 0 ? widget.totalProducts : widget.products.length;
    final remainingSlots = widget.productLimit - actualProductCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
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
                  const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'My Store Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Editing',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Save',
                                    style: TextStyle(
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
                          color: Colors.white.withOpacity(0.2),
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
                  // Store Name
                  _buildInfoRow(
                    icon: Icons.store_rounded,
                    label: 'Shop Name',
                    isRequired: true,
                    child: _isEditing
                        ? TextField(
                            controller: _nameController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Enter shop name',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    label: 'Store URL',
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                            color: _copied ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    const Padding(
                      padding: EdgeInsets.only(left: 36, top: 2),
                      child: Text(
                        'URL cannot be changed',
                        style: TextStyle(
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
                    label: 'Shop Address',
                    child: _isEditing
                        ? TextField(
                            controller: _addressController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter shop address',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          )
                        : Text(
                            widget.storeDetails.storeAddress ?? 'Not set',
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
                    label: 'Description',
                    child: _isEditing
                        ? TextField(
                            controller: _descriptionController,
                            enabled: !_isSaving,
                            maxLines: 3,
                            maxLength: 500,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter a brief description...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.all(10),
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
                          )
                        : Text(
                            widget.storeDetails.storeDescription ?? 'No description available',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.storeDetails.storeDescription != null
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
                const Text(
                  'Store Active',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Text(
                  'Slots: ',
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
                if (remainingSlots <= 3) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
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
                          const Text(
                            'Buy More',
                            style: TextStyle(
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
                  'Last order: ${_getLastOrderDate()}',
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF10B981)),
        ),
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
