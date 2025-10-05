import 'package:flutter/material.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../widgets/wallet/amount_input_field.dart';
import '../../widgets/wallet/payment_method_selector.dart';
import '../../widgets/wallet/terms_checkbox.dart';

class WithdrawTab extends StatefulWidget {
  final double balance;
  final VoidCallback onWithdrawSuccess;

  const WithdrawTab({
    super.key,
    required this.balance,
    required this.onWithdrawSuccess,
  });

  @override
  State<WithdrawTab> createState() => _WithdrawTabState();
}

class _WithdrawTabState extends State<WithdrawTab> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMethod = 'nagad';
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _amountError;
  String? _phoneError;
  String? _termsError;

  final List<PaymentMethodOption> _paymentMethods =
      WalletService.getPaymentMethods();

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    setState(() {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        _amountError = 'Please enter a valid amount';
      } else if (amount < WalletService.minWithdrawal) {
        _amountError =
            'Minimum withdrawal amount is ৳${WalletService.minWithdrawal.toStringAsFixed(0)}';
      } else {
        final totalWithCharge = WalletService.calculateWithdrawalTotal(amount);
        if (totalWithCharge > widget.balance) {
          _amountError = 'Insufficient balance';
        } else {
          _amountError = null;
        }
      }
    });
  }

  void _validatePhone() {
    setState(() {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _phoneError = 'Please enter $_selectedMethod number';
      } else if (phone.length < 11) {
        _phoneError = 'Please enter a valid phone number';
      } else {
        _phoneError = null;
      }
    });
  }

  Future<void> _handleWithdraw() async {
    _validateAmount();
    _validatePhone();

    setState(() {
      _termsError = _acceptedTerms ? null : 'Please accept terms and conditions';
    });

    if (_amountError != null || _phoneError != null || _termsError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final request = WithdrawRequest(
        paymentMethod: _selectedMethod,
        paymentNumber: _phoneController.text.trim(),
        amount: amount,
        policy: _acceptedTerms,
      );

      final response = await WalletService.createWithdrawal(request);

      if (response != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Withdrawal request submitted successfully',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset form
        _amountController.clear();
        _phoneController.clear();
        setState(() {
          _acceptedTerms = false;
          _selectedMethod = 'nagad';
        });

        // Refresh balance
        widget.onWithdrawSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final amount = double.tryParse(_amountController.text) ?? 0;
    final totalDeduction = amount > 0
        ? WalletService.calculateWithdrawalTotal(amount)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method Selector
          PaymentMethodSelector(
            selectedMethod: _selectedMethod,
            methods: _paymentMethods,
            onMethodSelected: (method) {
              setState(() {
                _selectedMethod = method;
                _phoneController.clear();
                _phoneError = null;
              });
            },
          ),
          const SizedBox(height: 24),

          // Phone Number Input
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (value) => _validatePhone(),
            decoration: InputDecoration(
              labelText: '${_selectedMethod == 'nagad' ? 'Nagad' : 'bKash'} Number',
              hintText: 'Enter ${_selectedMethod == 'nagad' ? 'Nagad' : 'bKash'} number',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              errorText: _phoneError,
            ),
          ),
          const SizedBox(height: 16),

          // Amount Input
          AmountInputField(
            controller: _amountController,
            label: 'Withdrawal Amount',
            hint: 'Enter amount to withdraw',
            errorText: _amountError,
            minAmount: WalletService.minWithdrawal,
            onChanged: _validateAmount,
          ),
          const SizedBox(height: 12),

          // Charge Information
          if (amount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Withdrawal Amount:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '৳${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Charges (${WalletService.withdrawalChargePercent}%):',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      Text(
                        '৳${(amount * WalletService.withdrawalChargePercent / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Deduction:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '৳${totalDeduction.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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

          // Withdraw Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
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
                      'Submit Withdrawal Request',
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
