import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class TimezoneService extends ChangeNotifier {
  static const String _timezoneKey = 'selected_timezone';

  String _currentTimezone = 'UTC';

  String get currentTimezone => _currentTimezone;

  /// Get the current Location object for timezone calculations
  tz.Location get location => tz.getLocation(_currentTimezone);

  static Map<String, List<String>> get timezonesByRegion {
    final allTimezones = tz.timeZoneDatabase.locations.keys.toList()..sort();

    final Map<String, List<String>> grouped = {};

    for (final timezone in allTimezones) {
      final parts = timezone.split('/');
      if (parts.length >= 2) {
        final region = parts[0];
        if (!grouped.containsKey(region)) {
          grouped[region] = [];
        }
        grouped[region]!.add(timezone);
      }
    }

    return grouped;
  }

  static List<String> get allTimezones {
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  String getTimezoneDisplayName(String timezone) {
    try {
      final location = tz.getLocation(timezone);
      final now = tz.TZDateTime.now(location);
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();

      final offsetStr = hours >= 0
          ? '+$hours${minutes > 0 ? ':${minutes.toString().padLeft(2, '0')}' : ''}'
          : '$hours${minutes > 0 ? ':${minutes.toString().padLeft(2, '0')}' : ''}';

      final parts = timezone.split('/');
      final cityName = parts.length > 1
          ? parts.sublist(1).join('/').replaceAll('_', ' ')
          : timezone.replaceAll('_', ' ');

      return '$cityName (UTC$offsetStr)';
    } catch (e) {
      return timezone.replaceAll('_', ' ');
    }
  }

  Future<void> loadSavedTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTimezone = prefs.getString(_timezoneKey);

    if (savedTimezone != null &&
        tz.timeZoneDatabase.locations.containsKey(savedTimezone)) {
      _currentTimezone = savedTimezone;
      notifyListeners();
    } else {
      try {
        _currentTimezone = DateTime.now().timeZoneName;
        tz.getLocation(_currentTimezone);
      } catch (e) {
        _currentTimezone = 'UTC';
      }
    }
  }

  Future<void> setTimezone(String timezone) async {
    if (!tz.timeZoneDatabase.locations.containsKey(timezone)) {
      throw ArgumentError('Invalid timezone: $timezone');
    }

    _currentTimezone = timezone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezoneKey, timezone);

    notifyListeners();
  }

  DateTime now() {
    final location = tz.getLocation(_currentTimezone);
    return tz.TZDateTime.now(location);
  }

  DateTime toSelectedTimezone(DateTime dateTime) {
    final location = tz.getLocation(_currentTimezone);
    return tz.TZDateTime.from(dateTime, location);
  }

  DateTime fromUtc(DateTime utcDateTime) {
    final location = tz.getLocation(_currentTimezone);
    return tz.TZDateTime.from(utcDateTime.toUtc(), location);
  }
}
