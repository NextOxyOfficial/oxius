import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BannerService {
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;
  BannerService._internal();

  // Use centralized API service base URL
  static String get baseUrl => ApiService.baseUrl;

  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get banners => _banners;
  bool get isLoading => _isLoading;

  /// Load banners from backend API
  Future<bool> loadBanners() async {
    if (_isLoading) return false;
    
    _isLoading = true;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/banners/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _banners = List<Map<String, dynamic>>.from(data['banners']);
        _isLoading = false;
        return true;
      } else {
        print('Error loading banners: ${response.statusCode}');
        // Fallback to default banners
        _setDefaultBanners();
        _isLoading = false;
        return false;
      }
    } catch (e) {
      print('Error loading banners: $e');
      // Fallback to default banners
      _setDefaultBanners();
      _isLoading = false;
      return false;
    }
  }

  void _setDefaultBanners() {
    _banners = [
      {
        "id": 1,
        "image_url": "https://via.placeholder.com/800x400/10B981/white?text=Welcome+to+AdsyClub",
        "title": "Welcome to AdsyClub",
        "subtitle": "Your Social Business Network"
      },
      {
        "id": 2,
        "image_url": "https://via.placeholder.com/800x400/3B82F6/white?text=Earn+Money+Online",
        "title": "Earn Money Online",
        "subtitle": "Start your journey today"
      },
      {
        "id": 3,
        "image_url": "https://via.placeholder.com/800x400/8B5CF6/white?text=E-Learning+Platform",
        "title": "E-Learning Platform",
        "subtitle": "Learn new skills"
      }
    ];
  }
}