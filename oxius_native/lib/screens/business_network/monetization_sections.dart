import 'package:flutter/material.dart';

import '../../config/app_config.dart';

/// Detail pages for the approved monetization view. The main screen stays a
/// clean overview; each page here goes deep on one thing. Data comes in from
/// the main screen's already-loaded status/earnings maps — no extra fetches.

const _accent = Color(0xFF2563EB);
const _accentSoft = Color(0xFF3B82F6);
const _ink = Color(0xFF111827);

int _asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

String _formatCount(int n) {
  if (n >= 1000) {
    final k = n / 1000;
    return k == k.roundToDouble() ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
  }
  return '$n';
}

String _taka(dynamic v) {
  final d = double.tryParse((v ?? '0').toString()) ?? 0;
  if (d == d.roundToDouble()) return '৳${d.round()}';
  return '৳${d.toStringAsFixed(2)}';
}

PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: _ink),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w800,
        color: _ink,
        letterSpacing: -0.3,
      ),
    ),
    shape: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
  );
}

Widget _sectionDivider() => Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFFF8FAFC),
    );

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

Widget _emptyState(IconData icon, String message) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
    child: Column(
      children: [
        Icon(icon, size: 38, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

// ── অ্যানালিটিক্স ────────────────────────────────────────────────────────────

class MonetizationAnalyticsScreen extends StatelessWidget {
  final Map<String, dynamic> earnings;
  final Map<String, dynamic> status;

  const MonetizationAnalyticsScreen({
    super.key,
    required this.earnings,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final p = (earnings['points'] as Map?) ?? {};
    final w = (earnings['weights'] as Map?) ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, 'অ্যানালিটিক্স'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          _sectionHeader('এই মাসের পয়েন্ট',
              'ভ্যালিড ভিউ ও এনগেজমেন্ট থেকে পয়েন্ট জমা হয়।'),
          _buildPointsBreakdown(p, w),
          _sectionDivider(),
          _sectionHeader('দৈনিক ভিউ', 'এই মাসে দিন অনুযায়ী আপনার কনটেন্টের ভিউ।'),
          _buildDailyChart(),
          _sectionDivider(),
          _sectionHeader('আয় বিশ্লেষণ', 'পয়েন্ট থেকে আয় এবং মাসভিত্তিক ট্রেন্ড।'),
          _buildEarningsAnalytics(),
          _sectionDivider(),
          _sectionHeader('আপনার রিচ', 'আপনার প্রোফাইল এই মুহূর্তে যেখানে দাঁড়িয়ে আছে।'),
          _buildReachGrid(),
        ],
      ),
    );
  }

  Widget _buildPointsBreakdown(Map p, Map w) {
    final rows = [
      (Icons.visibility_outlined, 'ভ্যালিড ভিউ', _asInt(p['valid_views']),
          _asInt(w['view'])),
      (Icons.favorite_outline_rounded, 'লাইক', _asInt(p['likes']),
          _asInt(w['like'])),
      (Icons.mode_comment_outlined, 'কমেন্ট', _asInt(p['comments']),
          _asInt(w['comment'])),
      (Icons.person_add_alt_outlined, 'নতুন ফলোয়ার',
          _asInt(p['followers_gained']), _asInt(w['follower'])),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Icon(rows[i].$1, size: 20, color: const Color(0xFF475569)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  '${_formatCount(rows[i].$3)} × ${rows[i].$4}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  child: Text(
                    '${_formatCount(rows[i].$3 * rows[i].$4)} পয়েন্ট',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'মোট পয়েন্ট',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                _formatCount(_asInt(p['total_points'])),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart() {
    final daily = (earnings['daily_views'] as List? ?? []);
    final p = (earnings['points'] as Map?) ?? {};

    final byDay = <int, int>{};
    for (final d in daily) {
      final date = (d['date'] ?? '').toString();
      final day = int.tryParse(date.length >= 10 ? date.substring(8, 10) : '');
      if (day != null) byDay[day] = _asInt(d['views']);
    }
    final today = DateTime.now().day;
    final totalViews = byDay.values.fold<int>(0, (a, b) => a + b);
    final avg = today > 0 ? (totalViews / today) : 0.0;
    int bestDay = 0;
    int bestViews = 0;
    byDay.forEach((day, v) {
      if (v > bestViews) {
        bestViews = v;
        bestDay = day;
      }
    });
    final maxViews = bestViews > 0 ? bestViews : 1;
    final engagement = _asInt(p['likes']) + _asInt(p['comments']);
    final validViews = _asInt(p['valid_views']);
    final engagementRate =
        validViews > 0 ? (engagement * 100 / validViews) : 0.0;

    final stats = [
      ('মোট ভিউ', _formatCount(totalViews)),
      ('দৈনিক গড়', avg >= 10 ? avg.round().toString() : avg.toStringAsFixed(1)),
      ('সেরা দিন', bestViews > 0 ? '$bestDay তারিখ • $bestViews ভিউ' : '—'),
      ('এনগেজমেন্ট রেট', '${engagementRate.toStringAsFixed(1)}%'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 84,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var day = 1; day <= today; day++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: byDay[day] == null || byDay[day] == 0
                            ? 3
                            : (6 + 78 * (byDay[day]! / maxViews))
                                .clamp(6, 84)
                                .toDouble(),
                        decoration: BoxDecoration(
                          color: byDay[day] == null || byDay[day] == 0
                              ? const Color(0xFFE2E8F0)
                              : _accentSoft,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('১ তারিখ',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              Text('আজ ($today তারিখ)',
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              for (final s in stats)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsAnalytics() {
    final p = (earnings['points'] as Map?) ?? {};
    final points = _asInt(p['total_points']);
    final estimated = earnings['estimated_amount'];
    final poolAmount = earnings['pool_amount'];

    // Per-point value this month (estimated ÷ points) — a simple "what one
    // point is worth" read for the creator.
    double perPoint = 0;
    final est = double.tryParse((estimated ?? '0').toString()) ?? 0;
    if (points > 0 && est > 0) perPoint = est / points;

    // Monthly earnings trend: this month + past months (oldest→newest).
    final history = (earnings['history'] as List? ?? []).toList();
    final series = <(String, double)>[];
    for (final h in history.reversed) {
      final period = (h['period'] ?? '').toString();
      final label = period.length >= 7 ? period.substring(5, 7) : period;
      series.add((label, double.tryParse((h['amount'] ?? '0').toString()) ?? 0));
    }
    final nowPeriod = (earnings['period'] ?? '').toString();
    series.add((
      nowPeriod.length >= 7 ? nowPeriod.substring(5, 7) : 'এখন',
      est,
    ));
    final maxAmt =
        series.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);

    final tiles = [
      ('এই মাসের আয়', _taka(estimated ?? '0')),
      ('মোট পয়েন্ট', _formatCount(points)),
      (
        'প্রতি পয়েন্টের মান',
        perPoint > 0 ? '৳${perPoint.toStringAsFixed(3)}' : '—',
      ),
      ('মাসিক পুল', _taka(poolAmount ?? '0')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              for (final s in tiles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (maxAmt > 0) ...[
            const SizedBox(height: 16),
            const Text(
              'মাসিক আয়ের ট্রেন্ড',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final s in series)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _taka(s.$2),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: (6 + 58 * (s.$2 / maxAmt))
                                  .clamp(6, 64)
                                  .toDouble(),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              s.$1,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                est > 0
                    ? 'মাসিক ট্রেন্ড কয়েক মাস পর থেকে দেখা যাবে।'
                    : 'অ্যাডমিন মাসিক পুল সেট করলে আপনার আয় এখানে দেখা যাবে। এখন পর্যন্ত আপনি $points পয়েন্ট অর্জন করেছেন।',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReachGrid() {
    final stats = [
      (Icons.group_outlined, 'ফলোয়ার', _formatCount(_asInt(status['followers']))),
      (Icons.visibility_outlined, 'কনটেন্ট ভিউ',
          _formatCount(_asInt(status['views']))),
      (Icons.videocam_outlined, 'ভিডিও পোস্ট',
          _formatCount(_asInt(status['video_posts']))),
      (Icons.photo_outlined, 'ছবি পোস্ট',
          _formatCount(_asInt(status['image_posts']))),
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
}

// ── কনটেন্ট অনুযায়ী আয় ──────────────────────────────────────────────────────

class MonetizationContentScreen extends StatelessWidget {
  final Map<String, dynamic> earnings;

  const MonetizationContentScreen({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final items = (earnings['top_content'] as List? ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, 'কনটেন্ট অনুযায়ী আয়'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          _sectionHeader('কোন কনটেন্ট থেকে কত আয়',
              'এই মাসে কোন কনটেন্ট থেকে কত আয় হয়েছে।'),
          if (items.isEmpty)
            _emptyState(Icons.article_outlined,
                'এই মাসে এখনো কোনো কনটেন্টে এনগেজমেন্ট আসেনি। পোস্ট করতে থাকুন — ভিউ এলেই এখানে হিসাব দেখা যাবে।')
          else
            for (var i = 0; i < items.length; i++)
              _contentRow(items[i], isLast: i == items.length - 1),
        ],
      ),
    );
  }

  Widget _contentRow(dynamic item, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFFF1F5F9)),
                  if ((item['thumbnail'] ?? '').toString().isNotEmpty)
                    Image.network(
                      AppConfig.getAbsoluteUrl(item['thumbnail'].toString()),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: Color(0xFF94A3B8)),
                    )
                  else
                    const Icon(Icons.article_outlined,
                        size: 20, color: Color(0xFF94A3B8)),
                  if ((item['media_type'] ?? '') == 'video')
                    Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['excerpt'] ?? '').toString().isNotEmpty
                      ? item['excerpt'].toString()
                      : 'কনটেন্ট',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatCount(_asInt(item['views']))} ভিউ • ${_formatCount(_asInt(item['likes']))} লাইক • ${_formatCount(_asInt(item['comments']))} কমেন্ট',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Points are internal machinery — creators see MONEY, not
              // points (Facebook-style).
              if (item['estimated_amount'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  _taka(item['estimated_amount']),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── পেআউট হিস্ট্রি ───────────────────────────────────────────────────────────

class MonetizationPayoutScreen extends StatelessWidget {
  final Map<String, dynamic> earnings;

  const MonetizationPayoutScreen({super.key, required this.earnings});

  static const _statusBn = {
    'accruing': 'চলমান',
    'held': 'রিভিউয়ে আটকে',
    'cleared': 'ক্লিয়ারড',
    'paid': 'পরিশোধিত',
    'forfeited': 'বাতিল',
  };

  @override
  Widget build(BuildContext context) {
    final history = (earnings['history'] as List? ?? []);
    final payoutDate = (earnings['expected_payout_date'] ?? '').toString();
    final holdback = _asInt(earnings['holdback_days']);

    final infoRows = [
      (
        Icons.event_available_outlined,
        'সম্ভাব্য পেমেন্ট তারিখ',
        payoutDate.isNotEmpty ? payoutDate : '—',
      ),
      (
        Icons.savings_outlined,
        'সর্বনিম্ন পেআউট',
        '${_taka(earnings['min_payout'])} — এর কম হলে পরের মাসে যোগ হয়ে থাকবে',
      ),
      (
        Icons.schedule_outlined,
        'রিভিউ উইন্ডো',
        'মাস শেষে $holdback দিনের যাচাই, তারপর পেমেন্ট',
      ),
      (
        Icons.account_balance_wallet_outlined,
        'পেমেন্ট মাধ্যম',
        'AdsyPay ব্যালেন্সে সরাসরি যোগ হয়',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, 'পেআউট হিস্ট্রি'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          _sectionHeader('পেমেন্ট তথ্য', 'কখন ও কীভাবে টাকা পাবেন।'),
          for (final r in infoRows)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(r.$1, size: 19, color: const Color(0xFF475569)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.$3,
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
          _sectionDivider(),
          _sectionHeader('আগের মাসগুলো', 'চূড়ান্ত হিসাব ও পেমেন্ট স্ট্যাটাস।'),
          if (history.isEmpty)
            _emptyState(Icons.receipt_long_outlined,
                'এখনো কোনো চূড়ান্ত পেআউট হয়নি। প্রথম মাস শেষ হলে এখানে মাসভিত্তিক হিসাব দেখা যাবে।')
          else
            for (var i = 0; i < history.length; i++)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                decoration: BoxDecoration(
                  border: i == history.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (history[i]['period'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatCount(_asInt(history[i]['total_points']))} পয়েন্ট • ${_statusBn[(history[i]['status'] ?? '').toString()] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _taka(history[i]['amount']),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: (history[i]['status'] == 'paid')
                            ? const Color(0xFF059669)
                            : _ink,
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

// ── আয় কীভাবে হিসাব হয় ──────────────────────────────────────────────────────

class MonetizationInfoScreen extends StatelessWidget {
  final Map<String, dynamic> earnings;

  const MonetizationInfoScreen({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final w = (earnings['weights'] as Map?) ?? {};
    final weightRows = [
      (Icons.visibility_outlined, 'প্রতি ভ্যালিড ভিউ', _asInt(w['view'])),
      (Icons.favorite_outline_rounded, 'প্রতি লাইক', _asInt(w['like'])),
      (Icons.mode_comment_outlined, 'প্রতি কমেন্ট', _asInt(w['comment'])),
      (Icons.person_add_alt_outlined, 'প্রতি নতুন ফলোয়ার',
          _asInt(w['follower'])),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, 'আয় কীভাবে হিসাব হয়'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'প্রতি মাসে AdsyClub একটি নির্দিষ্ট রেভিনিউ পুল সব মনিটাইজড ক্রিয়েটরের মধ্যে ভাগ করে — যার পয়েন্ট যত বেশি, তার ভাগ তত বড়। মাস শেষে হিসাব চূড়ান্ত হয়, রিভিউয়ের পর টাকা আপনার AdsyPay ব্যালেন্সে যোগ হয়।',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF334155),
                height: 1.6,
              ),
            ),
          ),
          _sectionDivider(),
          _sectionHeader('পয়েন্ট রেট', 'কোন কাজে কত পয়েন্ট জমা হয়।'),
          for (final r in weightRows)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(r.$1, size: 19, color: const Color(0xFF475569)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    '${r.$3} পয়েন্ট',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
          _sectionDivider(),
          _sectionHeader('নীতিমালা', 'মনিটাইজেশন সুস্থ রাখতে যা মানতে হবে।'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'শুধু আসল (ভ্যালিড) ভিউ ও এনগেজমেন্টে পয়েন্ট জমা হয় — নিজের ভিউ, নতুন খোলা অ্যাকাউন্টের ভিউ বা একই ব্যক্তির অতিরিক্ত ভিউ গণনা হয় না। ফেক বা এক্সচেঞ্জ ভিউ ধরা পড়লে ওই মাসের আয় আটকে যায় এবং বারবার হলে মনিটাইজেশন স্থায়ীভাবে বাতিল হতে পারে। তাই মানসম্মত কনটেন্টই আয়ের সবচেয়ে নিরাপদ পথ।',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF334155),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
