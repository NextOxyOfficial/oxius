import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing offline cache data
class OfflineCacheService {
  static const String _newsKey = 'cached_news_posts';
  static const String _productsKey = 'cached_products';
  static const String _salePostsKey = 'cached_sale_posts';
  static const String _bannersKey = 'cached_banners';
  static const String _lastUpdateKey = 'cache_last_update';
  
  /// Cache duration - 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);
  
  /// Cache news posts for offline viewing
  static Future<void> cacheNewsPosts(List<Map<String, dynamic>> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(posts);
      await prefs.setString(_newsKey, jsonString);
      await prefs.setString('${_newsKey}_timestamp', DateTime.now().toIso8601String());
      print('✅ Cached ${posts.length} news posts');
    } catch (e) {
      print('❌ Error caching news posts: $e');
    }
  }
  
  /// Get cached news posts
  static Future<List<Map<String, dynamic>>?> getCachedNewsPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_newsKey);
      final timestampString = prefs.getString('${_newsKey}_timestamp');
      
      if (jsonString == null || timestampString == null) return null;
      
      // Check if cache is still valid
      final timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        await prefs.remove(_newsKey);
        await prefs.remove('${_newsKey}_timestamp');
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error getting cached news posts: $e');
      return null;
    }
  }
  
  /// Cache products for offline viewing
  static Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(products);
      await prefs.setString(_productsKey, jsonString);
      await prefs.setString('${_productsKey}_timestamp', DateTime.now().toIso8601String());
      print('✅ Cached ${products.length} products');
    } catch (e) {
      print('❌ Error caching products: $e');
    }
  }
  
  /// Get cached products
  static Future<List<Map<String, dynamic>>?> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_productsKey);
      final timestampString = prefs.getString('${_productsKey}_timestamp');
      
      if (jsonString == null || timestampString == null) return null;
      
      // Check if cache is still valid
      final timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        await prefs.remove(_productsKey);
        await prefs.remove('${_productsKey}_timestamp');
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error getting cached products: $e');
      return null;
    }
  }
  
  /// Cache sale posts for offline viewing
  static Future<void> cacheSalePosts(List<Map<String, dynamic>> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(posts);
      await prefs.setString(_salePostsKey, jsonString);
      await prefs.setString('${_salePostsKey}_timestamp', DateTime.now().toIso8601String());
      print('✅ Cached ${posts.length} sale posts');
    } catch (e) {
      print('❌ Error caching sale posts: $e');
    }
  }
  
  /// Get cached sale posts
  static Future<List<Map<String, dynamic>>?> getCachedSalePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_salePostsKey);
      final timestampString = prefs.getString('${_salePostsKey}_timestamp');
      
      if (jsonString == null || timestampString == null) return null;
      
      // Check if cache is still valid
      final timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        await prefs.remove(_salePostsKey);
        await prefs.remove('${_salePostsKey}_timestamp');
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error getting cached sale posts: $e');
      return null;
    }
  }
  
  /// Cache banners for offline viewing
  static Future<void> cacheBanners(List<Map<String, dynamic>> banners) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(banners);
      await prefs.setString(_bannersKey, jsonString);
      await prefs.setString('${_bannersKey}_timestamp', DateTime.now().toIso8601String());
      print('✅ Cached ${banners.length} banners');
    } catch (e) {
      print('❌ Error caching banners: $e');
    }
  }
  
  /// Get cached banners
  static Future<List<Map<String, dynamic>>?> getCachedBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_bannersKey);
      final timestampString = prefs.getString('${_bannersKey}_timestamp');
      
      if (jsonString == null || timestampString == null) return null;
      
      // Check if cache is still valid
      final timestamp = DateTime.parse(timestampString);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        await prefs.remove(_bannersKey);
        await prefs.remove('${_bannersKey}_timestamp');
        return null;
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error getting cached banners: $e');
      return null;
    }
  }
  
  /// Check if we have any cached data
  static Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_newsKey) || 
             prefs.containsKey(_productsKey) || 
             prefs.containsKey(_salePostsKey) ||
             prefs.containsKey(_bannersKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_newsKey);
      await prefs.remove('${_newsKey}_timestamp');
      await prefs.remove(_productsKey);
      await prefs.remove('${_productsKey}_timestamp');
      await prefs.remove(_salePostsKey);
      await prefs.remove('${_salePostsKey}_timestamp');
      await prefs.remove(_bannersKey);
      await prefs.remove('${_bannersKey}_timestamp');
      print('✅ Cleared all cache');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
  
  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'news_cached': prefs.containsKey(_newsKey),
        'products_cached': prefs.containsKey(_productsKey),
        'sale_posts_cached': prefs.containsKey(_salePostsKey),
        'banners_cached': prefs.containsKey(_bannersKey),
        'news_timestamp': prefs.getString('${_newsKey}_timestamp'),
        'products_timestamp': prefs.getString('${_productsKey}_timestamp'),
        'sale_posts_timestamp': prefs.getString('${_salePostsKey}_timestamp'),
        'banners_timestamp': prefs.getString('${_bannersKey}_timestamp'),
      };
    } catch (e) {
      return {};
    }
  }
}
