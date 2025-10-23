class NewsPost {
  final dynamic id; // Can be int or String
  final String slug;
  final String title;
  final String content;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final AuthorDetails? authorDetails;
  final List<NewsComment> comments;

  NewsPost({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.authorDetails,
    this.comments = const [],
  });

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    return NewsPost(
      id: json['id'],
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      authorDetails: json['author_details'] != null
          ? AuthorDetails.fromJson(json['author_details'])
          : null,
      comments: json['post_comments'] != null
          ? (json['post_comments'] as List)
              .map((c) => NewsComment.fromJson(c))
              .toList()
          : [],
    );
  }

  String get formattedDate {
    return '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';
  }

  String get summary {
    if (content.isEmpty) return 'No content available';
    final plainText = content.replaceAll(RegExp(r'<[^>]*>'), '');
    return plainText.length > 150
        ? '${plainText.substring(0, 150)}...'
        : plainText;
  }

  int get readTime {
    return (content.length / 1000).ceil();
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class AuthorDetails {
  final dynamic id; // Can be int or String
  final String? name;
  final String? profession;
  final String? image;
  final String? firstName;
  final String? lastName;

  AuthorDetails({
    required this.id,
    this.name,
    this.profession,
    this.image,
    this.firstName,
    this.lastName,
  });

  factory AuthorDetails.fromJson(Map<String, dynamic> json) {
    return AuthorDetails(
      id: json['id'],
      name: json['name'],
      profession: json['profession'],
      image: json['image'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final first = firstName ?? '';
    final last = lastName ?? '';
    final fullName = '$first $last'.trim();
    return fullName.isNotEmpty ? fullName : 'Anonymous';
  }
}

class NewsComment {
  final dynamic id; // Can be int or String
  final String content;
  final DateTime createdAt;
  final dynamic userId; // Can be int or String
  final String? userName;

  NewsComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    this.userName,
  });

  factory NewsComment.fromJson(Map<String, dynamic> json) {
    return NewsComment(
      id: json['id'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userId: json['user'],
      userName: json['user_name'],
    );
  }
}

class NewsCategory {
  final dynamic id; // Can be int or String
  final String name;
  final String slug;
  final String? description;

  NewsCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      id: json['id'], // Accept both int and String
      name: json['name'] ?? json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
    );
  }
}

class TipSuggestion {
  final dynamic id; // Can be int or String
  final String title;
  final String description;

  TipSuggestion({
    required this.id,
    required this.title,
    required this.description,
  });

  factory TipSuggestion.fromJson(Map<String, dynamic> json) {
    return TipSuggestion(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class PaginatedNewsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<NewsPost> results;

  PaginatedNewsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedNewsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedNewsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: json['results'] != null
          ? (json['results'] as List).map((p) => NewsPost.fromJson(p)).toList()
          : [],
    );
  }

  bool get hasMore => next != null;
}
