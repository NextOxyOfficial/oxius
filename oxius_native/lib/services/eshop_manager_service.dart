import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import '../models/eshop_manager_models.dart';
import '../utils/api_error.dart';

class EshopManagerService {
  static String get baseUrl => ApiService.baseUrl;

  /// Get product slot packages
  static Future<List<Map<String, dynamic>>> getProductSlotPackages() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/product-slot-packages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Product slot packages response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching product slot packages: $e');
      return [];
    }
  }

  /// Purchase product slots
  static Future<Map<String, dynamic>> purchaseProductSlots({
    required dynamic packageId,
    required int slotCount,
    required double cost,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      print('📦 Purchasing slots - Package ID: $packageId, Slots: $slotCount, Cost: $cost');

      final response = await http.post(
        Uri.parse('$baseUrl/purchase-product-slots/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'package_id': packageId.toString(),
          'slot_count': slotCount,
          'cost': cost,
        }),
      );

      print('📦 Purchase slots response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorBody = response.body;
        print('❌ Purchase failed with body: $errorBody');
        try {
          final error = json.decode(errorBody);
          return {
            'success': false,
            'message': error['error'] ?? error['message'] ?? error['detail'] ?? 'Purchase failed',
          };
        } catch (e) {
          return {
            'success': false,
            'message': errorBody.isNotEmpty ? errorBody : 'Purchase failed',
          };
        }
      }
    } catch (e) {
      print('❌ Error purchasing slots: $e');
      return {
        'success': false,
        'message': 'Failed to purchase slots: $e',
      };
    }
  }

  /// Get product categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/product-categories/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Categories response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  /// Get store details by username
  static Future<StoreDetails?> getStoreDetails(String storeUsername) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/store/$storeUsername/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Store details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StoreDetails.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching store details: $e');
      return null;
    }
  }

  /// Update store information
  static Future<Map<String, dynamic>> updateStoreInfo({
    required String storeUsername,
    required String storeName,
    String? storeAddress,
    String? storeDescription,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/store/$storeUsername/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'store_name': storeName,
          'store_address': storeAddress ?? '',
          'store_description': storeDescription ?? '',
        }),
      );

      print('📦 Update store response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['store_name']?[0] ?? error['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      print('❌ Error updating store: $e');
      return {
        'success': false,
        'message': 'Failed to update store: $e',
      };
    }
  }

  /// Get seller's products with pagination
  static Future<Map<String, dynamic>> getMyProducts({int page = 1}) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        print('❌ No token for products');
        return {'products': [], 'hasMore': false, 'total': 0};
      }

      print('🔍 Fetching products (page $page)...');
      final response = await http.get(
        Uri.parse('$baseUrl/my-products/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('✅ Products response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Data type: ${data.runtimeType}');
        
        List<dynamic> productsList;
        bool hasMore = false;
        int total = 0;
        
        if (data is Map && data['results'] != null) {
          productsList = data['results'];
          hasMore = data['next'] != null;
          total = data['count'] ?? 0;
          print('📦 Found ${productsList.length} products on page $page (total: $total, hasMore: $hasMore)');
        } else if (data is List) {
          productsList = data;
          print('📦 Found ${productsList.length} products (list)');
        } else {
          print('❌ Unexpected data structure');
          return {'products': [], 'hasMore': false, 'total': 0};
        }

        final products = productsList.map((item) {
          try {
            final product = ShopProduct.fromJson(item);
            return product;
          } catch (e) {
            print('❌ Error parsing product: $e');
            return null;
          }
        }).whereType<ShopProduct>().toList();
        
        print('✅ Parsed ${products.length} products successfully');
        return {
          'products': products,
          'hasMore': hasMore,
          'total': total,
        };
      }
      
      print('❌ Bad response: ${response.statusCode}');
      return {'products': [], 'hasMore': false, 'total': 0};
    } catch (e) {
      print('❌ Exception: $e');
      return {'products': [], 'hasMore': false, 'total': 0};
    }
  }

  /// Get seller's orders
  static Future<List<ShopOrder>> getSellerOrders() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        print('❌ No token for seller orders');
        throw Exception('Not authenticated');
      }

      print('📦 Fetching seller orders from: $baseUrl/seller-orders/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/seller-orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Seller orders response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Data type: ${data.runtimeType}');
        
        List<dynamic> ordersList;
        if (data is Map && data['results'] != null) {
          ordersList = data['results'];
          print('📦 Found ${ordersList.length} orders in paginated response');
          if (data['count'] != null) {
            print('📦 Total orders count: ${data['count']}');
          }
        } else if (data is List) {
          ordersList = data;
          print('📦 Found ${ordersList.length} orders in list response');
        } else {
          print('❌ Unexpected data structure: $data');
          ordersList = [];
        }

        if (ordersList.isNotEmpty) {
          print('📦 First order raw data: ${ordersList.first}');
        }

        final orders = ordersList.map((json) {
          try {
            return ShopOrder.fromJson(json);
          } catch (e) {
            print('❌ Error parsing order: $e');
            print('❌ Order data: $json');
            return null;
          }
        }).whereType<ShopOrder>().toList();
        
        print('✅ Parsed ${orders.length} orders successfully');
        return orders;
      } else {
        print('❌ Bad response: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching orders: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get order statistics
  static Future<OrderStats?> getOrderStats() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/seller-orders/stats/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Order stats response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OrderStats.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching order stats: $e');
      return null;
    }
  }

  /// Create a new product with raw data (matching Vue structure)
  static Future<Map<String, dynamic>> createProductRaw(Map<String, dynamic> productData) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      print('📦 Creating product with data: $productData');

      final response = await http.post(
        Uri.parse('$baseUrl/products/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(productData),
      );

      print('📦 Create product response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final apiErr =
            ApiError.fromResponse(response.statusCode, response.body);
        print('❌ Error response: ${response.body}');
        return {
          'success': false,
          'message': apiErr.message,
          'code': apiErr.code,
        };
      }
    } catch (e) {
      print('❌ Error creating product: $e');
      return {
        'success': false,
        'message': 'Failed to create product: $e',
      };
    }
  }

  /// Create a new product
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required double regularPrice,
    required int quantity,
    String? description,
    String? shortDescription,
    List<int>? category,
    String? keywords,
    List<String>? images,
    double? salePrice,
    double? weight,
    bool isFreeDelivery = false,
    double deliveryFeeInsideDhaka = 0,
    double deliveryFeeOutsideDhaka = 0,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final Map<String, dynamic> productData = {
        'name': name,
        'regular_price': regularPrice,
        'quantity': quantity,
        'description': description,
        'short_description': shortDescription,
        'category': category,
        'keywords': keywords,
        'images': images,
        'sale_price': salePrice,
        'weight': weight,
        'is_free_delivery': isFreeDelivery,
        'delivery_fee_inside_dhaka': deliveryFeeInsideDhaka,
        'delivery_fee_outside_dhaka': deliveryFeeOutsideDhaka,
      };

      // Remove null values
      productData.removeWhere((key, value) => value == null);

      final response = await http.post(
        Uri.parse('$baseUrl/products/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(productData),
      );

      print('📦 Create product response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final apiErr =
            ApiError.fromResponse(response.statusCode, response.body);
        return {
          'success': false,
          'message': apiErr.message,
          'code': apiErr.code,
        };
      }
    } catch (e) {
      print('❌ Error creating product: $e');
      return {
        'success': false,
        'message': 'Failed to create product: $e',
      };
    }
  }

  /// Update a product
  static Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    double? price,
    int? stock,
    String? description,
    String? categoryId,
    String? image,
    String? status,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (price != null) body['sale_price'] = price; // Backend uses sale_price
      if (description != null) body['description'] = description;
      if (categoryId != null) body['category'] = categoryId;
      if (image != null) body['image'] = image;
      if (stock != null) body['quantity'] = stock; // Backend uses quantity
      
      // Convert status to is_active boolean
      if (status != null) {
        if (status == 'active') {
          body['is_active'] = true;
        } else if (status == 'inactive') {
          body['is_active'] = false;
        } else if (status == 'out-of-stock') {
          body['is_active'] = true;
          body['quantity'] = 0;
        }
      }

      print('📦 Updating product ID: $productId');
      print('📦 Update body: $body');
      print('📦 Endpoint: $baseUrl/products/$productId/');

      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('📦 Update product response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        try {
          final error = json.decode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? error['detail'] ?? 'Failed to update product',
            'errors': error,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to update product: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('❌ Error updating product: $e');
      return {
        'success': false,
        'message': 'Failed to update product: $e',
      };
    }
  }

  /// Delete a product
  static Future<bool> deleteProduct(String productId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Delete product response: ${response.statusCode}');

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }

  /// Update order status
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/seller-orders/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'order_status': status,
        }),
      );

      print('📦 Update order status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update order status',
        };
      }
    } catch (e) {
      print('❌ Error updating order status: $e');
      return {
        'success': false,
        'message': 'Failed to update order status: $e',
      };
    }
  }

  /// Check store username availability
  static Future<Map<String, dynamic>> checkStoreUsername(String username) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/check-store-username/?username=${Uri.encodeComponent(username)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📦 Check username response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'available': data['available'] ?? false,
          'suggestions': data['suggestions'] ?? [],
        };
      } else {
        return {
          'available': false,
          'suggestions': [],
        };
      }
    } catch (e) {
      print('❌ Error checking username: $e');
      return {
        'available': false,
        'suggestions': [],
      };
    }
  }

  /// Create store
  static Future<void> createStore({
    required String storeName,
    required String storeUsername,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not found');

      final response = await http.put(
        Uri.parse('$baseUrl/persons/update/${user.email}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'store_name': storeName,
          'store_username': storeUsername.toLowerCase(),
        }),
      );

      print('📦 Create store response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final error = json.decode(errorBody);
          throw Exception(error['error'] ?? error['message'] ?? error['detail'] ?? 'Failed to create store');
        } catch (e) {
          throw Exception(errorBody.isNotEmpty ? errorBody : 'Failed to create store');
        }
      }
    } catch (e) {
      print('❌ Error creating store: $e');
      rethrow;
    }
  }
}
