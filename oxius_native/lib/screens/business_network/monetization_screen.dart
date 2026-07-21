import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/business_network_service.dart';
import '../../widgets/common/adsy_loading.dart';
import 'monetization_sections.dart';
import '../../widgets/business_network/monetization_card.dart'
    show MonetizationApplySheet;

/// Full Content Monetization page.
///
/// Before approval: a status hero, the four requirement tiles with live
/// progress, how-it-works steps and the Apply action (opens the terms sheet).
/// After approval: the creator statistics view (current reach snapshot —
/// detailed earnings analytics land later).
class MonetizationScreen extends StatefulWidget {
  const MonetizationScreen({super.key});

  @override
  State<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends State<MonetizationScreen> {
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _earnings;
  bool _loading = true;
  int _tipPage = 0;
  Timer? _tipTimer;
  final PageController _tipController =
      PageController(viewportFraction: 0.92);

  // Business Network master blue — the page lives inside BN, so it follows
  // the BN palette (header/nav blue) instead of the commerce green.
  static const _accent = Color(0xFF2563EB);
  static const _accentSoft = Color(0xFF3B82F6);
  static const _ink = Color(0xFF111827);

  // Useful growth tips shown as a swipeable slider under the hero.
  static const _tips = [
    (
      Icons.groups_rounded,
      'ফলোয়ার বাড়ান',
      'নিয়মিত পোস্ট করুন এবং অন্যদের সাথে যুক্ত থাকুন — আসল ফলোয়ারই মনিটাইজেশনের ভিত্তি।'
    ),
    (
      Icons.video_library_rounded,
      'ভিডিও ও ছবি দুটোই দিন',
      'ভিডিও রিচ বাড়ায়, আর ছবি প্রোফাইলকে সমৃদ্ধ রাখে — তাই দুই ধরনের পোস্টই করুন।'
    ),
    (
      Icons.visibility_rounded,
      'ভিউ বাড়ান',
      'পোস্ট শেয়ার করুন, প্রাসঙ্গিক ট্যাগ ব্যবহার করুন এবং ব্যস্ত সময়ে পোস্ট করুন — বেশি মানুষ দেখবে।'
    ),
    (
      Icons.verified_rounded,
      'মানসম্মত কনটেন্টই জেতে',
      'নিজের তৈরি, কাজে লাগার মতো কনটেন্ট বেশি রেকমেন্ড হয় — মনিটাইজেশনও দীর্ঘমেয়াদে সুস্থ থাকে।'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-advance the tips slider; manual swipes just re-sync _tipPage.
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_tipController.hasClients) return;
      final next = (_tipPage + 1) % _tips.length;
      _tipController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final status = await BusinessNetworkService.getMonetizationStatus();
    Map<String, dynamic>? earnings;
    if (status != null &&
        status['applied'] == true &&
        (status['application_status'] ?? '') == 'approved') {
      earnings = await BusinessNetworkService.getMonetizationEarnings();
    }
    if (!mounted) return;
    setState(() {
      _status = status;
      _earnings = earnings;
      _loading = false;
    });
  }

  int _asInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'কনটেন্ট মনিটাইজেশন',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.3,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      body: _loading
          ? const Center(child: AdsyLoadingIndicator())
          : RefreshIndicator(
              color: _accent,
              onRefresh: _load,
              child: _status == null ? _buildError() : _buildBody(),
            ),
    );
  }

  Widget _buildError() {
    // Scrollable so pull-to-refresh works from the error state too.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text(
            'মনিটাইজেশন স্ট্যাটাস লোড করা যায়নি',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            child: const Text(
              'আবার চেষ্টা করুন',
              style: TextStyle(color: _accent),
            ),
          ),
        ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    final applied = _status!['applied'] == true;
    final appStatus = (_status!['application_status'] ?? '').toString();
    final approved = applied && appStatus == 'approved';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _buildStatusHero(),
        if (approved) ...[
          _sectionDivider(),
          if (_earnings != null) ...[
            _buildEarningsSummary(),
            _sectionDivider(),
            _sectionHeader('বিস্তারিত',
                'অ্যানালিটিক্স, কনটেন্ট আয় ও পেআউট — আলাদা পেজে গুছিয়ে।'),
            _buildDetailMenu(),
          ] else ...[
            _sectionHeader('আপনার রিচ',
                'আপনার প্রোফাইল এই মুহূর্তে যেখানে দাঁড়িয়ে আছে।'),
            _buildStatsGrid(),
          ],
        ] else ...[
          _buildTipsSlider(),
          _sectionDivider(),
          _sectionHeader('শর্তসমূহ',
              'মনিটাইজেশনের আবেদন করতে নিচের ৪টি শর্ত পূরণ করতে হবে।'),
          _buildRequirementTiles(),
          _sectionDivider(),
          _sectionHeader('কেন মনিটাইজেশন করবেন',
              'মনিটাইজড ক্রিয়েটর হিসেবে যা যা পাবেন —'),
          _buildBenefits(),
          _sectionDivider(),
          _sectionHeader('যেভাবে কাজ করে',
              'মাত্র ৩টি ধাপে আয় শুরু করতে পারবেন।'),
          _buildHowItWorks(),
          if (!applied) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildApplyButton(),
            ),
          ],
        ],
      ],
    );
  }

  // ── Section chrome (plain: soft band divider + Bangla header) ────────────

  Widget _sectionDivider() {
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFFF8FAFC),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status hero ──────────────────────────────────────────────────────────

  int _metCount() {
    final pairs = [
      (_asInt(_status!['followers']), _asInt(_status!['required_followers'])),
      (_asInt(_status!['views']), _asInt(_status!['required_views'])),
      (
        _asInt(_status!['video_posts']),
        _asInt(_status!['required_video_posts'])
      ),
      (
        _asInt(_status!['image_posts']),
        _asInt(_status!['required_image_posts'])
      ),
    ];
    return pairs.where((p) => p.$1 >= p.$2 && p.$2 > 0).length +
        pairs.where((p) => p.$2 <= 0).length;
  }

  static const _bnDigits = ['০', '১', '২', '৩', '৪'];

  Widget _buildStatusHero() {
    final applied = _status!['applied'] == true;
    final eligible = _status!['eligible'] == true;
    final appStatus = (_status!['application_status'] ?? '').toString();

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;

    if (applied) {
      switch (appStatus) {
        case 'approved':
          icon = Icons.verified_rounded;
          color = const Color(0xFF059669);
          title = 'মনিটাইজেশন চালু আছে';
          subtitle =
              'আপনার কনটেন্ট এখন মনিটাইজড। নিয়মিত মানসম্মত পোস্ট করতে থাকুন — আয় বাড়তে থাকবে।';
          break;
        case 'rejected':
          icon = Icons.info_outline_rounded;
          color = const Color(0xFFDC2626);
          title = 'আবেদন অনুমোদিত হয়নি';
          subtitle =
              'এবার আপনার আবেদন অনুমোদন করা যায়নি। বিস্তারিত জানতে সাপোর্টে যোগাযোগ করুন।';
          break;
        default:
          icon = Icons.hourglass_top_rounded;
          color = const Color(0xFFD97706);
          title = 'আবেদন রিভিউ চলছে';
          subtitle =
              'আমাদের টিম আপনার আবেদন যাচাই করছে। সিদ্ধান্ত হলে নোটিফিকেশনের মাধ্যমে জানিয়ে দেওয়া হবে।';
      }
    } else if (eligible) {
      icon = Icons.monetization_on_rounded;
      color = _accent;
      title = 'আপনি আবেদনের যোগ্য!';
      subtitle =
          'অভিনন্দন — সবগুলো শর্ত পূরণ হয়েছে। নিচের বাটনে ট্যাপ করে আবেদন জমা দিন।';
    } else {
      icon = Icons.monetization_on_rounded;
      color = _accent;
      title = 'মনিটাইজেশনের পথে এগিয়ে চলুন';
      subtitle =
          'নিচের শর্তগুলো পূরণ করলেই আবেদন করতে পারবেন এবং আপনার কনটেন্ট থেকে আয় শুরু হবে।';
    }

    final showProgress = !applied;
    final met = showProgress ? _metCount() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'সার্বিক অগ্রগতি',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  '৪টির মধ্যে ${_bnDigits[met.clamp(0, 4)]}টি শর্ত পূরণ হয়েছে',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: met / 4,
                minHeight: 7,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(_accentSoft),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  // ── Tips slider ──────────────────────────────────────────────────────────

  Widget _buildTipsSlider() {
    return Column(
      children: [
        SizedBox(
          height: 116,
          child: PageView.builder(
            controller: _tipController,
            itemCount: _tips.length,
            onPageChanged: (i) => setState(() => _tipPage = i),
            itemBuilder: (context, i) {
              final tip = _tips[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Icon(tip.$1, size: 21, color: _accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tip.$2,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tip.$3,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _tips.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _tipPage == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _tipPage == i ? _accent : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Why monetize (benefits) ──────────────────────────────────────────────

  Widget _buildBenefits() {
    const benefits = [
      (
        Icons.payments_outlined,
        'কনটেন্ট থেকে আয়',
        'আপনার পোস্ট ও শর্টসে আসা ভিউ এবং এনগেজমেন্ট অনুযায়ী টাকা পাবেন।'
      ),
      (
        Icons.insights_outlined,
        'ক্রিয়েটর ইনসাইট',
        'কোন কনটেন্ট কেমন পারফর্ম করছে তা দেখে নিজের রিচ আরও বাড়াতে পারবেন।'
      ),
      (
        Icons.workspace_premium_outlined,
        'ক্রিয়েটর স্বীকৃতি',
        'মনিটাইজড ক্রিয়েটরদের কনটেন্ট ফিড ও ডিসকভারিতে অগ্রাধিকার পায়।'
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final b in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(b.$1, size: 19, color: _accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.$3,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Requirements ─────────────────────────────────────────────────────────

  Widget _buildRequirementTiles() {
    final tiles = [
      (
        Icons.group_outlined,
        'ফলোয়ার',
        _asInt(_status!['followers']),
        _asInt(_status!['required_followers']),
      ),
      (
        Icons.visibility_outlined,
        'কনটেন্ট ভিউ',
        _asInt(_status!['views']),
        _asInt(_status!['required_views']),
      ),
      (
        Icons.videocam_outlined,
        'ভিডিও পোস্ট',
        _asInt(_status!['video_posts']),
        _asInt(_status!['required_video_posts']),
      ),
      (
        Icons.photo_outlined,
        'ছবি পোস্ট',
        _asInt(_status!['image_posts']),
        _asInt(_status!['required_image_posts']),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i++)
          _requirementTile(
            tiles[i].$1,
            tiles[i].$2,
            tiles[i].$3,
            tiles[i].$4,
            isLast: i == tiles.length - 1,
          ),
      ],
    );
  }

  Widget _requirementTile(
    IconData icon,
    String label,
    int current,
    int required, {
    required bool isLast,
  }) {
    final safeRequired = required <= 0 ? 1 : required;
    final ratio = (current / safeRequired).clamp(0.0, 1.0);
    final met = current >= required;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF475569)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${_formatCount(current)} / ${_formatCount(required)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: met ? const Color(0xFF059669) : _accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      met ? const Color(0xFF059669) : _accentSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color:
                met ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  // ── How it works ─────────────────────────────────────────────────────────

  Widget _buildHowItWorks() {
    const steps = [
      (
        '১',
        'শর্তগুলো পূরণ করুন',
        'ফলোয়ার ও ভিউ বাড়ান এবং পর্যাপ্ত ভিডিও ও ছবি পোস্ট করুন।'
      ),
      (
        '২',
        'এক ট্যাপে আবেদন করুন',
        'শর্তাবলি ও কমিউনিটি গাইডলাইন মেনে আপনার আবেদন জমা দিন।'
      ),
      (
        '৩',
        'রিভিউয়ের পর আয় শুরু',
        'আমাদের টিম আপনার প্রোফাইল যাচাই করবে। অনুমোদন পেলেই আপনার কনটেন্ট থেকে আয় শুরু হবে।'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.$1,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$2,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.$3,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Apply ────────────────────────────────────────────────────────────────

  Widget _buildApplyButton() {
    final eligible = _status!['eligible'] == true;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: eligible ? _openApplySheet : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: const Color(0xFFF1F5F9),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          eligible
              ? 'মনিটাইজেশনের জন্য আবেদন করুন'
              : 'শর্ত পূরণ হলেই আবেদন খুলে যাবে',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _openApplySheet() async {
    final submitted = await MonetizationApplySheet.show(context);
    if (submitted == true) {
      setState(() => _loading = true);
      _load();
    }
  }

  // ── Approved: reach snapshot + stats placeholder ─────────────────────────

  Widget _buildStatsGrid() {
    final stats = [
      (
        Icons.group_outlined,
        'ফলোয়ার',
        _formatCount(_asInt(_status!['followers']))
      ),
      (
        Icons.visibility_outlined,
        'কনটেন্ট ভিউ',
        _formatCount(_asInt(_status!['views']))
      ),
      (
        Icons.videocam_outlined,
        'ভিডিও পোস্ট',
        _formatCount(_asInt(_status!['video_posts']))
      ),
      (
        Icons.photo_outlined,
        'ছবি পোস্ট',
        _formatCount(_asInt(_status!['image_posts']))
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: [
          for (final s in stats)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(s.$1, size: 16, color: const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.$3,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Approved: earnings ───────────────────────────────────────────────────

  String _taka(dynamic v) {
    final s = (v ?? '0').toString();
    final d = double.tryParse(s) ?? 0;
    if (d == d.roundToDouble()) return '৳${d.round()}';
    return '৳${d.toStringAsFixed(2)}';
  }

  Widget _buildEarningsSummary() {
    final e = _earnings!;
    final flagged = e['fraud_flagged'] == true;
    final forfeited = (e['current_status'] ?? '') == 'forfeited';
    final holdback = _asInt(e['holdback_days']);
    final payoutDate = (e['expected_payout_date'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'এই মাসের আনুমানিক আয়',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _taka(e['estimated_amount']),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _accent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'চূড়ান্ত হিসাব মাস শেষে হয়। রিভিউয়ের ($holdback দিন) পর টাকা আপনার AdsyPay ব্যালেন্সে যোগ হবে। সর্বনিম্ন পেআউট ${_taka(e['min_payout'])} — এর কম হলে পরের মাসে যোগ হয়ে থাকবে।',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          if (payoutDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_available_outlined,
                    size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text(
                  'সম্ভাব্য পেমেন্ট তারিখ: $payoutDate',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                forfeited
                    ? Icons.cancel_rounded
                    : flagged
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                size: 17,
                color: forfeited
                    ? const Color(0xFFDC2626)
                    : flagged
                        ? const Color(0xFFD97706)
                        : const Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  forfeited
                      ? 'অ্যাকাউন্ট স্ট্যাটাস: এই মাসের আয় নীতিমালা লঙ্ঘনের কারণে বাতিল হয়েছে। বারবার হলে মনিটাইজেশন স্থায়ীভাবে বন্ধ হতে পারে।'
                      : flagged
                          ? 'অ্যাকাউন্ট স্ট্যাটাস: সতর্কতা — অস্বাভাবিক ভিউ অ্যাক্টিভিটি রিভিউ চলছে, এই মাসের আয় সাময়িকভাবে আটকে আছে।'
                          : 'অ্যাকাউন্ট স্ট্যাটাস: সুস্থ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: forfeited
                        ? const Color(0xFF991B1B)
                        : flagged
                            ? const Color(0xFF92400E)
                            : const Color(0xFF059669),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Approved overview: clean menu into the detail pages so the main screen
  // stays a short summary instead of one long scroll.
  Widget _buildDetailMenu() {
    final rows = [
      (
        Icons.insights_outlined,
        'অ্যানালিটিক্স',
        'পয়েন্ট, দৈনিক ভিউ ও রিচ',
        () => MonetizationAnalyticsScreen(
              earnings: _earnings!,
              status: _status!,
            ),
      ),
      (
        Icons.article_outlined,
        'কনটেন্ট অনুযায়ী আয়',
        'কোন কনটেন্ট থেকে কত পয়েন্ট ও আয়',
        () => MonetizationContentScreen(earnings: _earnings!),
      ),
      (
        Icons.receipt_long_outlined,
        'পেআউট হিস্ট্রি',
        'পেমেন্ট তথ্য ও আগের মাসগুলোর হিসাব',
        () => MonetizationPayoutScreen(earnings: _earnings!),
      ),
      (
        Icons.help_outline_rounded,
        'আয় কীভাবে হিসাব হয়',
        'পয়েন্ট রেট ও নীতিমালা',
        () => MonetizationInfoScreen(earnings: _earnings!),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => rows[i].$4()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  border: i == rows.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                ),
                child: Row(
                  children: [
                    Icon(rows[i].$1, size: 21, color: const Color(0xFF475569)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i].$2,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            rows[i].$3,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
