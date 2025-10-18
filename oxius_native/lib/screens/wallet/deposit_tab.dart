import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../widgets/wallet/amount_input_field.dart';
import '../../widgets/wallet/terms_checkbox.dart';

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

  Future<void> _handleDeposit() async {
    _validateAmount();

    setState(() {
      _termsError = _acceptedTerms ? null : 'Please accept terms and conditions';
    });

    if (_amountError != null || _termsError != null) {
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
        // Launch payment gateway
        final url = Uri.parse(response['checkout_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to payment gateway...'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 2),
              ),
            );
            
            // Reset form
            _amountController.clear();
            setState(() => _acceptedTerms = false);
            
            // Refresh balance after some delay
            Future.delayed(const Duration(seconds: 3), widget.onDepositSuccess);
          }
        } else {
          throw Exception('Could not launch payment gateway');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
