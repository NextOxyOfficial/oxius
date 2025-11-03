import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Us',
          style: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'AdsyClub',
                    style: GoogleFonts.roboto(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // About Text
            Text(
              'Welcome to AdsyClub',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Social Business Network',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Adsy Club is a social business network dedicated to connecting individuals and businesses through an innovative platform. Our mission is to create a vibrant ecosystem where you can earn money, build meaningful connections, and find the services you need—all in one place.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            
            // What We Offer
            _buildSection(
              'What We Offer',
              [
                'Classified Advertisements - Post and browse ads across multiple categories',
                'Business Networking - Connect with professionals and establish partnerships',
                'Mobile Recharge - Easily recharge mobile credits through our platform',
                'Earning Opportunities - Multiple ways to generate income',
              ],
            ),
            const SizedBox(height: 24),
            
            // Our Vision
            _buildSection(
              'Our Vision',
              [
                'Empower Bangladeshis to take control of their economic future',
                'Bridge the gap between businesses and customers',
                'Foster a sense of community and innovative business practices',
                'Be at the forefront of Bangladesh\'s digital transformation',
              ],
            ),
            const SizedBox(height: 24),
            
            // Commitment to Safety
            _buildSection(
              'Commitment to Safety',
              [
                'Verification processes for businesses and users',
                'Secure payment processing through trusted partners',
                'Content moderation to maintain quality standards',
                'Privacy controls that put you in charge of your data',
                'Regular security audits and updates',
              ],
            ),
            const SizedBox(height: 24),
            
            // Our Future
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Future',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'As Adsy Club continues to grow, we aim to enhance our services further by incorporating advanced features and technologies. Our future goals include improving user experience through personalized recommendations, expanding our reach across Bangladesh, and continually enhancing the opportunities for our users to connect and prosper.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'re committed to evolving alongside Bangladesh\'s digital transformation and playing a key role in creating a more connected and prosperous business ecosystem.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.email_outlined, 'support@adsyclub.com'),
                  _buildContactItem(Icons.language_rounded, 'www.adsyclub.com'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
