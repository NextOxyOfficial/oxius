import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/wallet/amount_input_field.dart';
import '../../widgets/wallet/terms_checkbox.dart';
import 'transfer_confirmation_dialog.dart';

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
    final user = AuthService.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Receive Money',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Show this QR code to receive payment',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: 'adsypay://pay/${user.id}',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // User info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isNotEmpty
                        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
                        : user.username ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Security badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 16,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secure Payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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

    final contact = _contactController.text.trim();
    final amount = double.parse(_amountController.text);

    // Show transfer confirmation dialog with password
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransferConfirmationDialog(
        contact: contact,
        amount: amount,
        onSuccess: () {
          // Reset form
          _contactController.clear();
          _amountController.clear();
          setState(() => _acceptedTerms = false);

          // Refresh balance
          widget.onTransferSuccess();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show My QR Code Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _showMyQrCode,
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Show My QR Code'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Input
          TextField(
            controller: _contactController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _validateContact(),
            decoration: InputDecoration(
              labelText: 'Recipient Email or Phone',
              hintText: 'Enter email or phone number',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                onPressed: () {
                  // TODO: Implement QR code scanner to scan recipient's payment QR
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scan recipient QR code - Coming soon'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                tooltip: 'Scan Recipient QR Code',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
              errorText: _contactError,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Amount Input
          AmountInputField(
            controller: _amountController,
            label: 'Transfer Amount',
            hint: 'Enter amount to transfer',
            errorText: _amountError,
            minAmount: WalletService.minTransfer,
            onChanged: _validateAmount,
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

          // Transfer Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleTransfer,
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
                        const Icon(Icons.swap_horiz, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Transfer Money',
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
}
