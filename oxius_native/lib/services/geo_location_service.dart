import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/geo_location.dart';

class GeoLocationService {
  final String baseUrl;
  final http.Client client;
  static const String _locationKey = 'user_location';

  GeoLocationService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Fetch regions (states/divisions)
  Future<List<Region>> fetchRegions({String country = 'Bangladesh'}) async {
    try {
      final uri = Uri.parse('$baseUrl/geo/regions/').replace(
        queryParameters: {'country_name_eng': country},
      );
      
      print('🌍 GeoLocationService: Fetching regions from: $uri');
      
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('🌍 GeoLocationService: Response status: ${response.statusCode}');
      print('🌍 GeoLocationService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns array directly, not wrapped in 'data'
        final results = data is List ? data : [];
        print('🌍 GeoLocationService: Parsed ${results.length} regions');
        return results
            .map((item) => Region.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ GeoLocationService: Failed with status ${response.statusCode}: ${response.body}');
      }
      return [];
    } catch (e) {
      print('❌ Error fetching regions: $e');
      return [];
    }
  }

  /// Fetch cities by region
  Future<List<City>> fetchCities({required String regionName}) async {
    try {
      final uri = Uri.parse('$baseUrl/geo/cities/').replace(
        queryParameters: {'region_name_eng': regionName},
      );
      
      print('🏙️ GeoLocationService: Fetching cities from: $uri');
      
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('🏙️ GeoLocationService: Response status: ${response.statusCode}');
      print('🏙️ GeoLocationService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns array directly, not wrapped in 'data'
        final results = data is List ? data : [];
        print('🏙️ GeoLocationService: Parsed ${results.length} cities');
        return results
            .map((item) => City.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ GeoLocationService: Failed with status ${response.statusCode}: ${response.body}');
      }
      return [];
    } catch (e) {
      print('❌ Error fetching cities: $e');
      return [];
    }
  }

  /// Fetch upazilas (areas) by city
  Future<List<Upazila>> fetchUpazilas({required String cityName}) async {
    try {
      final uri = Uri.parse('$baseUrl/geo/upazila/').replace(
        queryParameters: {'city_name_eng': cityName},
      );
      
      print('🏘️ GeoLocationService: Fetching upazilas from: $uri');
      
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('🏘️ GeoLocationService: Response status: ${response.statusCode}');
      print('🏘️ GeoLocationService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns array directly, not wrapped in 'data'
        final results = data is List ? data : [];
        print('🏘️ GeoLocationService: Parsed ${results.length} upazilas');
        return results
            .map((item) => Upazila.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ GeoLocationService: Failed with status ${response.statusCode}: ${response.body}');
      }
      return [];
    } catch (e) {
      print('❌ Error fetching upazilas: $e');
      return [];
    }
  }

  /// Save location to local storage
  Future<bool> saveLocation(GeoLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(location.toJson());
      return await prefs.setString(_locationKey, jsonString);
    } catch (e) {
      print('Error saving location: $e');
      return false;
    }
  }

  /// Get saved location from local storage
  Future<GeoLocation?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_locationKey);
      
      if (jsonString != null) {
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        return GeoLocation.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('Error getting saved location: $e');
      return null;
    }
  }

  /// Clear saved location
  Future<bool> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_locationKey);
    } catch (e) {
      print('Error clearing location: $e');
      return false;
    }
  }

  /// Check if location is saved
  Future<bool> hasLocation() async {
    final location = await getSavedLocation();
    return location != null && location.isComplete;
  }
}
