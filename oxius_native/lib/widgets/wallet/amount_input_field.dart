import 'package:flutter/material.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final double? minAmount;
  final VoidCallback? onChanged;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.minAmount,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => onChanged?.call(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            hintText: hint ?? 'Enter amount',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.account_balance_wallet, size: 20),
            prefixText: '৳ ',
            prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (minAmount != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Row(
              children: [
                const Text(
                  '* ',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
                Text(
                  'Minimum $label ৳${minAmount!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
