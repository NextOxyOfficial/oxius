import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/wallet/amount_input_field.dart';
import '../../widgets/wallet/terms_checkbox.dart';
import '../settings_screen.dart';

class DepositTab extends StatefulWidget {
  final double balance;
  final VoidCallback onDepositSuccess;

  const DepositTab({
    super.key,
    required this.balance,
    required this.onDepositSuccess,
  });

  @override
  State<DepositTab> createState() => _DepositTabState();
}

class _DepositTabState extends State<DepositTab> {
  final TextEditingController _amountController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _amountError;
  String? _termsError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    setState(() {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        _amountError = 'Please enter a valid amount';
      } else if (amount < WalletService.minDeposit) {
        _amountError =
            'Minimum deposit amount is ৳${WalletService.minDeposit.toStringAsFixed(0)}';
      } else {
        _amountError = null;
      }
    });
  }

  bool _isProfileComplete() {
    final user = AuthService.currentUser;
    if (user == null) return false;

    // Check if required profile fields are filled
    return (user.phone != null && user.phone!.isNotEmpty) &&
           (user.address != null && user.address!.isNotEmpty) &&
           (user.city != null && user.city!.isNotEmpty);
  }

  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To process deposits, please complete your profile with the following information:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildRequiredField(Icons.phone, 'Phone Number'),
              _buildRequiredField(Icons.location_on, 'Address'),
              _buildRequiredField(Icons.location_city, 'City'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This information is required for secure payment processing.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Complete Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequiredField(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeposit() async {
    _validateAmount();

    setState(() {
      _termsError = _acceptedTerms ? null : 'Please accept terms and conditions';
    });

    if (_amountError != null || _termsError != null) {
      return;
    }

    // Check if profile is complete before proceeding
    if (!_isProfileComplete()) {
      _showProfileIncompleteDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final request = DepositRequest(
        amount: amount,
        policy: _acceptedTerms,
      );

      final response = await WalletService.createDeposit(request);

      if (response != null && response['checkout_url'] != null) {
        // Extract order ID from response or generate it
        final orderId = response['order_id']?.toString() ?? 
                       response['merchant_invoice_no']?.toString() ??
                       DateTime.now().millisecondsSinceEpoch.toString();
        
        // Launch payment gateway
        final url = Uri.parse(response['checkout_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          if (mounted) {
            // Show message and start polling
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete payment in browser. We\'ll update your balance automatically.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 4),
              ),
            );
            
            // Reset form
            _amountController.clear();
            setState(() => _acceptedTerms = false);
            
            // Start polling for payment status
            _startPaymentStatusPolling(orderId);
          }
        } else {
          throw Exception('Could not launch payment gateway');
        }
      }
    } catch (e) {
      if (mounted) {
        // Extract clean error message
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // Check if it's a profile-related error
        if (errorMessage.contains('profile') || 
            errorMessage.contains('phone') || 
            errorMessage.contains('address')) {
          _showProfileIncompleteDialog();
        } else {
          // Show generic error with action button
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _handleDeposit,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPaymentStatusPolling(String orderId) {
    print('📱 Starting payment status polling for order: $orderId');
    int pollCount = 0;
    const maxPolls = 60; // Poll for 5 minutes (60 * 5 seconds)
    
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      pollCount++;
      
      try {
        print('📱 Polling attempt $pollCount/$maxPolls');
        
        final result = await WalletService.verifyPayment(orderId);
        
        if (result != null && result['shurjopay_message'] == 'Success') {
          timer.cancel();
          print('✅ Payment verified successfully!');
          
          // Add balance to account
          await WalletService.addBalanceAfterPayment(result);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Payment successful! Your balance has been updated.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 4),
              ),
            );
            
            // Refresh balance
            widget.onDepositSuccess();
          }
        } else if (result != null && result['shurjopay_message'] != null && 
                   result['shurjopay_message'] != 'Success') {
          // Payment failed
          timer.cancel();
          print('❌ Payment failed: ${result['shurjopay_message']}');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${result['shurjopay_message']}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
        
        // Stop polling after max attempts
        if (pollCount >= maxPolls) {
          timer.cancel();
          print('⏱️ Polling timeout reached');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment status check timed out. Please check your balance or contact support.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        print('⚠️ Polling error (will retry): $e');
        // Continue polling on error
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmountInputField(
            controller: _amountController,
            label: 'Deposit Amount',
            hint: 'Enter amount to deposit',
            errorText: _amountError,
            minAmount: WalletService.minDeposit,
            onChanged: _validateAmount,
          ),
          const SizedBox(height: 16),
          
          // Payment Method Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF3B82F6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payment Gateway',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'SSL Encrypted & Safe',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/payment.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPaymentIcon(Icons.credit_card),
                        _buildPaymentIcon(Icons.account_balance),
                        _buildPaymentIcon(Icons.phone_android),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Terms Checkbox
          TermsCheckbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
                _termsError = null;
              });
            },
            errorText: _termsError,
          ),
          const SizedBox(height: 16),
          
          // Deposit Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Safe area bottom padding for devices with gesture navigation
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, size: 24, color: const Color(0xFF10B981)),
    );
  }
}
