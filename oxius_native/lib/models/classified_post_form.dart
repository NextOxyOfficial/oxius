class ClassifiedPostForm {
  String? id;
  String? categoryId;
  String title;
  String instructions;
  double price;
  bool negotiable;
  String country;
  String? state;
  String? city;
  String? upazila;
  String location;
  List<dynamic> medias; // Can be String (URLs) or File objects
  bool acceptedPrivacy;
  String serviceStatus;
  bool activeService;

  ClassifiedPostForm({
    this.id,
    this.categoryId,
    this.title = '',
    this.instructions = '',
    this.price = 0.0,
    this.negotiable = false,
    this.country = 'Bangladesh',
    this.state,
    this.city,
    this.upazila,
    this.location = '',
    List<dynamic>? medias,
    this.acceptedPrivacy = false,
    this.serviceStatus = 'pending',
    this.activeService = true,
  }) : medias = medias ?? [];

  // Create form from existing post for editing
  factory ClassifiedPostForm.fromPost(Map<String, dynamic> json) {
    return ClassifiedPostForm(
      id: json['id']?.toString(),
      categoryId: json['category']?.toString(),
      title: json['title'] ?? '',
      instructions: json['instructions'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      negotiable: json['negotiable'] ?? false,
      country: json['country'] ?? 'Bangladesh',
      state: json['state'],
      city: json['city'],
      upazila: json['upazila'],
      location: json['location'] ?? '',
      medias: (json['medias'] as List?)?.map((m) => m['image'] ?? m).toList() ?? [],
      acceptedPrivacy: json['accepted_privacy'] ?? false,
      serviceStatus: json['service_status'] ?? 'pending',
      activeService: json['active_service'] ?? true,
    );
  }

  // Convert form to JSON for API submission
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (id != null) data['id'] = id;
    if (categoryId != null) data['category'] = categoryId;
    
    data['title'] = title;
    data['instructions'] = instructions;
    data['country'] = country;
    data['location'] = location;
    data['accepted_privacy'] = acceptedPrivacy;
    data['service_status'] = serviceStatus;
    data['active_service'] = activeService;

    // Handle price and negotiable
    if (negotiable) {
      data['negotiable'] = true;
    } else {
      data['price'] = price;
      data['negotiable'] = false;
    }

    // Add location fields if not all over Bangladesh
    if (state != null && state!.isNotEmpty) {
      data['state'] = state;
    }
    if (city != null && city!.isNotEmpty) {
      data['city'] = city;
    }
    if (upazila != null && upazila!.isNotEmpty) {
      data['upazila'] = upazila;
    }

    // Add medias
    if (medias.isNotEmpty) {
      data['medias'] = medias;
    }

    return data;
  }

  // Validate form
  bool validate({bool checkLocation = true}) {
    if (title.trim().isEmpty) return false;
    if (instructions.trim().isEmpty) return false;
    if (!negotiable && price <= 0) return false;
    if (location.trim().isEmpty) return false;
    if (!acceptedPrivacy) return false;
    if (categoryId == null || categoryId!.isEmpty) return false;

    // Check location fields if required
    if (checkLocation && state != null) {
      if (state!.isEmpty) return false;
      if (city == null || city!.isEmpty) return false;
      if (upazila == null || upazila!.isEmpty) return false;
    }

    return true;
  }

  // Get validation errors
  Map<String, String> getValidationErrors({bool checkLocation = true}) {
    final Map<String, String> errors = {};

    if (title.trim().isEmpty) {
      errors['title'] = 'You must enter a title!';
    }
    if (instructions.trim().isEmpty) {
      errors['instructions'] = 'You must enter a description!';
    }
    if (!negotiable && price <= 0) {
      errors['price'] = 'Price must be greater than 0 or Negotiable';
    }
    if (location.trim().isEmpty) {
      errors['location'] = 'You must enter your address!';
    }
    if (!acceptedPrivacy) {
      errors['privacy'] = 'You must accept our Terms & Conditions and Privacy Policy';
    }
    if (categoryId == null || categoryId!.isEmpty) {
      errors['category'] = 'You must select a category';
    }

    // Check location fields if required
    if (checkLocation && state != null && state!.isNotEmpty) {
      if (city == null || city!.isEmpty) {
        errors['city'] = 'You must select a city';
      }
      if (upazila == null || upazila!.isEmpty) {
        errors['upazila'] = 'You must select a Area/Upazila';
      }
    }
    if (checkLocation && (state == null || state!.isEmpty)) {
      errors['state'] = 'You must select a state!';
    }

    return errors;
  }

  // Copy with method for state management
  ClassifiedPostForm copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? instructions,
    double? price,
    bool? negotiable,
    String? country,
    String? state,
    String? city,
    String? upazila,
    String? location,
    List<dynamic>? medias,
    bool? acceptedPrivacy,
    String? serviceStatus,
    bool? activeService,
  }) {
    return ClassifiedPostForm(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      price: price ?? this.price,
      negotiable: negotiable ?? this.negotiable,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      upazila: upazila ?? this.upazila,
      location: location ?? this.location,
      medias: medias ?? this.medias,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      activeService: activeService ?? this.activeService,
    );
  }
}
