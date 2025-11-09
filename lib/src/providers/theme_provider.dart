import 'package:flutter/material.dart';
import '../models/app_theme_model.dart';
import '../services/theme_service.dart';

/// Provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  ThemeType _currentThemeType = ThemeType.dark;
  Color? _customColor;
  AppThemeModel _currentTheme = AppThemeModel.dark();

  ThemeType get currentThemeType => _currentThemeType;
  Color? get customColor => _customColor;
  AppThemeModel get currentTheme => _currentTheme;

  Future<void> loadSavedTheme() async {
    _currentThemeType = await ThemeService.getThemeType();

    if (_currentThemeType == ThemeType.custom) {
      _customColor = await ThemeService.getCustomThemeColor();
      if (_customColor != null) {
        _currentTheme = AppThemeModel.custom(_customColor!);
      } else {
        // If custom color not found, fallback to dark
        _currentThemeType = ThemeType.dark;
        _currentTheme = AppThemeModel.dark();
      }
    } else if (_currentThemeType == ThemeType.light) {
      _currentTheme = AppThemeModel.light();
    } else {
      _currentTheme = AppThemeModel.dark();
    }

    notifyListeners();
  }

  Future<void> setDarkTheme() async {
    _currentThemeType = ThemeType.dark;
    _currentTheme = AppThemeModel.dark();
    await ThemeService.saveThemeType(ThemeType.dark);
    notifyListeners();
  }

  Future<void> setLightTheme() async {
    _currentThemeType = ThemeType.light;
    _currentTheme = AppThemeModel.light();
    await ThemeService.saveThemeType(ThemeType.light);
    notifyListeners();
  }

  Future<void> setCustomTheme(Color color) async {
    _currentThemeType = ThemeType.custom;
    _customColor = color;
    _currentTheme = AppThemeModel.custom(color);
    await ThemeService.saveThemeType(ThemeType.custom);
    await ThemeService.saveCustomThemeColor(color);
    notifyListeners();
  }

  /// Get MaterialApp theme data
  ThemeData getMaterialTheme() {
    // Determine primary color for buttons to ensure good contrast
    final Color primaryColor;
    final Color onPrimaryColor;

    if (_currentThemeType == ThemeType.custom && _customColor != null) {
      // For custom themes, use a brighter/saturated version of the custom color
      final hsl = HSLColor.fromColor(_customColor!);
      primaryColor = hsl.withLightness(0.5).withSaturation(0.8).toColor();
      // Use black or white text based on the button color brightness
      final luminance = primaryColor.computeLuminance();
      onPrimaryColor = luminance > 0.5 ? Colors.black : Colors.white;
    } else if (_currentThemeType == ThemeType.light) {
      primaryColor = Colors.amber.shade700;
      onPrimaryColor = Colors.black;
    } else {
      primaryColor = Colors.amber;
      onPrimaryColor = Colors.black;
    }

    return ThemeData(
      brightness: _currentThemeType == ThemeType.light
          ? Brightness.light
          : Brightness.dark,
      scaffoldBackgroundColor: _currentTheme.primaryBackground,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: _currentThemeType == ThemeType.light
            ? Brightness.light
            : Brightness.dark,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        secondary: _currentTheme.tertiaryBackground,
        onSecondary: _currentTheme.primaryText,
        error: Colors.red,
        onError: Colors.white,
        surface: _currentTheme.primaryBackground,
        onSurface: _currentTheme.primaryText,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: _currentTheme.primaryText),
        bodyMedium: TextStyle(color: _currentTheme.primaryText),
        bodySmall: TextStyle(color: _currentTheme.mutedText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
