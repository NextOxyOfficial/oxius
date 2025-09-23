import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class SaleService {
  static String get _originBase => ApiService.baseUrl.replaceFirst('/api', '');
  static String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // ensure leading slash
    final u = url.startsWith('/') ? url : '/$url';
    return '$_originBase$u';
  }

  static Future<List<dynamic>> fetchCategories() async {
    final resp = await http.get(Uri.parse('${ApiService.baseUrl}/sale/categories/'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load sale categories: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    final list = data is List ? data : (data['results'] ?? []);
    // Normalize icon to absolute URL
    return List<Map<String, dynamic>>.from(list.map((e) => {
          ...Map<String, dynamic>.from(e),
          'icon': _abs(e['icon']),
        }));
  }

  static Future<List<dynamic>> fetchBanners() async {
    final resp = await http.get(Uri.parse('${ApiService.baseUrl}/sale/banners/'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load sale banners: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    final list = data is List ? data : (data['results'] ?? []);
    // Normalize image and nested category icon if present
    return List<Map<String, dynamic>>.from(list.map((e) => {
          ...Map<String, dynamic>.from(e),
          'image': _abs(e['image']),
          if (e['category_details'] != null)
            'category_details': {
              ...Map<String, dynamic>.from(e['category_details']),
              'icon': _abs(e['category_details']['icon']),
            }
        }));
  }

  static Future<Map<String, dynamic>> fetchPosts({required int categoryId, int page = 1}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/sale/posts/?category=$categoryId&page=$page');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load sale posts: ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    // Ensure results list exists
    if (data is List) {
      // Unpaginated safety
      return {
        'results': data,
        'next': null,
        'previous': null,
        'count': data.length,
      };
    }
    return data;
  }
}
