class MicroGigUser {
  final int id;
  final String name;
  final String? image;

  MicroGigUser({
    required this.id,
    required this.name,
    this.image,
  });

  factory MicroGigUser.fromJson(Map<String, dynamic> json) {
    return MicroGigUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
    );
  }
}

class MicroGigCategory {
  final int id;
  final String title;
  final String? image;

  MicroGigCategory({
    required this.id,
    required this.title,
    this.image,
  });

  factory MicroGigCategory.fromJson(Map<String, dynamic> json) {
    return MicroGigCategory(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'],
    );
  }
}

class MicroGig {
  final int id;
  final String slug;
  final String title;
  final double price;
  final int requiredQuantity;
  final int filledQuantity;
  final DateTime createdAt;
  final bool activeGig;
  final String gigStatus;
  final MicroGigUser? user;
  final MicroGigCategory? categoryDetails;

  MicroGig({
    required this.id,
    required this.slug,
    required this.title,
    required this.price,
    required this.requiredQuantity,
    required this.filledQuantity,
    required this.createdAt,
    this.activeGig = true,
    this.gigStatus = 'approved',
    this.user,
    this.categoryDetails,
  });

  factory MicroGig.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return (value as num).toDouble();
    }

    return MicroGig(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      price: parsePrice(json['price']),
      requiredQuantity: json['required_quantity'] ?? 0,
      filledQuantity: json['filled_quantity'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      activeGig: json['active_gig'] ?? true,
      gigStatus: json['gig_status'] ?? 'approved',
      user: json['user'] != null ? MicroGigUser.fromJson(json['user']) : null,
      categoryDetails: json['category_details'] != null 
          ? MicroGigCategory.fromJson(json['category_details']) 
          : null,
    );
  }

  bool get isAvailable => filledQuantity < requiredQuantity;
  int get remainingSlots => requiredQuantity - filledQuantity;
}

class MicroGigTask {
  final int id;
  final String? gigTitle;
  final double gigPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool completed;
  final bool approved;
  final bool rejected;
  final String? submitDetails;
  final String? reason;
  final String? taskCompletionLink;
  final List<String> mediaUrls;

  MicroGigTask({
    required this.id,
    this.gigTitle,
    required this.gigPrice,
    required this.createdAt,
    required this.updatedAt,
    this.completed = false,
    this.approved = false,
    this.rejected = false,
    this.submitDetails,
    this.reason,
    this.taskCompletionLink,
    this.mediaUrls = const [],
  });

  factory MicroGigTask.fromJson(Map<String, dynamic> json) {
    // Parse gig data
    final gig = json['gig'];
    String? gigTitle;
    double gigPrice = 0.0;
    
    if (gig != null) {
      gigTitle = gig['title'];
      final priceValue = gig['price'];
      if (priceValue != null) {
        gigPrice = priceValue is String 
          ? double.parse(priceValue) 
          : (priceValue as num).toDouble();
      }
    }

    // Parse media URLs
    List<String> mediaUrls = [];
    if (json['medias'] != null) {
      mediaUrls = (json['medias'] as List)
          .map((media) => media['image']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return MicroGigTask(
      id: json['id'] ?? 0,
      gigTitle: gigTitle,
      gigPrice: gigPrice,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      completed: json['completed'] ?? false,
      approved: json['approved'] ?? false,
      rejected: json['rejected'] ?? false,
      submitDetails: json['submit_details'],
      reason: json['reason'],
      taskCompletionLink: json['task_completion_link'],
      mediaUrls: mediaUrls,
    );
  }

  String get status {
    if (approved) return 'Approved';
    if (rejected) return 'Rejected';
    return 'Under Review';
  }

  String get statusColor {
    if (approved) return 'green';
    if (rejected) return 'red';
    return 'orange';
  }

  // Calculate remaining time for auto-approval (48 hours)
  String get remainingTime {
    final deadline = createdAt.add(const Duration(hours: 48));
    final now = DateTime.now();
    final remaining = deadline.difference(now);

    if (remaining.isNegative) {
      return 'Auto Approved';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  bool get is48HoursPassed {
    final deadline = createdAt.add(const Duration(hours: 48));
    return DateTime.now().isAfter(deadline);
  }
}
