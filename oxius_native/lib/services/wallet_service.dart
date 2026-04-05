import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet_models.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WalletService {
  static String get baseUrl => ApiService.baseUrl;
  static const _pendingPaymentSessionKey = 'wallet_pending_payment_session';

  // Minimum transaction amounts
  static const double minDeposit = 100.0;
  static const double minWithdrawal = 200.0;
  static const double minTransfer = 50.0;
  static const double withdrawalChargePercent = 2.95;

    static bool isPaymentSuccessful(Map<String, dynamic> paymentDetails) {
    final message =
      paymentDetails['shurjopay_message']?.toString().toLowerCase() ?? '';
    final bankStatus =
      paymentDetails['bank_status']?.toString().toLowerCase() ?? '';

    return message == 'success' ||
      bankStatus == 'success' ||
      bankStatus == 'completed';
    }

    static bool isPaymentFailed(Map<String, dynamic> paymentDetails) {
    final message =
      paymentDetails['shurjopay_message']?.toString().toLowerCase() ?? '';
    final bankStatus =
      paymentDetails['bank_status']?.toString().toLowerCase() ?? '';
    final combined = '$message $bankStatus';

    return combined.contains('fail') ||
      combined.contains('cancel') ||
      combined.contains('declin') ||
      combined.contains('expire') ||
      combined.contains('invalid');
  }

  static String? extractVerificationOrderId(Map<String, dynamic>? response) {
    if (response == null) {
      return null;
    }

    final candidates = [
      response['verification_order_id'],
      response['sp_order_id'],
      response['shurjopay_order_id'],
      response['order_id'],
      response['merchant_invoice_no'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static String? extractVerificationOrderIdFromUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final candidates = [
      uri.queryParameters['sp_order_id'],
      uri.queryParameters['order_id'],
      uri.queryParameters['invoice_no'],
      uri.queryParameters['merchant_invoice_no'],
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  static Future<void> cachePendingPaymentSession({
    required String orderId,
    required String verificationOrderId,
    required String checkoutUrl,
    required double amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingPaymentSessionKey,
      json.encode({
        'order_id': orderId,
        'verification_order_id': verificationOrderId,
        'checkout_url': checkoutUrl,
        'amount': amount,
      }),
    );
  }

  static Future<Map<String, dynamic>?> getPendingPaymentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_pendingPaymentSessionKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final decoded = json.decode(rawValue);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return null;
  }

  static Future<void> clearPendingPaymentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPaymentSessionKey);
  }

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
            actualBalance = refreshedUser.balance;
            pendingBalance = refreshedUser.pendingBalance;
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

      if (kIsWeb) {
        final origin = '${Uri.base.scheme}://${Uri.base.authority}';
        queryParams['return_url'] = '$origin/payment-callback.html';
        queryParams['cancel_url'] = '$origin/payment-cancel.html';
      }

      final uri = Uri.parse('$baseUrl/pay/').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        data['order_id'] ??= uniqueOrderId;
        data['verification_order_id'] ??= data['sp_order_id'] ??
            data['shurjopay_order_id'] ??
            data['order_id'];
        
        if (data['checkout_url'] != null) {
          return data; // Contains checkout_url for Surjopay gateway
        } else {
          throw Exception('Failed to get payment URL. Please check your profile information.');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
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
      rethrow;
    }
  }

  /// Get transaction history (sent transactions)
  static Future<List<Transaction>> getTransactions({
    String? type, // deposit, withdraw, transfer
    String? status, // completed, pending, rejected
    int page = 1,
    int pageSize = 20,
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
        Uri.parse('$baseUrl/user-balance/${user.email}/?page=$page&page_size=$pageSize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> data;
        if (decoded is Map && decoded['results'] is List) {
          data = List<dynamic>.from(decoded['results'] as List);
        } else if (decoded is List) {
          final full = List<dynamic>.from(decoded);
          final start = (page - 1) * pageSize;
          if (start >= full.length) {
            data = [];
          } else {
            final end = (start + pageSize) > full.length ? full.length : (start + pageSize);
            data = full.sublist(start, end);
          }
        } else {
          data = [];
        }
        
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
          } catch (_) {
          }
        }
        
        return transactions;
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get received transfers
  static Future<List<Transaction>> getReceivedTransfers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/received-transfers/?page=$page&page_size=$pageSize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> data;
        if (decoded is Map && decoded['results'] is List) {
          data = List<dynamic>.from(decoded['results'] as List);
        } else if (decoded is List) {
          final full = List<dynamic>.from(decoded);
          final start = (page - 1) * pageSize;
          if (start >= full.length) {
            data = [];
          } else {
            final end = (start + pageSize) > full.length ? full.length : (start + pageSize);
            data = full.sublist(start, end);
          }
        } else {
          data = [];
        }

        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load received transfers: ${response.statusCode}');
      }
    } catch (e) {
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

      final response = await http.get(
        Uri.parse('$baseUrl/verify-pay/?sp_order_id=$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Payment verification failed');
      }
    } catch (e) {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Refresh user data to get updated balance
        await AuthService.refreshUserData();
        
        return {
          'success': true,
          'message': 'Payment successful!',
          'already_processed': false,
          'data': data,
        };
      } else {
        final error = json.decode(response.body);
        final errorMessage =
            error['error'] ?? error['message'] ?? 'Failed to add balance';

        if (errorMessage
            .toString()
            .toLowerCase()
            .contains('already exists')) {
          await AuthService.refreshUserData();
          return {
            'success': true,
            'message': 'Payment already processed.',
            'already_processed': true,
            'data': null,
          };
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyAndFinalizePayment(
    String orderId,
  ) async {
    final verificationResult = await verifyPayment(orderId);

    if (verificationResult == null) {
      return {
        'success': false,
        'status': 'pending',
        'message': 'Waiting for payment confirmation.',
      };
    }

    if (isPaymentSuccessful(verificationResult)) {
      final balanceResult = await addBalanceAfterPayment(verificationResult);

      return {
        'success': true,
        'status': 'success',
        'message': balanceResult?['already_processed'] == true
            ? 'Payment already confirmed and balance is available.'
            : 'Payment successful! Your balance has been updated.',
        'paymentDetails': verificationResult,
        'balanceResult': balanceResult,
      };
    }

    if (isPaymentFailed(verificationResult)) {
      return {
        'success': false,
        'status': 'failed',
        'message': verificationResult['shurjopay_message']?.toString() ??
            'Payment was not successful.',
        'paymentDetails': verificationResult,
      };
    }

    return {
      'success': false,
      'status': 'pending',
      'message': verificationResult['shurjopay_message']?.toString() ??
          'Waiting for payment confirmation.',
      'paymentDetails': verificationResult,
    };
  }
}
