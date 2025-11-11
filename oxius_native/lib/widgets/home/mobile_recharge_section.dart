import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/translation_service.dart';
import '../../services/mobile_recharge_service.dart';
import '../../screens/mobile_recharge/mobile_recharge_screen.dart';

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
        print('🏠 Homepage: Loaded ${operators.length} operators');
      }
    } catch (e) {
      print('🏠 Homepage: Error loading operators: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String t(String key) => _translationService.translate(key);

  Color _getOperatorColor(String operatorName) {
    final name = operatorName.toLowerCase();
    if (name.contains('gp') || name.contains('grameenphone')) return const Color(0xFF00A651);
    if (name.contains('robi')) return const Color(0xFFE60012);
    if (name.contains('bl') || name.contains('banglalink')) return const Color(0xFFFF6600);
    if (name.contains('airtel')) return const Color(0xFFDC143C);
    if (name.contains('tt') || name.contains('teletalk')) return const Color(0xFF0066CC);
    return const Color(0xFF10B981); // Default green
  }

  String _getOperatorShortName(String operatorName) {
    final name = operatorName.toLowerCase();
    if (name.contains('gp') || name.contains('grameenphone')) return 'GP';
    if (name.contains('robi')) return 'Robi';
    if (name.contains('bl') || name.contains('banglalink')) return 'BL';
    if (name.contains('airtel')) return 'Airtel';
    if (name.contains('tt') || name.contains('teletalk')) return 'TT';
    // Return first 2-4 characters as fallback
    return operatorName.length <= 4 ? operatorName : operatorName.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MobileRechargeScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('mobile_recharge'),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _isLoading
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Loading operators...',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                          : _operators.isEmpty
                              ? Text(
                                  'No operators available',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                )
                              : Row(
                                  children: [
                                    ..._operators.take(5).map((operator) {
                                      final operatorName = operator['name'] as String;
                                      final operatorIcon = operator['icon'];
                                      final shortName = _getOperatorShortName(operatorName);
                                      final color = _getOperatorColor(operatorName);
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        width: 38,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: operatorIcon != null && operatorIcon.toString().isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.network(
                                                  operatorIcon,
                                                  width: 38,
                                                  height: 24,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    // Fallback to text badge if image fails
                                                    return Center(
                                                      child: Text(
                                                        shortName,
                                                        style: GoogleFonts.roboto(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: SizedBox(
                                                        width: 10,
                                                        height: 10,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 1.5,
                                                          valueColor: AlwaysStoppedAnimation<Color>(
                                                            Colors.white.withOpacity(0.7),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  shortName,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                      );
                                    }),
                                  ],
                                ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
