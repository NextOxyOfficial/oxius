class MindForceProblem {
  final int id;
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
      id: json['id'] ?? 0,
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
      category: json['category'] != null 
          ? MindForceCategory.fromJson(json['category']) 
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
    int? id,
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
  final int id;
  final String name;
  final String? image;
  final String? username;

  MindForceUser({
    required this.id,
    required this.name,
    this.image,
    this.username,
  });

  factory MindForceUser.fromJson(Map<String, dynamic> json) {
    return MindForceUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['username'] ?? 'Unknown User',
      image: json['image'] ?? json['avatar'],
      username: json['username'],
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
    );
  }
}

class MindForceMedia {
  final int id;
  final String image;

  MindForceMedia({
    required this.id,
    required this.image,
  });

  factory MindForceMedia.fromJson(Map<String, dynamic> json) {
    return MindForceMedia(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
    );
  }
}

class MindForceComment {
  final int id;
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
      id: json['id'] ?? 0,
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
    int? id,
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
