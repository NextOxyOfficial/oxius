import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gold_sponsor_models.dart';
import 'auth_service.dart';
import 'api_service.dart';

class GoldSponsorService {
  // Use centralized API service base URL
  static String get baseUrl => ApiService.baseUrl;
  
  // Fetch sponsorship packages
  static Future<List<SponsorshipPackage>> getPackages() async {
    try {
      final token = AuthService.accessToken;
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('Fetching packages from: $baseUrl/bn/gold-sponsors/packages/');
      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/packages/'),
        headers: headers,
      );

      print('Packages response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Packages response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        final packages = data.map((json) => SponsorshipPackage.fromJson(json)).toList();
        print('Parsed ${packages.length} packages');
        return packages;
      } else {
        print('Failed to load packages: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('Error fetching packages: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Fetch list of gold sponsors
  static Future<List<GoldSponsor>> getGoldSponsors() async {
    try {
      final token = AuthService.accessToken;
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('Fetching sponsors from: $baseUrl/bn/gold-sponsors/list/');
      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/list/'),
        headers: headers,
      );

      print('Sponsors response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Sponsors response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        final sponsors = data.map((json) => GoldSponsor.fromJson(json)).toList();
        print('Parsed ${sponsors.length} sponsors');
        return sponsors;
      } else {
        print('Failed to load gold sponsors: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('Error fetching gold sponsors: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Fetch banners for a specific sponsor
  static Future<List<SponsorBanner>> getSponsorBanners(String sponsorId) async {
    try {
      final token = AuthService.accessToken;
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/$sponsorId/banners/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final banners = data
            .map((json) => SponsorBanner.fromJson(json))
            .where((banner) => banner.isActive)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return banners;
      } else {
        print('Failed to load sponsor banners: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching sponsor banners: $e');
      return [];
    }
  }

  // Increment sponsor views
  static Future<bool> incrementViews(String sponsorId) async {
    try {
      final token = AuthService.accessToken;
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bn/gold-sponsors/increment-views/$sponsorId/'),
        headers: headers,
        body: json.encode({}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error incrementing sponsor views: $e');
      return false;
    }
  }
}
