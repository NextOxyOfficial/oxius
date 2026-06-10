import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/gold_sponsor_models.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class GoldSponsorService {
  // Use centralized API service base URL
  static String get baseUrl => ApiService.baseUrl;
  
  // Fetch sponsorship packages
  /// Pricing rules for location targeting (discount % + max custom locations).
  static Future<Map<String, int>> getPricingConfig() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/bn/gold-sponsors/pricing-config/'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final d = json.decode(response.body) as Map<String, dynamic>;
        return {
          'discount':
              (d['specific_location_discount_percent'] as num?)?.toInt() ?? 0,
          'maxLocations': (d['max_custom_locations'] as num?)?.toInt() ?? 10,
          'maxDiscountDivisions':
              (d['max_discount_divisions'] as num?)?.toInt() ?? 2,
        };
      }
    } catch (e) {
      debugPrint('getPricingConfig error: $e');
    }
    return {'discount': 0, 'maxLocations': 10};
  }

  static Future<List<SponsorshipPackage>> getPackages() async {
    try {
      final token = AuthService.accessToken;

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      debugPrint('Fetching packages from: $baseUrl/bn/gold-sponsors/packages/');
      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/packages/'),
        headers: headers,
      );

      debugPrint('Packages response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('Packages response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        final packages = data.map((json) => SponsorshipPackage.fromJson(json)).toList();
        debugPrint('Parsed ${packages.length} packages');
        return packages;
      } else {
        debugPrint('Failed to load packages: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching packages: $e');
      debugPrint('Stack trace: $stackTrace');
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

      debugPrint('Fetching sponsors from: $baseUrl/bn/gold-sponsors/list/');
      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/list/'),
        headers: headers,
      );

      debugPrint('Sponsors response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('Sponsors response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        final sponsors = data.map((json) => GoldSponsor.fromJson(json)).toList();
        debugPrint('Parsed ${sponsors.length} sponsors');
        return sponsors;
      } else {
        debugPrint('Failed to load gold sponsors: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching gold sponsors: $e');
      debugPrint('Stack trace: $stackTrace');
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
        debugPrint('Failed to load sponsor banners: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching sponsor banners: $e');
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
      debugPrint('Error incrementing sponsor views: $e');
      return false;
    }
  }

  // Submit gold sponsor application
  static Future<Map<String, dynamic>> submitApplication({
    required String businessName,
    required String businessDescription,
    required String contactEmail,
    required String phoneNumber,
    String? website,
    String? profileUrl,
    required int packageId,
    XFile? logoFile,
    List<Map<String, dynamic>>? banners,
    List<Map<String, String>>? locations,
  }) async {
    try {
      final token = AuthService.accessToken;
      if (token == null) {
        return {'success': false, 'error': 'Authentication required'};
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/bn/gold-sponsors/apply/'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['business_name'] = businessName;
      request.fields['business_description'] = businessDescription;
      request.fields['contact_email'] = contactEmail;
      request.fields['phone_number'] = phoneNumber;
      request.fields['package_id'] = packageId.toString();
      
      // Only add URL fields if they have valid content
      if (website != null && website.trim().isNotEmpty) {
        request.fields['website'] = website.trim();
      }
      if (profileUrl != null && profileUrl.trim().isNotEmpty) {
        request.fields['profile_url'] = profileUrl.trim();
      }

      // Target locations (empty => shown all over Bangladesh)
      final cleanLocations = (locations ?? [])
          .where((l) =>
              (l['division'] ?? '').trim().isNotEmpty ||
              (l['city'] ?? '').trim().isNotEmpty ||
              (l['area'] ?? '').trim().isNotEmpty)
          .toList();
      request.fields['locations'] = jsonEncode(cleanLocations);

      // Add logo file if provided (cross-platform)
      if (logoFile != null) {
        final bytes = await logoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            bytes,
            filename: logoFile.name,
          ),
        );
      }

      // Add banners if provided (cross-platform)
      if (banners != null && banners.isNotEmpty) {
        request.fields['banner_count'] = banners.length.toString();
        for (int i = 0; i < banners.length; i++) {
          final banner = banners[i];
          if (banner['title'] != null && banner['title'].toString().trim().isNotEmpty) {
            request.fields['banner_${i}_title'] = banner['title'].toString().trim();
          }
          if (banner['link_url'] != null && banner['link_url'].toString().trim().isNotEmpty) {
            request.fields['banner_${i}_link_url'] = banner['link_url'].toString().trim();
          }
          if (banner['file'] != null && banner['file'] is XFile) {
            final XFile file = banner['file'];
            final bytes = await file.readAsBytes();
            request.files.add(
              http.MultipartFile.fromBytes(
                'banner_${i}_image',
                bytes,
                filename: file.name,
              ),
            );
          }
          request.fields['banner_${i}_order'] = (i + 1).toString();
          request.fields['banner_${i}_is_active'] = 'true';
        }
      }

      debugPrint('Submitting gold sponsor application to: ${request.url}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Application response status: ${response.statusCode}');
      debugPrint('Application response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        try {
          final errorData = json.decode(response.body);
          
          // Extract validation errors
          if (errorData is Map) {
            final errorMessages = <String>[];
            errorData.forEach((key, value) {
              if (value is List) {
                errorMessages.add('$key: ${value.join(', ')}');
              } else {
                errorMessages.add('$key: $value');
              }
            });
            return {'success': false, 'error': errorMessages.join('\n')};
          }
          
          return {'success': false, 'error': errorData['message'] ?? 'Failed to submit application'};
        } catch (e) {
          return {'success': false, 'error': 'Failed to submit application (Status: ${response.statusCode})'};
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error submitting application: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'error': 'Failed to submit application: $e'};
    }
  }

  // Get user's gold sponsor stats (for drawer/sidebar)
  /// Full data of the logged-in user's sponsorships (for editing).
  static Future<List<Map<String, dynamic>>> getMySponsors() async {
    try {
      final token = AuthService.accessToken;
      if (token == null) return [];
      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/my-sponsors/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data is List ? data : (data['results'] ?? data['sponsors'] ?? []);
        return List<Map<String, dynamic>>.from(
            (list as List).map((e) => Map<String, dynamic>.from(e)));
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my sponsors: $e');
      return [];
    }
  }

  static Future<bool> updateMySponsor(
      int sponsorId, Map<String, dynamic> fields) async {
    try {
      final token = AuthService.accessToken;
      if (token == null) return false;
      final response = await http.put(
        Uri.parse('$baseUrl/bn/gold-sponsors/update/$sponsorId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(fields),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating sponsor: $e');
      return false;
    }
  }

  static Future<bool> deleteMySponsor(int sponsorId) async {
    try {
      final token = AuthService.accessToken;
      if (token == null) return false;
      final response = await http.delete(
        Uri.parse('$baseUrl/bn/gold-sponsors/delete/$sponsorId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting sponsor: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getMySponsorsStats() async {
    try {
      final token = AuthService.accessToken;
      if (token == null) {
        return {
          'active_count': 0,
          'total_views': 0,
          'featured_sponsors': [],
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      debugPrint('Fetching my sponsors stats from: $baseUrl/bn/gold-sponsors/stats/');
      final response = await http.get(
        Uri.parse('$baseUrl/bn/gold-sponsors/stats/'),
        headers: headers,
      );

      debugPrint('Stats response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('Stats response body: ${response.body}');
        final data = json.decode(response.body);
        return data;
      } else {
        debugPrint('Failed to load stats: ${response.statusCode} - ${response.body}');
        return {
          'active_count': 0,
          'total_views': 0,
          'featured_sponsors': [],
        };
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching sponsor stats: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'active_count': 0,
        'total_views': 0,
        'featured_sponsors': [],
      };
    }
  }
}
