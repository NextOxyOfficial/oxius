import 'package:flutter/foundation.dart';

/// Application configuration for different environments
/// Automatically switches between development and production based on build mode
class AppConfig {
  // ==================== DEVELOPMENT CONFIGURATION ====================
  // These are used when running in Debug mode (flutter run)
  static const String _devApiBaseUrl = 'http://localhost:8000/api';
  static const String _devMediaBaseUrl = 'http://localhost:8000';
  
  // ==================== PRODUCTION CONFIGURATION ====================
  // These are used when building Release APK (flutter build apk --release)
  static const String _prodApiBaseUrl = 'https://adsyclub.com/api';
  static const String _prodMediaBaseUrl = 'https://adsyclub.com';
  
  // ==================== ACTIVE CONFIGURATION ====================
  /// Current API base URL based on build mode
  static String get apiBaseUrl {
    if (kDebugMode) {
      return _devApiBaseUrl;
    } else {
      return _prodApiBaseUrl;
    }
  }
  
  /// Current media base URL based on build mode
  static String get mediaBaseUrl {
    if (kDebugMode) {
      return _devMediaBaseUrl;
    } else {
      return _prodMediaBaseUrl;
    }
  }
  
  /// Check if app is running in development mode
  static bool get isDevelopment => kDebugMode;
  
  /// Check if app is running in production mode
  static bool get isProduction => kReleaseMode;
  
  /// Get current environment name
  static String get environment => kDebugMode ? 'Development' : 'Production';
  
  // ==================== HELPER METHODS ====================
  /// Helper method to convert relative URLs to absolute
  static String getAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return '$mediaBaseUrl$path';
  }
  
  /// Print current configuration (for debugging)
  static void printConfig() {
    if (kDebugMode) {
      print('╔═══════════════════════════════════════════════════════════════╗');
      print('║               APP CONFIGURATION                               ║');
      print('╠═══════════════════════════════════════════════════════════════╣');
      print('║ Environment: $environment');
      print('║ API URL:     $apiBaseUrl');
      print('║ Media URL:   $mediaBaseUrl');
      print('║ Debug Mode:  $isDevelopment');
      print('╚═══════════════════════════════════════════════════════════════╝');
    }
  }
}
