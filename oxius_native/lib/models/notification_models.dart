class NotificationModel {
  final int id;
  final String type;
  final NotificationActor? actor;
  final String? content;
  final String createdAt;
  final bool read;
  final String? targetId;
  final String? parentId;

  NotificationModel({
    required this.id,
    required this.type,
    this.actor,
    this.content,
    required this.createdAt,
    required this.read,
    this.targetId,
    this.parentId,
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
      targetId: json['target_id']?.toString(),
      parentId: json['parent_id']?.toString(),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    NotificationActor? actor,
    String? content,
    String? createdAt,
    bool? read,
    String? targetId,
    String? parentId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actor: actor ?? this.actor,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      targetId: targetId ?? this.targetId,
      parentId: parentId ?? this.parentId,
    );
  }
}

class NotificationActor {
  final String id;
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
      id: json['id']?.toString() ?? '0',
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
  static const String reply = 'reply';
  static const String mention = 'mention';
  static const String solution = 'solution';
  static const String giftDiamonds = 'gift_diamonds';
}
