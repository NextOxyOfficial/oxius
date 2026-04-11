import 'package:flutter/foundation.dart';

/// Application configuration for different environments
/// Automatically switches between development and production based on build mode
class AppConfig {
  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');
  static const String _mediaOverride = String.fromEnvironment('MEDIA_BASE_URL');
  static const bool _useLocalDevServer = bool.fromEnvironment('USE_LOCAL_API');

  // ==================== DEVELOPMENT CONFIGURATION ====================
  // Local development is opt-in so debug builds on devices keep working
  // against the production backend unless a local server is requested.
  
  // ==================== PRODUCTION CONFIGURATION ====================
  // These are used when building Release APK (flutter build apk --release)
  static const String _prodApiBaseUrl = 'https://adsyclub.com/api';
  static const String _prodMediaBaseUrl = 'https://adsyclub.com';
  
  // ==================== ACTIVE CONFIGURATION ====================
  /// Current API base URL based on build mode
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) {
      return _apiOverride;
    }

    if (kDebugMode && _useLocalDevServer) {
      return '${_localDevHost}/api';
    }

    return _prodApiBaseUrl;
  }
  
  /// Current media base URL based on build mode
  static String get mediaBaseUrl {
    if (_mediaOverride.isNotEmpty) {
      return _mediaOverride;
    }

    if (kDebugMode && _useLocalDevServer) {
      return _localDevHost;
    }

    return _prodMediaBaseUrl;
  }
  
  /// Check if app is running in development mode
  static bool get isDevelopment => kDebugMode;
  
  /// Check if app is running in production mode
  static bool get isProduction => kReleaseMode;
  
  /// Get current environment name
  static String get environment {
    if (_apiOverride.isNotEmpty || _mediaOverride.isNotEmpty) {
      return 'Custom';
    }
    if (kDebugMode && _useLocalDevServer) {
      return 'Development';
    }
    return 'Production';
  }

  static String get _localDevHost {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
  
  // ==================== HELPER METHODS ====================
  /// Helper method to convert relative URLs to absolute
  static String getAbsoluteUrl(String? url) {
    final value = (url ?? '').trim();
    if (value.isEmpty) return '';

    final lower = value.toLowerCase();
    if (lower == 'null' || lower == 'none' || lower == 'n/a' || lower == 'na' || lower == 'undefined') {
      return '';
    }
    if (value.startsWith('https://')) return value;
    if (value.startsWith('http://')) {
      // On Android, cleartext HTTP is often blocked. Also, some CDNs redirect http->https,
      // which can break some media loaders. Only upgrade known production host.
      if (value.startsWith('http://adsyclub.com')) {
        return value.replaceFirst('http://', 'https://');
      }
      return value;
    }

    // Protocol-relative URL, e.g. //example.com/path
    if (value.startsWith('//')) return 'https:$value';

    // Host + path without scheme, e.g. adsyclub.com/media/...
    if (!value.startsWith('/') && value.contains('/')) {
      final firstSegment = value.split('/').first;
      if (firstSegment.contains('.')) {
        return 'https://$value';
      }
    }

    final path = value.startsWith('/') ? value : '/$value';
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
