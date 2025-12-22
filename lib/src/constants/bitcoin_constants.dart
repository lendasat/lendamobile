/// Bitcoin-related constants used throughout the app.
///
/// These constants ensure consistency and make the codebase more maintainable.
class BitcoinConstants {
  BitcoinConstants._();

  /// Number of satoshis in one Bitcoin (10^8)
  static const int satsPerBtc = 100000000;

  /// Convert satoshis to BTC
  static double satsToBtc(int sats) => sats / satsPerBtc;

  /// Convert BTC to satoshis
  static int btcToSats(double btc) => (btc * satsPerBtc).toInt();

  /// Format satoshis as BTC string with specified decimal places
  static String formatAsBtc(int sats, {int decimals = 8}) {
    return satsToBtc(sats).toStringAsFixed(decimals);
  }
}
