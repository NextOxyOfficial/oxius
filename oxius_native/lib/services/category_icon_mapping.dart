import 'package:flutter/material.dart';

class CategoryIconMapping {
  static const Map<String, String> _saleIconMap = {
    // Add mappings based on category names/IDs from your API
    'Electronics': 'assets/images/icons/mobileapp.png',
    'Fashion': 'assets/images/icons/onlineshopping.png',
    'Home & Garden': 'assets/images/icons/premium.png',
    'Sports & Recreation': 'assets/images/icons/onlineshopping.png',
    'Vehicles': 'assets/images/icons/transaction.png',
    'Services': 'assets/images/icons/sign.png',
    'Real Estate': 'assets/images/icons/premium.png',
    'Jobs': 'assets/images/icons/mobileapp.png',
    'Health': 'assets/images/icons/medicalreport.png',
    'Education': 'assets/images/icons/onlinelearning.png',
  };

  static const Map<String, String> _classifiedIconMap = {
    'Services & Business': 'assets/images/icons/sign.png',
    'Jobs & Employment': 'assets/images/icons/mobileapp.png',
    'Real Estate & Property': 'assets/images/icons/premium.png',
    'Vehicles & Transportation': 'assets/images/icons/transaction.png',
    'Electronics & Technology': 'assets/images/icons/mobileapp.png',
    'Health & Wellness': 'assets/images/icons/medicalreport.png',
    'Sports & Recreation': 'assets/images/icons/onlineshopping.png',
    'Education & Learning': 'assets/images/icons/onlinelearning.png',
    'Home & Garden': 'assets/images/icons/premium.png',
    'Fashion & Beauty': 'assets/images/icons/onlineshopping.png',
  };

  /// Get local asset path for sale category based on name
  static String? getSaleIconAsset(String? categoryName) {
    if (categoryName == null) return null;
    
    // Direct match
    if (_saleIconMap.containsKey(categoryName)) {
      return _saleIconMap[categoryName];
    }
    
    // Fuzzy matching for common terms
    final nameLower = categoryName.toLowerCase();
    for (final entry in _saleIconMap.entries) {
      if (nameLower.contains(entry.key.toLowerCase()) || 
          entry.key.toLowerCase().contains(nameLower)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Get local asset path for classified category based on name
  static String? getClassifiedIconAsset(String? categoryName) {
    if (categoryName == null) return null;
    
    // Direct match
    if (_classifiedIconMap.containsKey(categoryName)) {
      return _classifiedIconMap[categoryName];
    }
    
    // Fuzzy matching for common terms
    final nameLower = categoryName.toLowerCase();
    for (final entry in _classifiedIconMap.entries) {
      if (nameLower.contains(entry.key.toLowerCase()) || 
          entry.key.toLowerCase().contains(nameLower)) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Get appropriate fallback icon based on category type
  static Widget getDefaultIcon({bool isSale = false, double size = 20}) {
    return Icon(
      isSale ? Icons.shopping_bag_outlined : Icons.widgets_outlined,
      size: size,
      color: Colors.grey.shade600,
    );
  }
}