/// Bitcoin-related constants used throughout the app.
///
/// These constants ensure consistency and make the codebase more maintainable.
class BitcoinConstants {
  BitcoinConstants._();

  /// Number of satoshis in one Bitcoin (10^8)
  static const int satsPerBtc = 100000000;

  /// Convert satoshis to BTC
  static double satsToBtc(int sats) => sats / satsPerBtc;

  /// Convert satoshis to BTC (for BigInt)
  static double satsToBtcBigInt(BigInt sats) => sats.toInt() / satsPerBtc;

  /// Convert BTC to satoshis
  static int btcToSats(double btc) => (btc * satsPerBtc).toInt();

  /// Format satoshis as BTC string with specified decimal places
  static String formatAsBtc(int sats, {int decimals = 8}) {
    return satsToBtc(sats).toStringAsFixed(decimals);
  }
}

/// App-wide timeout and delay constants.
///
/// Centralizes timing values for consistency and easy tuning.
class AppTimeouts {
  AppTimeouts._();

  /// Default payment monitoring timeout (5 minutes)
  static const int paymentMonitoringSeconds = 300;

  /// Short delay for UI feedback (2 seconds)
  static const Duration shortDelay = Duration(seconds: 2);

  /// Medium delay for operations (5 seconds)
  static const Duration mediumDelay = Duration(seconds: 5);

  /// Debounce delay for search/input (300ms)
  static const Duration debounceDelay = Duration(milliseconds: 300);

  /// Quote refresh debounce (500ms)
  static const Duration quoteDebounce = Duration(milliseconds: 500);

  /// API request timeout (30 seconds)
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Long-running operation timeout (2 minutes)
  static const Duration longOperationTimeout = Duration(minutes: 2);

  /// Background task timeout (10 minutes)
  static const Duration backgroundTaskTimeout = Duration(minutes: 10);
}
