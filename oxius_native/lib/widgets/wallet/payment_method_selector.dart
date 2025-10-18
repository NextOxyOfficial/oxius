import 'package:flutter/material.dart';
import '../../models/wallet_models.dart';

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
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
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
                    color: isSelected ? const Color(0xFF10B981).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : Colors.grey[300]!,
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
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey[700],
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
