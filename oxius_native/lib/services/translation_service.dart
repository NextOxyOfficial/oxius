import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const Map<String, Map<String, String>> _localFallbackTranslations = {
    'en': {
      'premium_access': 'Premium Access',
      'current_plan': 'Current Plan',
      'pro': 'Pro',
      'free': 'Free',
      'upgrade_pro': 'Upgrade to Pro',
      'upgrade_pro_text': 'Get premium features',
      'pro_member': 'Pro Membership',
      'classified_service': 'My Services',
      'post_free_ad': 'Post Free Service',
      'business_network': 'Business Network',
      'breaking_news': 'Breaking News',
      'adsy_news': 'Adsy News',
      'verification': 'Verification',
      'adsy_pay': 'Adsy Pay',
      'mobile_recharge': 'Mobile Recharge',
      'settings': 'Settings',
      'logout': 'Logout',
      'eshop_manager': 'E-Shop Manager',
      'shop_manager': 'Shop Manager',
      'my_services_subtitle': 'Browse and post services',
      'post_free_service': 'Post Free Service',
      'loading_services': 'Loading services...',
      'classified_search_placeholder': 'Search services, categories...',
      'classified_search_helper': 'Find services by title or category',
      'classified_live_search': 'Search',
      'clear_search': 'Clear',
      'search_results_categories': 'Categories',
      'search_results_services': 'Services',
      'classified_loading_more': 'Loading more...',
      'classified_all_results_loaded': 'All results loaded',
      'classified_no_results_found': 'No results found',
      'classified_try_different_keywords': 'Try different keywords',
      'recent_post': 'Recent Posts',
      'no_recent_posts': 'No recent posts',
      'posts_loaded': 'Posts loaded',
      'popular_packages': 'Popular Packages',
      'all_packages': 'All Packages',
      'recharge_now': 'Recharge Now',
    },
    'bn': {
      'premium_access': 'প্রিমিয়াম অ্যাক্সেস',
      'current_plan': 'বর্তমান প্ল্যান',
      'pro': 'প্রো',
      'free': 'ফ্রি',
      'upgrade_pro': 'প্রো প্যাকেজ নিই',
      'upgrade_pro_text': 'প্রিমিয়াম ফিচার পান',
      'pro_member': 'প্রো মেম্বার',
      'classified_service': 'আমার সেবা',
      'post_free_ad': 'ফ্রি সেবা বিজ্ঞাপন দিই',
      'business_network': 'বিজনেস নেটওয়ার্ক',
      'breaking_news': '\u09ac\u09bf\u09b6\u09c7\u09b7 \u09b8\u0982\u09ac\u09be\u09a6',
      'adsy_news': 'নিউজ',
      'verification': 'ভেরিফিকেশন',
      'adsy_pay': 'অ্যাডজি পে',
      'mobile_recharge': 'মোবাইল রিচার্জ',
      'settings': 'সেটিংস্‌',
      'logout': 'লগ আউট',
      'eshop_manager': 'ই-শপ ম্যানেজার',
      'shop_manager': 'শপ ম্যানেজার',
      'my_services_subtitle': 'সেবা খুঁজুন এবং পোস্ট করুন',
      'post_free_service': 'ফ্রি সার্ভিস পোস্ট করুন',
      'loading_services': 'সেবাসমূহ লোড হচ্ছে...',
      'classified_search_placeholder': 'সেবা বা ক্যাটাগরি খুঁজুন...',
      'classified_search_helper': 'নাম বা ক্যাটাগরি দিয়ে সেবা খুঁজুন',
      'classified_live_search': 'সার্চ',
      'clear_search': 'মুছুন',
      'search_results_categories': 'ক্যাটাগরি',
      'search_results_services': 'সেবাসমূহ',
      'classified_loading_more': 'আরও লোড হচ্ছে...',
      'classified_all_results_loaded': 'সব ফলাফল দেখা হয়েছে',
      'classified_no_results_found': 'কোনো ফলাফল পাওয়া যায়নি',
      'classified_try_different_keywords': 'অন্য কীওয়ার্ড দিয়ে চেষ্টা করুন',      'recent_post': 'সাম্প্রতিক পোস্ট',
      'no_recent_posts': 'কোনো সাম্প্রতিক পোস্ট নেই',
      'posts_loaded': 'পোস্ট লোড হয়েছে',
      'popular_packages': 'জনপ্রিয় প্যাকেজ',
      'all_packages': 'সব প্যাকেজ',
      'recharge_now': 'রিচার্জ করুন',
    },
  };

  // Use centralized API service base URL
  static String get baseUrl => ApiService.baseUrl;
  
  String _currentLanguage = 'bn';
  Map<String, dynamic> _translations = {};
  List<Map<String, dynamic>> _availableLanguages = [];
  bool _isLoading = false;
  bool _initialized = false;

  String get currentLanguage => _currentLanguage;
  List<Map<String, dynamic>> get availableLanguages => _availableLanguages;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  /// Initialize the translation service
  Future<void> initialize() async {
    if (_initialized) return;
    await _loadSavedLanguage();
    await loadAvailableLanguages();
    await loadTranslations(_currentLanguage);
    _initialized = true;
    notifyListeners();
  }

  /// Load saved language preference from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('selected_language') ?? 'bn';
    } catch (e) {
      print('Error loading saved language: $e');
      _currentLanguage = 'bn';
    }
  }

  /// Save language preference to SharedPreferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  /// Load available languages from backend API
  Future<void> loadAvailableLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/languages/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _availableLanguages = List<Map<String, dynamic>>.from(data['languages']);
      } else {
        // Fallback to default languages if API fails
        _availableLanguages = [
          {'code': 'bn', 'name': 'Bengali', 'native_name': 'বাংলা', 'flag': '🇧🇩'},
          {'code': 'en', 'name': 'English', 'native_name': 'English', 'flag': '🇺🇸'},
        ];
      }
    } catch (e) {
      print('Error loading available languages: $e');
      // Fallback languages
      _availableLanguages = [
        {'code': 'bn', 'name': 'Bengali', 'native_name': 'বাংলা', 'flag': '🇧🇩'},
        {'code': 'en', 'name': 'English', 'native_name': 'English', 'flag': '🇺🇸'},
      ];
    }
  }

  /// Load translations for a specific language from backend API
  Future<bool> loadTranslations(String languageCode) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    
    try {
      // First try to load from cache
      final cachedTranslations = await _loadCachedTranslations(languageCode);
      if (cachedTranslations != null) {
        _translations = cachedTranslations;
        _currentLanguage = languageCode;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Load from API
      final response = await http.get(
        Uri.parse('$baseUrl/translations/$languageCode/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _translations = Map<String, dynamic>.from(data['translations']);
        _currentLanguage = languageCode;
        
        // Cache the translations
        await _cacheTranslations(languageCode, _translations);
        await _saveLanguage(languageCode);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('Error loading translations: ${response.statusCode}');
        _isLoading = false;
        return false;
      }
    } catch (e) {
      print('Error loading translations: $e');
      _isLoading = false;
      return false;
    }
  }

  /// Cache translations to SharedPreferences
  Future<void> _cacheTranslations(String languageCode, Map<String, dynamic> translations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'translations_$languageCode';
      await prefs.setString(cacheKey, json.encode(translations));
      
      // Store cache timestamp
      await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching translations: $e');
    }
  }

  /// Load cached translations from SharedPreferences
  Future<Map<String, dynamic>?> _loadCachedTranslations(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'translations_$languageCode';
      
      // Check if cache exists and is not too old (24 hours)
      final timestamp = prefs.getInt('${cacheKey}_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - timestamp;
      const maxCacheAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
      
      if (cacheAge > maxCacheAge) {
        return null; // Cache is too old
      }
      
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        return Map<String, dynamic>.from(json.decode(cachedString));
      }
    } catch (e) {
      print('Error loading cached translations: $e');
    }
    return null;
  }

  /// Get translation for a key
  String translate(String key, {String? fallback}) {
    final translatedValue = _translations[key]?.toString();
    if (translatedValue != null && translatedValue.isNotEmpty && !_shouldPreferFallback(key, translatedValue)) {
      return translatedValue;
    }

    final normalizedLanguageCode = _currentLanguage.split(RegExp(r'[-_]')).first;
    final localFallback = _localFallbackTranslations[_currentLanguage]?[key] ??
        _localFallbackTranslations[normalizedLanguageCode]?[key];
    if (localFallback != null && localFallback.isNotEmpty) {
      return localFallback;
    }

    return fallback ?? key;
  }

  bool _shouldPreferFallback(String key, String translatedValue) {
    final normalizedValue = _normalizeTranslationToken(translatedValue);
    final normalizedKey = _normalizeTranslationToken(key);

    if (normalizedValue.isEmpty) {
      return true;
    }

    if (normalizedValue == normalizedKey) {
      return true;
    }

    if (!_currentLanguage.startsWith('en')) {
      final englishFallback = _localFallbackTranslations['en']?[key];
      if (englishFallback != null &&
          _normalizeTranslationToken(englishFallback) == normalizedValue) {
        return true;
      }
    }

    if (key == 'adsy_pay' && !_currentLanguage.startsWith('en')) {
      return _isMalformedAdsyPayTranslation(normalizedValue);
    }

    return false;
  }

  bool _isMalformedAdsyPayTranslation(String normalizedValue) {
    if (normalizedValue.isEmpty) {
      return true;
    }

    return normalizedValue == 'adsypay' ||
        normalizedValue == 'adsypayment' ||
        normalizedValue == 'adsyclubpay' ||
        normalizedValue.contains('adsypay');
  }

  String _normalizeTranslationToken(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0980-\u09ff]+'), '');
  }

  /// Short form of translate method (similar to Vue.js $t)
  String t(String key, {String? fallback}) {
    return translate(key, fallback: fallback);
  }

  /// Change current language
  Future<bool> changeLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return true;
    
    final ok = await loadTranslations(languageCode);
    if (ok) notifyListeners();
    return ok;
  }

  /// Clear all cached translations
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('translations_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get language info by code
  Map<String, dynamic>? getLanguageInfo(String code) {
    return _availableLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'code': code, 'name': code, 'native_name': code, 'flag': '🌐'},
    );
  }
}
