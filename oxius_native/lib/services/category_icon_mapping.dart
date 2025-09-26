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
    // Exact category name matches
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
    
    // Additional common category variations
    'Services': 'assets/images/icons/sign.png',
    'Business': 'assets/images/icons/sign.png',
    'Jobs': 'assets/images/icons/mobileapp.png',
    'Employment': 'assets/images/icons/mobileapp.png',
    'Real Estate': 'assets/images/icons/premium.png',
    'Property': 'assets/images/icons/premium.png',
    'Vehicles': 'assets/images/icons/transaction.png',
    'Transportation': 'assets/images/icons/transaction.png',
    'Electronics': 'assets/images/icons/mobileapp.png',
    'Technology': 'assets/images/icons/mobileapp.png',
    'Health': 'assets/images/icons/medicalreport.png',
    'Wellness': 'assets/images/icons/medicalreport.png',
    'Sports': 'assets/images/icons/onlineshopping.png',
    'Recreation': 'assets/images/icons/onlineshopping.png',
    'Education': 'assets/images/icons/onlinelearning.png',
    'Learning': 'assets/images/icons/onlinelearning.png',
    'Home': 'assets/images/icons/premium.png',
    'Garden': 'assets/images/icons/premium.png',
    'Fashion': 'assets/images/icons/onlineshopping.png',
    'Beauty': 'assets/images/icons/onlineshopping.png',
    'News': 'assets/images/icons/news.png',
    'Finance': 'assets/images/icons/money.png',
    'Money': 'assets/images/icons/money.png',
    'Payment': 'assets/images/icons/payment.png',
    'Global': 'assets/images/icons/globalconnection.png',
    'Connection': 'assets/images/icons/globalconnection.png',
    'Question': 'assets/images/icons/question.png',
    'Help': 'assets/images/icons/question.png',
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
    if (categoryName == null || categoryName.isEmpty) return null;
    
    // Direct match (case insensitive)
    for (final entry in _classifiedIconMap.entries) {
      if (entry.key.toLowerCase() == categoryName.toLowerCase()) {
        return entry.value;
      }
    }
    
    // Fuzzy matching for common terms - check if category name contains any key words
    final nameLower = categoryName.toLowerCase();
    for (final entry in _classifiedIconMap.entries) {
      final keyLower = entry.key.toLowerCase();
      
      // Split both the category name and key into words for better matching
      final nameWords = nameLower.split(RegExp(r'[\s&-]+'));
      final keyWords = keyLower.split(RegExp(r'[\s&-]+'));
      
      // Check if any word in the key matches any word in the category name
      for (final keyWord in keyWords) {
        for (final nameWord in nameWords) {
          if (keyWord.isNotEmpty && nameWord.isNotEmpty &&
              (keyWord.contains(nameWord) || nameWord.contains(keyWord))) {
            return entry.value;
          }
        }
      }
    }
    
    // Additional keyword-based matching for common terms
    if (nameLower.contains('service') || nameLower.contains('business')) {
      return 'assets/images/icons/sign.png';
    } else if (nameLower.contains('job') || nameLower.contains('work') || nameLower.contains('career')) {
      return 'assets/images/icons/mobileapp.png';
    } else if (nameLower.contains('property') || nameLower.contains('estate') || nameLower.contains('rent')) {
      return 'assets/images/icons/premium.png';
    } else if (nameLower.contains('car') || nameLower.contains('vehicle') || nameLower.contains('transport')) {
      return 'assets/images/icons/transaction.png';
    } else if (nameLower.contains('electronic') || nameLower.contains('tech') || nameLower.contains('mobile')) {
      return 'assets/images/icons/mobileapp.png';
    } else if (nameLower.contains('health') || nameLower.contains('medical') || nameLower.contains('wellness')) {
      return 'assets/images/icons/medicalreport.png';
    } else if (nameLower.contains('education') || nameLower.contains('learn') || nameLower.contains('course')) {
      return 'assets/images/icons/onlinelearning.png';
    } else if (nameLower.contains('shop') || nameLower.contains('buy') || nameLower.contains('sell')) {
      return 'assets/images/icons/onlineshopping.png';
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