import 'package:flutter/material.dart';

import '../services/google_play_billing_service.dart';
import 'common/adsy_toast.dart';

/// A professional bottom sheet that lets the user pay for a digital good with
/// either their wallet BALANCE or GOOGLE PLAY. The balance path returns
/// 'balance' (the caller runs its own flow); the Google Play path loads the
/// catalog for [kind], runs the purchase, shows an in-sheet success state, and
/// returns 'google' on a verified, server-granted purchase.
///
/// Returns:
///   'balance'  — user chose balance (caller runs its own flow)
///   'google'   — Google Play purchase verified + granted
///   null       — dismissed / failed
Future<String?> showPurchaseMethodSheet(
  BuildContext context, {
  required String kind, // 'diamonds' | 'pro' | 'gold'
  String? refId,
  int? diamondsWanted, // for diamonds: preselect the matching pack
  VoidCallback? onBalance,
  bool allowBalance = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PurchaseMethodSheet(
      kind: kind,
      refId: refId,
      diamondsWanted: diamondsWanted,
      onBalance: onBalance,
      allowBalance: allowBalance,
    ),
  );
}

class _PurchaseMethodSheet extends StatefulWidget {
  final String kind;
  final String? refId;
  final int? diamondsWanted;
  final VoidCallback? onBalance;
  final bool allowBalance;

  const _PurchaseMethodSheet({
    required this.kind,
    this.refId,
    this.diamondsWanted,
    this.onBalance,
    this.allowBalance = true,
  });

  @override
  State<_PurchaseMethodSheet> createState() => _PurchaseMethodSheetState();
}

class _PurchaseMethodSheetState extends State<_PurchaseMethodSheet> {
  bool _loadingCatalog = true;
  bool _buying = false;
  bool _success = false;
  String _successMessage = '';
  List<IapCatalogItem> _catalog = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await GooglePlayBilling.loadCatalog(widget.kind);
    if (!mounted) return;
    setState(() {
      _catalog = items;
      _loadingCatalog = false;
    });
  }

  IapCatalogItem? get _defaultItem {
    if (_catalog.isEmpty) return null;
    if (widget.diamondsWanted != null) {
      for (final it in _catalog) {
        if (it.diamonds == widget.diamondsWanted) return it;
      }
    }
    return _catalog.first;
  }

  // ── Theme per product kind ────────────────────────────────────────────────
  IconData get _kindIcon {
    switch (widget.kind) {
      case 'pro':
        return Icons.workspace_premium_rounded;
      case 'gold':
        return Icons.military_tech_rounded;
      default:
        return Icons.diamond_rounded;
    }
  }

  Color get _kindColor {
    switch (widget.kind) {
      case 'pro':
        return const Color(0xFF7C3AED);
      case 'gold':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF9333EA);
    }
  }

  String get _productTitle {
    final it = _defaultItem;
    switch (widget.kind) {
      case 'pro':
        return 'AdsyClub Pro';
      case 'gold':
        return 'Gold Sponsor';
      default:
        final d = it?.diamonds ?? widget.diamondsWanted ?? 0;
        return '$d ডায়মন্ড';
    }
  }

  String get _productSubtitle {
    switch (widget.kind) {
      case 'pro':
      case 'gold':
        return 'মাসিক • অটো-রিনিউ';
      default:
        return 'আপনার ওয়ালেটে যোগ হবে';
    }
  }

  String _successFor(IapCatalogItem item) {
    switch (widget.kind) {
      case 'pro':
        return 'AdsyClub Pro চালু হয়েছে!';
      case 'gold':
        return 'Gold Sponsor চালু হয়েছে!';
      default:
        return '${item.diamonds} ডায়মন্ড যোগ হয়েছে!';
    }
  }

  Future<void> _buyGoogle(IapCatalogItem item) async {
    setState(() => _buying = true);
    final ok = await GooglePlayBilling.buy(item, refId: widget.refId);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _buying = false;
        _success = true;
        _successMessage = _successFor(item);
      });
      // Let the user see the confirmation, then return to caller.
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).pop('google');
      return;
    }
    setState(() => _buying = false);

    // The Google account already holds this subscription on another AdsyClub
    // account — Play will refuse to sell it again, so offer to move it here.
    final conflict = GooglePlayBilling.lastConflict;
    if (conflict != null) {
      await _showConflictDialog(conflict);
      return;
    }
    AdsyToast.error(context, 'পেমেন্ট সম্পন্ন হয়নি। আবার চেষ্টা করুন।');
  }

  Future<void> _showConflictDialog(IapOwnershipConflict conflict) async {
    final owner =
        conflict.ownerHint.isNotEmpty ? conflict.ownerHint : 'অন্য একটি';
    String? cooldownNote;
    if (!conflict.canTransfer && conflict.reason.startsWith('cooldown_')) {
      final days =
          conflict.reason.replaceAll(RegExp(r'[^0-9]'), '');
      cooldownNote = 'সাবস্ক্রিপশনটি সম্প্রতি সরানো হয়েছে — আরও $days দিন পরে '
          'আবার সরানো যাবে।';
    }

    final doTransfer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'সাবস্ক্রিপশনটি অন্য অ্যাকাউন্টে আছে',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'আপনার Google অ্যাকাউন্টের এই সাবস্ক্রিপশনটি $owner AdsyClub '
          'অ্যাকাউন্টের সাথে যুক্ত। Google Play একই সাবস্ক্রিপশন দুবার কিনতে '
          'দেয় না।\n\n${conflict.canTransfer ? 'চাইলে সাবস্ক্রিপশনটি এই '
              'অ্যাকাউন্টে নিয়ে আসতে পারেন — আগের অ্যাকাউন্ট থেকে সুবিধাটি '
              'সরে যাবে।' : cooldownNote ?? 'ঐ অ্যাকাউন্টে লগইন করে '
              'সাবস্ক্রিপশনটি ব্যবহার করুন।'}',
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ঠিক আছে'),
          ),
          if (conflict.canTransfer)
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              child: const Text('এই অ্যাকাউন্টে নিয়ে আসুন'),
            ),
        ],
      ),
    );
    if (doTransfer != true || !mounted) return;

    setState(() => _buying = true);
    final ok = await GooglePlayBilling.transferToCurrentAccount(
        conflict.purchaseToken);
    if (!mounted) return;
    setState(() => _buying = false);
    if (ok) {
      setState(() {
        _success = true;
        _successMessage = 'সাবস্ক্রিপশন এই অ্যাকাউন্টে চলে এসেছে!';
      });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).pop('google');
    } else {
      AdsyToast.error(context, 'সাবস্ক্রিপশন সরানো যায়নি। পরে আবার চেষ্টা করুন।');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _success ? _buildSuccess() : _buildChooser(),
        ),
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 44, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 18),
          const Text(
            'পেমেন্ট সফল',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _successMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  // ── Chooser state ─────────────────────────────────────────────────────────
  Widget _buildChooser() {
    final googleAvailable = _catalog.isNotEmpty;
    final showPackList =
        widget.kind == 'diamonds' && googleAvailable && _catalog.length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Product summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kindColor.withValues(alpha: 0.10),
                  _kindColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kindColor.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kindColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_kindIcon, size: 26, color: _kindColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _productSubtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'পেমেন্ট মাধ্যম বাছুন',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Balance option
          if (widget.allowBalance && widget.onBalance != null) ...[
            _optionTile(
              iconWidget: const Icon(Icons.account_balance_wallet_rounded,
                  size: 22, color: Color(0xFF059669)),
              iconBg: const Color(0xFFECFDF5),
              title: 'Adsy Pay ব্যালেন্স',
              subtitle: 'তাৎক্ষণিক • কোনো অতিরিক্ত ফি নেই',
              onTap: _buying ? null : () => Navigator.of(context).pop('balance'),
            ),
            const SizedBox(height: 10),
          ],

          // Google Play option (single, when not showing a pack list)
          if (!showPackList)
            _optionTile(
              iconWidget: _googlePlayGlyph(),
              iconBg: const Color(0xFFEFF6FF),
              title: 'Google Play',
              subtitle: _loadingCatalog
                  ? 'লোড হচ্ছে…'
                  : googleAvailable
                      ? '${_defaultItem?.price ?? ''}  •  ১৫% Google ফি সহ'
                      : 'এখন উপলব্ধ নয়',
              trailing: _buying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : null,
              onTap: (_loadingCatalog || _buying || !googleAvailable)
                  ? null
                  : () {
                      final item = _defaultItem;
                      if (item != null) _buyGoogle(item);
                    },
            ),

          // Diamonds: multiple Google Play packs
          if (showPackList) ...[
            _optionHeaderGoogle(),
            const SizedBox(height: 8),
            ..._catalog.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _optionTile(
                    iconWidget: const Icon(Icons.diamond_rounded,
                        size: 20, color: Color(0xFF9333EA)),
                    iconBg: const Color(0xFFF5F3FF),
                    title: '${it.diamonds} ডায়মন্ড',
                    subtitle: '${it.price}  •  ১৫% Google ফি সহ',
                    onTap: _buying ? null : () => _buyGoogle(it),
                  ),
                )),
          ],

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(
                'নিরাপদ পেমেন্ট • Google দ্বারা সুরক্ষিত',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionHeaderGoogle() {
    return Row(
      children: [
        _googlePlayGlyph(size: 18),
        const SizedBox(width: 8),
        const Text(
          'Google Play প্যাক বাছুন',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // A small Google-Play-style triangle glyph.
  Widget _googlePlayGlyph({double size = 22}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlayTrianglePainter()),
    );
  }

  Widget _optionTile({
    required Widget iconWidget,
    required Color iconBg,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7ECF3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: iconWidget,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (trailing == null && enabled)
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the multicolour Google Play triangle.
class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Path()
      ..moveTo(w * 0.16, h * 0.08)
      ..lineTo(w * 0.16, h * 0.92)
      ..lineTo(w * 0.86, h * 0.5)
      ..close();
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00D0FF), // blue
          Color(0xFF00E676), // green
          Color(0xFFFFCE00), // yellow
          Color(0xFFFF3D57), // red
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
