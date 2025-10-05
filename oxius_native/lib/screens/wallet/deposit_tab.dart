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
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 24),
          
          // Payment Method Image
          Center(
            child: Image.asset(
              'assets/images/payment.png',
              width: 240,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 240,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Secure Payment',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
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
          const SizedBox(height: 24),
          
          // Deposit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
                  : const Text(
                      'Proceed to Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
