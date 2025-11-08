import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _balancesVisibleKey = 'balances_visible';

  /// Set whether balances should be visible
  static Future<void> setBalancesVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_balancesVisibleKey, visible);
  }

  /// Get whether balances should be visible (defaults to true)
  static Future<bool> getBalancesVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_balancesVisibleKey) ?? true; // Default to visible
  }
}
