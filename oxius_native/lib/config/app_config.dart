class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://adsyclub.com/api';
  static const String mediaBaseUrl = 'https://adsyclub.com';
  
  // Alternative for development (comment out for production)
  // static const String apiBaseUrl = 'http://localhost:8000/api';
  // static const String mediaBaseUrl = 'http://localhost:8000';
  
  // Helper method to convert relative URLs to absolute
  static String getAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return '$mediaBaseUrl$path';
  }
}
