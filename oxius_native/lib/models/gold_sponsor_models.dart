class SponsorshipPackage {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationMonths;
  final bool isActive;

  SponsorshipPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMonths,
    this.isActive = true,
  });

  factory SponsorshipPackage.fromJson(Map<String, dynamic> json) {
    // Parse price - handle both string and number
    double price = 0;
    if (json['price'] is String) {
      price = double.tryParse(json['price']) ?? 0;
    } else if (json['price'] is num) {
      price = json['price'].toDouble();
    }
    
    return SponsorshipPackage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: price,
      durationMonths: json['duration_months'] ?? 1,
      isActive: json['is_active'] ?? true,
    );
  }
}

class GoldSponsor {
  final String id;
  final String businessName;
  final String? logo;
  final String? businessDescription;
  final String? contactEmail;
  final String? phoneNumber;
  final String? website;
  final String? profileUrl;
  final List<String> banners;
  final String packageType;
  final String? startDate;
  final String? endDate;
  final String status;
  final bool isFeatured;
  final int views;

  GoldSponsor({
    required this.id,
    required this.businessName,
    this.logo,
    this.businessDescription,
    this.contactEmail,
    this.phoneNumber,
    this.website,
    this.profileUrl,
    this.banners = const [],
    required this.packageType,
    this.startDate,
    this.endDate,
    required this.status,
    this.isFeatured = false,
    this.views = 0,
  });

  factory GoldSponsor.fromJson(Map<String, dynamic> json) {
    // Extract package name from nested object
    String packageName = 'gold';
    if (json['package'] is Map) {
      packageName = json['package']['name'] ?? 'gold';
    } else if (json['package'] is String) {
      packageName = json['package'];
    }
    
    return GoldSponsor(
      id: json['id']?.toString() ?? '0',
      businessName: json['business_name'] ?? 'Unknown Business',
      logo: json['logo'],
      businessDescription: json['business_description'],
      contactEmail: json['contact_email'],
      phoneNumber: json['phone_number'],
      website: json['website'],
      profileUrl: json['profile_url'],
      banners: [], // Will be fetched separately if needed
      packageType: packageName,
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'] ?? 'active',
      isFeatured: json['is_featured'] == true,
      views: json['views'] ?? 0,
    );
  }
}

class SponsorBanner {
  final String id;
  final String image;
  final int order;
  final bool isActive;

  SponsorBanner({
    required this.id,
    required this.image,
    required this.order,
    this.isActive = true,
  });

  factory SponsorBanner.fromJson(Map<String, dynamic> json) {
    return SponsorBanner(
      id: json['id']?.toString() ?? '0',
      image: json['image'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['is_active'] == true,
    );
  }
}
