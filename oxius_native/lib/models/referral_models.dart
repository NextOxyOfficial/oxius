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

  factory CommissionTransaction.fromJson(Map<String, dynamic> json) {
    return CommissionTransaction(
      date: json['date'] ?? '',
      type: json['type'] ?? 'Unknown',
      typeCode: json['type_code'] ?? 'gig_completion',
      amount: (json['amount'] ?? 0).toDouble(),
      commissionRate: json['commission_rate'] ?? '5%',
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
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String joinedDate;
  final String status;
  final double totalSpent;

  ReferredUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.joinedDate,
    required this.status,
    required this.totalSpent,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      phone: json['phone'],
      joinedDate: json['joined_date'] ?? json['date_joined'] ?? '',
      status: json['status'] ?? 'active',
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
    );
  }
}
