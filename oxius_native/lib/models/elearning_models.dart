// E-Learning Models for Flutter App

class Batch {
  final String id;
  final String name;
  final String code;
  final String description;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Batch({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.icon,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Division {
  final String id;
  final String name;
  final String code;
  final String description;
  final String? icon;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Division({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.icon,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String description;
  final String? icon;
  final String color;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.icon,
    required this.color,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      color: json['color'] ?? '#3B82F6',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'icon': icon,
      'color': color,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VideoLesson {
  final String id;
  final String title;
  final String? titleBn;
  final String description;
  final String? descriptionBn;
  final String youtubeUrl;
  final String lessonName;
  final String? lessonNameBn;
  final String duration;
  final String? thumbnailUrl;
  final int viewsCount;
  final String subjectId;
  final int displayOrder;
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoLesson({
    required this.id,
    required this.title,
    this.titleBn,
    required this.description,
    this.descriptionBn,
    required this.youtubeUrl,
    required this.lessonName,
    this.lessonNameBn,
    required this.duration,
    this.thumbnailUrl,
    required this.viewsCount,
    required this.subjectId,
    required this.displayOrder,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoLesson.fromJson(Map<String, dynamic> json) {
    return VideoLesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleBn: json['title_bn'],
      description: json['description'] ?? '',
      descriptionBn: json['description_bn'],
      youtubeUrl: json['youtube_url'] ?? '',
      lessonName: json['lesson_name'] ?? '',
      lessonNameBn: json['lesson_name_bn'],
      duration: json['duration'] ?? '0:00',
      thumbnailUrl: json['thumbnail_url'],
      viewsCount: json['views_count'] ?? 0,
      subjectId: json['subject'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_bn': titleBn,
      'description': description,
      'description_bn': descriptionBn,
      'youtube_url': youtubeUrl,
      'lesson_name': lessonName,
      'lesson_name_bn': lessonNameBn,
      'duration': duration,
      'thumbnail_url': thumbnailUrl,
      'views_count': viewsCount,
      'subject': subjectId,
      'display_order': displayOrder,
      'is_active': isActive,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Extract YouTube video ID from URL
  String? getYoutubeId() {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(youtubeUrl);
    return match?.group(1);
  }

  // Get YouTube thumbnail URL
  String getYoutubeThumbnail() {
    final videoId = getYoutubeId();
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return thumbnailUrl ?? '';
  }
}
