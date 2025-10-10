import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.indigo.shade600,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Privacy Policy',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Header
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.indigo.shade500,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.privacy_tip,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Last Updated
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Last Updated: October 10, 2025',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildSection(
                          '1. Information We Collect',
                          'We collect information you provide directly to us, including:\n\n• Personal Information: Name, email address, phone number, and profile information\n• Payment Information: Bank details and payment preferences\n• Task Submissions: Photos, videos, text, and other content you submit\n• Usage Data: Information about how you use our platform\n• Device Information: IP address, browser type, and operating system',
                        ),
                        
                        _buildSection(
                          '2. How We Use Your Information',
                          'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process your micro gig submissions\n• Process payments and prevent fraud\n• Send you updates, notifications, and promotional materials\n• Respond to your comments and questions\n• Analyze usage patterns and improve user experience\n• Comply with legal obligations',
                        ),
                        
                        _buildSection(
                          '3. Information Sharing',
                          'We may share your information with:\n\n• Service Providers: Third parties who help us operate our platform\n• Business Partners: Companies we collaborate with for gig offerings\n• Legal Requirements: When required by law or to protect our rights\n• Business Transfers: In case of merger, acquisition, or asset sale\n\nWe do not sell your personal information to third parties.',
                        ),
                        
                        _buildSection(
                          '4. Data Security',
                          'We implement appropriate technical and organizational measures to protect your personal information. However, no method of transmission over the internet is 100% secure. We use:\n\n• Encrypted data transmission (SSL/TLS)\n• Secure server infrastructure\n• Regular security audits\n• Access controls and authentication',
                        ),
                        
                        _buildSection(
                          '5. Data Retention',
                          'We retain your personal information for as long as necessary to fulfill the purposes outlined in this policy, unless a longer retention period is required by law. Account data is retained for 90 days after account closure.',
                        ),
                        
                        _buildSection(
                          '6. Your Rights',
                          'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your data\n• Object to processing of your data\n• Export your data in a portable format\n• Withdraw consent at any time\n\nTo exercise these rights, contact us at privacy@oxius.com',
                        ),
                        
                        _buildSection(
                          '7. Cookies and Tracking',
                          'We use cookies and similar tracking technologies to:\n\n• Remember your preferences\n• Analyze site traffic and usage\n• Improve our services\n• Provide personalized content\n\nYou can control cookies through your browser settings.',
                        ),
                        
                        _buildSection(
                          '8. Children\'s Privacy',
                          'Our service is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If you become aware that a child has provided us with personal information, please contact us.',
                        ),
                        
                        _buildSection(
                          '9. International Data Transfers',
                          'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information in accordance with this privacy policy.',
                        ),
                        
                        _buildSection(
                          '10. Changes to Privacy Policy',
                          'We may update this privacy policy from time to time. We will notify you of significant changes by posting the new policy on our platform and updating the "Last Updated" date.',
                        ),
                        
                        _buildSection(
                          '11. Contact Us',
                          'If you have questions about this Privacy Policy, please contact us:\n\nEmail: privacy@oxius.com\nAddress: Oxius Inc.\nWebsite: www.oxius.com\nPhone: +880-XXX-XXXXXX',
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Privacy Notice Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.indigo.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield, color: Colors.blue.shade600, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your privacy is important to us. We are committed to protecting your personal information and being transparent about our data practices.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
