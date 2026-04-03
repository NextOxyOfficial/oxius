import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/wallet_models.dart';

const _indigo = Color(0xFF6366F1);
const _slate50 = Color(0xFFF8FAFC);
const _slate200 = Color(0xFFE2E8F0);
const _slate500 = Color(0xFF64748B);
const _slate800 = Color(0xFF1E293B);

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final List<PaymentMethodOption> methods;
  final ValueChanged<String> onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.methods,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _slate800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: methods.map((method) {
            final isSelected = selectedMethod == method.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onMethodSelected(method.value),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? _indigo.withValues(alpha: 0.08) : _slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _indigo : _slate200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _slate200),
                        ),
                        child: Image.asset(
                          'assets/${method.icon}',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.payment,
                              size: 28,
                              color: Colors.grey[400],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        method.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? _indigo : _slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
