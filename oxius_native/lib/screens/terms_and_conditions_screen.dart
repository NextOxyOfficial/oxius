import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade700,
              Colors.green.shade600,
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
                      'Terms & Conditions',
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
                                  Colors.teal.shade400,
                                  Colors.green.shade500,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.description,
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
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Last Updated: October 10, 2025',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildSection(
                          '1. Acceptance of Terms',
                          'By accessing and using Oxius platform, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                        ),
                        
                        _buildSection(
                          '2. Micro Gig Participation',
                          'You agree to complete micro gigs honestly and accurately. All submissions must be your own work and must comply with the task requirements. Fraudulent or fake submissions will result in immediate account suspension or termination.',
                        ),
                        
                        _buildSection(
                          '3. Payment Terms',
                          'Payments for completed gigs are subject to verification. We reserve the right to withhold payment for gigs that do not meet the specified requirements or appear to be fraudulent. Payment processing may take 3-7 business days after verification.',
                        ),
                        
                        _buildSection(
                          '4. User Conduct',
                          'You agree not to:\n• Submit false or misleading information\n• Use automated tools or bots\n• Create multiple accounts\n• Attempt to manipulate the system\n• Violate any applicable laws or regulations\n• Engage in any form of harassment or abuse',
                        ),
                        
                        _buildSection(
                          '5. Account Termination',
                          'We reserve the right to terminate or suspend your account at any time, with or without notice, for violations of these terms or suspicious activity. Terminated accounts will forfeit any pending payments.',
                        ),
                        
                        _buildSection(
                          '6. Intellectual Property',
                          'All content submitted through the platform may be used by Oxius for promotional and operational purposes. You retain ownership of your original content but grant us a license to use it.',
                        ),
                        
                        _buildSection(
                          '7. Disclaimer of Warranties',
                          'The service is provided "as is" without warranties of any kind. We do not guarantee uninterrupted access, error-free operation, or that the service will meet your requirements.',
                        ),
                        
                        _buildSection(
                          '8. Limitation of Liability',
                          'Oxius shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service.',
                        ),
                        
                        _buildSection(
                          '9. Changes to Terms',
                          'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the modified terms.',
                        ),
                        
                        _buildSection(
                          '10. Contact Information',
                          'For questions about these Terms & Conditions, please contact us at:\n\nEmail: support@oxius.com\nWebsite: www.oxius.com',
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Agreement Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade50,
                                Colors.green.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user, color: Colors.teal.shade600, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'By using Oxius, you acknowledge that you have read and understood these terms and conditions.',
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
