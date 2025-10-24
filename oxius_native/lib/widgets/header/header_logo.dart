import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';

/// Header Logo Widget - Loads from backend database
class HeaderLogo extends StatefulWidget {
  const HeaderLogo({super.key});

  @override
  State<HeaderLogo> createState() => _HeaderLogoState();
}

class _HeaderLogoState extends State<HeaderLogo> {
  Map<String, dynamic>? logoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/logo/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          // Normalize URLs
          if (data['image'] != null) {
            data['image'] = AppConfig.getAbsoluteUrl(data['image']);
          }
          if (data['logo'] != null) {
            data['logo'] = AppConfig.getAbsoluteUrl(data['logo']);
          }
        }
        
        setState(() {
          logoData = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Logo load error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/'),
      child: SizedBox(
        width: 50,
        height: 22,
        child: _buildLogoContent(),
      ),
    );
  }

  Widget _buildLogoContent() {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (logoData != null) {
      final imageUrl = logoData!['image'] ?? logoData!['logo'];
      final logoText = logoData!['name'] ?? logoData!['title'];

      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        return Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildTextLogo(logoText ?? 'Logo'),
        );
      }

      if (logoText != null && logoText.toString().isNotEmpty) {
        return _buildTextLogo(logoText);
      }
    }

    return _buildTextLogo('AdsyClub');
  }

  Widget _buildTextLogo(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
