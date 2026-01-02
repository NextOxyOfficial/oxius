import '../config/app_config.dart';

// Helper function to parse IDs that can be strings or integers
int _parseId(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class BusinessNetworkPost {
  final int id;
  final String title;
  final BusinessNetworkUser user;
  final String content;
  final List<PostMedia> media;
  final List<PostTag> tags;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final String createdAt;
  final String? category;
  final List<BusinessNetworkComment> comments;
  final List<PostLike> postLikes;

  BusinessNetworkPost({
    required this.id,
    required this.title,
    required this.user,
    required this.content,
    required this.media,
    required this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isSaved,
    required this.createdAt,
    this.category,
    required this.comments,
    required this.postLikes,
  });

  factory BusinessNetworkPost.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both 'user' and 'author_details' fields
      final userData = json['author_details'] ?? json['user'];

      // Handle post media - merge possible keys
      final List<dynamic> mergedMediaList = [];
      final postMediaList = json['post_media'] ?? json['media'];
      if (postMediaList is List) mergedMediaList.addAll(postMediaList);
      final imagesList = json['images'];
      if (imagesList is List) mergedMediaList.addAll(imagesList);
      final videosList = json['videos'];
      if (videosList is List) mergedMediaList.addAll(videosList);

      final mediaItems = mergedMediaList.map((e) {
        try {
          if (e is Map) {
            return PostMedia.fromJson(Map<String, dynamic>.from(e));
          }

          final raw = e.toString();
          final lower = raw.toLowerCase();
          final looksLikeVideo = lower.contains('.mp4') ||
              lower.contains('.mov') ||
              lower.contains('.m4v') ||
              lower.contains('.webm') ||
              lower.contains('.mkv') ||
              lower.contains('.avi');

          if (looksLikeVideo) {
            return PostMedia(
              id: 0,
              image: '',
              type: 'video',
              url: raw,
              video: raw,
              thumbnail: '',
              post: _parseId(json['id']),
            );
          }

          return PostMedia(
            id: 0,
            image: raw,
            type: 'image',
            url: raw,
            video: null,
            thumbnail: null,
            post: _parseId(json['id']),
          );
        } catch (e) {
          print('Error parsing media item: $e');
          return null;
        }
      }).whereType<PostMedia>().toList();
      
      // Handle post tags - ensure it's a list
      final tagsList = json['post_tags'] ?? [];
      final tagItems = (tagsList is List ? tagsList : []).map((e) {
        try {
          if (e is Map) {
            return PostTag.fromJson(Map<String, dynamic>.from(e));
          }
          return PostTag(id: 0, tag: e.toString());
        } catch (e) {
          print('Error parsing tag item: $e');
          return null;
        }
      }).whereType<PostTag>().toList();
      
      // Handle both 'comments' and 'post_comments' fields - ensure it's a list
      final commentsList = json['post_comments'] ?? json['comments'] ?? [];
      
      // Handle post likes - ensure it's a list
      final likesData = json['post_likes'] ?? [];
      final likesList = (likesData is List ? likesData : []).map((e) {
        try {
          if (e is Map) {
            return PostLike.fromJson(Map<String, dynamic>.from(e));
          }
          return PostLike(id: 0, user: 0);
        } catch (e) {
          print('Error parsing like item: $e');
          return null;
        }
      }).whereType<PostLike>().toList();
      
      bool isLiked = json['is_liked'] ?? likesList.isNotEmpty;
      
      return BusinessNetworkPost(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title'] ?? '',
        user: userData != null
            ? BusinessNetworkUser.fromJson(userData)
            : BusinessNetworkUser(id: 0, name: 'Unknown', isVerified: false, isPro: false),
        content: json['content'] ?? '',
        media: mediaItems,
        tags: tagItems,
        likesCount: json['like_count'] ?? json['likes_count'] ?? 0,
        commentsCount: json['comment_count'] ?? json['comments_count'] ?? 0,
        isLiked: isLiked,
        isSaved: json['is_saved'] ?? json['isSaved'] ?? false,
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        category: json['category'],
        comments: (commentsList is List ? commentsList : [])
                .map((e) {
                  try {
                    return BusinessNetworkComment.fromJson(
                        e is Map ? Map<String, dynamic>.from(e) : e);
                  } catch (e) {
                    print('Error parsing comment: $e');
                    return null;
                  }
                })
                .whereType<BusinessNetworkComment>()
                .toList(),
        postLikes: likesList,
      );
    } catch (e, stackTrace) {
      print('Error parsing BusinessNetworkPost: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user': user.toJson(),
      'content': content,
      'post_media': media.map((e) => e.toJson()).toList(),
      'post_tags': tags.map((e) => e.toJson()).toList(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'created_at': createdAt,
      'category': category,
      'comments': comments.map((e) => e.toJson()).toList(),
      'post_likes': postLikes.map((e) => e.toJson()).toList(),
    };
  }

  BusinessNetworkPost copyWith({
    BusinessNetworkUser? user,
    List<PostMedia>? media,
    int? likesCount,
    bool? isLiked,
    bool? isSaved,
    int? commentsCount,
    List<BusinessNetworkComment>? comments,
    List<PostLike>? postLikes,
  }) {
    return BusinessNetworkPost(
      id: id,
      title: title,
      user: user ?? this.user,
      content: content,
      media: media ?? this.media,
      tags: tags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt,
      category: category,
      comments: comments ?? this.comments,
      postLikes: postLikes ?? this.postLikes,
    );
  }
}

class PostMedia {
  final int id;
  final String image;
  final String? type;
  final String? url;
  final String? video;
  final String? thumbnail;
  final int views;
  final int post;

  PostMedia({
    required this.id,
    required this.image,
    this.type,
    this.url,
    this.video,
    this.thumbnail,
    this.views = 0,
    required this.post,
  });

  bool get isVideo {
    final t = (type ?? '').toLowerCase().trim();
    if (t == 'video') return true;

    final raw = '${video ?? ''} ${url ?? ''} ${image} ${thumbnail ?? ''}'.toLowerCase();
    if (raw.contains('.mp4') ||
        raw.contains('.mov') ||
        raw.contains('.m4v') ||
        raw.contains('.webm') ||
        raw.contains('.mkv') ||
        raw.contains('.avi')) {
      return true;
    }

    if ((video ?? '').isNotEmpty) return true;
    return false;
  }

  String get bestUrl {
    if (isVideo) {
      return AppConfig.getAbsoluteUrl((video ?? url ?? image).toString());
    }
    final value = (image.isNotEmpty ? image : (url ?? thumbnail ?? '')).toString();
    return AppConfig.getAbsoluteUrl(value);
  }

  String get bestThumbnailUrl {
    final thumb = (thumbnail ?? '').toString();
    if (thumb.isNotEmpty) return AppConfig.getAbsoluteUrl(thumb);

    if (!isVideo) {
      final u = (url ?? '').toString();
      if (u.isNotEmpty) return AppConfig.getAbsoluteUrl(u);
    }

    final img = image.toString();
    final lower = img.toLowerCase();
    final looksLikeVideo = lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.m4v') ||
        lower.contains('.webm') ||
        lower.contains('.mkv') ||
        lower.contains('.avi');

    if (img.isNotEmpty && !looksLikeVideo) {
      return AppConfig.getAbsoluteUrl(img);
    }

    // For videos, try using the image field even if it looks like video URL
    // This helps when backend stores video URL in image field but has separate thumbnail
    if (isVideo) {
      final videoThumb = (video ?? '').toString();
      // Check if there's a thumbnail parameter in video URL
      if (videoThumb.contains('thumb') || videoThumb.contains('poster')) {
        return AppConfig.getAbsoluteUrl(videoThumb);
      }
    }

    return '';
  }

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString();
    final rawImage = (json['image'] ?? '').toString();
    final rawVideo = (json['video'] ?? json['video_url'] ?? '').toString();
    final rawUrl = (json['url'] ?? '').toString();
    final rawThumb = (json['thumbnail'] ?? json['thumbnail_url'] ?? json['thumb'] ?? '').toString();
    final rawViews = json['views'];

    return PostMedia(
      id: _parseId(json['id']),
      image: rawImage,
      type: rawType,
      url: rawUrl.isNotEmpty ? rawUrl : null,
      video: rawVideo.isNotEmpty ? rawVideo : null,
      thumbnail: rawThumb.isNotEmpty ? rawThumb : null,
      views: rawViews is int ? rawViews : int.tryParse((rawViews ?? '').toString()) ?? 0,
      post: _parseId(json['post']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'type': type,
      'url': url,
      'video': video,
      'thumbnail': thumbnail,
      'views': views,
      'post': post,
    };
  }
}

class PostTag {
  final int id;
  final String tag;

  PostTag({
    required this.id,
    required this.tag,
  });

  factory PostTag.fromJson(Map<String, dynamic> json) {
    return PostTag(
      id: _parseId(json['id']),
      tag: json['tag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
    };
  }
}

class PostLike {
  final int id;
  final int user;

  PostLike({
    required this.id,
    required this.user,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: _parseId(json['id']),
      user: _parseId(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
    };
  }
}

class BusinessNetworkUser {
  final int id;
  final String? uuid; // Original UUID string for API calls
  final String name;
  final String? avatar;
  final String? image;
  final bool isVerified;
  final bool isPro;
  final String? bio;
  final String? username;
  final String? firstName;
  final String? lastName;
  final bool isFollowing;

  BusinessNetworkUser({
    required this.id,
    this.uuid,
    required this.name,
    this.avatar,
    this.image,
    required this.isVerified,
    this.isPro = false,
    this.bio,
    this.username,
    this.firstName,
    this.lastName,
    this.isFollowing = false,
  });

  factory BusinessNetworkUser.fromJson(Map<String, dynamic> json) {
    // Build full name from first_name and last_name if name is not provided
    String displayName = json['name'] ?? json['username'] ?? '';
    if (displayName.isEmpty && (json['first_name'] != null || json['last_name'] != null)) {
      displayName = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    }
    if (displayName.isEmpty) {
      displayName = 'User';
    }
    
    // Handle UUID strings by using hashCode
    final idValue = json['id'];
    int parsedId;
    String? uuidString;
    
    if (idValue is String) {
      uuidString = idValue; // Store original UUID
      // Try to parse as int first, if that fails use hashCode for UUID
      parsedId = int.tryParse(idValue) ?? idValue.hashCode;
    } else {
      parsedId = _parseId(idValue);
    }
    
    // Handle all possible profile picture field names from backend
    // Priority: image > avatar > profile_picture
    final imageValue = json['image'];
    final avatarValue = json['avatar'];
    final profilePictureValue = json['profile_picture'];
    
    return BusinessNetworkUser(
      id: parsedId,
      uuid: uuidString,
      name: displayName,
      avatar: avatarValue ?? profilePictureValue,
      image: imageValue,
      isVerified: json['is_verified'] ?? json['kyc'] ?? false,
      isPro: json['is_pro'] ?? json['isPro'] ?? json['pro'] ?? false,
      bio: json['bio'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isFollowing: json['is_following'] ?? json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'image': image,
      'is_verified': isVerified,
      'is_pro': isPro,
      'bio': bio,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'is_following': isFollowing,
    };
  }
}

class BusinessNetworkComment {
  final int id;
  final BusinessNetworkUser user;
  final String content;
  final String createdAt;
  final int? parentComment;
  final bool isGiftComment;
  final int? diamondAmount;

  BusinessNetworkComment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    this.parentComment,
    this.isGiftComment = false,
    this.diamondAmount,
  });

  factory BusinessNetworkComment.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json['author_details'];
    return BusinessNetworkComment(
      id: _parseId(json['id']),
      user: userData != null
          ? BusinessNetworkUser.fromJson(userData)
          : BusinessNetworkUser(id: 0, name: 'Unknown', isVerified: false, isPro: false),
      content: json['content'] ?? json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      parentComment: _parseId(json['parent_comment']),
      isGiftComment: json['is_gift_comment'] == true,
      diamondAmount: json['diamond_amount'] != null ? int.tryParse(json['diamond_amount'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'created_at': createdAt,
      'parent_comment': parentComment,
      'is_gift_comment': isGiftComment,
      'diamond_amount': diamondAmount,
    };
  }
}
