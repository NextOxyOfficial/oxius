class MindForceProblem {
  final String id;
  final String title;
  final String description;
  final String status; // active, solved
  final String paymentOption; // free, paid
  final double? paymentAmount;
  final int views;
  final String createdAt;
  final String updatedAt;
  final MindForceUser userDetails;
  final MindForceCategory? category;
  final List<MindForceMedia> media;
  final List<MindForceComment> comments;

  MindForceProblem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.paymentOption,
    this.paymentAmount,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    required this.userDetails,
    this.category,
    this.media = const [],
    this.comments = const [],
  });

  factory MindForceProblem.fromJson(Map<String, dynamic> json) {
    return MindForceProblem(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'active',
      paymentOption: json['payment_option'] ?? 'free',
      paymentAmount: json['payment_amount'] != null 
          ? double.tryParse(json['payment_amount'].toString()) 
          : null,
      views: json['views'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      userDetails: MindForceUser.fromJson(json['user_details'] ?? {}),
      category: json['category_details'] != null 
          ? MindForceCategory.fromJson(json['category_details']) 
          : null,
      media: json['media'] != null
          ? (json['media'] as List).map((m) => MindForceMedia.fromJson(m)).toList()
          : [],
      comments: json['mindforce_comments'] != null
          ? (json['mindforce_comments'] as List).map((c) => MindForceComment.fromJson(c)).toList()
          : [],
    );
  }

  MindForceProblem copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? paymentOption,
    double? paymentAmount,
    int? views,
    String? createdAt,
    String? updatedAt,
    MindForceUser? userDetails,
    MindForceCategory? category,
    List<MindForceMedia>? media,
    List<MindForceComment>? comments,
  }) {
    return MindForceProblem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      paymentOption: paymentOption ?? this.paymentOption,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userDetails: userDetails ?? this.userDetails,
      category: category ?? this.category,
      media: media ?? this.media,
      comments: comments ?? this.comments,
    );
  }
}

class MindForceUser {
  final String id;
  final String name;
  final String? image;
  final String? username;
  final bool isPro;
  final bool kyc;

  MindForceUser({
    required this.id,
    required this.name,
    this.image,
    this.username,
    this.isPro = false,
    this.kyc = false,
  });

  factory MindForceUser.fromJson(Map<String, dynamic> json) {
    // Debug: print raw JSON to see what the backend sends
    print('=== MindForceUser JSON ===');
    print('Keys available: ${json.keys.toList()}');
    print('Full JSON: $json');
    
    // Get user ID first as fallback
    final userId = json['id']?.toString() ?? '0';
    
    // Try multiple field combinations for the user's name
    String userName = '';
    
    // Check all possible name field variations
    if (json['name'] != null && json['name'].toString().trim().isNotEmpty && json['name'].toString().trim() != 'null') {
      userName = json['name'].toString().trim();
    } else if (json['full_name'] != null && json['full_name'].toString().trim().isNotEmpty && json['full_name'].toString().trim() != 'null') {
      userName = json['full_name'].toString().trim();
    } else if (json['fullname'] != null && json['fullname'].toString().trim().isNotEmpty && json['fullname'].toString().trim() != 'null') {
      userName = json['fullname'].toString().trim();
    } else if (json['display_name'] != null && json['display_name'].toString().trim().isNotEmpty && json['display_name'].toString().trim() != 'null') {
      userName = json['display_name'].toString().trim();
    } else if (json['first_name'] != null || json['last_name'] != null) {
      final firstName = (json['first_name'] ?? '').toString().trim();
      final lastName = (json['last_name'] ?? '').toString().trim();
      userName = '$firstName $lastName'.trim();
    } else if (json['username'] != null && json['username'].toString().trim().isNotEmpty && json['username'].toString().trim() != 'null') {
      userName = json['username'].toString().trim();
    } else if (json['user_name'] != null && json['user_name'].toString().trim().isNotEmpty && json['user_name'].toString().trim() != 'null') {
      userName = json['user_name'].toString().trim();
    } else if (json['email'] != null && json['email'].toString().trim().isNotEmpty && json['email'].toString().trim() != 'null') {
      // Use email as last resort before user ID
      userName = json['email'].toString().split('@')[0].trim();
    }
    
    // If still empty, use User ID instead of "Unknown User"
    if (userName.isEmpty || userName == 'null') {
      userName = 'User $userId';
    }
    
    print('Final userName: $userName');
    print('Final image: ${json['image'] ?? json['avatar'] ?? json['profile_picture']}');
    
    return MindForceUser(
      id: userId,
      name: userName,
      image: json['image'] ?? json['avatar'] ?? json['profile_picture'],
      username: json['username'],
      isPro: json['is_pro'] == true,
      kyc: json['kyc'] == true,
    );
  }
}

class MindForceCategory {
  final int id;
  final String name;
  final String? icon;

  MindForceCategory({
    required this.id,
    required this.name,
    this.icon,
  });

  factory MindForceCategory.fromJson(Map<String, dynamic> json) {
    return MindForceCategory(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] ?? 0),
      name: json['name'] ?? '',
      icon: json['icon'],
    );
  }
}

class MindForceMedia {
  final String id;
  final String image;

  MindForceMedia({
    required this.id,
    required this.image,
  });

  factory MindForceMedia.fromJson(Map<String, dynamic> json) {
    return MindForceMedia(
      id: json['id']?.toString() ?? '0',
      image: json['image'] ?? '',
    );
  }
}

class MindForceComment {
  final String id;
  final String content;
  final bool isSolved;
  final String createdAt;
  final MindForceUser userDetails;
  final List<String> images;

  MindForceComment({
    required this.id,
    required this.content,
    required this.isSolved,
    required this.createdAt,
    required this.userDetails,
    this.images = const [],
  });

  factory MindForceComment.fromJson(Map<String, dynamic> json) {
    return MindForceComment(
      id: json['id']?.toString() ?? '0',
      content: json['content'] ?? '',
      isSolved: json['is_solved'] ?? false,
      createdAt: json['created_at'] ?? '',
      userDetails: MindForceUser.fromJson(json['user_details'] ?? {}),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
    );
  }

  MindForceComment copyWith({
    String? id,
    String? content,
    bool? isSolved,
    String? createdAt,
    MindForceUser? userDetails,
    List<String>? images,
  }) {
    return MindForceComment(
      id: id ?? this.id,
      content: content ?? this.content,
      isSolved: isSolved ?? this.isSolved,
      createdAt: createdAt ?? this.createdAt,
      userDetails: userDetails ?? this.userDetails,
      images: images ?? this.images,
    );
  }
}
