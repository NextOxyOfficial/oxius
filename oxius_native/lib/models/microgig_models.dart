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
