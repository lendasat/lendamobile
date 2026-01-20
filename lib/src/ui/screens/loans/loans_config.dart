/// Configuration constants for the loans screen.
abstract final class LoansConfig {
  /// Auto-refresh interval for active contracts (seconds)
  static const int autoRefreshIntervalSeconds = 30;

  /// Retry delay when initial data is empty (ms)
  static const int retryDelayMs = 500;

  /// Keyboard debounce delay (ms)
  static const int keyboardDebounceMs = 100;

  /// Sticky header height with search bar
  static const double headerHeight = 112.0;

  /// Filter bottom sheet height ratio
  static const double filterSheetHeightRatio = 0.6;

  /// Scroll to top animation duration (ms)
  static const int scrollToTopDurationMs = 300;

  /// Default invite code for registration
  static const String defaultInviteCode = 'LAS-651K4';
}
