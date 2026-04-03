import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../widgets/wallet/amount_input_field.dart';
import '../../widgets/wallet/payment_method_selector.dart';
import '../../widgets/wallet/terms_checkbox.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _slate50 = Color(0xFFF8FAFC);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);

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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
          const SizedBox(height: 16),

          // Phone Number Input
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (value) => _validatePhone(),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _slate800),
            decoration: InputDecoration(
              labelText: '${_selectedMethod == 'nagad' ? 'Nagad' : 'bKash'} Number',
              hintText: 'Enter ${_selectedMethod == 'nagad' ? 'Nagad' : 'bKash'} number',
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _slate500),
              hintStyle: GoogleFonts.inter(fontSize: 13, color: _slate400),
              prefixIcon: const Icon(Icons.phone_android_rounded, size: 18, color: _slate400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _indigo, width: 1.8),
              ),
              filled: true,
              fillColor: _slate50,
              errorText: _phoneError,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
          const SizedBox(height: 12),

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
                color: _slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Withdrawal Amount:',
                        style: GoogleFonts.inter(fontSize: 12, color: _slate700, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '৳${amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _slate800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Charges (${WalletService.withdrawalChargePercent}%):',
                        style: GoogleFonts.inter(fontSize: 12, color: _slate500, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '৳${(amount * WalletService.withdrawalChargePercent / 100).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _slate800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 12, color: _slate200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Deduction:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _slate800,
                        ),
                      ),
                      Text(
                        '৳${totalDeduction.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // Withdraw Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_indigo, _violet],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _indigo.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        const Icon(Icons.arrow_upward, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Submit Withdrawal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
}
