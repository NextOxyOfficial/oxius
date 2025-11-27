class UserProfile {
  final String? id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? upazila;
  final String? zip;
  final String? image;
  final String? storeBanner;
  final String? faceLink;
  final String? instagramLink;
  final String? whatsappLink;
  final String? profession;
  final String? company;
  final String? website;
  final String? about;
  final bool? kyc;
  final String? country;
  final double balance;
  final int diamondBalance;
  final bool isPro;
  final bool isVerified;
  final bool? emailPublic;
  final bool? phonePublic;

  UserProfile({
    this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.upazila,
    this.zip,
    this.image,
    this.storeBanner,
    this.faceLink,
    this.instagramLink,
    this.whatsappLink,
    this.profession,
    this.company,
    this.website,
    this.about,
    this.kyc,
    this.country,
    this.balance = 0.0,
    this.diamondBalance = 0,
    this.isPro = false,
    this.isVerified = false,
    this.emailPublic,
    this.phonePublic,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      upazila: json['upazila'],
      zip: json['zip'],
      image: json['image'],
      storeBanner: json['store_banner'],
      faceLink: json['face_link'],
      instagramLink: json['instagram_link'],
      whatsappLink: json['whatsapp_link'],
      profession: json['profession'],
      company: json['company'],
      website: json['website'],
      about: json['about'],
      kyc: json['kyc'],
      country: json['country'],
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      diamondBalance: int.tryParse(json['diamond_balance']?.toString() ?? '0') ?? 0,
      isPro: json['is_pro'] ?? false,
      isVerified: json['kyc'] ?? false,
      emailPublic: json['email_public'],
      phonePublic: json['phone_public'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (upazila != null) 'upazila': upazila,
      if (zip != null) 'zip': zip,
      if (image != null) 'image': image,
      if (storeBanner != null) 'store_banner': storeBanner,
      if (faceLink != null) 'face_link': faceLink,
      if (instagramLink != null) 'instagram_link': instagramLink,
      if (whatsappLink != null) 'whatsapp_link': whatsappLink,
      if (profession != null) 'profession': profession,
      if (company != null) 'company': company,
      if (website != null) 'website': website,
      if (about != null) 'about': about,
      if (kyc != null) 'kyc': kyc,
      if (country != null) 'country': country,
      'balance': balance,
      'diamond_balance': diamondBalance,
      'is_pro': isPro,
      'is_verified': isVerified,
      if (emailPublic != null) 'email_public': emailPublic,
      if (phonePublic != null) 'phone_public': phonePublic,
      'name': '${firstName ?? ''} ${lastName ?? ''}'.trim(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? upazila,
    String? zip,
    String? image,
    String? storeBanner,
    String? faceLink,
    String? instagramLink,
    String? whatsappLink,
    String? profession,
    String? company,
    String? website,
    String? about,
    bool? kyc,
    String? country,
    double? balance,
    int? diamondBalance,
    bool? isPro,
    bool? isVerified,
    bool? emailPublic,
    bool? phonePublic,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      upazila: upazila ?? this.upazila,
      zip: zip ?? this.zip,
      image: image ?? this.image,
      storeBanner: storeBanner ?? this.storeBanner,
      faceLink: faceLink ?? this.faceLink,
      instagramLink: instagramLink ?? this.instagramLink,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      profession: profession ?? this.profession,
      company: company ?? this.company,
      website: website ?? this.website,
      about: about ?? this.about,
      kyc: kyc ?? this.kyc,
      country: country ?? this.country,
      balance: balance ?? this.balance,
      diamondBalance: diamondBalance ?? this.diamondBalance,
      isPro: isPro ?? this.isPro,
      isVerified: isVerified ?? this.isVerified,
      emailPublic: emailPublic ?? this.emailPublic,
      phonePublic: phonePublic ?? this.phonePublic,
    );
  }
}

class Country {
  final String code;
  final String name;
  final String flag;

  Country({
    required this.code,
    required this.name,
    required this.flag,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      flag: json['flag'] ?? '',
    );
  }
}
