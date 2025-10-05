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
          decoration: InputDecoration(
            labelText: label,
            hintText: hint ?? 'Enter amount',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            prefixText: '৳ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            errorText: errorText,
          ),
        ),
        if (minAmount != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                const Text(
                  '* ',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                Text(
                  'Minimum $label ৳${minAmount!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
