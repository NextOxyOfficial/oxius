class ClassifiedCategory {
  final int id;
  final String title;
  final String slug;
  final String? image;
  final String? icon;
  final int? postCount;

  ClassifiedCategory({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
    this.icon,
    this.postCount,
  });

  factory ClassifiedCategory.fromJson(Map<String, dynamic> json) {
    return ClassifiedCategory(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'],
      icon: json['icon'],
      postCount: json['post_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'image': image,
      'icon': icon,
      'post_count': postCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassifiedCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}