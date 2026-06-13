import 'package:flutter/material.dart';
import '../../services/diamond_service.dart';
import '../../services/auth_service.dart';
import '../../utils/payment_policy.dart';
import 'diamond_purchase_bottom_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class DiamondGiftBottomSheet extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final String postAuthorName;
  final VoidCallback? onGiftSent;

  const DiamondGiftBottomSheet({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.postAuthorName,
    this.onGiftSent,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required String postAuthorId,
    required String postAuthorName,
    VoidCallback? onGiftSent,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiamondGiftBottomSheet(
        postId: postId,
        postAuthorId: postAuthorId,
        postAuthorName: postAuthorName,
        onGiftSent: onGiftSent,
      ),
    );
  }

  @override
  State<DiamondGiftBottomSheet> createState() => _DiamondGiftBottomSheetState();
}

class _DiamondGiftBottomSheetState extends State<DiamondGiftBottomSheet> {
  int? _giftAmount;
  int? _selectedPreset;
  bool _isSending = false;

  late int _currentDiamondBalance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  static const List<int> _presets = [10, 25, 50, 100, 500];

  @override
  void initState() {
    super.initState();
    _currentDiamondBalance = AuthService.currentUser?.diamondBalance ?? 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool _canSendGift() {
    return _giftAmount != null &&
        _giftAmount! > 0 &&
        _giftAmount! <= _currentDiamondBalance;
  }

  Future<void> _sendGift() async {
    if (!_canSendGift()) return;

    setState(() => _isSending = true);

    try {
      final message = _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : 'Sent ${_giftAmount!} diamonds as a gift! ✨';

      await DiamondService.sendGift(
        amount: _giftAmount!,
        recipientId: widget.postAuthorId,
        postId: widget.postId,
        message: message,
      );

      // Update local balance
      await AuthService.refreshUserData();

      if (mounted) {
        setState(() {
          _currentDiamondBalance = AuthService.currentUser?.diamondBalance ?? 0;
          _isSending = false;
        });

        // Show success message
        AdsyToast.success(context,
            'Successfully sent ${_giftAmount!} diamonds to ${widget.postAuthorName}! 🎁');

        widget.onGiftSent?.call();

        // Close bottom sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        AdsyToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Hero header ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Gift box visual
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🎁', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send a Gift',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'to ${widget.postAuthorName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Close
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF4FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Row(
                            children: [
                              const Text('💎', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Balance',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '$_currentDiamondBalance diamonds',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (PaymentPolicy.shouldShowDigitalPaymentUI()) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            DiamondPurchaseBottomSheet.show(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'Buy More',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quick amount presets
                  Text(
                    'QUICK AMOUNTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _presets.map((amount) {
                      final isSelected = _selectedPreset == amount;
                      final canAfford = amount <= _currentDiamondBalance;
                      return Expanded(
                        child: GestureDetector(
                          onTap: canAfford
                              ? () {
                                  setState(() {
                                    _selectedPreset = amount;
                                    _giftAmount = amount;
                                    _amountController.text = amount.toString();
                                  });
                                }
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFFDB2777)
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (canAfford
                                      ? const Color(0xFFF9F5FF)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (canAfford
                                        ? const Color(0xFFDDD6FE)
                                        : Colors.grey.shade200),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (canAfford
                                          ? const Color(0xFF7C3AED)
                                          : Colors.grey.shade400),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Custom amount input
                  Text(
                    'CUSTOM AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter diamond amount',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: Text('💎', style: TextStyle(fontSize: 18)),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C3AED), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _giftAmount = int.tryParse(value);
                        _selectedPreset = null;
                      });
                    },
                  ),
                  if (_giftAmount != null &&
                      _giftAmount! > _currentDiamondBalance)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 13, color: Colors.red.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Insufficient diamond balance',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade500),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Message input
                  Text(
                    'MESSAGE (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Write a nice message... ✨',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C3AED), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Send button
                  GestureDetector(
                    onTap: _canSendGift() && !_isSending ? _sendGift : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _canSendGift()
                            ? const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _canSendGift() ? null : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _canSendGift()
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: AdsyLoadingIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🎁',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: _canSendGift()
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _giftAmount != null && _giftAmount! > 0
                                        ? 'Send $_giftAmount Diamonds'
                                        : 'Send Gift',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _canSendGift()
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Zero balance warning
                  if (_currentDiamondBalance == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: Colors.orange.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You need diamonds to send a gift',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700),
                              ),
                            ),
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
    );
  }
}
