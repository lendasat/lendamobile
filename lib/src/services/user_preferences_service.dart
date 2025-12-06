import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService extends ChangeNotifier {
  static const String _balancesVisibleKey = 'balances_visible';

  bool _balancesVisible = true;

  bool get balancesVisible => _balancesVisible;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _balancesVisible = prefs.getBool(_balancesVisibleKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleBalancesVisible() async {
    _balancesVisible = !_balancesVisible;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_balancesVisibleKey, _balancesVisible);

    notifyListeners();
  }

  Future<void> setBalancesVisible(bool visible) async {
    _balancesVisible = visible;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_balancesVisibleKey, visible);

    notifyListeners();
  }

  // Static methods for backward compatibility
  static Future<void> setBalancesVisibleStatic(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_balancesVisibleKey, visible);
  }

  static Future<bool> getBalancesVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_balancesVisibleKey) ?? true;
  }
}
