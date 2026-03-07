import 'package:flutter/material.dart';

/// Drop-in replacement for GoogleFonts to avoid google_fonts package
/// compatibility issues with newer Dart SDK versions.
/// 
/// Uses system fonts instead of downloading Google Fonts at runtime.
/// Roboto is the default Material Design font and is bundled with Flutter.
class AppFonts {
  AppFonts._();

  /// Returns a TextStyle using the default system font (Roboto on Android,
  /// SF Pro on iOS) - matching AppFonts.roboto() behavior.
  static TextStyle roboto({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
  }) {
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      foreground: foreground,
      background: background,
      shadows: shadows,
      textBaseline: textBaseline,
    );
  }

  /// Returns a TextStyle using Poppins-like styling.
  /// Falls back to system font since Poppins is not bundled.
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      foreground: foreground,
      background: background,
      shadows: shadows,
      textBaseline: textBaseline,
    );
  }

  /// Returns a TextStyle using Inter-like styling.
  /// Falls back to system font since Inter is not bundled.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      foreground: foreground,
      background: background,
      shadows: shadows,
      textBaseline: textBaseline,
    );
  }

  /// Returns a TextStyle using monospace font.
  static TextStyle robotoMono({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    TextBaseline? textBaseline,
  }) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      foreground: foreground,
      background: background,
      shadows: shadows,
      textBaseline: textBaseline,
    );
  }

  /// Returns a complete TextTheme using Roboto - replacement for
  /// GoogleFonts.robotoTextTheme()
  static TextTheme robotoTextTheme([TextTheme? textTheme]) {
    final base = textTheme ?? const TextTheme();
    return base.apply(fontFamily: 'Roboto');
  }
}
