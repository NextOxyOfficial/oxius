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
                              'Last Updated: May 23, 2025',
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
                          '1. Introduction',
                          'Welcome to Adsy Club, a premium platform for classified advertisements and business networking. By accessing or using our website at www.adsyclub.com (the "Site"), mobile applications, or any other services provided by Adsy Club (collectively, the "Services"), you agree to comply with and be bound by these Terms and Conditions.\n\nThese Terms constitute a legally binding agreement between you and Adsy Club regarding your use of the Services. If you do not agree with these Terms, please refrain from using our Services.\n\nWe may update these Terms from time to time to reflect changes in our practices or for legal, operational, or regulatory reasons. The most current version will always be available on our website.',
                        ),
                        
                        _buildSection(
                          '2. Acceptance of Terms',
                          'By using our Services, you confirm that:\n\n• You are at least 18 years of age or the legal age of majority in your jurisdiction, whichever is greater.\n• You possess the legal capacity to enter into binding agreements.\n• If you are using the Services on behalf of an organization or entity, you have the authority to bind that entity to these Terms.\n• You will comply with all applicable local, state, national, and international laws and regulations.\n\nYour continued use of our Services following any changes to these Terms constitutes your acceptance of those changes. It is your responsibility to review these Terms periodically.',
                        ),
                        
                        _buildSection(
                          '3. User Accounts',
                          'To access certain features of our Services, you may need to create a user account. You agree to:\n\n• Provide accurate, current, and complete information during registration.\n• Maintain and promptly update your account information.\n• Keep your password confidential and secure.\n• Be solely responsible for all activities that occur under your account.\n• Notify us immediately of any unauthorized use of your account or any other security breach.\n• Ensure that you log out from your account at the end of each session when accessing our Services from a shared computer or public device.\n\nYou may not transfer or sell your account to another party. We reserve the right to suspend or terminate your account if any information provided during registration or thereafter proves to be inaccurate, incomplete, or fraudulent.\n\nAdsy Club is not responsible for any loss or damage arising from your failure to comply with these account security obligations.',
                        ),
                        
                        _buildSection(
                          '4. Content Policies',
                          'Users may post classified advertisements, business profiles, and other content on our platform. By posting content, you:\n\n• Grant Adsy Club a non-exclusive, worldwide, royalty-free, sublicensable, and transferable license to use, reproduce, modify, adapt, publish, translate, distribute, and display such content across our Services and promotional channels.\n• Represent and warrant that you own or have the necessary rights to grant us the license described above.\n• Agree that your content does not violate the privacy rights, publicity rights, intellectual property rights, or any other rights of any third party.\n• Understand that you are solely responsible for all content you post.\n\nWhile we do not claim ownership of your content, the license you grant allows us to use your content to operate, promote, and improve our Services.\n\nAdsy Club reserves the right to review, monitor, and remove any content that violates these Terms or that we find objectionable, at our sole discretion and without prior notice.',
                        ),
                        
                        _buildSection(
                          '5. Prohibited Activities',
                          'You agree not to engage in any of the following prohibited activities:\n\nContent Violations:\n• Posting false, misleading, deceptive, or fraudulent information.\n• Posting content that is defamatory, obscene, pornographic, vulgar, offensive, threatening, or harassing.\n• Posting content that promotes discrimination, bigotry, racism, or harm against any individual or group.\n• Posting content that infringes upon intellectual property rights, including copyrights and trademarks.\n• Posting content that violates any person\'s right to privacy or publicity.\n\nOperational Violations:\n• Using our Services for any illegal purpose or in violation of any local, state, national, or international law.\n• Attempting to interfere with, compromise, or disrupt the systems or security of our Services.\n• Circumventing, disabling, or otherwise interfering with security-related features of our Services.\n• Using any automated system (bots, scrapers, crawlers) to access our Services without our express written permission.\n• Attempting to impersonate another user, person, or entity, or falsely stating or misrepresenting your affiliation with a person or entity.\n\nViolation of these prohibitions may result in the removal of content, suspension or termination of your account, and potentially legal action, depending on the severity and nature of the violation.',
                        ),
                        
                        _buildSection(
                          '6. Intellectual Property',
                          'The Adsy Club platform, including its logo, trademarks, service marks, design elements, text, software, graphics, layout, and other content contained on the Site (collectively, "Adsy Club Content"), is owned by or licensed to Adsy Club and is protected by copyright, trademark, and other intellectual property laws.\n\nSubject to your compliance with these Terms, Adsy Club grants you a limited, non-exclusive, non-transferable, and revocable license to access and use the Services and Adsy Club Content for personal and non-commercial purposes.\n\nYou may not:\n• Modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any Adsy Club Content.\n• Use any Adsy Club Content for commercial purposes without our express written consent.\n• Remove any copyright, trademark, or other proprietary notices from Adsy Club Content.\n• Use any data mining, robots, or similar data gathering or extraction methods on our Services.\n\nIf you believe that any content on our Site infringes upon your copyright, please contact us with details of the alleged infringement.',
                        ),
                        
                        _buildSection(
                          '7. Termination',
                          'Adsy Club reserves the right to suspend, disable, or terminate your account and access to our Services at our sole discretion, without prior notice or liability, for any reason, including but not limited to:\n\n• A breach of these Terms or any other policies referenced herein.\n• Upon request by law enforcement or other government agencies.\n• Due to unexpected technical or security issues.\n• Extended periods of inactivity.\n• Engagement in fraudulent or illegal activities.\n• Any other conduct that we believe, in our sole discretion, violates these Terms or is harmful to other users or third parties, or the business interests of Adsy Club.\n\nUpon termination, your right to use the Services will immediately cease. All provisions of these Terms that by their nature should survive termination shall survive, including without limitation, ownership provisions, warranty disclaimers, indemnity, and limitations of liability.',
                        ),
                        
                        _buildSection(
                          '8. Disclaimers and Limitations',
                          'Disclaimer of Warranties:\nTHE SERVICES ARE PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. ADSY CLUB EXPRESSLY DISCLAIMS ALL WARRANTIES, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.\n\nLimitation of Liability:\nTO THE FULLEST EXTENT PERMITTED BY LAW, ADSY CLUB SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, GOODWILL, USE, DATA, OR OTHER INTANGIBLE LOSSES, RESULTING FROM: (I) YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE SERVICES; (II) ANY CONDUCT OR CONTENT OF ANY THIRD PARTY ON THE SERVICES; (III) ANY CONTENT OBTAINED FROM THE SERVICES; AND (IV) UNAUTHORIZED ACCESS, USE, OR ALTERATION OF YOUR TRANSMISSIONS OR CONTENT.\n\nIndemnification:\nYou agree to defend, indemnify, and hold harmless Adsy Club and its affiliates, officers, directors, employees, and agents, from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney\'s fees) arising from: (i) your use of and access to the Services; (ii) your violation of any term of these Terms; (iii) your violation of any third-party right, including without limitation any copyright, property, or privacy right; or (iv) any claim that your content caused damage to a third party.\n\nGoverning Law:\nThese Terms shall be governed by and construed in accordance with the laws of Bangladesh, without regard to its conflict of law provisions. Any legal action or proceeding arising out of these Terms or your use of the Services shall be brought exclusively in the courts located in Dhaka, Bangladesh, and you consent to the personal jurisdiction of such courts.',
                        ),
                        
                        _buildSection(
                          '9. Contact Information',
                          'If you have any questions, concerns, or feedback regarding these Terms or our Services, please contact us at:\n\nEmail: support@adsyclub.com\nPhone: +8801896144067\nAddress: H#116, Office Building, Sewria, Kushtia, Bangladesh',
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
                                  'By using Adsy Club, you acknowledge that you have read and understood these terms and conditions.',
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
