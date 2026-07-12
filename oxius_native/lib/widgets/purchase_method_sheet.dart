import 'package:flutter/material.dart';

import '../services/google_play_billing_service.dart';
import 'common/adsy_toast.dart';

/// A bottom sheet that lets the user pay for a digital good with either their
/// wallet BALANCE or GOOGLE PLAY. The balance path calls [onBalance] (the
/// screen's existing flow); the Google Play path loads the catalog for [kind],
/// runs the purchase, and returns true on a verified, server-granted purchase.
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

  Future<void> _buyGoogle(IapCatalogItem item) async {
    setState(() => _buying = true);
    final ok = await GooglePlayBilling.buy(item, refId: widget.refId);
    if (!mounted) return;
    setState(() => _buying = false);
    if (ok) {
      Navigator.of(context).pop('google');
    } else {
      AdsyToast.error(context, 'পেমেন্ট সম্পন্ন হয়নি। আবার চেষ্টা করুন।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleAvailable = _catalog.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'পেমেন্ট পদ্ধতি বাছুন',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              if (widget.allowBalance && widget.onBalance != null)
                _optionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF059669),
                  title: 'ব্যালেন্স দিয়ে',
                  subtitle: 'আপনার Adsy Pay ব্যালেন্স থেকে',
                  onTap: _buying
                      ? null
                      : () => Navigator.of(context).pop('balance'),
                ),
              const SizedBox(height: 10),
              _optionTile(
                icon: Icons.shop_rounded,
                color: const Color(0xFF2563EB),
                title: 'Google Play দিয়ে',
                subtitle: _loadingCatalog
                    ? 'লোড হচ্ছে…'
                    : googleAvailable
                        ? (_defaultItem?.price ?? 'Google Play')
                        : 'এখন উপলব্ধ নয়',
                trailing: _buying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.2))
                    : null,
                onTap: (_loadingCatalog || _buying || !googleAvailable)
                    ? null
                    : () {
                        final item = _defaultItem;
                        if (item != null) _buyGoogle(item);
                      },
              ),
              // Diamonds: if several packs are available, list them.
              if (widget.kind == 'diamonds' &&
                  googleAvailable &&
                  _catalog.length > 1) ...[
                const SizedBox(height: 14),
                const Text(
                  'অথবা Google Play প্যাক বাছুন',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                ..._catalog.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _optionTile(
                        icon: Icons.diamond_outlined,
                        color: const Color(0xFF7C3AED),
                        title: '${it.diamonds} ডায়মন্ড',
                        subtitle: it.price,
                        onTap: _buying ? null : () => _buyGoogle(it),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: 12),
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
    );
  }
}
