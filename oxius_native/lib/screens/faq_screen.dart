import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../widgets/ios_web_redirect_screen.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  // Design tokens shared across the app's plain pages.
  static const Color _ink = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _hair = Color(0xFFF1F5F9);
  static const Color _accent = Color(0xFF10B981);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<_FaqEntry> get _allFaqs => [
        const _FaqEntry(
          'What is AdsyClub?',
          'AdsyClub is an all-in-one platform where you can earn money, '
              'connect with the community and access the services you need. '
              'It combines a business network feed, an online shop, '
              'classifieds, micro gigs, mobile recharge and the AdsyPay '
              'wallet in a single app.',
        ),
        const _FaqEntry(
          'How do I create an account?',
          'Open the login screen and tap "Register". Enter your name, email, '
              'phone number and a password, then verify your email address. '
              'Once verified, you can sign in and start using every feature.',
        ),
        const _FaqEntry(
          'How do I post a sale ad?',
          'Go to the Classified or Buy & Sell section and tap "Post Sale". '
              'Add a clear title, description, price and location, then upload '
              'a few photos of the item. You need to be logged in to publish '
              'an ad, and good photos help it sell faster.',
        ),
        const _FaqEntry(
          'What is AdsyPay?',
          'AdsyPay is the built-in digital wallet. Use it to add funds, '
              'withdraw money and pay for services such as mobile recharge or '
              'Pro upgrades securely inside the app, without re-entering your '
              'payment details each time.',
        ),
        const _FaqEntry(
          'How do I recharge mobile phones?',
          'Open the Mobile Recharge section, enter the phone number, choose '
              'the operator and the amount, then confirm the payment using '
              'your AdsyPay wallet or another supported method. The recharge '
              'is usually applied within moments.',
        ),
        const _FaqEntry(
          'What are Micro-Gigs?',
          'Micro-Gigs are small paid tasks you can complete to earn, or post '
              'so that others complete them for you. Common examples include '
              'graphic design, writing, data entry and simple online tasks — a '
              'flexible way to earn in your spare time.',
        ),
        if (!isIOSPlatform)
          const _FaqEntry(
            'How do I upgrade to Pro?',
            'Open "Upgrade to Pro" from the menu, choose the package that '
                'fits your needs and complete the payment. Pro members unlock '
                'additional features and benefits across the platform.',
          ),
        const _FaqEntry(
          'Is my payment information secure?',
          'Yes. We use industry-standard encryption and trusted, secure '
              'payment gateways to protect your financial information, and we '
              'never store your complete payment details on our servers.',
        ),
        const _FaqEntry(
          'How do I contact support?',
          'Reach our team through the Contact Us page or email '
              'support@adsyclub.com directly. We typically reply within 24 '
              'hours and are happy to help with any question about your '
              'account or the app.',
        ),
        const _FaqEntry(
          'Can I delete my account?',
          'Yes. You can request account deletion by contacting our support '
              'team. Please note this is permanent — once your account is '
              'deleted it cannot be recovered, so make sure to withdraw any '
              'remaining wallet balance first.',
        ),
      ];

  List<_FaqEntry> get _filtered {
    if (_query.trim().isEmpty) return _allFaqs;
    final q = _query.trim().toLowerCase();
    return _allFaqs
        .where((f) =>
            f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filtered;
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
          'FAQ',
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
          Text(
            'Common questions',
            style: AppFonts.roboto(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quick answers to the things people ask most about AdsyClub.',
            style: AppFonts.roboto(
              fontSize: 14.5,
              height: 1.55,
              color: _muted,
            ),
          ),
          const SizedBox(height: 16),

          // Simple search / filter
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: AppFonts.roboto(fontSize: 14.5, color: _ink),
            decoration: InputDecoration(
              hintText: 'Search questions',
              hintStyle: AppFonts.roboto(fontSize: 14.5, color: const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _muted),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (faqs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No questions match “${_query.trim()}”.',
                  style: AppFonts.roboto(fontSize: 14.5, color: _muted),
                ),
              ),
            )
          else
            // Flat list of expandable rows separated by hairline dividers.
            Column(
              children: [
                const Divider(height: 1, thickness: 1, color: _hair),
                for (int i = 0; i < faqs.length; i++) ...[
                  _FaqTile(
                    entry: faqs[i],
                    ink: _ink,
                    muted: _muted,
                    accent: _accent,
                  ),
                  const Divider(height: 1, thickness: 1, color: _hair),
                ],
              ],
            ),

          const SizedBox(height: 28),

          // Still have questions? — plain block, no gradient hero.
          _sectionHeader('Still have questions?'),
          const SizedBox(height: 8),
          Text(
            'Our support team is happy to help with anything not covered here.',
            style: AppFonts.roboto(
              fontSize: 14.5,
              height: 1.55,
              color: _muted,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/contact-us'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text(
                'Contact support',
                style: AppFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
}

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry(this.question, this.answer);
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.entry,
    required this.ink,
    required this.muted,
    required this.accent,
  });

  final _FaqEntry entry;
  final Color ink;
  final Color muted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
        iconColor: accent,
        collapsedIconColor: muted,
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          entry.question,
          style: AppFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: ink,
          ),
        ),
        children: [
          Text(
            entry.answer,
            style: AppFonts.roboto(
              fontSize: 14,
              height: 1.6,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
