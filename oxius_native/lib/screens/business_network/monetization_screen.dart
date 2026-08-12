import 'package:flutter/material.dart';

import '../../services/business_network_service.dart';
import '../../widgets/business_network/monetization_card.dart'
    show MonetizationApplySheet;
import '../../widgets/common/adsy_loading.dart';
import 'monetization_sections.dart';

/// Content Monetization.
///
/// Before approval: where the creator stands against the bar, what they get,
/// and the apply action. After approval: the money, what earned it, and when
/// it lands.
///
/// What this page deliberately does NOT show — and must not start showing — is
/// the machinery that turns activity into money: the monthly pool, the
/// per-action point rates, "your points ÷ everyone's points". Those are
/// business levers, and publishing them both hands the platform's payout
/// budget to anyone who scrolls and reduces every month to an argument about
/// the formula. A creator sees what their content did and what it earned; the
/// amount moves with the response their work gets, which is the honest version
/// anyway.
class MonetizationScreen extends StatefulWidget {
  const MonetizationScreen({super.key});

  @override
  State<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends State<MonetizationScreen> {
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _earnings;
  bool _loading = true;

  // How many content rows the overview shows before handing off to the full
  // list — enough to be useful, short enough that payout info stays reachable.
  static const _inlineContent = 4;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: monAppBar(context, 'কনটেন্ট মনিটাইজেশন'),
      body: _loading
          ? const Center(child: AdsyLoadingIndicator())
          : RefreshIndicator(
              color: monAccent,
              onRefresh: _load,
              child: _status == null ? _errorState() : _body(),
            ),
    );
  }

  Widget _errorState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 38, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            const Text(
              'মনিটাইজেশন তথ্য লোড করা যায়নি',
              style: TextStyle(fontSize: 13.5, color: monInkSoft),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: const Text('আবার চেষ্টা করুন',
                  style: TextStyle(color: monAccent)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _body() {
    final applied = _status!['applied'] == true;
    final approved =
        applied && (_status!['application_status'] ?? '') == 'approved';

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(bottom: 30),
      children: approved && _earnings != null
          ? _approvedSections()
          : _journeySections(applied),
    );
  }

  // ══ approved ═══════════════════════════════════════════════════════════

  List<Widget> _approvedSections() {
    final e = _earnings!;
    final s = monStatusOf((e['current_status'] ?? '').toString());
    final content = (e['top_content'] as List? ?? []);
    final shown = content.take(_inlineContent).toList();
    final totalContent = monInt(e['content_count']);

    return [
      const SizedBox(height: 16),
      _earningsHero(e, s),
      if (s.note != null) ...[const SizedBox(height: 14), monNotice(s)],
      monBand(),
      monHeader('এই মাসের সাড়া',
          '${monPeriodLabel(e['period'])} মাসে আপনার কনটেন্টে যা যা হয়েছে।'),
      _activityStrip(e),
      monBand(),
      monHeader('দৈনিক ভিউ', 'কোন দিন কত মানুষ আপনার কনটেন্ট দেখেছে।'),
      _dailyViews(e),
      monBand(),
      monHeader(
        'কনটেন্ট অনুযায়ী আয়',
        'কোন কনটেন্ট কত সাড়া পেয়েছে আর তা থেকে কত আয় হয়েছে।',
        totalContent > shown.length ? _seeAllButton() : null,
      ),
      if (shown.isEmpty)
        monEmpty(
          Icons.article_outlined,
          'এই মাসে এখনো কোনো কনটেন্টে সাড়া আসেনি। পোস্ট করতে থাকুন — ভিউ আসা '
              'শুরু হলেই এখানে কনটেন্ট অনুযায়ী হিসাব দেখা যাবে।',
        )
      else ...[
        for (var i = 0; i < shown.length; i++)
          MonContentRow(
            item: shown[i] as Map,
            showDivider: i != shown.length - 1,
          ),
        if (totalContent > shown.length)
          _moreContentRow(totalContent - shown.length),
      ],
      monBand(),
      monHeader('পেমেন্ট'),
      _paymentSummary(e),
      monBand(),
      monHeader('আয় কীভাবে বাড়বে'),
      _earningRules(),
    ];
  }

  Widget _earningsHero(Map<String, dynamic> e, MonStatus s) {
    final amount = e['estimated_amount'];
    final pending = amount == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [monAccentDeep, monAccent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'এই মাসের আয়',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        s.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pending ? '৳০' : monTaka(amount),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pending
                  ? '${monPeriodLabel(e['period'])} — হিসাব চলছে, সাড়া এলেই '
                      'অঙ্ক বাড়তে শুরু করবে'
                  : '${monPeriodLabel(e['period'])} — মাস শেষে চূড়ান্ত হবে',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xB3FFFFFF),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _heroFoot(
                    Icons.event_available_outlined,
                    'সম্ভাব্য পেমেন্ট',
                    monDateLabel(e['expected_payout_date']),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: _heroFoot(
                      Icons.account_balance_wallet_outlined,
                      'মোট আয়',
                      monTaka(e['lifetime_earned']),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFoot(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xB3FFFFFF)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xB3FFFFFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Four actions across one surface, split by hairlines — not four cards.
  Widget _activityStrip(Map<String, dynamic> e) {
    final p = (e['points'] as Map?) ?? {};
    final cells = [
      (Icons.visibility_outlined, 'ভিউ', p['valid_views']),
      (Icons.favorite_outline_rounded, 'লাইক', p['likes']),
      (Icons.mode_comment_outlined, 'কমেন্ট', p['comments']),
      (Icons.person_add_alt_outlined, 'ফলোয়ার', p['followers_gained']),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: monSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0)
                Container(
                    width: 1, height: 34, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Column(
                  children: [
                    Icon(cells[i].$1, size: 17, color: monInkSoft),
                    const SizedBox(height: 6),
                    Text(
                      monCount(cells[i].$3),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: monInk,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cells[i].$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: monInkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dailyViews(Map<String, dynamic> e) {
    final daily = (e['daily_views'] as List? ?? []);
    final byDay = <int, int>{};
    for (final d in daily) {
      final date = (d['date'] ?? '').toString();
      if (date.length < 10) continue;
      final day = int.tryParse(date.substring(8, 10));
      if (day != null) byDay[day] = monInt(d['views']);
    }

    final today = DateTime.now().day;
    final total = byDay.values.fold<int>(0, (a, b) => a + b);
    final avg = today > 0 ? total / today : 0.0;
    var bestDay = 0;
    var bestViews = 0;
    byDay.forEach((day, v) {
      if (v > bestViews) {
        bestViews = v;
        bestDay = day;
      }
    });
    final peak = bestViews > 0 ? bestViews : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var day = 1; day <= today; day++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: (byDay[day] ?? 0) == 0
                            ? 3
                            : (8 + 72 * (byDay[day]! / peak))
                                .clamp(8, 80)
                                .toDouble(),
                        decoration: BoxDecoration(
                          color: (byDay[day] ?? 0) == 0
                              ? const Color(0xFFE2E8F0)
                              : (day == bestDay ? monAccentDeep : monAccent),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${bnDigits('1')} তারিখ',
                  style:
                      const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              Text('আজ ${bnDigits(today.toString())} তারিখ',
                  style:
                      const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniStat('মোট ভিউ', monCount(total))),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'দৈনিক গড়',
                  bnDigits(avg >= 10
                      ? avg.round().toString()
                      : avg.toStringAsFixed(1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'সেরা দিন',
                  bestViews > 0
                      ? '${bnDigits(bestDay.toString())} তারিখ'
                      : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: monSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: monInkSoft,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: monInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seeAllButton() {
    return TextButton(
      onPressed: _openContentList,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'সব দেখুন',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: monAccent,
        ),
      ),
    );
  }

  /// The tail the inline list leaves out, with its money, so the section still
  /// adds up to the headline instead of looking like it lost some.
  Widget _moreContentRow(int remaining) {
    final tailShown = (_earnings!['top_content'] as List? ?? [])
        .skip(_inlineContent)
        .fold<double>(
            0, (sum, c) => sum + monDouble((c as Map)['estimated_amount']));
    final amount = monDouble(_earnings!['other_content_amount']) + tailShown;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openContentList,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: monLine)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'বাকি ${monCount(remaining)}টি কনটেন্ট',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                monTaka(amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: monMoney,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 19, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  void _openContentList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonetizationContentScreen(earnings: _earnings!),
      ),
    );
  }

  Widget _paymentSummary(Map<String, dynamic> e) {
    final holdback = monInt(e['holdback_days']);
    return Column(
      children: [
        _infoLine(
          Icons.account_balance_wallet_outlined,
          'AdsyPay ব্যালেন্সে যোগ হয়',
          'এপ্রুভড আয় আপনার AdsyPay ব্যালেন্সে জমা হয়, সেখান থেকে স্বাভাবিক '
              'নিয়মেই তুলতে পারবেন।',
        ),
        _infoLine(
          Icons.schedule_outlined,
          'মাস শেষে চেক',
          'মাস শেষ হওয়ার পর ${bnDigits(holdback.toString())} দিন চেক চলে, '
              'তারপর টাকা ছাড়া হয়।',
        ),
        _infoLine(
          Icons.account_balance_wallet_outlined,
          'কমপক্ষে ${monTaka(e['min_payout'])}',
          'এর কম হলে টাকা হারায় না — পরের মাসের সাথে যোগ হয়ে জমা থাকে।',
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonetizationPayoutScreen(earnings: _earnings!),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: monLine)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 19, color: Color(0xFF475569)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'পেআউট ও মাসভিত্তিক হিসাব',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF475569)),
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
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: monInkSoft,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Everything here is true of the actual calculation, and none of it is a
  /// number the admin might retune tomorrow.
  Widget _earningRules() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আপনার কনটেন্টে যত বেশি আসল সাড়া আসবে — ভিউ, লাইক, কমেন্ট — আয় তত '
            'বাড়বে। প্রতি মাসের অঙ্ক আলাদা হয়, কারণ তা নির্ভর করে ওই মাসে আপনার '
            'কনটেন্ট কতটা সাড়া পেয়েছে তার উপর। তাই আগে থেকে নির্দিষ্ট কোনো অঙ্ক '
            'বলা সম্ভব নয়।',
            style: TextStyle(
                fontSize: 12.5, color: Color(0xFF334155), height: 1.65),
          ),
          SizedBox(height: 14),
          Text(
            'শুধু আসল ভিউ হিসাব হয়',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'নিজের ভিউ, একদম নতুন খোলা অ্যাকাউন্টের ভিউ আর একই ব্যক্তির বারবার '
            'দেখা হিসাবে ধরা হয় না। ফেক বা এক্সচেঞ্জ ভিউ ধরা পড়লে ওই মাসের আয় '
            'আটকে যায়, আর বারবার হলে মনিটাইজেশন স্থায়ীভাবে বাতিল হতে পারে। '
            'মানসম্মত কনটেন্টই আয়ের সবচেয়ে নিরাপদ পথ।',
            style: TextStyle(
                fontSize: 12.5, color: Color(0xFF334155), height: 1.65),
          ),
        ],
      ),
    );
  }

  // ══ not yet approved ═══════════════════════════════════════════════════

  List<Widget> _journeySections(bool applied) {
    return [
      const SizedBox(height: 18),
      _journeyHero(applied),
      monBand(),
      monHeader('শর্তসমূহ', 'আবেদন করতে নিচের ৪টি শর্তই পূরণ করতে হবে।'),
      _requirements(),
      monBand(),
      monHeader('মনিটাইজড হলে যা পাবেন'),
      _benefits(),
      monBand(),
      monHeader('যেভাবে কাজ করে'),
      _howItWorks(),
      if (!applied) ...[
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _applyButton(),
        ),
      ],
    ];
  }

  int _metCount() {
    final pairs = [
      (monInt(_status!['followers']), monInt(_status!['required_followers'])),
      (monInt(_status!['views']), monInt(_status!['required_views'])),
      (
        monInt(_status!['video_posts']),
        monInt(_status!['required_video_posts'])
      ),
      (
        monInt(_status!['image_posts']),
        monInt(_status!['required_image_posts'])
      ),
    ];
    return pairs.where((p) => p.$2 <= 0 || p.$1 >= p.$2).length;
  }

  Widget _journeyHero(bool applied) {
    final eligible = _status!['eligible'] == true;
    final appStatus = (_status!['application_status'] ?? '').toString();

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;

    if (applied) {
      switch (appStatus) {
        case 'rejected':
          icon = Icons.info_outline_rounded;
          color = const Color(0xFFDC2626);
          title = 'আবেদন অনুমোদন হয়নি';
          subtitle = 'এবারের আবেদনটি অনুমোদন করা যায়নি। কারণ জানতে ও পরবর্তী '
              'করণীয় বুঝতে সাপোর্টে যোগাযোগ করুন।';
          break;
        default:
          icon = Icons.hourglass_top_rounded;
          color = const Color(0xFFD97706);
          title = 'আবেদন চেক চলছে';
          subtitle = 'আমাদের টিম আপনার প্রোফাইল ও কনটেন্ট দেখছে। সিদ্ধান্ত হলে '
              'নোটিফিকেশনে জানিয়ে দেওয়া হবে।';
      }
    } else if (eligible) {
      icon = Icons.check_circle_outline_rounded;
      color = monMoney;
      title = 'আপনি আবেদনের যোগ্য';
      subtitle = 'সবগুলো শর্ত পূরণ হয়েছে। নিচের বাটনে ট্যাপ করে আবেদন জমা দিন '
          '— অনুমোদন পেলেই কনটেন্ট থেকে আয় শুরু হবে।';
    } else {
      icon = Icons.trending_up_rounded;
      color = monAccent;
      title = 'কনটেন্ট থেকে আয় শুরু করুন';
      subtitle = 'নিচের শর্তগুলো পূরণ হলেই আবেদন করতে পারবেন, আর অনুমোদনের পর '
          'আপনার কনটেন্টে আসা সাড়া থেকে প্রতি মাসে আয় হবে।';
    }

    final met = _metCount();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 23, color: color),
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
                        color: monInk,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: monInkSoft,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!applied) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'অগ্রগতি',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  '৪টির মধ্যে ${bnDigits(met.toString())}টি পূরণ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: met >= 4 ? monMoney : monAccent,
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
                backgroundColor: monLine,
                valueColor: AlwaysStoppedAnimation<Color>(
                    met >= 4 ? monMoney : monAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _requirements() {
    final tiles = [
      (
        Icons.group_outlined,
        'ফলোয়ার',
        monInt(_status!['followers']),
        monInt(_status!['required_followers']),
      ),
      (
        Icons.visibility_outlined,
        'কনটেন্ট ভিউ',
        monInt(_status!['views']),
        monInt(_status!['required_views']),
      ),
      (
        Icons.videocam_outlined,
        'ভিডিও পোস্ট',
        monInt(_status!['video_posts']),
        monInt(_status!['required_video_posts']),
      ),
      (
        Icons.photo_outlined,
        'ছবি পোস্ট',
        monInt(_status!['image_posts']),
        monInt(_status!['required_image_posts']),
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
    final met = required <= 0 || current >= required;
    final ratio = required <= 0 ? 1.0 : (current / required).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border:
            isLast ? null : const Border(bottom: BorderSide(color: monLine)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF475569)),
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
                      '${monCount(current)} / ${monCount(required)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: met ? monMoney : monAccent,
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
                    backgroundColor: monLine,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        met ? monMoney : monAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: met ? monMoney : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  Widget _benefits() {
    const items = [
      (
        Icons.payments_outlined,
        'কনটেন্ট থেকে মাসিক আয়',
        'আপনার পোস্ট ও শর্টসে আসা আসল ভিউ, লাইক ও কমেন্ট থেকে প্রতি মাসে আয় হবে।'
      ),
      (
        Icons.insights_outlined,
        'কোন কনটেন্টে কত আয়',
        'কোন পোস্ট কত সাড়া পেয়েছে আর তা থেকে কত এসেছে — সব আলাদা করে দেখতে পারবেন।'
      ),
      (
        Icons.account_balance_wallet_outlined,
        'AdsyPay-তে সরাসরি',
        'এপ্রুভড আয় আপনার AdsyPay ব্যালেন্সে জমা হয়, আলাদা কোনো ঝামেলা নেই।'
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final b in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: monAccent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(b.$1, size: 18, color: monAccent),
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
                            color: monInkSoft,
                            height: 1.5,
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

  Widget _howItWorks() {
    const steps = [
      (
        'শর্তগুলো পূরণ করুন',
        'ফলোয়ার ও ভিউ বাড়ান, আর পর্যাপ্ত ভিডিও ও ছবি পোস্ট করুন।'
      ),
      (
        'আবেদন জমা দিন',
        'শর্তাবলি ও কমিউনিটি গাইডলাইন মেনে এক ট্যাপে আবেদন করুন।'
      ),
      (
        'অনুমোদনের পর আয় শুরু',
        'এরপর আপনার কনটেন্টে আসা সাড়া থেকে আয় জমতে থাকবে। প্রতি মাসের হিসাব '
            'মাস শেষে চূড়ান্ত হয় এবং চেকয়ের পর টাকা AdsyPay-তে যোগ হয়।'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: monAccent.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bnDigits((i + 1).toString()),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: monAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].$1,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: monInkSoft,
                            height: 1.5,
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

  Widget _applyButton() {
    final eligible = _status!['eligible'] == true;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: eligible ? _openApplySheet : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: monAccent,
          disabledBackgroundColor: monLine,
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          eligible
              ? 'মনিটাইজেশনের জন্য আবেদন করুন'
              : 'শর্ত পূরণ হলে খুলে যাবে',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _openApplySheet() async {
    final submitted = await MonetizationApplySheet.show(context);
    if (submitted == true && mounted) {
      setState(() => _loading = true);
      _load();
    }
  }
}
