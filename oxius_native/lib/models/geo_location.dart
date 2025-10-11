class GeoLocation {
  final String country;
  final String? state;
  final String? city;
  final String? upazila;
  final bool allOverBangladesh;

  GeoLocation({
    this.country = 'Bangladesh',
    this.state,
    this.city,
    this.upazila,
    this.allOverBangladesh = false,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      country: json['country']?.toString() ?? 'Bangladesh',
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      upazila: json['upazila']?.toString(),
      allOverBangladesh: json['allOverBangladesh'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'state': state,
      'city': city,
      'upazila': upazila,
      'allOverBangladesh': allOverBangladesh,
    };
  }

  bool get isComplete => allOverBangladesh || (state != null && city != null && upazila != null);

  String get displayLocation {
    if (allOverBangladesh) return 'All over Bangladesh';
    final parts = <String>[];
    if (upazila != null) parts.add(upazila!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (parts.isEmpty) parts.add(country);
    return parts.join(', ');
  }

  GeoLocation copyWith({
    String? country,
    String? state,
    String? city,
    String? upazila,
    bool? allOverBangladesh,
  }) {
    return GeoLocation(
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      upazila: upazila ?? this.upazila,
      allOverBangladesh: allOverBangladesh ?? this.allOverBangladesh,
    );
  }
}

class Region {
  final String id;
  final String nameEng;
  final String? nameBn;
  final String? countryNameEng;

  Region({
    required this.id,
    required this.nameEng,
    this.nameBn,
    this.countryNameEng,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id']?.toString() ?? '',
      nameEng: json['name_eng']?.toString() ?? '',
      nameBn: json['name_ban']?.toString() ?? json['name_bn']?.toString(),
      countryNameEng: json['country']?.toString() ?? json['country_name_eng']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_eng': nameEng,
      'name_bn': nameBn,
      'country_name_eng': countryNameEng,
    };
  }
}

class City {
  final String id;
  final String nameEng;
  final String? nameBn;
  final String? regionNameEng;

  City({
    required this.id,
    required this.nameEng,
    this.nameBn,
    this.regionNameEng,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id']?.toString() ?? '',
      nameEng: json['name_eng']?.toString() ?? '',
      nameBn: json['name_ban']?.toString() ?? json['name_bn']?.toString(),
      regionNameEng: json['region']?.toString() ?? json['region_name_eng']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_eng': nameEng,
      'name_bn': nameBn,
      'region_name_eng': regionNameEng,
    };
  }
}

class Upazila {
  final String id;
  final String nameEng;
  final String? nameBn;
  final String? cityNameEng;

  Upazila({
    required this.id,
    required this.nameEng,
    this.nameBn,
    this.cityNameEng,
  });

  factory Upazila.fromJson(Map<String, dynamic> json) {
    return Upazila(
      id: json['id']?.toString() ?? '',
      nameEng: json['name_eng']?.toString() ?? '',
      nameBn: json['name_ban']?.toString() ?? json['name_bn']?.toString(),
      cityNameEng: json['city']?.toString() ?? json['city_name_eng']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_eng': nameEng,
      'name_bn': nameBn,
      'city_name_eng': cityNameEng,
    };
  }
}
