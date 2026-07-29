import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The one header every rideshare sub-page uses: back chevron, centred title,
/// optional single action. No AppBar, no elevation, no drawer hamburger.
///
/// It exists so History, Vehicles and Account cannot drift apart again — they
/// each used to draw their own bar, which is how one ended up with a menu
/// button to a sidebar that no longer exists.
class RidesharePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onBack;

  const RidesharePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFF0F172A)),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          // Same width as the leading button so the title stays optically
          // centred whether or not there is an action.
          SizedBox(width: 44, child: action),
        ],
      ),
    );
  }
}
