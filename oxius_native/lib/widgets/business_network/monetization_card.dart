import 'package:flutter/material.dart';

import '../../services/business_network_service.dart';
import '../common/adsy_toast.dart';

/// Content monetization entry point on the profile options screen.
///
/// Three states, driven by `/bn/monetization/status/`:
///  1. Progress — followers/views bars toward 1,000 followers + 20,000 views
///  2. Eligible — congratulation row + Apply button that opens the terms sheet
///  3. Applied — under review / approved / rejected status chip
class MonetizationCard extends StatefulWidget {
  const MonetizationCard({super.key});

  @override
  State<MonetizationCard> createState() => _MonetizationCardState();
}

class _MonetizationCardState extends State<MonetizationCard> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  // Progress state is collapsed by default (just the header + arrow) so the
  // card stays small; tapping the header expands the requirement checklist.
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    if (_loading || _status == null) return const SizedBox.shrink();

    final eligible = _status!['eligible'] == true;
    final applied = _status!['applied'] == true;
    final appStatus = (_status!['application_status'] ?? '').toString();

    // Progress state manages its own tap (expand/collapse). The compact
    // eligible/applied states tap through to the full monetization page.
    if (!applied && !eligible) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: const Color(0xFFF8FAFC),
        child: _buildProgressState(),
      );
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).pushNamed('/monetization');
        if (mounted) _load();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: const Color(0xFFF8FAFC),
        child: applied ? _buildAppliedState(appStatus) : _buildEligibleState(),
      ),
    );
  }

  // ── State 1: collapsible "what to complete" checklist ────────────────────

  Widget _buildProgressState() {
    final reqFollowers = _asInt(_status!['required_followers']);
    final reqViews = _asInt(_status!['required_views']);
    final reqVideos = _asInt(_status!['required_video_posts']);
    final reqPhotos = _asInt(_status!['required_image_posts']);
    final reqs = [
      (
        Icons.group_outlined,
        'Gain ${_fullNum(reqFollowers)} followers',
        _asInt(_status!['followers']),
        reqFollowers,
      ),
      (
        Icons.visibility_outlined,
        'Gain ${_fullNum(reqViews)} content views',
        _asInt(_status!['views']),
        reqViews,
      ),
      (
        Icons.videocam_outlined,
        'Post ${_fullNum(reqVideos)} videos',
        _asInt(_status!['video_posts']),
        reqVideos,
      ),
      (
        Icons.photo_outlined,
        'Post ${_fullNum(reqPhotos)} photos',
        _asInt(_status!['image_posts']),
        reqPhotos,
      ),
    ];
    final metCount = reqs.where((r) => r.$3 >= r.$4).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — tap anywhere on it to expand/collapse the checklist.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Unlock Content Monetization',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '$metCount/${reqs.length}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        // Collapsible checklist body.
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Complete these to apply and start earning from your content:',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < reqs.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _progressRow(reqs[i].$1, reqs[i].$2, reqs[i].$3, reqs[i].$4),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await Navigator.of(context).pushNamed('/monetization');
                  if (mounted) _load();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }

  // Each requirement as a plain instruction — "Get 1,000 followers" on the
  // left, the current/goal count on the right — which is easier to grasp
  // than a progress bar.
  Widget _progressRow(IconData icon, String goal, int current, int required) {
    final met = current >= required;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon,
              size: 15,
              color: met ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              goal,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Text(
            '${_formatCount(current)} / ${_formatCount(required)}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: met ? const Color(0xFF059669) : const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: met ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }

  // "1000" -> "1,000" for the instruction text.
  String _fullNum(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── State 2: eligible, show Apply ────────────────────────────────────────

  Widget _buildEligibleState() {
    return Row(
      children: [
        const Icon(Icons.workspace_premium_rounded,
            size: 22, color: Color(0xFF2563EB)),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You're eligible for monetization!",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Apply now and start earning from your content.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _openApplySheet,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Apply',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Future<void> _openApplySheet() async {
    final submitted = await MonetizationApplySheet.show(context);
    if (submitted == true) {
      _load();
    }
  }

  // ── State 3: applied ─────────────────────────────────────────────────────

  Widget _buildAppliedState(String appStatus) {
    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;
    switch (appStatus) {
      case 'approved':
        icon = Icons.verified_rounded;
        color = const Color(0xFF059669);
        title = 'Monetization approved';
        subtitle = 'Congratulations — your content is now monetized.';
        break;
      case 'rejected':
        icon = Icons.info_outline_rounded;
        color = const Color(0xFFDC2626);
        title = 'Application not approved';
        subtitle = 'Contact support for details about your application.';
        break;
      default:
        icon = Icons.hourglass_top_rounded;
        color = const Color(0xFFD97706);
        title = 'Application under review';
        subtitle = "We're reviewing your application. You'll be notified soon.";
    }
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style:
                    const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet: what monetization is, the terms & community guidelines, an
/// accept checkbox, and the Apply action.
class MonetizationApplySheet extends StatefulWidget {
  const MonetizationApplySheet({super.key});

  /// Returns true when an application was submitted.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MonetizationApplySheet(),
    );
  }

  @override
  State<MonetizationApplySheet> createState() => _MonetizationApplySheetState();
}

class _MonetizationApplySheetState extends State<MonetizationApplySheet> {
  bool _accepted = false;
  bool _submitting = false;

  static const _benefits = [
    (
      Icons.paid_outlined,
      'Earn from your content',
      'Approved creators earn from the views and engagement their posts and shorts generate.'
    ),
    (
      Icons.insights_outlined,
      'Creator insights',
      'Track how your content performs and grow your audience with better reach.'
    ),
    (
      Icons.verified_outlined,
      'Creator recognition',
      'Monetized creators get priority placement in feeds and discovery.'
    ),
  ];

  static const _terms = [
    'You must be the original creator of the content you publish.',
    'Earnings depend on genuine views and engagement — artificial or purchased engagement leads to disqualification.',
    'AdsyClub may review, adjust, or withhold earnings for content that violates these terms.',
    'Payouts follow the standard AdsyClub wallet withdrawal process and its verification requirements.',
    'AdsyClub may update the monetization program, rates, and requirements at any time.',
  ];

  static const _guidelines = [
    'No copied or plagiarized content — share your own work.',
    'No misleading, spam, or clickbait posts.',
    'No hate speech, harassment, or abusive language.',
    'No adult, violent, or illegal content.',
    'Respect others — content violating community standards is removed and may end monetization.',
  ];

  Future<void> _submit() async {
    if (!_accepted || _submitting) return;
    setState(() => _submitting = true);
    final error = await BusinessNetworkService.applyForMonetization();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      AdsyToast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 24, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Apply for Content Monetization',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in _benefits) _benefitTile(b.$1, b.$2, b.$3),
                  const SizedBox(height: 6),
                  _sectionHeading('Terms & Conditions'),
                  _bulletList(_terms),
                  const SizedBox(height: 12),
                  _sectionHeading('Community Guidelines'),
                  _bulletList(_guidelines),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              10 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _accepted,
                          activeColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) =>
                              setState(() => _accepted = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'I have read and accept the Terms & Conditions and Community Guidelines.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _accepted && !_submitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Application',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _benefitTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }

  Widget _sectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

  Widget _bulletList(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle,
                        size: 5, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.45,
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
}
