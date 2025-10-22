class DiamondPackage {
  final int diamonds;
  final double price;

  DiamondPackage({
    required this.diamonds,
    required this.price,
  });

  factory DiamondPackage.fromJson(Map<String, dynamic> json) {
    return DiamondPackage(
      diamonds: json['diamonds'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diamonds': diamonds,
      'price': price,
    };
  }
}

class DiamondTransaction {
  final String id;
  final int amount;
  final double cost;
  final String status;
  final DateTime createdAt;

  DiamondTransaction({
    required this.id,
    required this.amount,
    required this.cost,
    required this.status,
    required this.createdAt,
  });

  factory DiamondTransaction.fromJson(Map<String, dynamic> json) {
    return DiamondTransaction(
      id: json['id']?.toString() ?? '',
      amount: json['amount'] ?? 0,
      cost: double.tryParse(json['cost']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'cost': cost,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DiamondTransactionsResponse {
  final List<DiamondTransaction> results;
  final int count;
  final String? next;
  final String? previous;

  DiamondTransactionsResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  factory DiamondTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return DiamondTransactionsResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((item) => DiamondTransaction.fromJson(item))
              .toList() ??
          [],
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
    );
  }
}
