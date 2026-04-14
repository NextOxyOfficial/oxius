class RidePoint {
  final String name;
  final String? title;
  final String? subtitle;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? address;
  final String? badge;
  final String? source;
  final bool isCustomLocation;

  RidePoint({
    required this.name,
    this.title,
    this.subtitle,
    required this.latitude,
    required this.longitude,
    this.address,
    this.badge,
    this.source,
    this.isCustomLocation = false,
  });

  factory RidePoint.fromJson(Map<String, dynamic> json) {
    return RidePoint(
      name: json['name'] ?? json['display_name'] ?? 'Selected location',
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ??
          double.tryParse(json['lat']?.toString() ?? '') ??
          0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ??
          double.tryParse(json['lon']?.toString() ?? '') ??
          0.0,
      address: json['address'] as Map<String, dynamic>?,
      badge: json['badge']?.toString(),
      source: json['source']?.toString(),
      isCustomLocation: json['is_custom'] == true || json['source']?.toString() == 'user_custom',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'subtitle': subtitle,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'badge': badge,
        'source': source,
        'is_custom': isCustomLocation,
      };

  String get badgeLabel {
    final resolvedBadge = badge?.trim();
    if (resolvedBadge != null && resolvedBadge.isNotEmpty) {
      return resolvedBadge;
    }
    return isCustomLocation ? 'My Custom Location' : '';
  }

  String get displayTitle {
    final resolvedTitle = title?.trim();
    if (resolvedTitle != null && resolvedTitle.isNotEmpty) {
      return resolvedTitle;
    }
    final compactName = name.split(',').first.trim();
    return compactName.isNotEmpty ? compactName : name;
  }

  String get displaySubtitle {
    final resolvedSubtitle = subtitle?.trim();
    if (resolvedSubtitle != null && resolvedSubtitle.isNotEmpty) {
      return resolvedSubtitle;
    }

    final addressMap = address;
    if (addressMap != null && addressMap.isNotEmpty) {
      final parts = <String>[
        addressMap['suburb']?.toString() ?? addressMap['neighbourhood']?.toString() ?? '',
        addressMap['city']?.toString() ?? addressMap['town']?.toString() ?? addressMap['county']?.toString() ?? '',
        addressMap['state_district']?.toString() ?? '',
      ].where((part) => part.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    final segments = name.split(',').map((segment) => segment.trim()).where((segment) => segment.isNotEmpty).toList();
    if (segments.length <= 1) {
      return '';
    }
    return segments.skip(1).join(', ');
  }
}

class CustomRideLocation {
  final String id;
  final String name;
  final String subtitle;
  final String searchKeywords;
  final double latitude;
  final double longitude;
  final double feePaid;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomRideLocation({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.searchKeywords,
    required this.latitude,
    required this.longitude,
    required this.feePaid,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomRideLocation.fromJson(Map<String, dynamic> json) {
    return CustomRideLocation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Custom location',
      subtitle: json['subtitle']?.toString() ?? '',
      searchKeywords: json['search_keywords']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      feePaid: double.tryParse(json['fee_paid']?.toString() ?? '') ?? 0.0,
      isActive: json['is_active'] != false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  RidePoint get asRidePoint {
    return RidePoint(
      name: subtitle.trim().isEmpty ? name : '$name, $subtitle',
      title: name,
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
      badge: 'My Custom Location',
      source: 'user_custom',
      isCustomLocation: true,
      address: const {'country': 'Bangladesh'},
    );
  }
}

class CustomRideLocationPurchase {
  final CustomRideLocation location;
  final double feeCharged;
  final double walletBalance;

  CustomRideLocationPurchase({
    required this.location,
    required this.feeCharged,
    required this.walletBalance,
  });

  factory CustomRideLocationPurchase.fromJson(Map<String, dynamic> json) {
    return CustomRideLocationPurchase(
      location: CustomRideLocation.fromJson(
        (json['location'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      feeCharged: double.tryParse(json['fee_charged']?.toString() ?? '') ?? 0.0,
      walletBalance: double.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0.0,
    );
  }
}

String _parseStringId(dynamic value) {
  if (value == null) return '';
  if (value is Map<String, dynamic>) {
    return value['id']?.toString() ?? '';
  }
  return value.toString();
}

List<Vehicle> _parseVehicles(Map<String, dynamic> json) {
  final parsedVehicles = (json['vehicles'] as List<dynamic>?)
          ?.map((vehicle) => Vehicle.fromJson(vehicle as Map<String, dynamic>))
          .toList() ??
      <Vehicle>[];

  final defaultVehicleJson = json['default_vehicle'];
  if (defaultVehicleJson is Map<String, dynamic>) {
    final defaultVehicle = Vehicle.fromJson(defaultVehicleJson);
    final exists = parsedVehicles.any((vehicle) => vehicle.id == defaultVehicle.id);
    if (!exists) {
      parsedVehicles.insert(0, defaultVehicle);
    }
  }

  return parsedVehicles;
}

class Vehicle {
  final String id;
  final String vehicleType;
  final String brand;
  final String modelName;
  final String color;
  final String registrationNumber;
  final int seatCapacity;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.vehicleType,
    required this.brand,
    required this.modelName,
    required this.color,
    required this.registrationNumber,
    required this.seatCapacity,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      vehicleType: json['vehicle_type'] ?? 'bike',
      brand: json['brand'] ?? '',
      modelName: json['model_name'] ?? '',
      color: json['color'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      seatCapacity: json['seat_capacity'] ?? 1,
      isActive: json['is_active'] ?? true,
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicle_type': vehicleType,
        'brand': brand,
        'model_name': modelName,
        'color': color,
        'registration_number': registrationNumber,
        'seat_capacity': seatCapacity,
        'is_active': isActive,
        'is_default': isDefault,
      };

  String get displayName {
    if (brand.isNotEmpty && modelName.isNotEmpty) {
      return '$brand $modelName';
    }
    return registrationNumber;
  }

  String get vehicleIcon {
    switch (vehicleType) {
      case 'bike':
        return '🏍️';
      case 'car':
        return '🚗';
      case 'cng':
        return '🛺';
      default:
        return '🚗';
    }
  }
}

class DriverProfile {
  final String userId;
  final String userName;
  final String userPhone;
  final String? userAvatar;
  final bool userIsVerified;
  final bool userIsPro;
  final String licenseNumber;
  final String nationalIdNumber;
  final String driverDetails;
  final List<String> additionalDocuments;
  final String approvalStatus;
  final bool isOnline;
  final bool isAvailable;
  final double serviceRadiusKm;
  final double maxRideDistanceKm;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationAt;
  final int totalTrips;
  final double totalEarnings;
  final int outstandingCashDueCount;
  final double outstandingCashDueAmount;
  final bool cashDueLimitReached;
  final List<Vehicle> vehicles;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverProfile({
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userAvatar,
    required this.userIsVerified,
    required this.userIsPro,
    required this.licenseNumber,
    required this.nationalIdNumber,
    required this.driverDetails,
    required this.additionalDocuments,
    required this.approvalStatus,
    required this.isOnline,
    required this.isAvailable,
    required this.serviceRadiusKm,
    required this.maxRideDistanceKm,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationAt,
    required this.totalTrips,
    required this.totalEarnings,
    required this.outstandingCashDueCount,
    required this.outstandingCashDueAmount,
    required this.cashDueLimitReached,
    required this.vehicles,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return DriverProfile(
      userId: _parseStringId(user['id'] ?? json['user_id']),
      userName: user['name'] ?? user['username'] ?? '',
      userPhone: user['phone'] ?? '',
      userAvatar: user['avatar'] ?? user['image'],
      userIsVerified: user['kyc'] == true || user['is_verified'] == true,
      userIsPro: user['is_pro'] == true,
      licenseNumber: json['license_number'] ?? '',
      nationalIdNumber: json['national_id_number'] ?? '',
        driverDetails: json['driver_details'] ?? '',
        additionalDocuments: (json['additional_documents'] as List<dynamic>? ?? [])
          .map((doc) => doc.toString())
          .where((doc) => doc.trim().isNotEmpty)
          .toList(),
      approvalStatus: json['approval_status'] ?? 'pending',
      isOnline: json['is_online'] ?? false,
      isAvailable: json['is_available'] ?? false,
      serviceRadiusKm: double.tryParse(json['service_radius_km']?.toString() ?? '') ?? 8.0,
      maxRideDistanceKm: double.tryParse(json['max_ride_distance_km']?.toString() ?? '') ?? 0.0,
      currentLatitude: double.tryParse(json['current_latitude']?.toString() ?? ''),
      currentLongitude: double.tryParse(json['current_longitude']?.toString() ?? ''),
      lastLocationAt: json['last_location_at'] != null
          ? DateTime.tryParse(json['last_location_at'])
          : null,
      totalTrips: json['total_trips'] ?? 0,
      totalEarnings: double.tryParse(json['total_earnings']?.toString() ?? '') ?? 0.0,
      outstandingCashDueCount: json['outstanding_cash_due_count'] ?? 0,
      outstandingCashDueAmount:
          double.tryParse(json['outstanding_cash_due_amount']?.toString() ?? '') ?? 0.0,
      cashDueLimitReached: json['cash_due_limit_reached'] ?? false,
      vehicles: _parseVehicles(json),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isSuspended => approvalStatus == 'suspended';

  Vehicle? get defaultVehicle {
    try {
      return vehicles.firstWhere((vehicle) => vehicle.isDefault && vehicle.isActive);
    } catch (_) {
      try {
        return vehicles.firstWhere((vehicle) => vehicle.isActive);
      } catch (_) {
        return null;
      }
    }
  }
}

class RideStatusHistory {
  final String id;
  final String status;
  final String? actorId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  RideStatusHistory({
    required this.id,
    required this.status,
    this.actorId,
    required this.metadata,
    required this.createdAt,
  });

  factory RideStatusHistory.fromJson(Map<String, dynamic> json) {
    return RideStatusHistory(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      actorId: _parseStringId(json['actor']).isEmpty ? null : _parseStringId(json['actor']),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class RideDriverLocation {
  final String id;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKph;
  final double? accuracyMeters;
  final DateTime recordedAt;

  RideDriverLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKph,
    this.accuracyMeters,
    required this.recordedAt,
  });

  factory RideDriverLocation.fromJson(Map<String, dynamic> json) {
    return RideDriverLocation(
      id: json['id']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      heading: double.tryParse(json['heading']?.toString() ?? ''),
      speedKph: double.tryParse(json['speed_kph']?.toString() ?? ''),
      accuracyMeters: double.tryParse(json['accuracy_meters']?.toString() ?? ''),
      recordedAt: DateTime.tryParse(json['recorded_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class Ride {
  final String id;
  final String riderId;
  final String riderName;
  final String? riderPhone;
  final String? riderAvatar;
  final bool riderIsVerified;
  final bool riderIsPro;
  final int riderCompletedTrips;
  final DriverProfile? assignedDriver;
  final DriverProfile? targetedDriver;
  final Vehicle? vehicle;
  final String requestedVehicleType;
  final DateTime? targetedAt;
  final DateTime? targetedExpiresAt;
  final int dispatchAttempt;
  final DateTime? searchExpiresAt;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropLatitude;
  final double dropLongitude;
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final int durationSeconds;
  final Map<String, dynamic>? routeGeometry;
  final double fareEstimate;
  final double? finalFare;
  final double platformFeePercent;
  final double platformFeeAmount;
  final double driverPayoutAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final double driverDueAmount;
  final DateTime? driverDueSettledAt;
  final String? cancellationReason;
  final DateTime? earlyCompletionRequestedAt;
  final double? earlyCompletionDistanceKm;
  final int earlyCompletionDurationSeconds;
  final double? earlyCompletionFare;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final RideDriverLocation? latestDriverLocation;
  final bool passengerCanCancel;
  final bool driverCanCancel;
  final bool canReportDriver;
  final List<RideStatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ride({
    required this.id,
    required this.riderId,
    required this.riderName,
    this.riderPhone,
    this.riderAvatar,
    required this.riderIsVerified,
    required this.riderIsPro,
    required this.riderCompletedTrips,
    this.assignedDriver,
    this.targetedDriver,
    this.vehicle,
    required this.requestedVehicleType,
    this.targetedAt,
    this.targetedExpiresAt,
    required this.dispatchAttempt,
    this.searchExpiresAt,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.durationSeconds,
    this.routeGeometry,
    required this.fareEstimate,
    this.finalFare,
    required this.platformFeePercent,
    required this.platformFeeAmount,
    required this.driverPayoutAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.driverDueAmount,
    this.driverDueSettledAt,
    this.cancellationReason,
    this.earlyCompletionRequestedAt,
    this.earlyCompletionDistanceKm,
    required this.earlyCompletionDurationSeconds,
    this.earlyCompletionFare,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.latestDriverLocation,
    required this.passengerCanCancel,
    required this.driverCanCancel,
    required this.canReportDriver,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final rider = json['rider'] as Map<String, dynamic>? ?? {};
    return Ride(
      id: json['id']?.toString() ?? '',
      riderId: _parseStringId(rider['id'] ?? json['rider_id']),
      riderName: rider['name'] ?? rider['username'] ?? '',
      riderPhone: rider['phone'],
      riderAvatar: rider['avatar'] ?? rider['image'],
      riderIsVerified: rider['kyc'] == true || rider['is_verified'] == true,
      riderIsPro: rider['is_pro'] == true,
      riderCompletedTrips: rider['completed_trips'] ?? 0,
      assignedDriver: json['assigned_driver'] != null
          ? DriverProfile.fromJson(json['assigned_driver'] as Map<String, dynamic>)
          : null,
      targetedDriver: json['targeted_driver'] != null
          ? DriverProfile.fromJson(json['targeted_driver'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      requestedVehicleType: json['requested_vehicle_type'] ?? 'bike',
      targetedAt: json['targeted_at'] != null ? DateTime.tryParse(json['targeted_at']) : null,
      targetedExpiresAt: json['targeted_driver_response_expires_at'] != null
          ? DateTime.tryParse(json['targeted_driver_response_expires_at'])
          : null,
      dispatchAttempt: json['dispatch_attempt'] ?? 0,
      searchExpiresAt: json['search_expires_at'] != null ? DateTime.tryParse(json['search_expires_at']) : null,
      pickupLatitude: double.tryParse(json['pickup_latitude']?.toString() ?? '') ?? 0.0,
      pickupLongitude: double.tryParse(json['pickup_longitude']?.toString() ?? '') ?? 0.0,
      dropLatitude: double.tryParse(json['drop_latitude']?.toString() ?? '') ?? 0.0,
      dropLongitude: double.tryParse(json['drop_longitude']?.toString() ?? '') ?? 0.0,
      pickupAddress: json['pickup_address'] ?? '',
      dropAddress: json['drop_address'] ?? '',
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ?? 0.0,
      durationSeconds: json['duration_seconds'] ?? 0,
      routeGeometry: json['route_geometry'] as Map<String, dynamic>?,
      fareEstimate: double.tryParse(json['fare_estimate']?.toString() ?? '') ?? 0.0,
      finalFare: double.tryParse(json['final_fare']?.toString() ?? ''),
      platformFeePercent: double.tryParse(json['platform_fee_percent']?.toString() ?? '') ?? 0.0,
      platformFeeAmount: double.tryParse(json['platform_fee_amount']?.toString() ?? '') ?? 0.0,
      driverPayoutAmount: double.tryParse(json['driver_payout_amount']?.toString() ?? '') ?? 0.0,
      status: json['status'] ?? 'requested',
      paymentStatus: json['payment_status'] ?? 'pending',
        paymentMethod: json['payment_method'] ?? 'wallet',
        driverDueAmount: double.tryParse(json['driver_due_amount']?.toString() ?? '') ?? 0.0,
        driverDueSettledAt: json['driver_due_settled_at'] != null
          ? DateTime.tryParse(json['driver_due_settled_at'])
          : null,
      cancellationReason: json['cancellation_reason'],
      earlyCompletionRequestedAt: json['early_completion_requested_at'] != null
          ? DateTime.tryParse(json['early_completion_requested_at'])
          : null,
      earlyCompletionDistanceKm: double.tryParse(json['early_completion_distance_km']?.toString() ?? ''),
      earlyCompletionDurationSeconds: json['early_completion_duration_seconds'] ?? 0,
      earlyCompletionFare: double.tryParse(json['early_completion_fare']?.toString() ?? ''),
      requestedAt: DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at']) : null,
      latestDriverLocation: json['latest_driver_location'] != null
          ? RideDriverLocation.fromJson(json['latest_driver_location'] as Map<String, dynamic>)
          : null,
      passengerCanCancel: json['passenger_can_cancel'] ?? false,
      driverCanCancel: json['driver_can_cancel'] ?? false,
      canReportDriver: json['can_report_driver'] ?? false,
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((history) => RideStatusHistory.fromJson(history as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isActive => const [
        'requested',
        'searching_driver',
        'accepted',
        'driver_arriving',
        'in_progress',
        'awaiting_passenger_confirmation',
      ].contains(status);

  bool get isSearching => status == 'searching_driver';
  bool get isAccepted => status == 'accepted';
  bool get isDriverArriving => status == 'driver_arriving';
  bool get isInProgress => status == 'in_progress';
  bool get isAwaitingPassengerConfirmation => status == 'awaiting_passenger_confirmation';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'requested':
        return 'Requested';
      case 'searching_driver':
        return 'Finding Driver';
      case 'accepted':
        return 'Driver Assigned';
      case 'driver_arriving':
        return 'Driver Arriving';
      case 'in_progress':
        return 'In Progress';
      case 'awaiting_passenger_confirmation':
        return 'Awaiting Confirmation';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String get vehicleIcon {
    switch (requestedVehicleType) {
      case 'bike':
        return '🏍️';
      case 'car':
        return '🚗';
      case 'cng':
        return '🛺';
      default:
        return '🚗';
    }
  }

  String get etaDisplay {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  RidePoint get pickupPoint => RidePoint(
        name: pickupAddress,
        latitude: pickupLatitude,
        longitude: pickupLongitude,
      );

  RidePoint get dropPoint => RidePoint(
        name: dropAddress,
        latitude: dropLatitude,
        longitude: dropLongitude,
      );

  double get payableFare => finalFare ?? earlyCompletionFare ?? fareEstimate;

  int targetedCountdownSeconds({int timeoutSeconds = 60, DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    // Prefer server-computed expiry for accurate countdown
    if (targetedExpiresAt != null) {
      final remaining = targetedExpiresAt!.difference(currentTime).inSeconds;
      return remaining > 0 ? remaining : 0;
    }
    if (targetedAt == null) return timeoutSeconds;
    final elapsed = currentTime.difference(targetedAt!).inSeconds;
    final remaining = timeoutSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  Ride copyWith({
    DriverProfile? assignedDriver,
    DriverProfile? targetedDriver,
    Vehicle? vehicle,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? cancellationReason,
    double? finalFare,
    double? platformFeePercent,
    double? platformFeeAmount,
    double? driverPayoutAmount,
    double? driverDueAmount,
    DateTime? driverDueSettledAt,
    DateTime? targetedAt,
    DateTime? targetedExpiresAt,
    int? dispatchAttempt,
    DateTime? searchExpiresAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    RideDriverLocation? latestDriverLocation,
    DateTime? earlyCompletionRequestedAt,
    double? earlyCompletionDistanceKm,
    int? earlyCompletionDurationSeconds,
    double? earlyCompletionFare,
    bool? passengerCanCancel,
    bool? driverCanCancel,
    bool? canReportDriver,
    List<RideStatusHistory>? statusHistory,
  }) {
    return Ride(
      id: id,
      riderId: riderId,
      riderName: riderName,
      riderPhone: riderPhone,
      riderAvatar: riderAvatar,
      riderIsVerified: riderIsVerified,
      riderIsPro: riderIsPro,
      riderCompletedTrips: riderCompletedTrips,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      targetedDriver: targetedDriver ?? this.targetedDriver,
      vehicle: vehicle ?? this.vehicle,
      requestedVehicleType: requestedVehicleType,
      targetedAt: targetedAt ?? this.targetedAt,
      targetedExpiresAt: targetedExpiresAt ?? this.targetedExpiresAt,
      dispatchAttempt: dispatchAttempt ?? this.dispatchAttempt,
      searchExpiresAt: searchExpiresAt ?? this.searchExpiresAt,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropLatitude: dropLatitude,
      dropLongitude: dropLongitude,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      routeGeometry: routeGeometry,
      fareEstimate: fareEstimate,
      finalFare: finalFare ?? this.finalFare,
      platformFeePercent: platformFeePercent ?? this.platformFeePercent,
      platformFeeAmount: platformFeeAmount ?? this.platformFeeAmount,
      driverPayoutAmount: driverPayoutAmount ?? this.driverPayoutAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      driverDueAmount: driverDueAmount ?? this.driverDueAmount,
      driverDueSettledAt: driverDueSettledAt ?? this.driverDueSettledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      earlyCompletionRequestedAt: earlyCompletionRequestedAt ?? this.earlyCompletionRequestedAt,
      earlyCompletionDistanceKm: earlyCompletionDistanceKm ?? this.earlyCompletionDistanceKm,
      earlyCompletionDurationSeconds:
          earlyCompletionDurationSeconds ?? this.earlyCompletionDurationSeconds,
      earlyCompletionFare: earlyCompletionFare ?? this.earlyCompletionFare,
      requestedAt: requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      latestDriverLocation: latestDriverLocation ?? this.latestDriverLocation,
      passengerCanCancel: passengerCanCancel ?? this.passengerCanCancel,
      driverCanCancel: driverCanCancel ?? this.driverCanCancel,
      canReportDriver: canReportDriver ?? this.canReportDriver,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class RideEstimate {
  final String vehicleType;
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final int etaSeconds;
  final double fare;
  final Map<String, dynamic>? routeGeometry;
  final String routingSource;

  RideEstimate({
    required this.vehicleType,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.etaSeconds,
    required this.fare,
    this.routeGeometry,
    required this.routingSource,
  });

  factory RideEstimate.fromJson(Map<String, dynamic> json) {
    return RideEstimate(
      vehicleType: json['vehicle_type'] ?? 'bike',
      pickupAddress: json['pickup_address'] ?? '',
      dropAddress: json['drop_address'] ?? '',
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ?? 0.0,
      etaSeconds: json['eta_seconds'] ?? 0,
      fare: double.tryParse(json['fare']?.toString() ?? '') ?? 0.0,
      routeGeometry: json['route_geometry'] as Map<String, dynamic>?,
      routingSource: json['routing_source'] ?? 'fallback',
    );
  }

  String get etaDisplay {
    final minutes = (etaSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String get vehicleIcon {
    switch (vehicleType) {
      case 'bike':
        return '🏍️';
      case 'car':
        return '🚗';
      case 'cng':
        return '🛺';
      default:
        return '🚗';
    }
  }
}

class RoutePreview {
  final String originAddress;
  final String destinationAddress;
  final double distanceKm;
  final int etaSeconds;
  final Map<String, dynamic>? routeGeometry;
  final String routingSource;
  final bool isFallback;

  RoutePreview({
    required this.originAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.etaSeconds,
    this.routeGeometry,
    required this.routingSource,
    required this.isFallback,
  });

  factory RoutePreview.fromJson(Map<String, dynamic> json) {
    return RoutePreview(
      originAddress: json['origin_address'] ?? '',
      destinationAddress: json['destination_address'] ?? '',
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ?? 0.0,
      etaSeconds: json['eta_seconds'] ?? 0,
      routeGeometry: json['route_geometry'] as Map<String, dynamic>?,
      routingSource: json['routing_source'] ?? 'fallback',
      isFallback: json['is_fallback'] == true,
    );
  }

  String get etaDisplay {
    final minutes = (etaSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
}

class NearbyDriver {
  final double latitude;
  final double longitude;
  final String name;
  final String vehicleType;
  final double? distance;
  final bool isOnline;

  NearbyDriver({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.vehicleType,
    this.distance,
    this.isOnline = true,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      name: json['name'] ?? 'Driver',
      vehicleType: json['vehicle_type'] ?? 'bike',
      distance: double.tryParse(json['distance']?.toString() ?? ''),
      isOnline: json['is_online'] != false,
    );
  }

  String get vehicleIcon {
    switch (vehicleType) {
      case 'bike':
        return '🏍️';
      case 'car':
        return '🚗';
      case 'cng':
        return '🛺';
      default:
        return '🚗';
    }
  }
}

class DriverEarningsSummary {
  final int totalTrips;
  final double totalEarnings;
  final bool isOnline;
  final bool isAvailable;

  DriverEarningsSummary({
    required this.totalTrips,
    required this.totalEarnings,
    required this.isOnline,
    required this.isAvailable,
  });

  factory DriverEarningsSummary.fromJson(Map<String, dynamic> json) {
    return DriverEarningsSummary(
      totalTrips: json['total_trips'] ?? 0,
      totalEarnings: double.tryParse(json['total_earnings']?.toString() ?? '') ?? 0.0,
      isOnline: json['is_online'] ?? false,
      isAvailable: json['is_available'] ?? false,
    );
  }
}
