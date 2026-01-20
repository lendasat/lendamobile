/// Configuration constants for the wallet screen.
abstract final class WalletConfig {
  /// Delay for initial data retry if first fetch appears empty (ms)
  static const int initialRetryDelayMs = 1500;

  /// Keyboard debounce delay (ms)
  static const int keyboardDebounceMs = 100;

  /// Auto-settle cooldown period (minutes)
  static const int autoSettleCooldownMinutes = 5;

  /// Transaction history sticky header height with search
  static const double headerHeightWithSearch = 112.0;

  /// Transaction history sticky header height without search
  static const double headerHeightBasic = 40.0;

  /// Bitcoin chart bottom sheet height ratio
  static const double chartSheetHeightRatio = 0.9;

  /// Settings bottom sheet height ratio
  static const double settingsSheetHeightRatio = 0.85;

  /// Filter bottom sheet height ratio
  static const double filterSheetHeightRatio = 0.7;
}
