class User {
  final String id;
  final String name;
  final String? username;
  final String? image;
  final String? avatar;
  final String? profession;
  final String? phone;
  final String? email;
  final bool isVerified;
  final bool isPro;

  User({
    required this.id,
    required this.name,
    this.username,
    this.image,
    this.avatar,
    this.profession,
    this.phone,
    this.email,
    this.isVerified = false,
    this.isPro = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle different name formats from API
    String displayName = json['name'] ?? '';
    if (displayName.isEmpty) {
      final firstName = json['first_name'] ?? '';
      final lastName = json['last_name'] ?? '';
      displayName = '$firstName $lastName'.trim();
    }
    if (displayName.isEmpty) {
      displayName = json['username'] ?? 'Unknown User';
    }

    return User(
      id: json['id']?.toString() ?? '',
      name: displayName,
      username: json['username'],
      image: json['image'],
      avatar: json['avatar'],
      profession: json['profession'],
      phone: json['phone'],
      email: json['email'],
      // Backend serializers use kyc for the verified flag.
      isVerified: json['is_verified'] ?? (json['kyc'] == true),
      isPro: json['is_pro'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (username != null) 'username': username,
      if (image != null) 'image': image,
      if (avatar != null) 'avatar': avatar,
      if (profession != null) 'profession': profession,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'is_verified': isVerified,
      'is_pro': isPro,
    };
  }
}
