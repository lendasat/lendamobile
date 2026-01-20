import 'package:ark_flutter/src/constants/bitcoin_constants.dart';

/// Configuration constants for swap functionality.
abstract final class SwapConfig {
  // Amount limits
  static const int minSwapSats = 1000;
  static const int maxSwapSats = 100000000; // 1 BTC

  // Thresholds for unit switching
  static const double btcToSatsThreshold = 0.001; // Below this, show sats
  static const double satsToBtcThreshold = 100000000; // At 1 BTC, show BTC

  // Default prices (fallbacks)
  static const double defaultBtcPrice = 104000.0;
  static const double defaultXautPrice = 2650.0; // 1 oz gold

  // Fee defaults (when quote unavailable)
  static const double defaultProtocolFeePercent = 0.5;
  static const int defaultNetworkFeeSats = 250;

  // Debounce duration for quote fetching (ms)
  static const int quoteDebounceMs = 300;

  /// Convert BTC to sats
  static int btcToSats(double btc) =>
      (btc * BitcoinConstants.satsPerBtc).round();

  /// Convert sats to BTC
  static double satsToBtc(int sats) => sats / BitcoinConstants.satsPerBtc;

  /// Check if amount meets minimum
  static bool meetsMinimum(int sats) => sats >= minSwapSats;

  /// Estimate total sats required including fees
  static int estimateTotalRequired(int inputSats,
      {double? protocolFeePercent, int? networkFeeSats}) {
    final protocol = protocolFeePercent ?? defaultProtocolFeePercent;
    final network = networkFeeSats ?? defaultNetworkFeeSats;
    return inputSats + (inputSats * protocol / 100).round() + network;
  }
}
