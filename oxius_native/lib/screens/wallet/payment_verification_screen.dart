import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final String orderId;

  const PaymentVerificationScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = 'Verifying payment...';

  @override
  void initState() {
    super.initState();
    _verifyAndProcessPayment();
  }

  Future<void> _verifyAndProcessPayment() async {
    try {
      print('🔍 Starting payment verification for order: ${widget.orderId}');
      
      // Step 1: Verify payment with Surjopay
      final verificationResult = await WalletService.verifyPayment(widget.orderId);
      
      if (verificationResult == null) {
        throw Exception('Payment verification failed');
      }

      print('✅ Payment verified: ${verificationResult['shurjopay_message']}');

      // Step 2: Check if payment was successful
      if (verificationResult['shurjopay_message'] == 'Success') {
        // Step 3: Add balance to user account
        final addBalanceResult = await WalletService.addBalanceAfterPayment(verificationResult);
        
        if (addBalanceResult != null && addBalanceResult['success'] == true) {
          setState(() {
            _isSuccess = true;
            _message = 'Payment successful! Your balance has been updated.';
            _isLoading = false;
          });
          
          // Auto-navigate back after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        } else {
          throw Exception('Failed to add balance');
        }
      } else {
        throw Exception('Payment was not successful');
      }
    } catch (e) {
      print('❌ Payment verification error: $e');
      setState(() {
        _isSuccess = false;
        _message = 'Payment verification failed. Please contact support if money was deducted.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        automaticallyImplyLeading: !_isLoading,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                Column(
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isSuccess 
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFEF4444).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSuccess 
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        size: 48,
                        color: _isSuccess 
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isSuccess ? 'Payment Successful!' : 'Payment Failed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _isSuccess 
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (!_isSuccess)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
}
