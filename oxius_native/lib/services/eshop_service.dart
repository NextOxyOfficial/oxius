import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class EshopService {
  static String get baseUrl => ApiService.baseUrl;
  static String get _originBase => ApiService.baseUrl.replaceFirst('/api', '');

  static String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final u = url.startsWith('/') ? url : '/$url';
    return '$_originBase$u';
  }
  
  static Future<List<Map<String, dynamic>>> fetchEshopProducts({
    String? query,
    String? categoryId,
    int page = 1,
    int pageSize = 12,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }

  // Correct backend path based on Django urls.py -> api/sale/posts/
  final uri = Uri.parse('$baseUrl/sale/posts/').replace(queryParameters: queryParams);
      print('EshopService: Fetching products from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('EshopService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> _normalize(List list) {
          return List<Map<String, dynamic>>.from(list.map((e) {
            final m = Map<String, dynamic>.from(e);
            // Top-level image fields
            if (m['image'] is String) m['image'] = _abs(m['image']);
            if (m['main_image'] is String) m['main_image'] = _abs(m['main_image']);
            // medias array
            if (m['medias'] is List) {
              m['medias'] = (m['medias'] as List).map((it) {
                if (it is Map && it['image'] is String) {
                  return {...it, 'image': _abs(it['image'])};
                }
                return it;
              }).toList();
            }
            // image_details array
            if (m['image_details'] is List) {
              m['image_details'] = (m['image_details'] as List).map((it) {
                if (it is Map && it['image'] is String) {
                  return {...it, 'image': _abs(it['image'])};
                }
                if (it is String) return _abs(it);
                return it;
              }).toList();
            }
            return m;
          }));
        }

        if (data is Map && data['results'] is List) {
          final products = _normalize(data['results']);
          print('EshopService: Successfully fetched ${products.length} products');
          return products;
        } else if (data is List) {
          final products = _normalize(data);
          print('EshopService: Successfully fetched ${products.length} products (direct array)');
          return products;
        }
      }
      
      print('EshopService: Failed to fetch products. Status: ${response.statusCode}');
      print('EshopService: Response body: ${response.body}');
      
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching products: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEshopCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/eshop/categories/');
      print('EshopService: Fetching categories from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('EshopService: Categories response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data['results'] is List) {
          final categories = List<Map<String, dynamic>>.from(data['results']);
          print('EshopService: Successfully fetched ${categories.length} categories');
          return categories;
        } else if (data is List) {
          final categories = List<Map<String, dynamic>>.from(data);
          print('EshopService: Successfully fetched ${categories.length} categories (direct array)');
          return categories;
        }
      }
      
      print('EshopService: Failed to fetch categories. Status: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching categories: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  // Mock data fallback for development
  static List<Map<String, dynamic>> getMockProducts() {
    return [
      {
        'id': '1',
        'title': 'Wireless Bluetooth Headphones',
        'price': '2500',
        'image': 'https://placehold.co/300x200?text=Headphones',
        'category': 'Electronics',
        'location': 'Dhaka',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Headphones'}
        ],
      },
      {
        'id': '2',
        'title': 'Smart Watch Series 6',
        'price': '15000',
        'image': 'https://placehold.co/300x200?text=Smart+Watch',
        'category': 'Electronics',
        'location': 'Chittagong',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Smart+Watch'}
        ],
      },
      {
        'id': '3',
        'title': 'Cotton T-Shirt Premium Quality',
        'price': '800',
        'image': 'https://placehold.co/300x200?text=T-Shirt',
        'category': 'Fashion',
        'location': 'Sylhet',
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=T-Shirt'}
        ],
      },
      {
        'id': '4',
        'title': 'Gaming Mouse RGB LED',
        'price': '1200',
        'image': 'https://placehold.co/300x200?text=Gaming+Mouse',
        'category': 'Electronics',
        'location': 'Rajshahi',
        'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Gaming+Mouse'}
        ],
      },
      {
        'id': '5',
        'title': 'Organic Green Tea 500g',
        'price': '450',
        'image': 'https://placehold.co/300x200?text=Green+Tea',
        'category': 'Food & Beverage',
        'location': 'Khulna',
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        'medias': [
          {'image': 'https://placehold.co/300x200?text=Green+Tea'}
        ],
      },
    ];
  }
}