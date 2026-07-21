import 'package:flutter/material.dart';

import '../../services/business_network_service.dart';
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
  bool _loading = true;
  int _tipPage = 0;
  final PageController _tipController =
      PageController(viewportFraction: 0.92);

  // Brand green — monetization is about earning, and it matches the
  // eShop/AdsyConnect concept palette (ink text + green accent).
  static const _accent = Color(0xFF16A34A);

  // Useful growth tips shown as a swipeable slider under the hero.
  static const _tips = [
    (
      Icons.groups_rounded,
      'Grow your audience',
      'Post consistently and engage with others — genuine followers are the foundation of monetization.'
    ),
    (
      Icons.video_library_rounded,
      'Mix video & photos',
      'Share both video and photo posts. Video drives reach; photos keep your profile rich and active.'
    ),
    (
      Icons.visibility_rounded,
      'Earn more views',
      'Share your posts, use relevant tags and post at busy hours to boost how many people see your content.'
    ),
    (
      Icons.verified_rounded,
      'Quality wins',
      'Original, helpful content gets recommended more — and keeps your monetization healthy long-term.'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final status = await BusinessNetworkService.getMonetizationStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Content Monetization',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            )
          : _status == null
              ? _buildError()
              : RefreshIndicator(
                  color: _accent,
                  onRefresh: _load,
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          const Text(
            'Could not load your monetization status',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final applied = _status!['applied'] == true;
    final appStatus = (_status!['application_status'] ?? '').toString();
    final approved = applied && appStatus == 'approved';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 28),
      children: [
        _buildStatusHero(),
        const SizedBox(height: 16),
        if (approved) ...[
          _sectionLabel('Your reach'),
          _buildStatsGrid(),
          const SizedBox(height: 16),
          _buildComingSoon(),
        ] else ...[
          const SizedBox(height: 4),
          _buildTipsSlider(),
          const SizedBox(height: 20),
          _sectionLabel('Requirements'),
          _buildRequirementTiles(),
          const SizedBox(height: 16),
          _sectionLabel('Why monetize'),
          _buildBenefits(),
          const SizedBox(height: 16),
          _sectionLabel('How it works'),
          _buildHowItWorks(),
          if (!applied) ...[
            const SizedBox(height: 20),
            _buildApplyButton(),
          ],
        ],
      ],
    );
  }

  // ── Status hero ──────────────────────────────────────────────────────────

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
          title = 'Monetization active';
          subtitle =
              'Your content is monetized. Keep posting quality content to grow your earnings.';
          break;
        case 'rejected':
          icon = Icons.info_outline_rounded;
          color = const Color(0xFFDC2626);
          title = 'Application not approved';
          subtitle =
              'Your application was reviewed but not approved this time. Contact support for details.';
          break;
        default:
          icon = Icons.hourglass_top_rounded;
          color = const Color(0xFFD97706);
          title = 'Application under review';
          subtitle =
              "Our team is reviewing your application. You'll be notified once a decision is made.";
      }
    } else if (eligible) {
      icon = Icons.monetization_on_rounded;
      color = _accent;
      title = "You're eligible to apply";
      subtitle =
          'You have met all the requirements. Submit your application below to start earning.';
    } else {
      icon = Icons.monetization_on_rounded;
      color = _accent;
      title = 'Grow toward monetization';
      subtitle =
          'Meet the requirements below to unlock the application and start earning from your content.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tips slider ──────────────────────────────────────────────────────────

  Widget _buildTipsSlider() {
    return Column(
      children: [
        SizedBox(
          height: 118,
          child: PageView.builder(
            controller: _tipController,
            itemCount: _tips.length,
            onPageChanged: (i) => setState(() => _tipPage = i),
            itemBuilder: (context, i) {
              final tip = _tips[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
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
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tip.$3,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                height: 1.4,
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
        'Earn from your content',
        'Get paid for the views and engagement your posts and shorts generate.'
      ),
      (
        Icons.insights_outlined,
        'Creator insights',
        'Track how your content performs and grow your reach over time.'
      ),
      (
        Icons.workspace_premium_outlined,
        'Creator recognition',
        'Monetized creators get priority placement in feeds and discovery.'
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          for (final b in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.08),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.$3,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildRequirementTiles() {
    final tiles = [
      (
        Icons.group_outlined,
        'Followers',
        _asInt(_status!['followers']),
        _asInt(_status!['required_followers']),
      ),
      (
        Icons.visibility_outlined,
        'Content views',
        _asInt(_status!['views']),
        _asInt(_status!['required_views']),
      ),
      (
        Icons.videocam_outlined,
        'Video posts',
        _asInt(_status!['video_posts']),
        _asInt(_status!['required_video_posts']),
      ),
      (
        Icons.photo_outlined,
        'Photo posts',
        _asInt(_status!['image_posts']),
        _asInt(_status!['required_image_posts']),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
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
      ),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
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
                        fontSize: 13,
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
                      met ? const Color(0xFF059669) : _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
        '1',
        'Meet the requirements',
        'Grow your followers, views and post enough video & photo content.'
      ),
      (
        '2',
        'Apply with one tap',
        'Accept the Terms & Community Guidelines and submit your application.'
      ),
      (
        '3',
        'Get reviewed & earn',
        'Our team reviews your profile. Once approved, your content starts earning.'
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.$3,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
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
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          eligible ? 'Apply for Monetization' : 'Keep growing to unlock',
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
        'Followers',
        _formatCount(_asInt(_status!['followers']))
      ),
      (
        Icons.visibility_outlined,
        'Content views',
        _formatCount(_asInt(_status!['views']))
      ),
      (
        Icons.videocam_outlined,
        'Video posts',
        _formatCount(_asInt(_status!['video_posts']))
      ),
      (
        Icons.photo_outlined,
        'Photo posts',
        _formatCount(_asInt(_status!['image_posts']))
      ),
    ];

    return GridView.count(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildComingSoon() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.query_stats_rounded,
              size: 22, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Earnings analytics',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Detailed earnings and performance statistics are coming soon.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
