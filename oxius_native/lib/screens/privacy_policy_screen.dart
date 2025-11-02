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
                              'Last Updated: May 23, 2025',
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
                          'We collect several types of information from and about users of our platform:\n\nPersonal Information:\nWhen you register an account, post ads, or contact us, you may provide us with personally identifiable information such as your:\n• Full name\n• Email address\n• Phone number\n• Physical address or location\n• Profile pictures\n• Payment information (processed securely through our payment processors)\n• Communication preferences\n\nUsage and Technical Data:\nWe automatically collect certain information when you visit, use or navigate our platform. This information does not reveal your specific identity but may include:\n• Device and connection information (IP address, browser type, operating system)\n• Usage patterns and browsing history on our platform\n• Time spent on specific pages\n• Referring websites or applications\n• Click-stream data and interaction patterns\n• Device identifiers and attributes\n\nContent and Media:\nWhen posting ads or engaging with our platform, you may provide:\n• Images and photos of items for sale\n• Text descriptions and details\n• Price information and product specifications\n• Comments, reviews, and messaging content',
                        ),
                        
                        _buildSection(
                          '2. How We Use Your Information',
                          'We use the information we collect for various legitimate business purposes:\n\nService Provision:\nTo provide and maintain our platform, process transactions, and manage your account\n\nCommunications:\nTo contact you regarding your account, updates, security alerts, and support messages\n\nAnalytics & Improvement:\nTo understand usage patterns and enhance user experience through site analytics\n\nMarketing:\nTo deliver relevant content, promotions, and advertising based on your preferences\n\nSecurity:\nTo detect, prevent, and address technical issues, fraud, and security breaches\n\nLegal Compliance:\nTo comply with applicable laws, regulations, and legal processes\n\nLegal Basis for Processing:\nWe process your personal information based on legitimate interests, consent, contractual necessity, and/or compliance with legal obligations. You can withdraw consent at any time by contacting us, though this will not affect the lawfulness of processing prior to withdrawal.',
                        ),
                        
                        _buildSection(
                          '3. Information Sharing and Disclosure',
                          'We do not sell or rent your personal information to third parties.\n\nHowever, we may share your information in the following circumstances:\n\nService Providers:\nWe may share your information with third-party vendors, service providers, contractors, or agents who perform services for us or on our behalf. These entities include:\n• Cloud hosting and storage providers\n• Payment processors\n• Customer support services\n• Analytics providers\n• Email and communication service providers\n• Security and fraud prevention services\n\nThese third parties are contractually obligated to use personal information only for the purposes for which we disclose it to them.\n\nLegal Requirements:\nWe may disclose your information if required to do so by law or in response to valid requests by public authorities (e.g., a court or government agency). These circumstances may include:\n• Compliance with legal obligations\n• Response to legal processes such as court orders or subpoenas\n• Protection against legal liability\n• Protection of the rights, property, or safety of our users or others\n\nBusiness Transfers:\nIf Adsy Club is involved in a merger, acquisition, or sale of all or a portion of its assets, your information may be transferred as part of that transaction. We will notify you via email and/or a prominent notice on our website of any change in ownership or uses of your personal information, as well as any choices you may have regarding your personal information.\n\nWith Your Consent:\nWe may share your information with third parties when you have given us your consent to do so. For example, if you choose to make your profile or listings public, this information will be visible to other users of our platform.\n\nWhen you post content publicly on our platform, that information may be viewed by any user of the platform. We cannot control what other users do with information you voluntarily disclose in public areas.',
                        ),
                        
                        _buildSection(
                          '4. Data Security',
                          'We implement appropriate technical and organizational security measures to protect your personal information from unauthorized access, use, alteration, or destruction. Our security practices include:\n\nEncryption:\nUsing industry-standard encryption to protect data transmission and storage\n\nAccess Controls:\nRestricting access to personal information to authorized personnel only\n\nSecure Infrastructure:\nHosting data in secure, certified data centers with physical and network security\n\nRegular Monitoring:\nContinuously monitoring systems for suspicious activities and potential vulnerabilities\n\nSecurity Limitation Notice:\nDespite our efforts to protect your information, no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security. By using our Services, you acknowledge this inherent risk.\n\nData Breach Procedures:\nIn the event of a data breach that affects your personal information, we will notify you and the relevant authorities as required by applicable law. We maintain incident response procedures to ensure timely and appropriate action in response to data breaches.',
                        ),
                        
                        _buildSection(
                          '5. Your Privacy Rights',
                          'Depending on your location, you may have certain rights regarding your personal information. These may include:\n\nAccess Rights:\nYou have the right to request copies of your personal information. We may charge a small fee for this service if allowed by law.\n\nRectification Rights:\nYou have the right to request that we correct inaccurate or incomplete information about you.\n\nErasure Rights:\nYou have the right to request that we delete your personal information in certain circumstances, subject to legal retention requirements.\n\nData Portability:\nYou have the right to request that we transfer your data to another organization or directly to you in a machine-readable format.\n\nRestriction Rights:\nYou have the right to request that we restrict the processing of your data in certain circumstances.\n\nObjection Rights:\nYou have the right to object to our processing of your personal information for direct marketing purposes or based on legitimate interests.\n\nHow to Exercise Your Rights:\nTo exercise any of these rights, please contact us using the information provided in the "Contact Information" section. We will respond to your request within the timeframe required by applicable law.\n\nYou will not be discriminated against for exercising any of your privacy rights. However, we may not be able to fulfill some requests if doing so would prevent us from complying with legal obligations or providing the services you have requested.',
                        ),
                        
                        _buildSection(
                          '6. Cookies & Tracking Technologies',
                          'We use cookies and similar tracking technologies to enhance your experience on our platform. These technologies allow us to remember your preferences, understand how you use our site, and personalize content.\n\nTypes of Cookies We Use:\n\nEssential Cookies:\nNecessary for the operation of our platform. They enable basic functions like page navigation and access to secure areas.\n\nFunctional Cookies:\nAllow us to remember choices you make and provide enhanced, personalized features.\n\nAnalytics Cookies:\nHelp us understand how visitors interact with our platform by collecting and reporting information anonymously.\n\nAdvertising Cookies:\nUsed to deliver relevant advertisements based on your interests and to measure the effectiveness of marketing campaigns.\n\nCookie Management:\nMost web browsers allow you to control cookies through their settings. You can typically delete cookies and adjust your cookie preferences at any time. However, if you disable cookies, some features of our platform may not function properly.\n\nYou can learn more about cookies and how to manage them in your browser at www.allaboutcookies.org.\n\nDo Not Track Signals:\nSome browsers have a "Do Not Track" feature that signals to websites that you visit that you do not want to have your online activity tracked. Given that there is not yet a common understanding of how to interpret these signals, our platform does not currently respond to "Do Not Track" signals.',
                        ),
                        
                        _buildSection(
                          '7. Children\'s Privacy',
                          'Age Restriction:\nOur Services are not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If you are a parent or guardian and believe that your child has provided us with personal information, please contact us immediately.\n\nIf we learn that we have collected personal information from a child under the age of 18, we will take steps to delete that information as quickly as possible. If you believe we might have any information from or about a child, please contact us using the information provided in the "Contact Information" section.',
                        ),
                        
                        _buildSection(
                          '8. Changes to This Privacy Policy',
                          'We may update our Privacy Policy from time to time to reflect changes in our practices, technologies, legal requirements, and other factors. When we make changes, we will update the "Last Updated" date at the top of this Privacy Policy.\n\nNotification of Changes:\nFor significant changes to this Privacy Policy, we will make reasonable efforts to notify you, such as by sending an email to the address associated with your account (if applicable) or by placing a prominent notice on our website. We encourage you to periodically review this Privacy Policy to stay informed about our information practices.\n\nYour continued use of our Services after changes to this Privacy Policy have been posted constitutes your acceptance of the updated Privacy Policy.',
                        ),
                        
                        _buildSection(
                          '9. Contact Information',
                          'If you have any questions, concerns, or requests regarding this Privacy Policy or our privacy practices, please contact us at:\n\nEmail: privacy@adsyclub.com\nPhone: +8801896144067\nAddress: H#116, Office Building, Sewria, Kushtia, Bangladesh',
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
                                  'Your privacy is important to us. We are committed to protecting your personal information and being transparent about our data practices at Adsy Club.',
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
