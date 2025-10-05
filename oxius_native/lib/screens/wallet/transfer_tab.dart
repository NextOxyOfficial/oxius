import 'package:flutter/material.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../widgets/wallet/amount_input_field.dart';
import '../../widgets/wallet/terms_checkbox.dart';

class TransferTab extends StatefulWidget {
  final double balance;
  final String userPhone;
  final VoidCallback onTransferSuccess;

  const TransferTab({
    super.key,
    required this.balance,
    required this.userPhone,
    required this.onTransferSuccess,
  });

  @override
  State<TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<TransferTab> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _contactError;
  String? _amountError;
  String? _termsError;
  bool _showQrCode = false;

  @override
  void dispose() {
    _contactController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _validateContact() {
    setState(() {
      final contact = _contactController.text.trim();
      if (contact.isEmpty) {
        _contactError = 'Please enter email or phone number';
      } else {
        _contactError = null;
      }
    });
  }

  void _validateAmount() {
    setState(() {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        _amountError = 'Please enter a valid amount';
      } else if (amount < WalletService.minTransfer) {
        _amountError =
            'Minimum transfer amount is ৳${WalletService.minTransfer.toStringAsFixed(0)}';
      } else if (amount > widget.balance) {
        _amountError = 'Insufficient balance';
      } else {
        _amountError = null;
      }
    });
  }

  void _showMyQrCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // Placeholder for QR code
                  // You'd need to add qr_flutter package and generate QR
                  Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.qr_code, size: 100),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userPhone,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTransfer() async {
    _validateContact();
    _validateAmount();

    setState(() {
      _termsError = _acceptedTerms ? null : 'Please accept terms and conditions';
    });

    if (_contactError != null || _amountError != null || _termsError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final request = TransferRequest(
        contact: _contactController.text.trim(),
        amount: amount,
        policy: _acceptedTerms,
      );

      final response = await WalletService.createTransfer(request);

      if (response != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Transfer completed successfully',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset form
        _contactController.clear();
        _amountController.clear();
        setState(() => _acceptedTerms = false);

        // Refresh balance
        widget.onTransferSuccess();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show My QR Code Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _showMyQrCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Show My QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact Input
          TextField(
            controller: _contactController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _validateContact(),
            decoration: InputDecoration(
              labelText: 'Recipient Email or Phone',
              hintText: 'Enter email or phone number',
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {
                  // TODO: Implement QR code scanner
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR Scanner - Coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Scan QR Code',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              errorText: _contactError,
            ),
          ),
          const SizedBox(height: 16),

          // Amount Input
          AmountInputField(
            controller: _amountController,
            label: 'Transfer Amount',
            hint: 'Enter amount to transfer',
            errorText: _amountError,
            minAmount: WalletService.minTransfer,
            onChanged: _validateAmount,
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

          // Transfer Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
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
                      'Transfer Money',
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
