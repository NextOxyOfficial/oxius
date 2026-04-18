import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

/// Returns true if running on iOS (native only, not web)
bool get isIOSPlatform {
  if (kIsWeb) return false;
  try {
    return Platform.isIOS;
  } catch (_) {
    return false;
  }
}

/// Generates a web login URL with auto-login token if user is authenticated.
/// Falls back to direct URL if not logged in or token generation fails.
Future<Uri> _buildWebRedirectUrl(String webPath) async {
  final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
  final targetPath = webPath.isNotEmpty ? '/$webPath' : '/';

  // Try to get auth token for seamless login
  final token = await AuthService.getValidToken();
  if (token != null) {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/generate-web-token/'),
      );
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body);
        final webToken = data['token'];
        if (webToken != null) {
          client.close();
          return Uri.parse(
            '$baseUrl/auth/app-login?token=$webToken&redirect=${Uri.encodeComponent(targetPath)}',
          );
        }
      }
      client.close();
    } catch (_) {
      // Fall through to direct URL
    }
  }

  return Uri.parse('$baseUrl$targetPath');
}

/// A screen that redirects iOS users to the website for features
/// managed through the web platform.
class IOSWebRedirectScreen extends StatefulWidget {
  final String title;
  final String description;
  final String webPath;

  const IOSWebRedirectScreen({
    super.key,
    required this.title,
    required this.description,
    this.webPath = '',
  });

  @override
  State<IOSWebRedirectScreen> createState() => _IOSWebRedirectScreenState();
}

class _IOSWebRedirectScreenState extends State<IOSWebRedirectScreen> {
  bool _isLoading = false;

  Future<void> _openWebsite() async {
    setState(() => _isLoading = true);
    try {
      final url = await _buildWebRedirectUrl(widget.webPath);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF14213D),
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFFFFBF4),
        surfaceTintColor: const Color(0xFFFFFBF4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF14213D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 56,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Available on Web',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14213D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _openWebsite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93B4F5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continue on Website',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ll be signed in automatically',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
