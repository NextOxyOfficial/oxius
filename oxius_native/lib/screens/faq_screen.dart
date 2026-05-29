import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../widgets/ios_web_redirect_screen.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF0F766E);
  static const Color _softPrimary = Color(0xFFE6F7F3);
  static const Color _border = Color(0xFFE5E7EB);

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
          'Frequently Asked Questions',
          style: AppFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: _ink,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 80),
        children: [
          Text(
            'Common Questions',
            style: AppFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quick answers to the things users ask most.',
            style: AppFonts.roboto(
              fontSize: 15,
              height: 1.45,
              color: _muted,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _buildFaqItem(
                  'What is AdsyClub?',
                  'AdsyClub is a comprehensive platform that allows you to earn money, connect with society, and find the services you need. It includes a marketplace, business networking, micro-gigs, e-learning, and more.',
                ),
                _buildFaqItem(
                  'How do I create an account?',
                  'Click on the "Register" button on the login page, fill in your details including name, email, phone number, and password, then verify your email address.',
                ),
                _buildFaqItem(
                  'How do I post a sale ad?',
                  'Navigate to the Buy & Sell section, click on "Post Sale", fill in the product details including title, description, price, location, and upload photos. You must be logged in to post ads.',
                ),
                _buildFaqItem(
                  'What is AdsyPay?',
                  'AdsyPay is our digital wallet service that allows you to deposit funds, withdraw money, and make secure transactions within the platform.',
                ),
                _buildFaqItem(
                  'How do I recharge mobile phones?',
                  'Go to the Mobile Recharge section, enter the phone number, select the operator and amount, then complete the payment using your AdsyPay wallet or other payment methods.',
                ),
                _buildFaqItem(
                  'What are Micro-Gigs?',
                  'Micro-Gigs are small tasks or services that you can offer or hire others to complete. Examples include graphic design, writing, data entry, and more.',
                ),
                if (!isIOSPlatform)
                  _buildFaqItem(
                    'How do I upgrade to Pro?',
                    'Visit the Upgrade to Pro section from the menu, select a package that suits your needs, and complete the payment. Pro members get additional features and benefits.',
                  ),
                _buildFaqItem(
                  'Is my payment information secure?',
                  'Yes, we use industry-standard encryption and secure payment gateways to protect your financial information. We never store your complete payment details.',
                ),
                _buildFaqItem(
                  'How do I contact support?',
                  'You can reach our support team through the Contact Us page, or email us directly at support@adsyclub.com. We typically respond within 24 hours.',
                ),
                _buildFaqItem(
                  'Can I delete my account?',
                  'Yes, you can request account deletion by contacting our support team. Please note that this action is permanent and cannot be undone.',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Still have questions?
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _softPrimary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF99D9C9)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 48,
                  color: _primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Still have questions?',
                  style: AppFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact our support team for personalized assistance',
                  style: AppFonts.roboto(
                    fontSize: 14,
                    color: _muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/contact-us');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: Text(
                    'Contact Us',
                    style: AppFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    String question,
    String answer, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            iconColor: _primary,
            collapsedIconColor: _ink,
            title: Text(
              question,
              style: AppFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: AppFonts.roboto(
                    fontSize: 15,
                    height: 1.6,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 1, color: _border),
      ],
    );
  }
}
