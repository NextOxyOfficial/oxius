class SalePost {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final double price;
  final String condition; // new, like_new, good, fair, poor
  final String country;
  final String? state;
  final String? city;
  final String? upazila;
  final String? location;
  final String? division;
  final String? district;
  final String? area;
  final String? categoryId;
  final String? categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final List<SaleImage>? images;
  final SaleUser? user;
  final int viewsCount;
  final String status; // pending, active, sold, expired
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SalePost({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.price,
    required this.condition,
    required this.country,
    this.state,
    this.city,
    this.upazila,
    this.location,
    this.division,
    this.district,
    this.area,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.images,
    this.user,
    this.viewsCount = 0,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  // Helper getter for backward compatibility
  bool get isActive => status == 'active';

  factory SalePost.fromJson(Map<String, dynamic> json) {
    return SalePost(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      condition: json['condition'] as String? ?? 'good',
      country: json['country'] as String? ?? 'Bangladesh',
      state: json['state'] as String?,
      city: json['city'] as String?,
      upazila: json['upazila'] as String?,
      location: json['location'] as String?,
      division: json['division'] as String?,
      district: json['district'] as String?,
      area: json['area'] as String?,
      categoryId: json['category']?.toString(),
      categoryName: json['category_name'] as String?,
      subcategoryId: json['subcategory']?.toString(),
      subcategoryName: json['subcategory_name'] as String?,
      images: json['images'] != null
          ? (json['images'] as List).map((e) => SaleImage.fromJson(e)).toList()
          : null,
      user: json['user'] != null ? SaleUser.fromJson(json['user']) : null,
      viewsCount: json['view_count'] as int? ?? json['views_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'price': price,
      'condition': condition,
      'country': country,
      'state': state,
      'city': city,
      'upazila': upazila,
      'location': location,
      'division': division,
      'district': district,
      'area': area,
      'category': categoryId,
      'subcategory': subcategoryId,
      'status': status,
      'view_count': viewsCount,
    };
  }
}

class SaleImage {
  final String id;
  final String image;
  final int order;

  SaleImage({
    required this.id,
    required this.image,
    this.order = 0,
  });

  factory SaleImage.fromJson(Map<String, dynamic> json) {
    return SaleImage(
      id: json['id']?.toString() ?? '',
      image: json['image'] as String? ?? '',
      order: json['order'] as int? ?? 0,
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

class SaleUser {
  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String? phone;

  SaleUser({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.phone,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username ?? 'User';
  }

  factory SaleUser.fromJson(Map<String, dynamic> json) {
    return SaleUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePicture: json['profile_picture'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class SaleCategory {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameBn;
  final String? icon;
  final String? image;
  final int order;
  final int postCount;
  final List<SaleSubcategory>? subcategories;

  SaleCategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameBn,
    this.icon,
    this.image,
    this.order = 0,
    this.postCount = 0,
    this.subcategories,
  });

  factory SaleCategory.fromJson(Map<String, dynamic> json) {
    return SaleCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      order: json['order'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((e) => SaleSubcategory.fromJson(e))
              .toList()
          : null,
    );
  }
}

class SaleSubcategory {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameBn;
  final String categoryId;
  final int order;
  final int postCount;

  SaleSubcategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameBn,
    required this.categoryId,
    this.order = 0,
    this.postCount = 0,
  });

  factory SaleSubcategory.fromJson(Map<String, dynamic> json) {
    return SaleSubcategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      categoryId: json['category']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
      postCount: json['post_count'] as int? ?? 0,
    );
  }
}

class SalePostsResponse {
  final List<SalePost> results;
  final int count;
  final String? next;
  final String? previous;

  SalePostsResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
  });

  factory SalePostsResponse.fromJson(Map<String, dynamic> json) {
    return SalePostsResponse(
      results: (json['results'] as List?)
              ?.map((e) => SalePost.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}
