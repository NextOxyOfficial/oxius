import 'package:flutter/material.dart';
import '../utils/app_fonts.dart';

/// Centralized, professional typography + text-colour system for the app.
///
/// Use these semantic styles everywhere instead of hand-writing `fontSize` /
/// `fontWeight` / `color` on each `Text`, so every screen shares ONE consistent
/// visual standard. Each style accepts an optional [color] override for the few
/// cases that genuinely need it (e.g. a coloured status label).
///
/// Colour roles (dark → light):
///   primary   — headings & the most important text
///   secondary — strong body text
///   body      — normal body text
///   tertiary  — supporting / secondary info
///   muted     — captions, hints, timestamps, meta
class AppText {
  AppText._();

  // ── Semantic text colours ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A); // headings / key text
  static const Color secondary = Color(0xFF334155); // strong body
  static const Color body = Color(0xFF475569); // normal body
  static const Color tertiary = Color(0xFF64748B); // supporting text
  static const Color muted = Color(0xFF94A3B8); // captions / meta / hints
  static const Color inverse = Colors.white;
  static const Color link = Color(0xFF2563EB);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // ── Type scale (semantic) ──────────────────────────────────────────────

  /// Big screen / page title (app-bar-level headings).
  static TextStyle screenTitle({Color? color}) => AppFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: color ?? primary,
        letterSpacing: -0.4,
        height: 1.2,
      );

  /// Section heading inside a page (e.g. "My Services", "Gold Sponsors").
  static TextStyle sectionTitle({Color? color}) => AppFonts.roboto(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: color ?? secondary,
        letterSpacing: -0.3,
        height: 1.25,
      );

  /// One-line supporting text under a section title.
  static TextStyle sectionSubtitle({Color? color}) => AppFonts.roboto(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: color ?? tertiary,
        height: 1.4,
      );

  /// Title of a card / list item.
  static TextStyle cardTitle({Color? color}) => AppFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? secondary,
        letterSpacing: -0.1,
        height: 1.3,
      );

  /// Secondary line inside a card / list item.
  static TextStyle cardSubtitle({Color? color}) => AppFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? body,
        height: 1.35,
      );

  /// Default body / paragraph text.
  static TextStyle bodyText({Color? color}) => AppFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color ?? body,
        height: 1.45,
      );

  /// Emphasised body text.
  static TextStyle bodyStrong({Color? color}) => AppFonts.roboto(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? secondary,
        height: 1.4,
      );

  /// Form / field label, small tab label.
  static TextStyle label({Color? color}) => AppFonts.roboto(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: color ?? secondary,
      );

  /// Caption — hints, helper text.
  static TextStyle caption({Color? color}) => AppFonts.roboto(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: color ?? muted,
        height: 1.35,
      );

  /// Meta — timestamps, counts, tiny secondary info.
  static TextStyle meta({Color? color}) => AppFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color ?? muted,
      );

  /// Grid / chip tile label under an icon.
  static TextStyle tileLabel({Color? color}) => AppFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? body,
        letterSpacing: -0.1,
        height: 1.2,
      );

  /// Button label (colour is usually set by the button's foreground).
  static TextStyle button({Color? color}) => AppFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color ?? inverse,
        letterSpacing: 0.1,
      );

  /// Inline link / action text.
  static TextStyle linkText({Color? color}) => AppFonts.roboto(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: color ?? link,
      );

  /// Price / amount emphasis.
  static TextStyle price({Color? color}) => AppFonts.roboto(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: color ?? success,
        letterSpacing: -0.3,
      );

  /// Small pill / badge label.
  static TextStyle badge({Color? color}) => AppFonts.roboto(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color ?? inverse,
        letterSpacing: 0.2,
      );
}
