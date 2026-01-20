/// Configuration constants for contract detail screen.
abstract final class ContractDetailConfig {
  /// Polling interval for contract status updates (seconds)
  static const int pollingIntervalSeconds = 3;

  /// Duration to show copy feedback (seconds)
  static const int copyFeedbackSeconds = 3;

  /// Delay before stopping payment suppression (seconds)
  static const int paymentSuppressionDelaySeconds = 5;

  /// Discord support URL
  static const String discordSupportUrl =
      'https://discord.com/invite/a5MP7yZDpQ';
}
