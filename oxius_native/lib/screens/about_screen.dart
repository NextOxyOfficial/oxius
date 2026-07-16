import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Design tokens shared across the app's plain pages.
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _hair = Color(0xFFF1F5F9);
  static const Color _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Us',
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          // Brand / intro
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'AdsyClub',
                    style: AppFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'A social business network for Bangladesh',
            style: AppFonts.roboto(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.3,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'AdsyClub brings earning, buying, selling and connecting into a '
            'single app. From a business feed and micro gigs to an online '
            'shop, classifieds, mobile recharge and a built-in wallet, it is '
            'designed to help everyday people and small businesses grow.',
            style: AppFonts.roboto(
              fontSize: 14.5,
              height: 1.65,
              color: _muted,
            ),
          ),
          const SizedBox(height: 26),

          // Our aim
          _sectionHeader('Our aim'),
          const SizedBox(height: 10),
          Text(
            'Our aim is simple: to give people practical ways to earn and do '
            'business online, without the barriers that usually get in the '
            'way. We want a student, a shop owner and a freelancer to all '
            'find real value in the same place — whether that means '
            'picking up a small task, listing a product, or paying a bill in '
            'seconds.',
            style: _bodyStyle(),
          ),
          const SizedBox(height: 26),

          // What AdsyClub offers
          _sectionHeader('What AdsyClub offers'),
          const SizedBox(height: 14),
          _feature(
            Icons.hub_outlined,
            'Business Network',
            'A social feed to share updates, follow people and build professional connections.',
          ),
          _featureDivider(),
          _feature(
            Icons.work_outline_rounded,
            'Micro Gigs',
            'Complete small paid tasks or post your own to get quick work done.',
          ),
          _featureDivider(),
          _feature(
            Icons.storefront_outlined,
            'eShop',
            'Browse and sell products in a simple, mobile-first online store.',
          ),
          _featureDivider(),
          _feature(
            Icons.sell_outlined,
            'Classified',
            'Post and discover buy-and-sell ads across categories near you.',
          ),
          _featureDivider(),
          _feature(
            Icons.smartphone_outlined,
            'Mobile Recharge',
            'Top up any operator in a few taps, straight from your wallet.',
          ),
          _featureDivider(),
          _feature(
            Icons.account_balance_wallet_outlined,
            'AdsyPay Wallet',
            'Add funds, get paid and make secure in-app transactions.',
          ),
          _featureDivider(),
          _feature(
            Icons.article_outlined,
            'News',
            'Stay updated with news and stories relevant to the community.',
          ),
          _featureDivider(),
          _feature(
            Icons.play_circle_outline_rounded,
            'Shorts',
            'Watch and share short videos inside the app.',
          ),
          const SizedBox(height: 26),

          // Our vision
          _sectionHeader('Our vision'),
          const SizedBox(height: 12),
          _bullet('Help Bangladeshis take control of their economic future.'),
          _bullet('Close the gap between businesses and the customers they serve.'),
          _bullet('Grow a trusted community built on fair and honest dealing.'),
          _bullet('Play a meaningful part in the country’s digital growth.'),
          const SizedBox(height: 26),

          // What we value
          _sectionHeader('What we value'),
          const SizedBox(height: 12),
          _bullet('Trust — verification and moderation to keep the platform genuine.'),
          _bullet('Security — payments handled through trusted, encrypted channels.'),
          _bullet('Simplicity — tools that feel easy, even on a modest phone.'),
          _bullet('Fairness — opportunity that is open to everyone, not just a few.'),
          const SizedBox(height: 26),

          // Why AdsyClub
          _sectionHeader('Why AdsyClub'),
          const SizedBox(height: 10),
          Text(
            'Most apps do one thing. AdsyClub connects several everyday needs '
            'in one account, so you can move from earning to spending to '
            'connecting without switching between services. We keep improving '
            'the experience and expanding what is possible, and we are '
            'committed to growing responsibly alongside the people who use it.',
            style: _bodyStyle(),
          ),
          const SizedBox(height: 26),

          // Contact
          _sectionHeader('Get in touch'),
          const SizedBox(height: 12),
          _contactRow(Icons.mail_outline_rounded, 'support@adsyclub.com'),
          const SizedBox(height: 12),
          _contactRow(Icons.language_rounded, 'www.adsyclub.com'),
          const SizedBox(height: 28),

          // Footer
          Container(height: 1, color: _hair),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'AdsyClub · Version 1.0.0',
              style: AppFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  TextStyle _bodyStyle() => AppFonts.roboto(
        fontSize: 14.5,
        height: 1.65,
        color: _muted,
      );

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      ),
    );
  }

  Widget _feature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, size: 19, color: _accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppFonts.roboto(
                    fontSize: 13.5,
                    height: 1.5,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 49),
      child: Container(height: 1, color: _hair),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppFonts.roboto(
                fontSize: 14.5,
                height: 1.55,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 19, color: _accent),
        const SizedBox(width: 11),
        Text(
          text,
          style: AppFonts.roboto(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
        ),
      ],
    );
  }
}
