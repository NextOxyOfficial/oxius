import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _indigo = Color(0xFF6366F1);
const _slate50 = Color(0xFFF8FAFC);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);

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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _slate700,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => onChanged?.call(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _slate800,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter amount',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: _slate400),
            prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: _slate400),
            prefixText: '৳ ',
            prefixStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _slate800),
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
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                  style: GoogleFonts.inter(
                    color: _slate500,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
