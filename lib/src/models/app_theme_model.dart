import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enum representing available theme types
enum ThemeType {
  dark,
  light,
  custom,
}

/// Extension to convert ThemeType to/from string for storage
extension ThemeTypeExtension on ThemeType {
  String toStorageString() {
    switch (this) {
      case ThemeType.dark:
        return 'dark';
      case ThemeType.light:
        return 'light';
      case ThemeType.custom:
        return 'custom';
    }
  }

  static ThemeType fromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeType.dark;
      case 'light':
        return ThemeType.light;
      case 'custom':
        return ThemeType.custom;
      default:
        return ThemeType.dark; // Default to dark theme
    }
  }
}

/// Model representing a complete app theme
class AppThemeModel {
  // Background colors
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color tertiaryBackground;

  // Text colors
  final Color primaryText;
  final Color mutedText;
  final Color subtleText;

  // Accent colors
  final Color borderColor;
  final Color subtleBorderColor;

  // Gradient colors (for cards)
  final Color gradientStart;
  final Color gradientEnd;

  const AppThemeModel({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.primaryText,
    required this.mutedText,
    required this.subtleText,
    required this.borderColor,
    required this.subtleBorderColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  /// Calculate relative luminance of a color (WCAG formula)
  static double _calculateLuminance(Color color) {
    final r = ((color.r * 255.0).round() & 0xff) / 255.0;
    final g = ((color.g * 255.0).round() & 0xff) / 255.0;
    final b = ((color.b * 255.0).round() & 0xff) / 255.0;

    final rLinear =
        r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4);
    final gLinear =
        g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4);
    final bLinear =
        b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  /// Determine if a color is light (needs dark text) or dark (needs light text)
  static bool _isLightColor(Color color) {
    return _calculateLuminance(color) > 0.5;
  }

  /// Lighten a color by a percentage
  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken a color by a percentage
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Create a dark theme (default - current theme)
  factory AppThemeModel.dark() {
    return const AppThemeModel(
      primaryBackground: Color(0xFF0A0A0A),
      secondaryBackground: Color(0xFF1A1A1A),
      tertiaryBackground: Color(0xFF2A2A2A),
      primaryText: Color(0xFFFFFFFF),
      mutedText: Color(0xB3FFFFFF), // White with 70% opacity
      subtleText: Color(0x80FFFFFF), // White with 50% opacity
      borderColor: Color(0x1AFFFFFF), // White with 10% opacity
      subtleBorderColor: Color(0x0DFFFFFF), // White with 5% opacity
      gradientStart: Color(0xFF585858),
      gradientEnd: Color(0xFFC6C6C6),
    );
  }

  /// Create a light theme
  factory AppThemeModel.light() {
    return const AppThemeModel(
      primaryBackground: Color(0xFFFFFFFF),
      secondaryBackground: Color(0xFFF5F5F5),
      tertiaryBackground: Color(0xFFE8E8E8),
      primaryText: Color(0xFF0A0A0A),
      mutedText: Color(0xFF424242), // Dark gray for better contrast
      subtleText: Color(0xFF757575), // Medium gray
      borderColor: Color(0xFFE0E0E0), // Light gray border
      subtleBorderColor: Color(0xFFF0F0F0), // Very light gray border
      gradientStart: Color(0xFF9E9E9E),
      gradientEnd: Color(0xFF616161),
    );
  }

  /// Create a custom theme from a user-selected color
  factory AppThemeModel.custom(Color baseColor) {
    final isLight = _isLightColor(baseColor);

    // Generate background shades
    final primaryBg = baseColor;
    final secondaryBg =
        isLight ? _darken(baseColor, 0.05) : _lighten(baseColor, 0.05);
    final tertiaryBg =
        isLight ? _darken(baseColor, 0.1) : _lighten(baseColor, 0.1);

    // Determine text colors based on background luminance
    final textColor =
        isLight ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF);
    final mutedTextColor = isLight
        ? const Color(0xFF424242) // Dark gray for better contrast
        : const Color(0xFFBDBDBD); // Light gray
    final subtleTextColor = isLight
        ? const Color(0xFF757575) // Medium gray
        : const Color(0xFF9E9E9E); // Medium-light gray

    // Border colors
    final borderCol = isLight
        ? const Color(0xFFE0E0E0) // Light gray border
        : const Color(0xFF424242); // Dark gray border
    final subtleBorderCol = isLight
        ? const Color(0xFFF0F0F0) // Very light gray border
        : const Color(0xFF2A2A2A); // Very dark gray border

    // Gradient colors - create complementary shades
    final gradStart =
        isLight ? _darken(baseColor, 0.2) : _lighten(baseColor, 0.15);
    final gradEnd =
        isLight ? _darken(baseColor, 0.3) : _lighten(baseColor, 0.25);

    return AppThemeModel(
      primaryBackground: primaryBg,
      secondaryBackground: secondaryBg,
      tertiaryBackground: tertiaryBg,
      primaryText: textColor,
      mutedText: mutedTextColor,
      subtleText: subtleTextColor,
      borderColor: borderCol,
      subtleBorderColor: subtleBorderCol,
      gradientStart: gradStart,
      gradientEnd: gradEnd,
    );
  }
}
