import 'package:flutter/material.dart';
import '../../services/diamond_service.dart';
import '../../services/auth_service.dart';
import 'diamond_purchase_bottom_sheet.dart';

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

  static void show(
    BuildContext context, {
    required String postId,
    required String postAuthorId,
    required String postAuthorName,
    VoidCallback? onGiftSent,
  }) {
    showModalBottomSheet(
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
  String _giftMessage = '';
  bool _isSending = false;
  
  late int _currentDiamondBalance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully sent ${_giftAmount!} diamonds to ${widget.postAuthorName}! 🎁'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        widget.onGiftSent?.call();

        // Close bottom sheet
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: screenHeight * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade500, Colors.purple.shade500],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Send Gift to ${widget.postAuthorName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Balance Card - Compact
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade50, Colors.purple.shade50],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.pink.shade200, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Diamonds',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.diamond, size: 18, color: Colors.pink.shade500),
                            const SizedBox(width: 6),
                            Text(
                              '$_currentDiamondBalance',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [Colors.pink.shade600, Colors.purple.shade600],
                                  ).createShader(const Rect.fromLTWH(0, 0, 150, 50)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gift Amount Input
                  Text(
                    'Diamond Amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      suffixIcon: Icon(Icons.auto_awesome, color: Colors.pink.shade400, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.pink.shade500, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _giftAmount = int.tryParse(value);
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  if (_giftAmount != null && _giftAmount! > _currentDiamondBalance)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Insufficient diamond balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Gift Message Input
                  Text(
                    'Message (Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Write your message...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.pink.shade500, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Send Gift Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _canSendGift() && !_isSending ? _sendGift : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade500,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.card_giftcard_rounded, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Send Gift',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // No Balance / Purchase Button
                  if (_currentDiamondBalance == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.orange.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'You need diamonds to send a gift',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                DiamondPurchaseBottomSheet.show(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart, size: 16),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Purchase Diamonds',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Purchase button for users with balance
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          DiamondPurchaseBottomSheet.show(context);
                        },
                        icon: Icon(Icons.add_shopping_cart, size: 14, color: Colors.blue.shade700),
                        label: Text(
                          'Buy more Diamonds!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
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
