class NotificationModel {
  final int id;
  final String type;
  final NotificationActor? actor;
  final String? content;
  final String createdAt;
  final bool read;
  final int? targetId;
  final String? targetType;

  NotificationModel({
    required this.id,
    required this.type,
    this.actor,
    this.content,
    required this.createdAt,
    required this.read,
    this.targetId,
    this.targetType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      actor: json['actor'] != null 
          ? NotificationActor.fromJson(json['actor']) 
          : null,
      content: json['content'],
      createdAt: json['created_at'] ?? '',
      read: json['read'] ?? false,
      targetId: json['target_id'],
      targetType: json['target_type'],
    );
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    NotificationActor? actor,
    String? content,
    String? createdAt,
    bool? read,
    int? targetId,
    String? targetType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actor: actor ?? this.actor,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
    );
  }
}

class NotificationActor {
  final int id;
  final String name;
  final String? image;
  final String? username;

  NotificationActor({
    required this.id,
    required this.name,
    this.image,
    this.username,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['username'] ?? 'Unknown User',
      image: json['image'] ?? json['avatar'],
      username: json['username'],
    );
  }
}

// Notification types enum
class NotificationType {
  static const String follow = 'follow';
  static const String likePost = 'like_post';
  static const String likeComment = 'like_comment';
  static const String comment = 'comment';
  static const String mention = 'mention';
  static const String share = 'share';
  static const String reply = 'reply';
}
