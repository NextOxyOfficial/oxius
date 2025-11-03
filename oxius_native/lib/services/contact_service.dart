import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class ContactInfo {
  final String email;
  final String phone;
  final String supportHours;

  ContactInfo({
    required this.email,
    required this.phone,
    required this.supportHours,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'] ?? 'support@adsyclub.com',
      phone: json['phone'] ?? '+880 1896 144066',
      supportHours: json['support_hours'] ?? '24/7 Support Available',
    );
  }
}

class ContactService {
  static final String baseUrl = AppConfig.apiBaseUrl;

  /// Get contact information from backend
  static Future<ContactInfo> getContactInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contact-info/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContactInfo.fromJson(data);
      } else {
        // Return default values if API fails
        return ContactInfo(
          email: 'support@adsyclub.com',
          phone: '+880 1896 144066',
          supportHours: '24/7 Support Available',
        );
      }
    } catch (e) {
      print('Error fetching contact info: $e');
      // Return default values on error
      return ContactInfo(
        email: 'support@adsyclub.com',
        phone: '+880 1896 144066',
        supportHours: '24/7 Support Available',
      );
    }
  }

  /// Submit contact form message to backend
  static Future<Map<String, dynamic>> submitContactForm({
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String message,
  }) async {
    try {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Add auth token if available (optional for contact form)
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/public-contact/'),
        headers: headers,
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'subject': subject,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Message sent successfully! We will get back to you soon.',
        };
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Please check your input and try again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send message. Please try again later.',
        };
      }
    } catch (e) {
      print('Error submitting contact form: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}
