import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rideshare_models.dart';
import 'api_service.dart';

class RideshareApiResult<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  RideshareApiResult({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
}

class RideshareService {
  static String get _baseUrl => '${ApiService.baseUrl}/rides';

  static Future<Map<String, String>> _getHeaders() async {
    return await ApiService.getHeaders();
  }

  static RideshareApiResult<T> _parseResponse<T>(
    http.Response response,
    T Function(dynamic)? parser,
  ) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map && data.containsKey('success')) {
          return RideshareApiResult<T>(
            success: data['success'] == true,
            message: data['message'] ?? 'Success',
            data: parser != null && data['data'] != null 
                ? parser(data['data']) 
                : data['data'] as T?,
            errors: data['errors'],
          );
        }
        return RideshareApiResult<T>(
          success: true,
          message: 'Success',
          data: parser != null ? parser(data) : data as T?,
        );
      } else {
        return RideshareApiResult<T>(
          success: false,
          message: data['message'] ?? data['detail'] ?? 'Request failed',
          errors: data['errors'] ?? data,
        );
      }
    } catch (e) {
      return RideshareApiResult<T>(
        success: false,
        message: 'Failed to parse response: $e',
        errors: e.toString(),
      );
    }
  }

  // ==================== Ride Estimation ====================
  
  static Future<RideshareApiResult<RideEstimate>> estimateRide({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropLatitude,
    required double dropLongitude,
    required String vehicleType,
    String? pickupAddress,
    String? dropAddress,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/estimate/'),
        headers: headers,
        body: json.encode({
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'drop_latitude': dropLatitude,
          'drop_longitude': dropLongitude,
          'vehicle_type': vehicleType,
          'pickup_address': pickupAddress ?? '',
          'drop_address': dropAddress ?? '',
        }),
      );
      return _parseResponse<RideEstimate>(
        response,
        (data) => RideEstimate.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<RideEstimate>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Ride Creation ====================
  
  static Future<RideshareApiResult<Ride>> createRide({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropLatitude,
    required double dropLongitude,
    required String vehicleType,
    String? pickupAddress,
    String? dropAddress,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/create/'),
        headers: headers,
        body: json.encode({
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'drop_latitude': dropLatitude,
          'drop_longitude': dropLongitude,
          'vehicle_type': vehicleType,
          'pickup_address': pickupAddress ?? '',
          'drop_address': dropAddress ?? '',
        }),
      );
      return _parseResponse<Ride>(
        response,
        (data) => Ride.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Ride>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Ride List & Details ====================
  
  static Future<RideshareApiResult<List<Ride>>> listRides({bool asDriver = false}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/').replace(
        queryParameters: asDriver ? {'as_driver': 'true'} : null,
      );
      final response = await http.get(uri, headers: headers);
      return _parseResponse<List<Ride>>(
        response,
        (data) => (data as List).map((r) => Ride.fromJson(r as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return RideshareApiResult<List<Ride>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Ride?>> getActiveRide() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/active/'),
        headers: headers,
      );
      return _parseResponse<Ride?>(
        response,
        (data) => data != null ? Ride.fromJson(data as Map<String, dynamic>) : null,
      );
    } catch (e) {
      return RideshareApiResult<Ride?>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Ride>> getRide(String rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/$rideId/'),
        headers: headers,
      );
      return _parseResponse<Ride>(
        response,
        (data) => Ride.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Ride>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Ride Actions ====================
  
  static Future<RideshareApiResult<Ride>> acceptRide(String rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/accept/'),
        headers: headers,
        body: json.encode({}),
      );
      return _parseResponse<Ride>(
        response,
        (data) => Ride.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Ride>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Ride>> cancelRide(String rideId, {String reason = ''}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/cancel/'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );
      return _parseResponse<Ride>(
        response,
        (data) => Ride.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Ride>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Ride>> updateRideStatus(
    String rideId,
    String status, {
    double? finalFare,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{'status': status};
      if (finalFare != null) {
        body['final_fare'] = finalFare;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/status/'),
        headers: headers,
        body: json.encode(body),
      );
      return _parseResponse<Ride>(
        response,
        (data) => Ride.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Ride>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Location Services ====================
  
  static Future<RideshareApiResult<List<RidePoint>>> searchLocations(
    String query, {
    int limit = 5,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/location/search/').replace(
        queryParameters: {'q': query, 'limit': limit.toString()},
      );
      final response = await http.get(uri, headers: headers);
      return _parseResponse<List<RidePoint>>(
        response,
        (data) => (data as List).map((p) => RidePoint.fromJson(p as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return RideshareApiResult<List<RidePoint>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<RidePoint?>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/location/reverse/').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
        },
      );
      final response = await http.get(uri, headers: headers);
      return _parseResponse<RidePoint?>(
        response,
        (data) => data != null ? RidePoint.fromJson(data as Map<String, dynamic>) : null,
      );
    } catch (e) {
      return RideshareApiResult<RidePoint?>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<List<NearbyDriver>>> getNearbyDrivers(
    double latitude,
    double longitude, {
    String vehicleType = 'bike',
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/location/nearby-drivers/').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'vehicle_type': vehicleType,
        },
      );
      final response = await http.get(uri, headers: headers);
      return _parseResponse<List<NearbyDriver>>(
        response,
        (data) => (data as List).map((d) => NearbyDriver.fromJson(d as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return RideshareApiResult<List<NearbyDriver>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Driver Profile ====================
  
  static Future<RideshareApiResult<DriverProfile>> getDriverProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/profile/'),
        headers: headers,
      );
      return _parseResponse<DriverProfile>(
        response,
        (data) => DriverProfile.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<DriverProfile>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<DriverProfile>> updateDriverProfile({
    String? licenseNumber,
    String? nationalIdNumber,
    double? serviceRadiusKm,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (licenseNumber != null) body['license_number'] = licenseNumber;
      if (nationalIdNumber != null) body['national_id_number'] = nationalIdNumber;
      if (serviceRadiusKm != null) body['service_radius_km'] = serviceRadiusKm;
      
      final response = await http.put(
        Uri.parse('$_baseUrl/drivers/profile/'),
        headers: headers,
        body: json.encode(body),
      );
      return _parseResponse<DriverProfile>(
        response,
        (data) => DriverProfile.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<DriverProfile>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<DriverProfile>> toggleDriverOnline(bool isOnline) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/toggle-online/'),
        headers: headers,
        body: json.encode({'is_online': isOnline}),
      );
      return _parseResponse<DriverProfile>(
        response,
        (data) => DriverProfile.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<DriverProfile>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Map<String, dynamic>>> updateDriverLocation({
    required double latitude,
    required double longitude,
    String? rideId,
    double? heading,
    double? speedKph,
    double? accuracyMeters,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (rideId != null) body['ride_id'] = rideId;
      if (heading != null) body['heading'] = heading;
      if (speedKph != null) body['speed_kph'] = speedKph;
      if (accuracyMeters != null) body['accuracy_meters'] = accuracyMeters;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/location/update/'),
        headers: headers,
        body: json.encode(body),
      );
      return _parseResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return RideshareApiResult<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<DriverEarningsSummary>> getDriverEarningsSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/earnings-summary/'),
        headers: headers,
      );
      return _parseResponse<DriverEarningsSummary>(
        response,
        (data) => DriverEarningsSummary.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<DriverEarningsSummary>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Vehicles ====================
  
  static Future<RideshareApiResult<List<Vehicle>>> listVehicles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/vehicles/'),
        headers: headers,
      );
      return _parseResponse<List<Vehicle>>(
        response,
        (data) => (data as List).map((v) => Vehicle.fromJson(v as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return RideshareApiResult<List<Vehicle>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Vehicle>> createVehicle({
    required String vehicleType,
    required String registrationNumber,
    String? brand,
    String? modelName,
    String? color,
    int seatCapacity = 1,
    bool isDefault = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/vehicles/'),
        headers: headers,
        body: json.encode({
          'vehicle_type': vehicleType,
          'registration_number': registrationNumber,
          'brand': brand ?? '',
          'model_name': modelName ?? '',
          'color': color ?? '',
          'seat_capacity': seatCapacity,
          'is_default': isDefault,
        }),
      );
      return _parseResponse<Vehicle>(
        response,
        (data) => Vehicle.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Vehicle>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<Vehicle>> updateVehicle(
    String vehicleId, {
    String? vehicleType,
    String? registrationNumber,
    String? brand,
    String? modelName,
    String? color,
    int? seatCapacity,
    bool? isActive,
    bool? isDefault,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (vehicleType != null) body['vehicle_type'] = vehicleType;
      if (registrationNumber != null) body['registration_number'] = registrationNumber;
      if (brand != null) body['brand'] = brand;
      if (modelName != null) body['model_name'] = modelName;
      if (color != null) body['color'] = color;
      if (seatCapacity != null) body['seat_capacity'] = seatCapacity;
      if (isActive != null) body['is_active'] = isActive;
      if (isDefault != null) body['is_default'] = isDefault;
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/drivers/vehicles/$vehicleId/'),
        headers: headers,
        body: json.encode(body),
      );
      return _parseResponse<Vehicle>(
        response,
        (data) => Vehicle.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return RideshareApiResult<Vehicle>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static Future<RideshareApiResult<void>> deleteVehicle(String vehicleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/drivers/vehicles/$vehicleId/'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RideshareApiResult<void>(
          success: true,
          message: 'Vehicle deleted successfully',
        );
      }
      final data = json.decode(response.body);
      return RideshareApiResult<void>(
        success: false,
        message: data['message'] ?? 'Failed to delete vehicle',
      );
    } catch (e) {
      return RideshareApiResult<void>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ==================== Available Ride Requests (Driver) ====================
  
  static Future<RideshareApiResult<List<Ride>>> listAvailableRideRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/driver/available/'),
        headers: headers,
      );
      return _parseResponse<List<Ride>>(
        response,
        (data) => (data as List).map((r) => Ride.fromJson(r as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return RideshareApiResult<List<Ride>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}
