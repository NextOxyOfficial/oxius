import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../widgets/app_network_image.dart';

/// Shared kit + detail pages for the Content Monetization screen.
///
/// House rule for everything in this file: a creator sees WHAT THEY DID and
/// WHAT THEY EARNED — never the machinery in between. No points, no per-action
/// rates, no monthly pool. Those are business levers the admin retunes; putting
/// them on screen turns every payout into an argument about the formula, and
/// publishes the platform's payout budget to every user who scrolls.

// ── palette ────────────────────────────────────────────────────────────────

const monAccent = Color(0xFF2563EB);
const monAccentDeep = Color(0xFF1D4ED8);
const monMoney = Color(0xFF059669);
const monInk = Color(0xFF111827);
const monInkSoft = Color(0xFF64748B);
const monLine = Color(0xFFF1F5F9);
const monSurface = Color(0xFFF8FAFC);

// ── numbers ────────────────────────────────────────────────────────────────

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// ASCII digits → Bangla digits, everything else untouched.
String bnDigits(String s) {
  final out = StringBuffer();
  for (final unit in s.codeUnits) {
    out.write(unit >= 48 && unit <= 57
        ? _bnDigits[unit - 48]
        : String.fromCharCode(unit));
  }
  return out.toString();
}

/// Bangladeshi grouping: last three digits, then pairs — 1234567 → 12,34,567.
String _group(String digits) {
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final parts = <String>[];
  var i = head.length;
  while (i > 2) {
    parts.insert(0, head.substring(i - 2, i));
    i -= 2;
  }
  if (i > 0) parts.insert(0, head.substring(0, i));
  return '${parts.join(',')},$tail';
}

int monInt(dynamic v) =>
    v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

double monDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

/// Grouped Bangla count: 12345 → ১২,৩৪৫.
String monCount(dynamic v) => bnDigits(_group(monInt(v).toString()));

/// Money. Whole amounts drop the decimals — ৳১,২০০ reads better than ৳১,২০০.০০.
///
/// Rounds to paisa FIRST and splits afterwards. Taking the fraction off the
/// raw double instead turned 99.999999 (which is what summing a column of
/// doubles actually hands you) into "৳৯৯.১০০" — the paisa rounded up to 100
/// and got printed as three digits.
String monTaka(dynamic v) {
  final raw = monDouble(v);
  final totalPaisa = (raw.abs() * 100).round();
  final whole = totalPaisa ~/ 100;
  final paisa = totalPaisa % 100;
  final sign = raw < 0 && totalPaisa > 0 ? '-' : '';
  final grouped = bnDigits(_group(whole.toString()));
  if (paisa == 0) return '৳$sign$grouped';
  return '৳$sign$grouped.${bnDigits(paisa.toString().padLeft(2, '0'))}';
}

const monMonthsBn = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

/// '2026-08' → 'আগস্ট ২০২৬'. Returns the input unchanged if it is not a period.
String monPeriodLabel(dynamic period) {
  final s = (period ?? '').toString();
  if (s.length < 7) return s;
  final year = int.tryParse(s.substring(0, 4));
  final month = int.tryParse(s.substring(5, 7));
  if (year == null || month == null || month < 1 || month > 12) return s;
  return '${monMonthsBn[month - 1]} ${bnDigits(year.toString())}';
}

/// 'DD-MM-YYYY' (what the API sends) → '৭ সেপ্টেম্বর ২০২৬'.
///
/// The day and year ranges are checked, not just the month: an ISO date
/// ('2026-09-07') also splits into three parseable parts with a valid month in
/// the middle, and without the range check it rendered as "২০২৬ সেপ্টেম্বর ৭"
/// — a confidently wrong date. Anything that is not DD-MM-YYYY falls back to
/// the raw string in Bangla digits, which at least reads as unformatted.
String monDateLabel(dynamic raw) {
  final s = (raw ?? '').toString();
  final parts = s.split('-');
  if (parts.length != 3) return bnDigits(s);
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return bnDigits(s);
  if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1000) {
    return bnDigits(s);
  }
  return '${bnDigits(day.toString())} ${monMonthsBn[month - 1]} '
      '${bnDigits(year.toString())}';
}

// ── status vocabulary ──────────────────────────────────────────────────────

class MonStatus {
  final String label;
  final Color color;
  final IconData icon;
  final String? note;
  const MonStatus(this.label, this.color, this.icon, [this.note]);
}

MonStatus monStatusOf(String status) {
  switch (status) {
    case 'held':
      return const MonStatus(
        'রিভিউয়ে',
        Color(0xFFD97706),
        Icons.pause_circle_outline_rounded,
        'অস্বাভাবিক ভিউ অ্যাক্টিভিটি চেক করা হচ্ছে, তাই এই মাসের আয় '
            'সাময়িকভাবে আটকে আছে। চেক শেষ হলে নিজে থেকেই চালু হবে।',
      );
    case 'forfeited':
      return const MonStatus(
        'বাতিল',
        Color(0xFFDC2626),
        Icons.cancel_outlined,
        'নিয়ম লঙ্ঘনের কারণে এই মাসের আয় বাতিল হয়েছে। বারবার হলে '
            'মনিটাইজেশন স্থায়ীভাবে বন্ধ হয়ে যেতে পারে।',
      );
    case 'cleared':
      return const MonStatus(
        'পেমেন্টের অপেক্ষায়',
        monMoney,
        Icons.task_alt_rounded,
      );
    case 'paid':
      return const MonStatus('পেমেন্টিত', monMoney, Icons.verified_rounded);
    default:
      return const MonStatus('চলমান', monAccent, Icons.trending_up_rounded);
  }
}

// ── shared chrome ──────────────────────────────────────────────────────────

PreferredSizeWidget monAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: monInk),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w800,
        color: monInk,
        letterSpacing: -0.3,
      ),
    ),
    shape: const Border(bottom: BorderSide(color: monLine)),
  );
}

/// Soft band between sections. The page is ONE surface with dividers, not a
/// stack of floating cards.
Widget monBand() => Container(
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 18),
      color: monSurface,
    );

Widget monHeader(String title, [String? subtitle, Widget? trailing]) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: monInk,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: monInkSoft,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing],
      ],
    ),
  );
}

Widget monEmpty(IconData icon, String message) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
    child: Column(
      children: [
        Icon(icon, size: 36, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: monInkSoft,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

/// Amber/red explainer strip for held + forfeited months.
Widget monNotice(MonStatus s) {
  if (s.note == null) return const SizedBox.shrink();
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
    decoration: BoxDecoration(
      color: s.color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: s.color.withValues(alpha: 0.18)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(s.icon, size: 18, color: s.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            s.note!,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: s.color.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── one content row: what it did, what it earned ───────────────────────────

class MonContentRow extends StatelessWidget {
  final Map item;
  final bool showDivider;

  const MonContentRow({
    super.key,
    required this.item,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = (item['thumbnail'] ?? '').toString();
    final excerpt = (item['excerpt'] ?? '').toString().trim();
    final amount = item['estimated_amount'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: monLine))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: monLine),
                  if (thumb.isNotEmpty)
                    AppNetworkImage(
                      AppConfig.getAbsoluteUrl(thumb),
                      fit: BoxFit.cover,
                      errorWidget: const Icon(Icons.image_outlined,
                          size: 19, color: Color(0xFF94A3B8)),
                    )
                  else
                    const Icon(Icons.article_outlined,
                        size: 19, color: Color(0xFF94A3B8)),
                  if ((item['media_type'] ?? '') == 'video')
                    Center(
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
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
                  excerpt.isNotEmpty ? excerpt : 'কনটেন্ট',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 12,
                  runSpacing: 3,
                  children: [
                    _action(Icons.visibility_outlined, item['views']),
                    _action(Icons.favorite_outline_rounded, item['likes']),
                    _action(Icons.mode_comment_outlined, item['comments']),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount == null ? '—' : monTaka(amount),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: amount == null ? const Color(0xFFCBD5E1) : monMoney,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, dynamic value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(
          monCount(value),
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF7B8798),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The tail the top-N list leaves out. Without it the rows would visibly fail
/// to add up to the headline, which reads as money going missing.
Widget monRemainderRow(int count, dynamic amount) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    color: monSurface,
    child: Row(
      children: [
        const Icon(Icons.more_horiz_rounded, size: 18, color: monInkSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'বাকি ${monCount(count)}টি কনটেন্ট',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D4759),
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
      ],
    ),
  );
}

// ── কনটেন্ট অনুযায়ী আয় (full list) ─────────────────────────────────────────

class MonetizationContentScreen extends StatelessWidget {
  final Map<String, dynamic> earnings;

  const MonetizationContentScreen({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final items = (earnings['top_content'] as List? ?? []);
    final total = monInt(earnings['content_count']);
    final other = earnings['other_content_amount'];
    final otherCount = total - items.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: monAppBar(context, 'কনটেন্ট অনুযায়ী আয়'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          monHeader(
            monPeriodLabel(earnings['period']),
            'এই মাসে কোন কনটেন্টে কত সাড়া এসেছে আর তা থেকে কত আয় হয়েছে — '
                'সবচেয়ে বেশি আয় করা কনটেন্ট উপরে।',
          ),
          if (items.isEmpty)
            monEmpty(
              Icons.article_outlined,
              'এই মাসে এখনো কোনো কনটেন্টে সাড়া আসেনি। পোস্ট করতে থাকুন — '
                  'ভিউ আসা শুরু হলেই এখানে কনটেন্ট অনুযায়ী হিসাব দেখা যাবে।',
            )
          else ...[
            for (var i = 0; i < items.length; i++)
              MonContentRow(
                item: items[i] as Map,
                showDivider: i != items.length - 1 || otherCount > 0,
              ),
            if (otherCount > 0 && other != null)
              monRemainderRow(otherCount, other),
          ],
        ],
      ),
    );
  }
}

// ── পেআউট ──────────────────────────────────────────────────────────────────

class MonetizationPayoutScreen extends StatelessWidget {
  final Map<String, dynamic> earnings;

  const MonetizationPayoutScreen({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final history = (earnings['history'] as List? ?? []);
    final holdback = monInt(earnings['holdback_days']);

    final rows = [
      (
        Icons.account_balance_wallet_outlined,
        'কোথায় পাবেন',
        'এপ্রুভড আয় আপনার AdsyPay ব্যালেন্সে যোগ করা হয়, সেখান থেকে '
            'স্বাভাবিক নিয়মেই তুলতে পারবেন।',
      ),
      (
        Icons.event_available_outlined,
        'সম্ভাব্য পেমেন্ট তারিখ',
        monDateLabel(earnings['expected_payout_date']),
      ),
      (
        Icons.schedule_outlined,
        'চেকয়ের সময়',
        'মাস শেষ হওয়ার পর ${bnDigits(holdback.toString())} দিন চেক চলে, '
            'তারপর পেমেন্ট ছাড়া হয়।',
      ),
      (
        Icons.account_balance_wallet_outlined,
        'কমপক্ষে পেআউট',
        '${monTaka(earnings['min_payout'])} — এর কম হলে টাকা হারায় না, '
            'পরের মাসের সাথে যোগ হয়ে জমা থাকে।',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: monAppBar(context, 'পেআউট'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: [
          _lifetime(),
          monBand(),
          monHeader('কীভাবে ও কখন টাকা পাবেন'),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
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
          monBand(),
          monHeader('মাসভিত্তিক হিসাব', 'আগের মাসগুলোর চূড়ান্ত আয় ও অবস্থা।'),
          if (history.isEmpty)
            monEmpty(
              Icons.receipt_long_outlined,
              'এখনো কোনো মাস শেষ হয়নি। প্রথম মাস পূর্ণ হলে এখানে '
                  'মাসভিত্তিক হিসাব জমা হতে থাকবে।',
            )
          else
            for (var i = 0; i < history.length; i++)
              _historyRow(history[i] as Map, i == history.length - 1),
        ],
      ),
    );
  }

  Widget _lifetime() {
    final lifetime = earnings['lifetime_earned'];
    final paid = earnings['paid_total'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: monSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(child: _tile('মোট আয়', monTaka(lifetime), monInk)),
            Container(width: 1, height: 34, color: const Color(0xFFE2E8F0)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _tile('পেমেন্টিত', monTaka(paid), monMoney),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: monInkSoft,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _historyRow(Map row, bool isLast) {
    final s = monStatusOf((row['status'] ?? '').toString());
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border:
            isLast ? null : const Border(bottom: BorderSide(color: monLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monPeriodLabel(row['period']),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(s.icon, size: 13, color: s.color),
                    const SizedBox(width: 4),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: s.color,
                      ),
                    ),
                    const Text(' • ',
                        style: TextStyle(
                            fontSize: 11.5, color: Color(0xFFCBD5E1))),
                    Text(
                      '${monCount(row['valid_views'])} ভিউ',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7B8798),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            monTaka(row['amount']),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: (row['status'] == 'paid') ? monMoney : monInk,
            ),
          ),
        ],
      ),
    );
  }
}
