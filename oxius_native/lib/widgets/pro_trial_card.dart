import 'package:flutter/material.dart';

import '../services/pro_trial_service.dart';

/// Free-Pro-trial offer card, shown on the Pro upgrade and store-create
/// screens. Renders nothing unless the server says this account can still
/// claim a trial, so a user who already used it never sees the pitch again.
///
/// Tapping opens a stepped sheet that states the conditions before activating —
/// the server re-checks every one of them, this is only how they're explained.
class ProTrialCard extends StatefulWidget {
  /// Called after a successful activation so the host screen can refresh the
  /// user's Pro state without a manual reload.
  final VoidCallback? onActivated;

  const ProTrialCard({super.key, this.onActivated});

  @override
  State<ProTrialCard> createState() => _ProTrialCardState();
}

class _ProTrialCardState extends State<ProTrialCard> {
  ProTrialStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ProTrialService.fetchStatus();
    if (!mounted) return;
    setState(() {
      _status = s;
      _loading = false;
    });
  }

  Future<void> _openSheet() async {
    final s = _status;
    if (s == null) return;
    final activated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProTrialSheet(status: s),
    );
    if (activated == true) {
      widget.onActivated?.call();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (_loading || s == null || !s.shouldOffer) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _openSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.days} দিনের ফ্রি প্রো ট্রায়াল',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.requiresKyc && !s.kycVerified
                          ? 'KYC ভেরিফাই করে ফ্রিতে শুরু করুন'
                          : 'কোনো টাকা লাগবে না — এখনই শুরু করুন',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'শুরু করুন',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stepped activation sheet: what you get → what's required → activate.
class _ProTrialSheet extends StatefulWidget {
  final ProTrialStatus status;

  const _ProTrialSheet({required this.status});

  @override
  State<_ProTrialSheet> createState() => _ProTrialSheetState();
}

class _ProTrialSheetState extends State<_ProTrialSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _activate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await ProTrialService.activate();
    if (!mounted) return;
    if (res.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      return;
    }
    setState(() {
      _busy = false;
      _error = res.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    final kycOk = !s.requiresKyc || s.kycVerified;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            '${s.days} দিনের ফ্রি প্রো ট্রায়াল',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'প্রো-এর সব সুবিধা ব্যবহার করে দেখুন — কোনো পেমেন্ট ছাড়াই।',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          _step(
            index: 1,
            title: 'KYC ভেরিফিকেশন',
            subtitle: kycOk
                ? 'আপনার অ্যাকাউন্ট ভেরিফাইড ✓'
                : (s.kycPending
                    ? 'আপনার KYC রিভিউতে আছে — অনুমোদনের পর ট্রায়াল নিতে পারবেন।'
                    : 'ট্রায়াল নিতে আগে KYC সম্পন্ন করতে হবে।'),
            done: kycOk,
          ),
          _step(
            index: 2,
            title: 'ট্রায়াল চালু করুন',
            subtitle: 'এক ট্যাপেই ${s.days} দিনের প্রো চালু হয়ে যাবে।',
            done: false,
          ),
          _step(
            index: 3,
            title: 'মেয়াদ শেষে',
            subtitle:
                'ট্রায়াল শেষ হলে অ্যাকাউন্ট নিজে থেকেই সাধারণ প্ল্যানে ফিরে যাবে — '
                'অটো-চার্জ হবে না।',
            done: false,
            last: true,
          ),

          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFF64748B)),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'প্রতি অ্যাকাউন্টে ফ্রি ট্রায়াল একবারই নেওয়া যায়।',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (!kycOk || _busy) ? null : _activate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      kycOk
                          ? 'ফ্রি ট্রায়াল চালু করুন'
                          : 'আগে KYC সম্পন্ন করুন',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step({
    required int index,
    required String title,
    required String subtitle,
    required bool done,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 14 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: done ? const Color(0xFF16A34A) : const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                ),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 26,
                  color: const Color(0xFFE2E8F0),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
