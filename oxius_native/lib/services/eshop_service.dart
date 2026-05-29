import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class EshopService {
  static String get baseUrl => ApiService.baseUrl;
  static String get _originBase => ApiService.baseUrl.replaceFirst('/api', '');

  static Future<Map<String, String>> _jsonHeaders() async {
    final headers = await ApiService.getHeaders();
    headers['Accept'] = 'application/json';
    return headers;
  }

  static String _normalizeSearchQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> _dedupeSearchHistory(Iterable<String> searches) {
    final seen = <String>{};
    final deduped = <String>[];

    for (final raw in searches) {
      final query = _normalizeSearchQuery(raw);
      if (query.length < 3) continue;

      final key = query.toLowerCase();
      if (seen.add(key)) {
        deduped.add(query);
      }

      if (deduped.length >= 10) break;
    }

    return deduped;
  }

  static String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final u = url.startsWith('/') ? url : '/$url';
    return '$_originBase$u';
  }

  static Map<String, dynamic> _normalizeStore(Map<String, dynamic> store) {
    final normalized = Map<String, dynamic>.from(store);

    if (normalized['image'] != null) {
      normalized['image'] = _abs(normalized['image'].toString());
    }
    if (normalized['store_logo'] != null) {
      normalized['store_logo'] = _abs(normalized['store_logo'].toString());
    }
    if (normalized['store_banner'] != null) {
      normalized['store_banner'] = _abs(normalized['store_banner'].toString());
    }

    return normalized;
  }

  static List<Map<String, dynamic>> _extractProductList(dynamic data) {
    if (data is Map && data['results'] is List) {
      return List<Map<String, dynamic>>.from(
        (data['results'] as List)
            .map((e) => _transformProduct(Map<String, dynamic>.from(e))),
      );
    }
    if (data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((e) => _transformProduct(Map<String, dynamic>.from(e))),
      );
    }
    if (data is Map<String, dynamic>) {
      return [_transformProduct(data)];
    }
    return [];
  }

  // Transform backend Product model to expected frontend format
  static Map<String, dynamic> _transformProduct(
      Map<String, dynamic> backendProduct) {
    try {
      print(
          'DEBUG _transformProduct: Input product keys: ${backendProduct.keys.toList()}');

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
      print(
          'DEBUG _transformProduct: ownerDetails type: ${ownerDetails.runtimeType}');
      print('DEBUG _transformProduct: ownerDetails value: $ownerDetails');

      String storeName = 'Store'; // Default fallback
      String storeUsername = '';
      if (ownerDetails is Map<String, dynamic>) {
        print(
            'DEBUG _transformProduct: ownerDetails keys: ${ownerDetails.keys.toList()}');
        // Prioritize store_name first, then other fields
        storeName = ownerDetails['store_name']?.toString() ??
            ownerDetails['name']?.toString() ??
            ownerDetails['username']?.toString() ??
            ownerDetails['first_name']?.toString() ??
            'Store';
        storeUsername = ownerDetails['store_username']?.toString() ??
            ownerDetails['username']?.toString() ??
            '';

        print('DEBUG _transformProduct: Extracted storeName: "$storeName"');

        // Add last name if available and we're using first_name
        if (ownerDetails['first_name'] != null &&
            ownerDetails['last_name'] != null &&
            storeName == ownerDetails['first_name']?.toString() &&
            ownerDetails['last_name'].toString().isNotEmpty) {
          storeName += ' ${ownerDetails['last_name']}';
          print(
              'DEBUG _transformProduct: storeName with last name: "$storeName"');
        }
      }

      final transformed = {
        'id': backendProduct['id']?.toString() ?? '',
        'name': backendProduct['name']?.toString() ?? '',
        'title':
            backendProduct['name']?.toString() ?? '', // Alias for compatibility
        'slug': backendProduct['slug']?.toString() ?? '',
        'description': backendProduct['description']?.toString() ?? '',
        'short_description':
            backendProduct['short_description']?.toString() ?? '',
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
        'medias':
            backendProduct['image_details'] ?? [], // Alias for compatibility

        // Owner/Store information
        'owner':
            storeName, // Use the extracted store name instead of raw owner ID
        'owner_details': {
          'id': ownerDetails is Map ? ownerDetails['id']?.toString() ?? '' : '',
          'store_name': storeName,
          'name': storeName,
          'store_username': storeUsername,
          'username': ownerDetails is Map
              ? (ownerDetails['username']?.toString() ?? '')
              : '',
          'email': ownerDetails is Map
              ? (ownerDetails['email']?.toString() ?? '')
              : '',
          'image': ownerDetails is Map && ownerDetails['image'] != null
              ? _abs(ownerDetails['image'].toString())
              : null,
          'store_logo':
              ownerDetails is Map && ownerDetails['store_logo'] != null
                  ? _abs(ownerDetails['store_logo'].toString())
                  : null,
          'store_banner':
              ownerDetails is Map && ownerDetails['store_banner'] != null
                  ? _abs(ownerDetails['store_banner'].toString())
                  : null,
          'store_description': ownerDetails is Map
              ? ownerDetails['store_description']?.toString() ?? ''
              : '',
          'is_verified': ownerDetails is Map
              ? (ownerDetails['kyc'] == true ||
                  ownerDetails['is_verified'] == true)
              : false,
          'rating': ownerDetails is Map ? ownerDetails['rating'] : null,
          'followers_count':
              ownerDetails is Map ? ownerDetails['followers_count'] : null,
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
        'delivery_information':
            backendProduct['delivery_information']?.toString() ?? '',
        'delivery_fee_free': backendProduct['delivery_fee_free'] ?? 0.0,
        'delivery_fee_inside_dhaka':
            backendProduct['delivery_fee_inside_dhaka'] ?? 0.0,
        'delivery_fee_outside_dhaka':
            backendProduct['delivery_fee_outside_dhaka'] ?? 0.0,
      };

      print(
          'DEBUG _transformProduct: Final transformed owner_details: ${transformed['owner_details']}');
      return transformed;
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
        'owner': 'Store',
        'owner_details': {
          'store_name': 'Store',
          'name': 'Store',
          'store_username': '',
        },
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEshopProducts({
    String? query,
    String? categoryId,
    String? categorySlug,
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

      // Prefer category_slug over category ID (matches Vue implementation)
      if (categorySlug != null && categorySlug.isNotEmpty) {
        queryParams['category_slug'] = categorySlug;
      } else if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }

      // Correct backend path for public product listing -> api/all-products/
      // NOTE: /api/products/ is owner-only (auth-required, returns only own products)
      //       /api/all-products/ is AllProductsListView (AllowAny, supports category/search/price filters)
      final uri = Uri.parse('$baseUrl/all-products/')
          .replace(queryParameters: queryParams);
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

        if (data is Map && data['results'] is List) {
          final products = _extractProductList(data);
          print(
              'EshopService: Successfully fetched ${products.length} products (paginated)');
          return products;
        } else if (data is List) {
          final products = _extractProductList(data);
          print(
              'EshopService: Successfully fetched ${products.length} products (direct array)');
          return products;
        } else if (data is Map<String, dynamic>) {
          // Single product object
          final product = _transformProduct(data);
          print('EshopService: Successfully fetched 1 product (single object)');
          return [product];
        }
      }

      print(
          'EshopService: Failed to fetch products. Status: ${response.statusCode}');
      print('EshopService: Response body: ${response.body}');

      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching products: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchProductDetails({
    dynamic productId,
    String? slug,
  }) async {
    final candidates = <Uri>[];

    final idValue = productId?.toString();
    if (idValue != null && idValue.isNotEmpty) {
      candidates.add(Uri.parse('$baseUrl/products/$idValue/'));
    }

    if (slug != null && slug.isNotEmpty) {
      candidates.add(Uri.parse('$baseUrl/products/$slug/'));
      candidates.add(
        Uri.parse('$baseUrl/products/').replace(
          queryParameters: {
            'search': slug,
            'page_size': '20',
          },
        ),
      );
    }

    for (final uri in candidates) {
      try {
        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          continue;
        }

        final data = json.decode(response.body);
        final products = _extractProductList(data);
        if (products.isNotEmpty) {
          if (slug != null && slug.isNotEmpty) {
            for (final product in products) {
              if (product['slug']?.toString() == slug) {
                return product;
              }
            }
          }

          if (idValue != null && idValue.isNotEmpty) {
            for (final product in products) {
              if (product['id']?.toString() == idValue) {
                return product;
              }
            }
          }

          return products.first;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> fetchStoreDetails(
      String storeIdentity) async {
    try {
      final uri = Uri.parse('$baseUrl/store/$storeIdentity/');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        return _normalizeStore(data);
      }
      return null;
    } catch (e) {
      print('EshopService: Error fetching store details: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchStoreProducts({
    required String storeIdentity,
    int page = 1,
    int pageSize = 24,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/store/$storeIdentity/products/').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load store products: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final products = _extractProductList(data);
      final hasMore = data is Map && data['next'] != null;

      return {
        'products': products,
        'hasMore': hasMore,
      };
    } catch (e) {
      print('EshopService: Error fetching store products: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEshopCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/product-categories/');
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
          print(
              'EshopService: Successfully fetched ${categories.length} categories');
          return categories;
        } else if (data is List) {
          final categories = List<Map<String, dynamic>>.from(data);
          print(
              'EshopService: Successfully fetched ${categories.length} categories (direct array)');
          return categories;
        }
      }

      print(
          'EshopService: Failed to fetch categories. Status: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching categories: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProductCategories({
    bool? specialOffer,
    bool? hotArrival,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (specialOffer != null) {
        queryParams['special_offer'] = specialOffer.toString();
      }
      if (hotArrival != null) {
        queryParams['hot_arrival'] = hotArrival.toString();
      }

      final uri = Uri.parse('$baseUrl/product-categories/').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      print('EshopService: Fetching product categories from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print(
          'EshopService: Product categories response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> categories = [];

        if (data is Map && data['results'] is List) {
          categories = List<Map<String, dynamic>>.from(data['results']);
        } else if (data is List) {
          categories = List<Map<String, dynamic>>.from(data);
        }

        // Transform image URLs to absolute
        for (var category in categories) {
          if (category['image'] != null) {
            category['image'] = _abs(category['image'].toString());
          }
        }

        print(
            'EshopService: Successfully fetched ${categories.length} product categories');
        return categories;
      }

      print(
          'EshopService: Failed to fetch product categories. Status: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching product categories: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEshopBanners(
      {String endpoint = '/eshop-banner/'}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('EshopService: Fetching banners from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('EshopService: Banners response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> banners = [];

        if (data is Map && data['results'] is List) {
          banners = List<Map<String, dynamic>>.from(data['results']);
        } else if (data is List) {
          banners = List<Map<String, dynamic>>.from(data);
        }

        // Transform banner URLs to absolute
        for (var banner in banners) {
          if (banner['image'] != null) {
            banner['image'] = _abs(banner['image'].toString());
          }
          if (banner['mobile_image'] != null) {
            banner['mobile_image'] = _abs(banner['mobile_image'].toString());
          }
        }

        print('EshopService: Successfully fetched ${banners.length} banners');
        return banners;
      }

      print(
          'EshopService: Failed to fetch banners. Status: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching banners: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  // Search products by query - Uses public /all-products/ endpoint (AllowAny, supports search/name params)
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      // /all-products/ accepts both 'search' and 'name' params; send both for max compatibility
      final uri = Uri.parse('$baseUrl/all-products/').replace(queryParameters: {
        'search': query,
        'name': query,
        'page_size': '20',
        'ordering': '-created_at',
      });

      print('EshopService: Searching products with query: $query');
      print('EshopService: Search URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('EshopService: Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> products = [];

        if (data is Map && data.containsKey('results')) {
          // Paginated response
          final results = data['results'];
          if (results is List) {
            for (var item in results) {
              if (item is Map<String, dynamic>) {
                try {
                  products.add(_transformProduct(item));
                } catch (e) {
                  print('EshopService: Error transforming search result: $e');
                }
              }
            }
          }
        } else if (data is List) {
          // Direct array response
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              try {
                products.add(_transformProduct(item));
              } catch (e) {
                print('EshopService: Error transforming search result: $e');
              }
            }
          }
        }

        print(
            'EshopService: Successfully searched ${products.length} products for query: "$query"');

        // NOTE: Search history is saved explicitly from the UI layer on user
        // intent (submit / suggestion tap) — NOT here. Saving on every API
        // call caused duplicates because each debounced keystroke fired a
        // search and each one was persisted.

        return products;
      }

      print('EshopService: Search failed. Status: ${response.statusCode}');
      print('EshopService: Response body: ${response.body}');
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error searching products: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  // Get recent search history from backend
  static Future<List<String>> getSearchHistory() async {
    try {
      final uri = Uri.parse('$baseUrl/search-history/');
      print('EshopService: Fetching search history from: $uri');
      final headers = await _jsonHeaders();

      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print(
          'EshopService: Search history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<String> searches = [];

        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic> && item['query'] != null) {
              searches.add(item['query'].toString());
            }
          }
        }

        final deduped = _dedupeSearchHistory(searches);
        print(
            'EshopService: Successfully fetched ${deduped.length} search history items');
        return deduped;
      }

      print(
          'EshopService: Failed to fetch search history. Status: ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('EshopService: Error fetching search history: $e');
      print('EshopService: Stack trace: $stackTrace');
      return [];
    }
  }

  // Save search query to history
  static Future<bool> saveSearchHistory(String query) async {
    try {
      final normalizedQuery = _normalizeSearchQuery(query);
      if (normalizedQuery.length < 3) return false;

      final uri = Uri.parse('$baseUrl/search-history/save/');
      final headers = await _jsonHeaders();

      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode({
              'query': normalizedQuery,
              'search_type': 'product',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data is Map && data['saved'] == false) {
          print('EshopService: Search history was not saved for anonymous user');
          return false;
        }
        print(
            'EshopService: Search history saved for query: "$normalizedQuery"');
        return true;
      } else {
        print(
            'EshopService: Failed to save search history. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('EshopService: Error saving search history: $e');
      return false;
    }
  }

  // Delete a single search history item by query string
  static Future<bool> deleteSearchHistoryItem(String query) async {
    try {
      final normalizedQuery = _normalizeSearchQuery(query);
      if (normalizedQuery.isEmpty) return true;

      final uri = Uri.parse('$baseUrl/search-history/delete/');
      final headers = await _jsonHeaders();

      final response = await http
          .delete(
            uri,
            headers: headers,
            body: json.encode({'query': normalizedQuery}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('EshopService: Search item deleted: $normalizedQuery');
        return true;
      }

      print(
          'EshopService: Failed to delete search item. Status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('EshopService: Error deleting search item: $e');
      return false;
    }
  }

  // Clear all search history
  static Future<bool> clearSearchHistory() async {
    try {
      final uri = Uri.parse('$baseUrl/search-history/clear/');
      final headers = await _jsonHeaders();

      final response = await http
          .delete(
            uri,
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('EshopService: Search history cleared');
        return true;
      }

      print(
          'EshopService: Failed to clear search history. Status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('EshopService: Error clearing search history: $e');
      return false;
    }
  }

  // Get eShop logo (different from main logo)
  static Future<String?> getEshopLogo() async {
    try {
      final uri = Uri.parse('$baseUrl/eshop-logo/');
      print('EshopService: Fetching eShop logo from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      print('EshopService: Logo response status: ${response.statusCode}');
      print('EshopService: Logo response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logoUrl = data['image']?.toString();
        print('EshopService: Raw logo URL from backend: $logoUrl');
        if (logoUrl != null && logoUrl.isNotEmpty) {
          final absoluteUrl = _abs(logoUrl);
          print('EshopService: Absolute logo URL: $absoluteUrl');
          return absoluteUrl;
        } else {
          print('EshopService: Logo URL is null or empty');
        }
      }

      print('EshopService: Returning null for logo');
      return null;
    } catch (e) {
      print('EshopService: Error fetching eshop logo: $e');
      return null;
    }
  }
}
