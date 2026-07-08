import 'package:flutter/material.dart';

import '../../utils/app_fonts.dart';

/// Shared design tokens for the settings screen.
/// Follows the app-wide design language: slate palette, white cards,
/// one blue accent, bottom sheets instead of dialogs/dropdowns.
class SettingsTokens {
  SettingsTokens._();

  static const Color background = Color(0xFFF1F5F9);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color iconTile = Color(0xFFF8FAFC);
  static const Color title = Color(0xFF0F172A);
  static const Color heading = Color(0xFF1E293B);
  static const Color body = Color(0xFF475569);
  static const Color muted = Color(0xFF64748B);
  static const Color faint = Color(0xFF94A3B8);
  static const Color chevron = Color(0xFFCBD5E1);
  static const Color accent = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFB45309);
}

/// UPPERCASE section heading shown above a card group.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: AppFonts.roboto(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: SettingsTokens.faint,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Plain white card with the standard border and radius.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: SettingsTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SettingsTokens.border),
      ),
      child: child,
    );
  }
}

/// 36px rounded-square leading icon tile used in list rows.
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile(
    this.icon, {
    super.key,
    this.color = SettingsTokens.body,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: SettingsTokens.iconTile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SettingsTokens.divider),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// List row with a switch, used for the privacy toggles.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.preview,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? preview;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsIconTile(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: SettingsTokens.heading,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppFonts.roboto(
                    fontSize: 11.5,
                    color: SettingsTokens.muted,
                    height: 1.35,
                  ),
                ),
                if (preview != null && preview!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    preview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: value ? SettingsTokens.accent : SettingsTokens.faint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: SettingsTokens.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 1px hairline divider between rows, indented past the icon tile.
class SettingsRowDivider extends StatelessWidget {
  const SettingsRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 62),
      child: Divider(height: 1, thickness: 1, color: SettingsTokens.divider),
    );
  }
}

/// Standard drag handle for the settings bottom sheets.
class SettingsSheetHandle extends StatelessWidget {
  const SettingsSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: SettingsTokens.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Bottom-sheet list picker used instead of dropdowns.
/// Returns the tapped item, or null if dismissed.
Future<String?> showSettingsSelectionSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.72;
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                child: Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SettingsTokens.title,
                  ),
                ),
              ),
              const Divider(
                  height: 1, thickness: 1, color: SettingsTokens.divider),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(left: 18),
                    child: Divider(
                        height: 1,
                        thickness: 1,
                        color: SettingsTokens.divider),
                  ),
                  itemBuilder: (itemContext, index) {
                    final item = items[index];
                    final isSelected = item == selected;
                    return InkWell(
                      onTap: () => Navigator.of(itemContext).pop(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? SettingsTokens.accent
                                      : SettingsTokens.heading,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded,
                                  size: 18, color: SettingsTokens.accent),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Bottom-sheet confirmation used instead of AlertDialog for
/// destructive actions. Returns true when confirmed.
Future<bool> showSettingsConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsSheetHandle(),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: SettingsTokens.title,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppFonts.roboto(
                  fontSize: 12.5,
                  color: SettingsTokens.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        side: const BorderSide(color: SettingsTokens.border),
                        foregroundColor: SettingsTokens.body,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        cancelLabel,
                        style: AppFonts.roboto(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: destructive
                            ? SettingsTokens.danger
                            : SettingsTokens.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        confirmLabel,
                        style: AppFonts.roboto(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
