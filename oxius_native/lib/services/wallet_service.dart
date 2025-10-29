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

  /// Create a deposit request (initiates payment gateway)
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

      final response = await http.post(
        Uri.parse('$baseUrl/add-user-balance/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          ...request.toJson(),
          'transaction_type': 'deposit',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data; // Contains checkout_url for payment gateway
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create deposit');
      }
    } catch (e) {
      print('Error creating deposit: $e');
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
        Uri.parse('$baseUrl/user-balance/${user.email}/'),
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
  static Future<List<Transaction>> getReceivedTransfers() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/received-transfers/'),
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
}
