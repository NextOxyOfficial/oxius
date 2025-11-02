import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WalletService {
  static String get baseUrl => ApiService.baseUrl;

  // Minimum transaction amounts
  static const double minDeposit = 100.0;
  static const double minWithdrawal = 200.0;
  static const double minTransfer = 50.0;
  static const double withdrawalChargePercent = 2.95;

  /// Get user's wallet balance
  static Future<WalletBalance?> getBalance() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('No user found');
      }

      // Fetch user balance and pending transactions
      final response = await http.get(
        Uri.parse('$baseUrl/user-balance/${user.email}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Extract user's balance from user_details in the first transaction
        double actualBalance = 0.0;
        double pendingBalance = 0.0;
        List<Map<String, dynamic>> pendingTxns = [];
        
        if (data.isNotEmpty) {
          // Get balance from user_details (returned by BalanceSerializer)
          final userDetails = data[0]['user_details'];
          if (userDetails != null) {
            // Parse balance - backend returns as string "16569.00"
            final balanceValue = userDetails['balance'];
            final pendingValue = userDetails['pending_balance'];
            
            if (balanceValue != null) {
              actualBalance = balanceValue is String 
                ? double.parse(balanceValue) 
                : (balanceValue as num).toDouble();
            }
            
            if (pendingValue != null) {
              pendingBalance = pendingValue is String 
                ? double.parse(pendingValue) 
                : (pendingValue as num).toDouble();
            }
          }
        } else {
          // No transactions exist - refresh user data and get balance from currentUser
          // This handles users added via scripts who have no transaction history
          await AuthService.refreshUserData();
          final refreshedUser = AuthService.currentUser;
          
          if (refreshedUser != null) {
            if (refreshedUser.balance != null) {
              actualBalance = refreshedUser.balance!;
            }
            if (refreshedUser.pendingBalance != null) {
              pendingBalance = refreshedUser.pendingBalance!;
            }
          }
        }
        
        // Collect pending transactions for display (not for balance calculation)
        for (var item in data) {
          if (item['bank_status'] == 'pending' && 
              item['completed'] == false && 
              item['rejected'] == false) {
            pendingTxns.add(item);
          }
        }
        
        // Use pending_balance directly from backend user model (don't recalculate)
        return WalletBalance.fromJson({
          'balance': actualBalance,
          'pending_balance': pendingBalance, // This comes from user model, not calculated
          'pending_transactions': pendingTxns,
        });
      } else {
        throw Exception('Failed to load balance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting balance: $e');
      return null;
    }
  }

  /// Create a deposit request (initiates Surjopay payment gateway)
  static Future<Map<String, dynamic>?> createDeposit(DepositRequest request) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      if (request.amount < minDeposit) {
        throw Exception('Minimum deposit amount is ৳$minDeposit');
      }

      if (!request.policy) {
        throw Exception('Please accept terms and conditions');
      }

      // Get current user data for payment gateway
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      // Validate required user profile fields
      final firstName = user.firstName ?? 'User';
      final lastName = user.lastName ?? '';
      final address = user.address ?? 'N/A';
      final phone = user.phone ?? 'N/A';
      final city = user.city ?? 'N/A';
      final zip = user.zip ?? '0000';

      // Generate unique order ID
      final uniqueOrderId = '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecond % 1000)}';

      // Build payment URL with all required parameters (matching Vue implementation)
      final queryParams = {
        'amount': request.amount.toString(),
        'order_id': uniqueOrderId,
        'currency': 'BDT',
        'customer_name': '$firstName $lastName',
        'customer_address': address,
        'customer_phone': phone,
        'customer_city': city,
        'customer_post_code': zip,
      };

      final uri = Uri.parse('$baseUrl/pay/').replace(queryParameters: queryParams);

      print('📱 Initiating Surjopay deposit: ${request.amount} BDT');
      print('📱 Payment URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📱 Payment response status: ${response.statusCode}');
      print('📱 Payment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['checkout_url'] != null) {
          print('✅ Surjopay checkout URL received: ${data['checkout_url']}');
          return data; // Contains checkout_url for Surjopay gateway
        } else {
          print('❌ No checkout_url in response');
          throw Exception('Failed to get payment URL. Please check your profile information.');
        }
      } else {
        final error = json.decode(response.body);
        print('❌ Payment gateway error: $error');
        throw Exception(error['message'] ?? error['error'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      print('❌ Error creating deposit: $e');
      rethrow;
    }
  }

  /// Create a withdrawal request
  static Future<Map<String, dynamic>?> createWithdrawal(WithdrawRequest request) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      if (request.amount < minWithdrawal) {
        throw Exception('Minimum withdrawal amount is ৳$minWithdrawal');
      }

      if (!request.policy) {
        throw Exception('Please accept terms and conditions');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/add-user-balance/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          ...request.toJson(),
          'transaction_type': 'withdraw',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create withdrawal');
      }
    } catch (e) {
      print('Error creating withdrawal: $e');
      rethrow;
    }
  }

  /// Transfer money to another user
  static Future<Map<String, dynamic>?> createTransfer(TransferRequest request) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      if (request.amount < minTransfer) {
        throw Exception('Minimum transfer amount is ৳$minTransfer');
      }

      if (!request.policy) {
        throw Exception('Please accept terms and conditions');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/add-user-balance/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          ...request.toJson(),
          'transaction_type': 'transfer',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Failed to transfer');
      }
    } catch (e) {
      print('Error creating transfer: $e');
      rethrow;
    }
  }

  /// Get transaction history (sent transactions)
  static Future<List<Transaction>> getTransactions({
    String? type, // deposit, withdraw, transfer
    String? status, // completed, pending, rejected
    int page = 1,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('No user found');
      }

      // Use the same endpoint as getBalance to get user's transactions
      final response = await http.get(
        Uri.parse('$baseUrl/user-balance/${user.email}/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Filter transactions based on optional parameters
        List<Transaction> transactions = [];
        for (var item in data) {
          // Skip if type filter doesn't match
          if (type != null && item['transaction_type']?.toLowerCase() != type.toLowerCase()) {
            continue;
          }
          
          // Skip if status filter doesn't match
          if (status != null) {
            final itemStatus = item['bank_status'] ?? 'pending';
            if (itemStatus.toLowerCase() != status.toLowerCase()) {
              continue;
            }
          }
          
          try {
            transactions.add(Transaction.fromJson(item));
          } catch (e) {
            print('Error parsing transaction: $e');
          }
        }
        
        return transactions;
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Get received transfers
  static Future<List<Transaction>> getReceivedTransfers({int page = 1}) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/received-transfers/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load received transfers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting received transfers: $e');
      return [];
    }
  }

  /// Calculate total withdrawal amount including charges
  static double calculateWithdrawalTotal(double amount) {
    return amount + (amount * withdrawalChargePercent / 100);
  }

  /// Get user details by ID (for QR code transfers)
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      rethrow;
    }
  }

  /// Get available payment methods
  static List<PaymentMethodOption> getPaymentMethods() {
    return [
      PaymentMethodOption(
        value: 'nagad',
        label: 'Nagad',
        icon: 'images/nagad.png',
      ),
      PaymentMethodOption(
        value: 'bkash',
        label: 'bKash',
        icon: 'images/bkash.png',
      ),
    ];
  }

  /// Verify payment with Surjopay (called after payment gateway redirects back)
  static Future<Map<String, dynamic>?> verifyPayment(String orderId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('📱 Verifying payment for order: $orderId');

      final response = await http.get(
        Uri.parse('$baseUrl/verify-pay/?sp_order_id=$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📱 Verification response status: ${response.statusCode}');
      print('📱 Verification response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Payment verification failed');
      }
    } catch (e) {
      print('❌ Error verifying payment: $e');
      rethrow;
    }
  }

  /// Add balance after successful payment verification
  static Future<Map<String, dynamic>?> addBalanceAfterPayment(
    Map<String, dynamic> paymentDetails,
  ) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('📱 Adding balance after payment verification');

      final response = await http.post(
        Uri.parse('$baseUrl/add-user-balance/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bank_status': paymentDetails['bank_status']?.toString().toLowerCase(),
          'transaction_type': 'Deposit',
          'payment_method': paymentDetails['payment_method'],
          'amount': paymentDetails['amount'],
          'payable_amount': paymentDetails['payable_amount'],
          'received_amount': paymentDetails['received_amount'],
          'merchant_invoice_no': paymentDetails['merchant_invoice_no'],
          'shurjopay_order_id': paymentDetails['shurjopay_order_id'],
          'payment_confirmed_at': paymentDetails['payment_confirmed_at'],
        }),
      );

      print('📱 Add balance response status: ${response.statusCode}');
      print('📱 Add balance response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Refresh user data to get updated balance
        await AuthService.refreshUserData();
        
        return {
          'success': true,
          'message': 'Payment successful!',
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to add balance');
      }
    } catch (e) {
      print('❌ Error adding balance: $e');
      rethrow;
    }
  }
}
