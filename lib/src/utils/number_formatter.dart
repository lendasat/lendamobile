import 'package:intl/intl.dart';

/// Centralized number formatting utilities for consistent number display across the app.
class NumberFormatter {
  NumberFormatter._();

  /// Formats an integer with locale-aware thousand separators.
  /// Uses the provided locale or defaults to system locale.
  static String formatWithSeparators(int value, {String? locale}) {
    final formatter = NumberFormat.decimalPattern(locale);
    return formatter.format(value);
  }

  /// Formats satoshi amount with locale-aware thousand separators and optional sign.
  static String formatSats(int sats, {String? locale, bool showSign = false}) {
    final absValue = sats.abs();
    final formatted = formatWithSeparators(absValue, locale: locale);

    if (showSign) {
      return sats.isNegative ? '-$formatted' : '+$formatted';
    }
    return sats.isNegative ? '-$formatted' : formatted;
  }
}
