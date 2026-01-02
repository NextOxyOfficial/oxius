import 'package:characters/characters.dart';

class PlatformStats {
  final int activeReferrers;
  final double topEarnerAmount;
  final String quickPayoutTime;
  final CommissionRates commissionRates;

  PlatformStats({
    required this.activeReferrers,
    required this.topEarnerAmount,
    required this.quickPayoutTime,
    required this.commissionRates,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      activeReferrers: json['active_referrers'] ?? 500,
      topEarnerAmount: (json['top_earner_amount'] ?? 10000).toDouble(),
      quickPayoutTime: json['quick_payout_time'] ?? '24hr',
      commissionRates: CommissionRates.fromJson(json['commission_rates'] ?? {}),
    );
  }
}

class CommissionRates {
  final String gigCompletion;
  final String proSubscription;
  final String goldSponsor;

  CommissionRates({
    required this.gigCompletion,
    required this.proSubscription,
    required this.goldSponsor,
  });

  factory CommissionRates.fromJson(Map<String, dynamic> json) {
    return CommissionRates(
      gigCompletion: json['gig_completion'] ?? '5%',
      proSubscription: json['pro_subscription'] ?? '20%',
      goldSponsor: json['gold_sponsor'] ?? '20%',
    );
  }
}

class CommissionData {
  final double totalCommissions;
  final double totalEarned;
  final CommissionBreakdownData commissionBreakdown;
  final List<CommissionTransaction> recentTransactions;

  CommissionData({
    required this.totalCommissions,
    required this.totalEarned,
    required this.commissionBreakdown,
    required this.recentTransactions,
  });

  factory CommissionData.fromJson(Map<String, dynamic> json) {
    return CommissionData(
      totalCommissions: (json['total_commissions'] ?? 0).toDouble(),
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      commissionBreakdown: CommissionBreakdownData.fromJson(
        json['commission_breakdown'] ?? {},
      ),
      recentTransactions: (json['recent_transactions'] as List?)
              ?.map((t) => CommissionTransaction.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class CommissionBreakdownData {
  final ServiceCommission gigCompletion;
  final ServiceCommission proSubscription;
  final ServiceCommission goldSponsor;

  CommissionBreakdownData({
    required this.gigCompletion,
    required this.proSubscription,
    required this.goldSponsor,
  });

  factory CommissionBreakdownData.fromJson(Map<String, dynamic> json) {
    return CommissionBreakdownData(
      gigCompletion: ServiceCommission.fromJson(json['gig_completion'] ?? {}),
      proSubscription: ServiceCommission.fromJson(json['pro_subscription'] ?? {}),
      goldSponsor: ServiceCommission.fromJson(json['gold_sponsor'] ?? {}),
    );
  }
}

class ServiceCommission {
  final int count;
  final double totalAmount;
  final String rate;
  final List<dynamic> transactions;

  ServiceCommission({
    required this.count,
    required this.totalAmount,
    required this.rate,
    required this.transactions,
  });

  factory ServiceCommission.fromJson(Map<String, dynamic> json) {
    return ServiceCommission(
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      rate: json['rate'] ?? '5%',
      transactions: json['transactions'] ?? [],
    );
  }
}

class CommissionTransaction {
  final String date;
  final String type;
  final String typeCode;
  final double amount;
  final String commissionRate;
  final ReferredUserInfo? referredUser;

  CommissionTransaction({
    required this.date,
    required this.type,
    required this.typeCode,
    required this.amount,
    required this.commissionRate,
    this.referredUser,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _parseCommissionRate(dynamic value) {
    if (value == null) return '5%';
    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return '5%';
      return v.contains('%') ? v : '${v}%';
    }
    if (value is num) {
      final d = value.toDouble();
      final s = d % 1 == 0
          ? d.toStringAsFixed(0)
          : d
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
      return '$s%';
    }
    return value.toString();
  }

  factory CommissionTransaction.fromJson(Map<String, dynamic> json) {
    return CommissionTransaction(
      date: json['date']?.toString() ?? '',
      type: json['type'] ?? 'Unknown',
      typeCode: json['type_code'] ?? 'gig_completion',
      amount: _parseDouble(json['amount']),
      commissionRate: _parseCommissionRate(json['commission_rate']),
      referredUser: json['referred_user'] != null
          ? ReferredUserInfo.fromJson(json['referred_user'])
          : null,
    );
  }
}

class ReferredUserInfo {
  final String name;
  final String? email;

  ReferredUserInfo({
    required this.name,
    this.email,
  });

  factory ReferredUserInfo.fromJson(Map<String, dynamic> json) {
    return ReferredUserInfo(
      name: json['name'] ?? 'Unknown User',
      email: json['email'],
    );
  }
}

class ReferredUser {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? name;
  final String email;
  final String? phone;
  final String? image;
  final bool isActive;
  final String joinedDate;

  ReferredUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.name,
    required this.email,
    this.phone,
    this.image,
    required this.isActive,
    required this.joinedDate,
  });

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return false;
  }

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      username: json['username']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      image: json['image']?.toString(),
      isActive: _parseBool(json['is_active'] ?? json['active'] ?? true),
      joinedDate: json['date_joined']?.toString() ?? json['joined_date']?.toString() ?? '',
    );
  }

  String get displayName {
    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    final full = ('$fn $ln').trim();
    if (full.isNotEmpty) return full;

    final n = name?.trim() ?? '';
    if (n.isNotEmpty) return n;

    final u = username?.trim() ?? '';
    if (u.isNotEmpty) return u;

    if (email.trim().isNotEmpty) return email.trim();
    return 'User';
  }

  String get initial {
    final t = displayName.trim();
    if (t.isEmpty) return 'U';
    return t.characters.first.toUpperCase();
  }
}
