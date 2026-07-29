import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// What the rider filled in, handed back to the caller to submit.
///
/// The sheet deliberately does not call the API itself: the account page owns
/// the resulting profile and has to redraw around it, so it owns the request.
class DriverApplication {
  final String licenseNumber;
  final String nationalIdNumber;
  final String details;

  const DriverApplication({
    required this.licenseNumber,
    required this.nationalIdNumber,
    required this.details,
  });
}

/// "Apply for a Driver" — the form behind that button.
///
/// Both numbers are required here even though the server accepts blanks. A
/// blank application still creates a pending profile that an admin then has
/// to reject by hand, which wastes the rider's wait as much as the admin's
/// time.
class RideshareDriverApplySheet extends StatefulWidget {
  const RideshareDriverApplySheet({super.key});

  static Future<DriverApplication?> show(BuildContext context) {
    return showModalBottomSheet<DriverApplication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RideshareDriverApplySheet(),
    );
  }

  @override
  State<RideshareDriverApplySheet> createState() =>
      _RideshareDriverApplySheetState();
}

class _RideshareDriverApplySheetState extends State<RideshareDriverApplySheet> {
  static const _ink = Color(0xFF0F172A);

  final _license = TextEditingController();
  final _nid = TextEditingController();
  final _details = TextEditingController();

  String? _licenseError;
  String? _nidError;

  @override
  void dispose() {
    _license.dispose();
    _nid.dispose();
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final license = _license.text.trim();
    final nid = _nid.text.trim();

    setState(() {
      _licenseError = license.isEmpty ? 'ড্রাইভিং লাইসেন্স নম্বর দিন' : null;
      _nidError = nid.isEmpty ? 'জাতীয় পরিচয়পত্র নম্বর দিন' : null;
    });
    if (_licenseError != null || _nidError != null) return;

    Navigator.pop(
      context,
      DriverApplication(
        licenseNumber: license,
        nationalIdNumber: nid,
        details: _details.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'ড্রাইভার হোন',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'আবেদন জমা দিলে আমাদের টিম যাচাই করবে। অনুমোদন হলে আপনার '
                  'অ্যাকাউন্টে ড্রাইভার মোড চালু হয়ে যাবে।',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                _Field(
                  label: 'ড্রাইভিং লাইসেন্স নম্বর',
                  hint: 'DK-0123456789',
                  controller: _license,
                  error: _licenseError,
                  icon: Icons.badge_rounded,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: () {
                    if (_licenseError != null) {
                      setState(() => _licenseError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  label: 'জাতীয় পরিচয়পত্র (NID) নম্বর',
                  hint: '১০ বা ১৭ সংখ্যার এনআইডি',
                  controller: _nid,
                  error: _nidError,
                  icon: Icons.credit_card_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: () {
                    if (_nidError != null) setState(() => _nidError = null);
                  },
                ),
                const SizedBox(height: 14),
                _Field(
                  label: 'আপনার সম্পর্কে',
                  hint: 'কত বছর চালাচ্ছেন, কোন এলাকায় চালাতে চান…',
                  controller: _details,
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                  optional: true,
                ),

                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_rounded,
                          size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'অনুমোদনের পর গাড়ি যোগ করলে তবেই রাইড রিকোয়েস্ট পাবেন।',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            height: 1.45,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ink,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'আবেদন জমা দিন',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String? error;
  final int maxLines;
  final bool optional;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final VoidCallback? onChanged;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.error,
    this.maxLines = 1,
    this.optional = false,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text(
                'ঐচ্ছিক',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onChanged: (_) => onChanged?.call(),
          style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 13.5, color: const Color(0xFFB4BECC)),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
                : null,
            filled: true,
            fillColor: const Color(0xFFF7F9FC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: _border(const Color(0xFFE9EDF3)),
            enabledBorder:
                _border(hasError ? const Color(0xFFFCA5A5) : const Color(0xFFE9EDF3)),
            focusedBorder: _border(
                hasError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                width: 1.4),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Text(
            error!,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: color, width: width),
      );
}
