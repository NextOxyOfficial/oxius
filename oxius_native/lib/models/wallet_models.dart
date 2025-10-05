class Transaction {
  final int id;
  final String transactionType;
  final double amount;
  final String? status;
  final String? bankStatus;
  final bool? completed;
  final bool? rejected;
  final String? paymentMethod;
  final String? paymentNumber;
  final String? senderName;
  final String? senderPhone;
  final String? recipientName;
  final String? recipientPhone;
  final DateTime createdAt;
  final String? note;

  Transaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    this.status,
    this.bankStatus,
    this.completed,
    this.rejected,
    this.paymentMethod,
    this.paymentNumber,
    this.senderName,
    this.senderPhone,
    this.recipientName,
    this.recipientPhone,
    required this.createdAt,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      transactionType: json['transaction_type'] ?? '',
      amount: (json['amount'] ?? json['payable_amount'] ?? 0).toDouble(),
      status: json['status'],
      bankStatus: json['bank_status'],
      completed: json['completed'],
      rejected: json['rejected'],
      paymentMethod: json['payment_method'],
      paymentNumber: json['payment_number'],
      senderName: json['sender_name'],
      senderPhone: json['sender_phone'],
      recipientName: json['recipient_name'] ?? json['receiver_name'],
      recipientPhone: json['recipient_phone'] ?? json['receiver_phone'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      note: json['note'],
    );
  }

  String get displayStatus {
    if (bankStatus != null) return bankStatus!;
    if (status != null) return status!;
    if (completed == true) return 'completed';
    if (rejected == true) return 'rejected';
    return 'pending';
  }
}

class DepositRequest {
  final double amount;
  final bool policy;

  DepositRequest({
    required this.amount,
    required this.policy,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'policy': policy,
    };
  }
}

class WithdrawRequest {
  final String paymentMethod;
  final String paymentNumber;
  final double amount;
  final bool policy;

  WithdrawRequest({
    required this.paymentMethod,
    required this.paymentNumber,
    required this.amount,
    required this.policy,
  });

  Map<String, dynamic> toJson() {
    return {
      'selected': paymentMethod,
      'payment_number': paymentNumber,
      'withdrawAmount': amount,
      'policy': policy,
    };
  }
}

class TransferRequest {
  final String contact; // email or phone
  final double amount;
  final bool policy;

  TransferRequest({
    required this.contact,
    required this.amount,
    required this.policy,
  });

  Map<String, dynamic> toJson() {
    return {
      'contact': contact,
      'payable_amount': amount,
      'policy': policy,
    };
  }
}

class WalletBalance {
  final double balance;
  final double pendingBalance;
  final List<Transaction> pendingTransactions;

  WalletBalance({
    required this.balance,
    this.pendingBalance = 0.0,
    this.pendingTransactions = const [],
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    // Calculate pending balance from pending transactions
    double pending = 0.0;
    List<Transaction> pendingTxns = [];
    
    if (json['pending_transactions'] != null) {
      pendingTxns = (json['pending_transactions'] as List)
          .map((txn) => Transaction.fromJson(txn))
          .toList();
      pending = pendingTxns.fold(0.0, (sum, txn) => sum + txn.amount);
    }

    return WalletBalance(
      balance: (json['balance'] ?? 0).toDouble(),
      pendingBalance: pending,
      pendingTransactions: pendingTxns,
    );
  }
}

class PaymentMethodOption {
  final String value;
  final String label;
  final String icon;

  PaymentMethodOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
