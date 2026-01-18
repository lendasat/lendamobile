import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for chart time range
enum ChartTimeRange { day, week, month, year, max }

class UserPreferencesService extends ChangeNotifier {
  static const String _balancesVisibleKey = 'balances_visible';
  static const String _chartTimeRangeKey = 'chart_time_range';
  static const String _autoReadClipboardKey = 'auto_read_clipboard';
  static const String _allowAnalyticsKey = 'allow_analytics';

  bool _balancesVisible = true;
  ChartTimeRange _chartTimeRange = ChartTimeRange.day;
  bool _autoReadClipboard = false; // Default OFF
  bool _allowAnalytics = true; // Default ON

  bool get balancesVisible => _balancesVisible;
  ChartTimeRange get chartTimeRange => _chartTimeRange;
  bool get autoReadClipboard => _autoReadClipboard;
  bool get allowAnalytics => _allowAnalytics;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _balancesVisible = prefs.getBool(_balancesVisibleKey) ?? true;
    final rangeIndex = prefs.getInt(_chartTimeRangeKey) ?? 0;
    _chartTimeRange = ChartTimeRange
        .values[rangeIndex.clamp(0, ChartTimeRange.values.length - 1)];
    _autoReadClipboard = prefs.getBool(_autoReadClipboardKey) ?? false;
    _allowAnalytics = prefs.getBool(_allowAnalyticsKey) ?? true;
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

  Future<void> setChartTimeRange(ChartTimeRange range) async {
    _chartTimeRange = range;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chartTimeRangeKey, range.index);

    notifyListeners();
  }

  Future<void> setAutoReadClipboard(bool value) async {
    _autoReadClipboard = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoReadClipboardKey, value);

    notifyListeners();
  }

  Future<void> toggleAutoReadClipboard() async {
    await setAutoReadClipboard(!_autoReadClipboard);
  }

  Future<void> setAllowAnalytics(bool value) async {
    _allowAnalytics = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowAnalyticsKey, value);

    notifyListeners();
  }

  Future<void> toggleAllowAnalytics() async {
    await setAllowAnalytics(!_allowAnalytics);
  }

  String getChartTimeRangeLabel() {
    switch (_chartTimeRange) {
      case ChartTimeRange.day:
        return '1D';
      case ChartTimeRange.week:
        return '1W';
      case ChartTimeRange.month:
        return '1M';
      case ChartTimeRange.year:
        return '1Y';
      case ChartTimeRange.max:
        return 'Max';
    }
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

  static Future<bool> getAllowAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_allowAnalyticsKey) ?? true;
  }
}
