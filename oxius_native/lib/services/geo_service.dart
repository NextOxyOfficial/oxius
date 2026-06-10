import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class GeoService {
  /// Remove rows that share the same `name_eng`. The geo dataset occasionally
  /// returns duplicates (e.g. two "Dhaka" rows); feeding those into a
  /// DropdownButton crashes it with "2 or more items with the same value".
  static List<Map<String, dynamic>> _dedupeByNameEng(List list) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final name = (item['name_eng'] ?? '').toString().trim();
      if (name.isEmpty || !seen.add(name)) continue;
      out.add(item);
    }
    return out;
  }

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
          return _dedupeByNameEng(data);
        }
        return [];
      } else {
        throw Exception('Failed to load regions');
      }
    } catch (e) {
      debugPrint('Error loading regions: $e');
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
          return _dedupeByNameEng(data);
        }
        return [];
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
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
          return _dedupeByNameEng(data);
        }
        return [];
      } else {
        throw Exception('Failed to load upazilas');
      }
    } catch (e) {
      debugPrint('Error loading upazilas: $e');
      return [];
    }
  }
}
