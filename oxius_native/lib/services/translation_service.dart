import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // Use centralized API service base URL
  static String get baseUrl => ApiService.baseUrl;
  
  String _currentLanguage = 'en';
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
      _currentLanguage = prefs.getString('selected_language') ?? 'en';
    } catch (e) {
      print('Error loading saved language: $e');
      _currentLanguage = 'en';
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
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _availableLanguages = List<Map<String, dynamic>>.from(data['languages']);
      } else {
        // Fallback to default languages if API fails
        _availableLanguages = [
          {'code': 'en', 'name': 'English', 'native_name': 'English', 'flag': '🇺🇸'},
          {'code': 'bn', 'name': 'Bengali', 'native_name': 'বাংলা', 'flag': '🇧🇩'},
        ];
      }
    } catch (e) {
      print('Error loading available languages: $e');
      // Fallback languages
      _availableLanguages = [
        {'code': 'en', 'name': 'English', 'native_name': 'English', 'flag': '🇺🇸'},
        {'code': 'bn', 'name': 'Bengali', 'native_name': 'বাংলা', 'flag': '🇧🇩'},
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
      );

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
    return _translations[key]?.toString() ?? fallback ?? key;
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