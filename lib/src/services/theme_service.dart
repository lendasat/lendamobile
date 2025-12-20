import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme_model.dart';

/// Service for persisting theme preferences using SharedPreferences
class ThemeService {
  static const String _themeTypeKey = 'theme_type';
  static const String _customThemeColorKey = 'custom_theme_color';

  static Future<ThemeType> getThemeType() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeTypeKey);
    if (themeString == null) {
      return ThemeType.dark;
    }
    return ThemeTypeExtension.fromString(themeString);
  }

  static Future<void> saveThemeType(ThemeType themeType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeTypeKey, themeType.toStorageString());
  }

  static Future<Color?> getCustomThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_customThemeColorKey);
    if (colorValue == null) {
      return null;
    }
    return Color(colorValue);
  }

  static Future<void> saveCustomThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customThemeColorKey, color.toARGB32());
  }

  static Future<void> clearThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeTypeKey);
    await prefs.remove(_customThemeColorKey);
  }
}
