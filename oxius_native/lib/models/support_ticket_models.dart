class SupportTicket {
  final String id;
  final TicketUser user;
  final String title;
  final String message;
  final String status; // open, in_progress, resolved, closed
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketReply> replies;
  final int replyCount;
  final DateTime? lastReadAt;
  final bool isUnread;

  SupportTicket({
    required this.id,
    required this.user,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
    required this.replyCount,
    this.lastReadAt,
    required this.isUnread,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      user: TicketUser.fromJson(json['user'] ?? {}),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      replies: (json['replies'] as List?)
          ?.map((r) => TicketReply.fromJson(r))
          .toList() ?? [],
      replyCount: json['reply_count'] ?? 0,
      lastReadAt: json['last_read_at'] != null 
          ? DateTime.parse(json['last_read_at']) 
          : null,
      isUnread: json['is_unread'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'title': title,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
      'reply_count': replyCount,
      'last_read_at': lastReadAt?.toIso8601String(),
      'is_unread': isUnread,
    };
  }
}

class TicketReply {
  final String id;
  final TicketUser user;
  final String message;
  final bool isFromAdmin;
  final DateTime createdAt;

  TicketReply({
    required this.id,
    required this.user,
    required this.message,
    required this.isFromAdmin,
    required this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['id']?.toString() ?? '',
      user: TicketUser.fromJson(json['user'] ?? {}),
      message: json['message'] ?? '',
      isFromAdmin: json['is_from_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'message': message,
      'is_from_admin': isFromAdmin,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TicketUser {
  final String id;
  final String username;
  final String email;
  final String? image;

  TicketUser({
    required this.id,
    required this.username,
    required this.email,
    this.image,
  });

  factory TicketUser.fromJson(Map<String, dynamic> json) {
    return TicketUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'image': image,
    };
  }
}
