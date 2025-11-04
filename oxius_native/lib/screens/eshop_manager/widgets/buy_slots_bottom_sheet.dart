import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/eshop_manager_service.dart';
import '../../../services/auth_service.dart';

class BuySlotsBottomSheet extends StatefulWidget {
  final int currentProductCount;
  final int productLimit;
  final VoidCallback onPurchaseSuccess;

  const BuySlotsBottomSheet({
    super.key,
    required this.currentProductCount,
    required this.productLimit,
    required this.onPurchaseSuccess,
  });

  @override
  State<BuySlotsBottomSheet> createState() => _BuySlotsBottomSheetState();
}

class _BuySlotsBottomSheetState extends State<BuySlotsBottomSheet> {
  List<Map<String, dynamic>> _packages = [];
  Map<String, dynamic>? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  double _userBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final packages = await EshopManagerService.getProductSlotPackages();
      final user = AuthService.currentUser;
      final balance = user?.balance ?? 0.0;
      
      if (mounted) {
        setState(() {
          _packages = packages;
          _userBalance = balance;
          if (_packages.isNotEmpty) {
            _selectedPackage = _packages[0];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading buy slots data: $e');
      if (mounted) {
        setState(() {
          _packages = [];
          _userBalance = 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchaseSlots() async {
    if (_selectedPackage == null) return;

    final price = (_selectedPackage!['price'] is int) 
        ? (_selectedPackage!['price'] as int).toDouble() 
        : _selectedPackage!['price'] as double;

    if (_userBalance < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. You need ৳${price.toStringAsFixed(0)}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPurchasing = true);

    final result = await EshopManagerService.purchaseProductSlots(
      packageId: _selectedPackage!['id'],
      slotCount: _selectedPackage!['slots'],
      cost: price,
    );

    setState(() => _isPurchasing = false);

    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${_selectedPackage!['slots']} slot(s)!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onPurchaseSuccess();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Purchase failed'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy Product Slots',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Expand your store capacity',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 22),
                  color: const Color(0xFF6B7280),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)),
                      ),
                    ),
                  )
                : _packages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No packages available',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF10B981)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Using ${widget.currentProductCount}/${widget.productLimit} slots',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Balance
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Text(
                                  'Balance:',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '৳${_userBalance.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/deposit-withdraw'),
                                  icon: const Icon(Icons.add_circle_outline, size: 14),
                                  label: const Text('Add Funds', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Packages
                            ..._packages.map((pkg) {
                              final isSelected = _selectedPackage?['id'] == pkg['id'];
                              final price = (pkg['price'] is int) 
                                  ? (pkg['price'] as int).toDouble() 
                                  : pkg['price'] as double;
                              final originalPrice = pkg['original_price'] != null
                                  ? ((pkg['original_price'] is int) 
                                      ? (pkg['original_price'] as int).toDouble() 
                                      : pkg['original_price'] as double)
                                  : null;
                              final hasDiscount = originalPrice != null && originalPrice > price;
                              final discount = hasDiscount 
                                  ? ((originalPrice - price) / originalPrice * 100).round()
                                  : 0;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedPackage = pkg),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Radio
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300,
                                                width: 2,
                                              ),
                                              color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${pkg['slots']} Slots',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF111827),
                                                      ),
                                                    ),
                                                    if (pkg['is_featured'] == true) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF6366F1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'BEST',
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.w800,
                                                            color: Colors.white,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Add ${pkg['slots']} more products',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Price
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '৳${price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                              if (hasDiscount)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '৳${originalPrice.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade400,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF3C7),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        '-$discount%',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFFD97706),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            // Warning
                            if (_selectedPackage != null &&
                                _userBalance < ((_selectedPackage!['price'] is int) 
                                    ? (_selectedPackage!['price'] as int).toDouble() 
                                    : _selectedPackage!['price'] as double)) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Insufficient balance. Please add funds.',
                                        style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isPurchasing ||
                              _selectedPackage == null ||
                              _userBalance < ((_selectedPackage!['price'] is int) 
                                  ? (_selectedPackage!['price'] as int).toDouble() 
                                  : _selectedPackage!['price'] as double)
                          ? null
                          : _purchaseSlots,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Purchase Now',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
