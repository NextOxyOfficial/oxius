class RidePoint {
  final String name;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? address;

  RidePoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory RidePoint.fromJson(Map<String, dynamic> json) {
    return RidePoint(
      name: json['name'] ?? json['display_name'] ?? 'Selected location',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 
                double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 
                 double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
      address: json['address'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };
}

String _parseStringId(dynamic value) {
  if (value == null) return '';
  if (value is Map<String, dynamic>) {
    return value['id']?.toString() ?? '';
  }
  return value.toString();
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
  final String licenseNumber;
  final String nationalIdNumber;
  final String approvalStatus;
  final bool isOnline;
  final bool isAvailable;
  final double serviceRadiusKm;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationAt;
  final int totalTrips;
  final double totalEarnings;
  final List<Vehicle> vehicles;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverProfile({
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userAvatar,
    required this.licenseNumber,
    required this.nationalIdNumber,
    required this.approvalStatus,
    required this.isOnline,
    required this.isAvailable,
    required this.serviceRadiusKm,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationAt,
    required this.totalTrips,
    required this.totalEarnings,
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
      licenseNumber: json['license_number'] ?? '',
      nationalIdNumber: json['national_id_number'] ?? '',
      approvalStatus: json['approval_status'] ?? 'pending',
      isOnline: json['is_online'] ?? false,
      isAvailable: json['is_available'] ?? false,
      serviceRadiusKm: double.tryParse(json['service_radius_km']?.toString() ?? '') ?? 8.0,
      currentLatitude: double.tryParse(json['current_latitude']?.toString() ?? ''),
      currentLongitude: double.tryParse(json['current_longitude']?.toString() ?? ''),
      lastLocationAt: json['last_location_at'] != null 
          ? DateTime.tryParse(json['last_location_at']) 
          : null,
      totalTrips: json['total_trips'] ?? 0,
      totalEarnings: double.tryParse(json['total_earnings']?.toString() ?? '') ?? 0.0,
      vehicles: (json['vehicles'] as List<dynamic>?)
          ?.map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isSuspended => approvalStatus == 'suspended';

  Vehicle? get defaultVehicle {
    try {
      return vehicles.firstWhere((v) => v.isDefault && v.isActive);
    } catch (_) {
      try {
        return vehicles.firstWhere((v) => v.isActive);
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

class Ride {
  final String id;
  final String riderId;
  final String riderName;
  final String? riderPhone;
  final String? riderAvatar;
  final DriverProfile? assignedDriver;
  final Vehicle? vehicle;
  final String requestedVehicleType;
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
  final String status;
  final String paymentStatus;
  final String? cancellationReason;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final List<RideStatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ride({
    required this.id,
    required this.riderId,
    required this.riderName,
    this.riderPhone,
    this.riderAvatar,
    this.assignedDriver,
    this.vehicle,
    required this.requestedVehicleType,
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
    required this.status,
    required this.paymentStatus,
    this.cancellationReason,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
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
      assignedDriver: json['assigned_driver'] != null 
          ? DriverProfile.fromJson(json['assigned_driver'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null 
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      requestedVehicleType: json['requested_vehicle_type'] ?? 'bike',
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
      status: json['status'] ?? 'requested',
      paymentStatus: json['payment_status'] ?? 'pending',
      cancellationReason: json['cancellation_reason'],
      requestedAt: DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at']) : null,
      statusHistory: (json['status_history'] as List<dynamic>?)
          ?.map((h) => RideStatusHistory.fromJson(h as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isActive => [
    'requested',
    'searching_driver',
    'accepted',
    'driver_arriving',
    'in_progress',
  ].contains(status);

  bool get isSearching => status == 'searching_driver';
  bool get isAccepted => status == 'accepted';
  bool get isDriverArriving => status == 'driver_arriving';
  bool get isInProgress => status == 'in_progress';
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

class NearbyDriver {
  final double latitude;
  final double longitude;
  final String name;
  final String vehicleType;
  final double? distance;

  NearbyDriver({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.vehicleType,
    this.distance,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      name: json['name'] ?? 'Driver',
      vehicleType: json['vehicle_type'] ?? 'bike',
      distance: double.tryParse(json['distance']?.toString() ?? ''),
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
