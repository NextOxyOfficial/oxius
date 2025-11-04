// Category Dropdown Widget for eShop Screen
import 'package:flutter/material.dart';

Widget buildCategoryDropdown({
  required BuildContext context,
  required List<Map<String, dynamic>> categories,
  required String? selectedCategoryId,
  required Function(String?, String?) onCategorySelected,
}) {
  return PopupMenuButton<String>(
    offset: const Offset(0, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_list_rounded,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            selectedCategoryId != null ? 'Filtered' : 'All',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
    itemBuilder: (context) {
      return [
        // All Categories option
        PopupMenuItem<String>(
          value: null,
          child: Row(
            children: [
              Icon(
                Icons.apps_rounded,
                size: 18,
                color: selectedCategoryId == null 
                    ? const Color(0xFF10B981) 
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              const Text(
                'All Products',
                style: TextStyle(fontSize: 14),
              ),
              const Spacer(),
              if (selectedCategoryId == null)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Category options
        ...categories.map((category) {
          final categoryId = category['id'].toString();
          final categoryName = category['name']?.toString() ?? 'Unknown';
          final isSelected = selectedCategoryId == categoryId;
          
          return PopupMenuItem<String>(
            value: categoryId,
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  size: 18,
                  color: isSelected 
                      ? const Color(0xFF10B981) 
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
              ],
            ),
          );
        }).toList(),
      ];
    },
    onSelected: (value) {
      if (value == null) {
        onCategorySelected(null, null);
      } else {
        final category = categories.firstWhere(
          (cat) => cat['id'].toString() == value,
          orElse: () => {},
        );
        onCategorySelected(value, category['name']?.toString());
      }
    },
  );
}
