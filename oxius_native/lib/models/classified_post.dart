class ClassifiedPost {
  final String id;
  final String title;
  final String? slug;
  final String? instructions;
  final double? price;
  final bool? negotiable;
  final String? country;
  final String? state;
  final String? city;
  final String? upazila;
  final String? location;
  final String? latitude;
  final String? longitude;
  final String serviceStatus;
  final bool activeService;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CategoryDetails? categoryDetails;
  final UserDetails? user;
  final List<MediaItem>? medias;
  final int viewsCount;

  ClassifiedPost({
    required this.id,
    required this.title,
    this.slug,
    this.instructions,
    this.price,
    this.negotiable,
    this.country,
    this.state,
    this.city,
    this.upazila,
    this.location,
    this.latitude,
    this.longitude,
    required this.serviceStatus,
    this.activeService = false,
    this.createdAt,
    this.updatedAt,
    this.categoryDetails,
    this.user,
    this.medias,
    this.viewsCount = 0,
  });

  factory ClassifiedPost.fromJson(Map<String, dynamic> json) {
    final dynamic rawUser =
        json['user'] ??
        json['seller'] ??
        json['owner'] ??
        json['provider'] ??
        json['created_by'] ??
        json['createdBy'] ??
        json['user_details'] ??
        json['userDetails'];

    UserDetails? user;
    if (rawUser is Map<String, dynamic>) {
      user = UserDetails.fromJson(rawUser);
    } else if (rawUser is Map) {
      user = UserDetails.fromJson(Map<String, dynamic>.from(rawUser));
    }

    return ClassifiedPost(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      instructions: json['instructions']?.toString(),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      negotiable: json['negotiable'] as bool?,
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      upazila: json['upazila']?.toString(),
      location: json['location']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      serviceStatus: json['service_status']?.toString() ?? 'pending',
      activeService: json['active_service'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      categoryDetails: json['category_details'] != null 
          ? CategoryDetails.fromJson(json['category_details'] as Map<String, dynamic>) 
          : null,
      user: user,
      medias: json['medias'] != null
          ? (json['medias'] as List).map((m) => MediaItem.fromJson(m as Map<String, dynamic>)).toList()
          : null,
      viewsCount: json['views_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'instructions': instructions,
      'price': price,
      'negotiable': negotiable,
      'country': country,
      'state': state,
      'city': city,
      'upazila': upazila,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'service_status': serviceStatus,
      'active_service': activeService,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'category_details': categoryDetails?.toJson(),
      'user': user?.toJson(),
      'medias': medias?.map((m) => m.toJson()).toList(),
      'views_count': viewsCount,
    };
  }

  String get displayPrice {
    if (negotiable == true) return 'Negotiable';
    if (price == null) return 'Contact for price';
    return '৳${price!.toStringAsFixed(0)}';
  }

  String getRelativeTime() {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 30) return '${difference.inDays} days ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
  }
}

class CategoryDetails {
  final String id;
  final String title;
  final String? slug;
  final String? image;
  final String? businessType;

  CategoryDetails({
    required this.id,
    required this.title,
    this.slug,
    this.image,
    this.businessType,
  });

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      image: json['image']?.toString(),
      businessType: json['business_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'image': image,
      'business_type': businessType,
    };
  }
}

class UserDetails {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;
  final String? phone;
  final String? profilePicture;
  final String? about;
  final String? faceLink;
  final String? instagramLink;
  final String? whatsappLink;
  final DateTime? createdAt;

  UserDetails({
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.phone,
    this.profilePicture,
    this.about,
    this.faceLink,
    this.instagramLink,
    this.whatsappLink,
    this.createdAt,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    final dynamic rawProfilePicture =
        json['profile_picture'] ??
        json['profilePicture'] ??
        json['profile_photo'] ??
        json['profilePhoto'] ??
        json['avatar'] ??
        json['image'];

    String? profilePicture;
    if (rawProfilePicture is String) {
      profilePicture = rawProfilePicture;
    } else if (rawProfilePicture is List && rawProfilePicture.isNotEmpty) {
      final first = rawProfilePicture.first;
      if (first is String) {
        profilePicture = first;
      } else if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        profilePicture = (map['url'] ??
                map['image'] ??
                map['path'] ??
                map['file'] ??
                map['src'] ??
                map['location'])
            ?.toString();
      } else {
        profilePicture = first?.toString();
      }
    } else if (rawProfilePicture is Map) {
      final map = Map<String, dynamic>.from(rawProfilePicture);
      profilePicture = (map['url'] ??
              map['image'] ??
              map['path'] ??
              map['file'] ??
              map['src'] ??
              map['location'])
          ?.toString();
    } else if (rawProfilePicture != null) {
      profilePicture = rawProfilePicture.toString();
    }

    return UserDetails(
      id: json['id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      profilePicture: profilePicture,
      about: json['about']?.toString(),
      faceLink: json['face_link']?.toString(),
      instagramLink: json['instagram_link']?.toString(),
      whatsappLink: json['whatsapp_link']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'about': about,
      'face_link': faceLink,
      'instagram_link': instagramLink,
      'whatsapp_link': whatsappLink,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (username != null) return username!;
    return 'Anonymous User';
  }

  String get maskedPhone {
    if (phone == null || phone!.length < 3) return 'XXXXXXX';
    return 'XXXXXXX${phone!.substring(phone!.length - 3)}';
  }
}

class MediaItem {
  final String? id;
  final String? image;
  final int? order;

  MediaItem({
    this.id,
    this.image,
    this.order,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id']?.toString(),
      image: json['image']?.toString(),
      order: json['order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'order': order,
    };
  }
}
