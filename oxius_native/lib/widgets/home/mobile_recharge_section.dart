import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/translation_service.dart';
import '../../services/mobile_recharge_service.dart';
import '../../screens/mobile_recharge/mobile_recharge_screen.dart';

// Design tokens — mirrors the rideshare panel palette
const _emerald = Color(0xFF10B981);
const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate800 = Color(0xFF1E293B);

class MobileRechargeSection extends StatefulWidget {
  const MobileRechargeSection({super.key});

  @override
  State<MobileRechargeSection> createState() => _MobileRechargeSectionState();
}

class _MobileRechargeSectionState extends State<MobileRechargeSection> {
  final TranslationService _translationService = TranslationService();
  List<Map<String, dynamic>> _operators = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    try {
      final operators = await MobileRechargeService.getOperators();
      if (mounted) {
        setState(() {
          _operators = operators;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String t(String key) => _translationService.translate(key);

  String _getOperatorShortName(String name) {
    final n = name.toLowerCase();
    if (n.contains('gp') || n.contains('grameenphone')) return 'GP';
    if (n.contains('robi')) return 'Robi';
    if (n.contains('bl') || n.contains('banglalink')) return 'BL';
    if (n.contains('airtel')) return 'Airtel';
    if (n.contains('tt') || n.contains('teletalk')) return 'TT';
    return name.length <= 4 ? name : name.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MobileRechargeScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          splashColor: _emerald.withValues(alpha: 0.06),
          highlightColor: _emerald.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // ── Gradient icon ─────────────────────────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_indigo, _violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: _indigo.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),

                // ── Text + operator chips ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('mobile_recharge'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _slate800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildOperatorRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorRow() {
    if (_isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 11,
            height: 11,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(_slate400),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Loading operators...',
            style: GoogleFonts.inter(fontSize: 11, color: _slate400),
          ),
        ],
      );
    }

    if (_operators.isEmpty) {
      return Text(
        'Recharge any operator instantly',
        style: GoogleFonts.inter(fontSize: 11, color: _slate400),
      );
    }

    final visibleOperators = _operators.take(4).toList();

    return Row(
      children: [
        for (int i = 0; i < visibleOperators.length; i++) ...[
          Expanded(
            child: _OperatorChip(
              shortName: _getOperatorShortName(visibleOperators[i]['name'] as String),
              iconUrl: visibleOperators[i]['icon']?.toString(),
            ),
          ),
          if (i != visibleOperators.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _OperatorChip extends StatelessWidget {
  final String shortName;
  final String? iconUrl;

  const _OperatorChip({
    required this.shortName,
    this.iconUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 30, child: _buildContent());
  }

  Widget _buildContent() {
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return Image.network(
        iconUrl!,
        width: double.infinity,
        height: 30,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _textFallback(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _textFallback(),
      );
    }
    return _textFallback();
  }

  Widget _textFallback() {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: Center(
        child: Text(
          shortName,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _slate500,
            height: 1,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
