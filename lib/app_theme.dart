import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'models/app_theme_model.dart';

class AppTheme {
  final AppThemeModel _themeModel;

  AppTheme._(this._themeModel);

  /// Get AppTheme from context
  static AppTheme of(BuildContext context, {bool listen = true}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: listen);
    return AppTheme._(themeProvider.currentTheme);
  }

  // Colors - now dynamic based on current theme
  Color get primaryBlack => _themeModel.primaryBackground;
  Color get secondaryBlack => _themeModel.secondaryBackground;
  Color get tertiaryBlack => _themeModel.tertiaryBackground;

  Color get primaryWhite => _themeModel.primaryText;
  Color get secondaryWhite => _themeModel.primaryText;

  Color get primaryGray => _themeModel.gradientStart;
  Color get secondaryGray => _themeModel.gradientEnd;
  Color get tertiaryGray => _themeModel.mutedText;

  // Gradients
  LinearGradient get silverGradient => LinearGradient(
    colors: [_themeModel.gradientStart, _themeModel.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border Colors
  Color get borderColor => _themeModel.borderColor;
  Color get subtleBorderColor => _themeModel.subtleBorderColor;

  // Text Colors
  Color get mutedText => _themeModel.mutedText;
  Color get subtleText => _themeModel.subtleText;

  // Spacing - these remain static as they don't depend on theme
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius - these remain static
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

  // Button Heights - these remain static
  static const double buttonHeight = 56.0;
  static const double buttonHeightS = 44.0;

  // Icon Sizes - these remain static
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 40.0;
}
