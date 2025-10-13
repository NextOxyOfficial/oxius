import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class OrderService {
  static const String _baseUrl = ApiService.baseUrl;

  Future<OrderResponse?> createOrder(CreateOrderRequest orderData) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/orders/create-with-items/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData.toJson()),
      );

      print('Order creation response status: ${response.statusCode}');
      print('Order creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return OrderResponse.fromJson(responseData);
      } else {
        print('Failed to create order: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      rethrow;
    }
  }
}
