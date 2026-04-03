import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rideshare_models.dart';
import 'api_service.dart';
import '../utils/network_error_handler.dart';

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

  static double _roundToPrecision(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  static double? _normalizeMetric(
    double? value,
    int fractionDigits, {
    bool allowNegative = false,
  }) {
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }

    final normalized = _roundToPrecision(value, fractionDigits);
    if (!allowNegative && normalized < 0) {
      return null;
    }

    return normalized;
  }

  static Future<Map<String, String>> _getHeaders() async {
    return await ApiService.getHeaders();
  }

  static List<dynamic> _extractListPayload(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final candidates = [
        data['results'],
        data['vehicles'],
        data['items'],
        data['list'],
        data['data'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }
    return const <dynamic>[];
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
        message: NetworkErrorHandler.getErrorMessage(e),
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

  static Future<RideshareApiResult<void>> skipRideRequest(String rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/skip/'),
        headers: headers,
        body: json.encode({}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RideshareApiResult<void>(
          success: true,
          message: 'Ride skipped successfully',
        );
      }

      final data = json.decode(response.body);
      return RideshareApiResult<void>(
        success: false,
        message: data['message'] ?? 'Failed to skip ride',
      );
    } catch (e) {
      return RideshareApiResult<void>(
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
    String paymentMethod = 'wallet',
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{'status': status};
      if (finalFare != null) {
        body['final_fare'] = finalFare;
      }
      body['payment_method'] = paymentMethod;
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

  static Future<RideshareApiResult<Ride>> requestEarlyCompletion(
    String rideId, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/early-complete/'),
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

  static Future<RideshareApiResult<Ride>> confirmEarlyCompletion(
    String rideId, {
    bool confirm = true,
    String paymentMethod = 'wallet',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/confirm-early-complete/'),
        headers: headers,
        body: json.encode({'confirm': confirm, 'payment_method': paymentMethod}),
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

  static Future<RideshareApiResult<Map<String, dynamic>>> reportDriverCancellation(
    String rideId, {
    String details = '',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$rideId/report-cancellation/'),
        headers: headers,
        body: json.encode({'details': details}),
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
    double? maxRideDistanceKm,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (licenseNumber != null) body['license_number'] = licenseNumber;
      if (nationalIdNumber != null) body['national_id_number'] = nationalIdNumber;
      if (serviceRadiusKm != null) body['service_radius_km'] = serviceRadiusKm;
      if (maxRideDistanceKm != null) body['max_ride_distance_km'] = maxRideDistanceKm;
      
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

  static Future<RideshareApiResult<DriverProfile>> applyAsDriver({
    String? licenseNumber,
    String? nationalIdNumber,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (licenseNumber != null) body['license_number'] = licenseNumber;
      if (nationalIdNumber != null) body['national_id_number'] = nationalIdNumber;
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/apply/'),
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

  static Future<RideshareApiResult<DriverProfile>> settleDriverCashDues({
    bool goOnlineAfterPayment = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/drivers/settle-cash-dues/'),
        headers: headers,
        body: json.encode({'go_online_after_payment': goOnlineAfterPayment}),
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
      final normalizedLatitude = _roundToPrecision(latitude, 6);
      final normalizedLongitude = _roundToPrecision(longitude, 6);
      final normalizedHeading = _normalizeMetric(heading, 2);
      final normalizedSpeed = _normalizeMetric(speedKph, 2);
      final normalizedAccuracy = _normalizeMetric(accuracyMeters, 2);
      final body = <String, dynamic>{
        'latitude': normalizedLatitude,
        'longitude': normalizedLongitude,
      };
      if (rideId != null && rideId.isNotEmpty) body['ride_id'] = rideId;
      if (normalizedHeading != null) body['heading'] = normalizedHeading;
      if (normalizedSpeed != null) body['speed_kph'] = normalizedSpeed;
      if (normalizedAccuracy != null) body['accuracy_meters'] = normalizedAccuracy;
      
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
        (data) => _extractListPayload(data)
            .whereType<Map<String, dynamic>>()
            .map(Vehicle.fromJson)
            .toList(),
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
