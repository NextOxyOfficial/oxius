import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GeoService {
  // Get regions/states by country
  static Future<List<Map<String, dynamic>>> getRegions(String country) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/geo/regions/?country_name_eng=$country'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load regions');
      }
    } catch (e) {
      print('Error loading regions: $e');
      return [];
    }
  }

  // Get cities by region
  static Future<List<Map<String, dynamic>>> getCities(String region) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/geo/cities/?region_name_eng=$region'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      print('Error loading cities: $e');
      return [];
    }
  }

  // Get upazilas/areas by city
  static Future<List<Map<String, dynamic>>> getUpazilas(String city) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/geo/upazila/?city_name_eng=$city'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load upazilas');
      }
    } catch (e) {
      print('Error loading upazilas: $e');
      return [];
    }
  }
}
