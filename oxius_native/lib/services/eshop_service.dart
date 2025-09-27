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
  
  // Transform backend Product model to expected frontend format
  static Map<String, dynamic> _transformProduct(Map<String, dynamic> backendProduct) {
    try {
      // Extract image from image_details (ProductMediaSerializer)
      String? imageUrl;
      final imageDetails = backendProduct['image_details'];
      if (imageDetails is List && imageDetails.isNotEmpty) {
        final firstImage = imageDetails.first;
        if (firstImage is Map<String, dynamic> && firstImage['image'] != null) {
          imageUrl = _abs(firstImage['image'].toString());
        }
      }
      
      // Extract store name from owner_details (UserSerializer)  
      final ownerDetails = backendProduct['owner_details'];
      String storeName = 'Store'; // Default fallback
      if (ownerDetails is Map<String, dynamic>) {
        storeName = ownerDetails['name']?.toString() ??
                    ownerDetails['store_name']?.toString() ??
                    ownerDetails['username']?.toString() ??
                    ownerDetails['first_name']?.toString() ??
                    'Store';
        
        // Add last name if available
        if (storeName != 'Store' && ownerDetails['last_name'] != null && ownerDetails['last_name'].toString().isNotEmpty) {
          storeName += ' ${ownerDetails['last_name']}';
        }
      }
      
      return {
        'id': backendProduct['id']?.toString() ?? '',
        'name': backendProduct['name']?.toString() ?? '',
        'title': backendProduct['name']?.toString() ?? '', // Alias for compatibility
        'slug': backendProduct['slug']?.toString() ?? '',
        'description': backendProduct['description']?.toString() ?? '',
        'short_description': backendProduct['short_description']?.toString() ?? '',
        'regular_price': backendProduct['regular_price'] ?? 0.0,
        'sale_price': backendProduct['sale_price'],
        'price': backendProduct['regular_price'] ?? 0.0, // Fallback alias
        'quantity': backendProduct['quantity'] ?? 0,
        'is_featured': backendProduct['is_featured'] ?? false,
        'is_free_delivery': backendProduct['is_free_delivery'] ?? false,
        'is_active': backendProduct['is_active'] ?? true,
        'views': backendProduct['views'] ?? 0,
        'created_at': backendProduct['created_at']?.toString() ?? '',
        'updated_at': backendProduct['updated_at']?.toString() ?? '',
        'weight': backendProduct['weight'] ?? 0.0,
        'keywords': backendProduct['keywords']?.toString() ?? '',
        
        // Images
        'image': imageUrl ?? '',
        'image_details': backendProduct['image_details'] ?? [],
        'medias': backendProduct['image_details'] ?? [], // Alias for compatibility
        
        // Owner/Store information
        'owner': backendProduct['owner']?.toString() ?? '',
        'owner_details': {
          'store_name': storeName,
          'name': storeName,
          'username': ownerDetails is Map ? (ownerDetails['username']?.toString() ?? '') : '',
          'email': ownerDetails is Map ? (ownerDetails['email']?.toString() ?? '') : '',
          'image': ownerDetails is Map && ownerDetails['image'] != null ? _abs(ownerDetails['image'].toString()) : null,
        },
        
        // Categories
        'category': backendProduct['category'] ?? [],
        'category_details': backendProduct['category_details'] ?? [],
        
        // Additional product details
        'benefits': backendProduct['benefits'] ?? [],
        'faqs': backendProduct['faqs'] ?? [],
        'trust_badges': backendProduct['trust_badges'] ?? [],
        'order_count': backendProduct['order_count'] ?? 0,
        'total_items_ordered': backendProduct['total_items_ordered'] ?? 0,
        
        // Delivery information
        'delivery_information': backendProduct['delivery_information']?.toString() ?? '',
        'delivery_fee_free': backendProduct['delivery_fee_free'] ?? 0.0,
        'delivery_fee_inside_dhaka': backendProduct['delivery_fee_inside_dhaka'] ?? 0.0,
        'delivery_fee_outside_dhaka': backendProduct['delivery_fee_outside_dhaka'] ?? 0.0,
      };
    } catch (e) {
      print('EshopService: Error transforming product: $e');
      // Return minimal safe product structure
      return {
        'id': backendProduct['id']?.toString() ?? '',
        'name': backendProduct['name']?.toString() ?? 'Product',
        'title': backendProduct['name']?.toString() ?? 'Product',
        'regular_price': backendProduct['regular_price'] ?? 0.0,
        'sale_price': backendProduct['sale_price'],
        'price': backendProduct['regular_price'] ?? 0.0,
        'is_free_delivery': backendProduct['is_free_delivery'] ?? false,
        'image': '',
        'image_details': [],
        'owner_details': {
          'store_name': 'Store',
          'name': 'Store',
        },
      };
    }
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

  // Correct backend path for products -> api/products/ (base.urls included at api/)
  final uri = Uri.parse('$baseUrl/products/').replace(queryParameters: queryParams);
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
            
            // Transform backend Product model to expected format
            return _transformProduct(m);
          }));
        }

        if (data is Map && data['results'] is List) {
          final products = _normalize(data['results']);
          print('EshopService: Successfully fetched ${products.length} products (paginated)');
          return products;
        } else if (data is List) {
          final products = _normalize(data);
          print('EshopService: Successfully fetched ${products.length} products (direct array)');
          return products;
        } else if (data is Map<String, dynamic>) {
          // Single product object
          final product = _transformProduct(data);
          print('EshopService: Successfully fetched 1 product (single object)');
          return [product];
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