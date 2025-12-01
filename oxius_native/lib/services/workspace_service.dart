import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WorkspaceService {
  static String get baseUrl => ApiService.baseUrl;

  // ==================== GIG ENDPOINTS ====================

  /// Fetch all gigs with optional filters
  Future<Map<String, dynamic>> fetchGigs({
    String? category,
    String? search,
    String? ordering,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (ordering != null && ordering.isNotEmpty) {
        queryParams['ordering'] = ordering;
      }
      
      final uri = Uri.parse('$baseUrl/workspace/gigs/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'results': List<Map<String, dynamic>>.from(data['results'] ?? []),
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Failed to load gigs: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch gig details by ID
  Future<Map<String, dynamic>> fetchGigDetails(String gigId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load gig details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user's own gigs
  Future<Map<String, dynamic>> fetchMyGigs({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final uri = Uri.parse('$baseUrl/workspace/gigs/my/').replace(
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'results': List<Map<String, dynamic>>.from(data['results'] ?? []),
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Failed to load my gigs: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new gig
  Future<Map<String, dynamic>> createGig(Map<String, dynamic> gigData) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/gigs/create/'),
        headers: headers,
        body: json.encode(gigData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create gig');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update a gig
  Future<Map<String, dynamic>> updateGig(String gigId, Map<String, dynamic> gigData) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/update/'),
        headers: headers,
        body: json.encode(gigData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to update gig');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a gig
  Future<bool> deleteGig(String gigId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/delete/'),
        headers: headers,
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update gig status (pause/activate)
  Future<bool> updateGigStatus(String gigId, String status) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/update/'),
        headers: headers,
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite on a gig
  Future<bool> toggleFavorite(String gigId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/favorite/'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Fetch gig categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/gigs/categories/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch gig options (for creating gigs)
  Future<Map<String, dynamic>> fetchGigOptions() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/gig-options/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== ORDER ENDPOINTS ====================

  /// Create an order for a gig
  Future<Map<String, dynamic>> createOrder(String gigId, Map<String, dynamic> orderData) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/order/'),
        headers: headers,
        body: json.encode(orderData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create order');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch orders placed by user (as buyer)
  Future<Map<String, dynamic>> fetchMyOrders({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      final uri = Uri.parse('$baseUrl/workspace/orders/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'results': List<Map<String, dynamic>>.from(data['results'] ?? []),
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch orders received by user (as seller)
  Future<Map<String, dynamic>> fetchSellerOrders({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      final uri = Uri.parse('$baseUrl/workspace/orders/seller/').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'results': List<Map<String, dynamic>>.from(data['results'] ?? []),
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Failed to load seller orders: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String action) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/orders/$orderId/$action/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Complete order payment
  Future<Map<String, dynamic>> completeOrderPayment(String orderId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/orders/$orderId/complete/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to complete payment');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/orders/$orderId/cancel/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== REVIEW ENDPOINTS ====================

  /// Fetch reviews for a gig
  Future<Map<String, dynamic>> fetchGigReviews(String gigId, {int page = 1}) async {
    try {
      final headers = await ApiService.getHeaders();
      final uri = Uri.parse('$baseUrl/workspace/gigs/$gigId/reviews/').replace(
        queryParameters: {'page': page.toString()},
      );
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'results': List<Map<String, dynamic>>.from(data['results'] ?? []),
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
        };
      }
      return {'results': [], 'count': 0};
    } catch (e) {
      return {'results': [], 'count': 0};
    }
  }

  /// Create a review
  Future<bool> createReview(String gigId, int rating, String comment) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/gigs/$gigId/reviews/create/'),
        headers: headers,
        body: json.encode({'rating': rating, 'comment': comment}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== DISPUTE ENDPOINTS ====================

  /// Dispute reason choices
  static const List<Map<String, String>> disputeReasons = [
    {'value': 'unresponsive_seller', 'label': 'Seller is unresponsive'},
    {'value': 'unresponsive_buyer', 'label': 'Buyer is unresponsive'},
    {'value': 'work_not_delivered', 'label': 'Work not delivered'},
    {'value': 'work_not_as_described', 'label': 'Work not as described'},
    {'value': 'quality_issues', 'label': 'Quality issues'},
    {'value': 'late_delivery', 'label': 'Late delivery'},
    {'value': 'payment_issue', 'label': 'Payment issue'},
    {'value': 'communication_issue', 'label': 'Communication breakdown'},
    {'value': 'other', 'label': 'Other'},
  ];

  /// Create a dispute for an order
  Future<Map<String, dynamic>> createDispute({
    required String orderId,
    required String reason,
    required String description,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/orders/$orderId/dispute/'),
        headers: headers,
        body: json.encode({
          'reason': reason,
          'description': description,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Dispute raised successfully',
          'dispute': data['dispute'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create dispute',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get dispute details for an order
  Future<Map<String, dynamic>?> getOrderDispute(String orderId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/orders/$orderId/dispute/details/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dispute'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== ORDER MESSAGES ====================

  /// Get messages for an order
  Future<List<Map<String, dynamic>>> getOrderMessages(String orderId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/orders/$orderId/messages/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['results'] != null) {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Send a message for an order
  Future<Map<String, dynamic>?> sendOrderMessage({
    required String orderId,
    required String content,
    String? mediaPath,
    String messageType = 'text',
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      if (mediaPath != null) {
        // Multipart request for file upload
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/workspace/orders/$orderId/messages/create/'),
        );
        
        // Add auth header
        final authHeaders = await ApiService.getHeaders();
        request.headers.addAll({
          'Authorization': authHeaders['Authorization'] ?? '',
        });
        
        request.fields['content'] = content;
        request.fields['message_type'] = messageType;
        request.files.add(await http.MultipartFile.fromPath('media', mediaPath));
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return Map<String, dynamic>.from(json.decode(response.body));
        }
      } else {
        // Regular JSON request for text message
        final response = await http.post(
          Uri.parse('$baseUrl/workspace/orders/$orderId/messages/create/'),
          headers: headers,
          body: json.encode({'content': content}),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          return Map<String, dynamic>.from(json.decode(response.body));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mark messages as read for an order
  Future<bool> markMessagesAsRead(String orderId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/orders/$orderId/messages/mark-read/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get unread message counts for all orders
  Future<Map<String, int>> getUnreadMessageCounts() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/orders/unread-counts/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, int>.from(data);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== FEE SETTINGS ====================

  /// Get fee settings
  Future<Map<String, dynamic>> getFeeSettings() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/fee-settings/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Calculate order fees
  Future<Map<String, dynamic>> calculateFees(double amount) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/workspace/calculate-fees/'),
        headers: headers,
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== BANNERS ====================

  /// Get workspace banners
  Future<List<Map<String, dynamic>>> fetchBanners() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/workspace/banners/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
