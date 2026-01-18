import 'dart:async';

import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:flutter/material.dart';

/// Service responsible for monitoring pending onchain transactions and
/// triggering wallet refresh when they become confirmed.
///
/// This service polls for transaction status updates in the background,
/// similar to how SwapMonitoringService monitors swap confirmations.
///
/// Usage:
/// ```dart
/// // Initialize in BottomNav:
/// OnchainMonitoringService().initialize(
///   onWalletRefresh: () => walletKey.currentState?.fetchWalletData(),
/// );
/// ```
class OnchainMonitoringService extends ChangeNotifier
    with WidgetsBindingObserver {
  // Singleton instance
  static final OnchainMonitoringService _instance =
      OnchainMonitoringService._internal();
  factory OnchainMonitoringService() => _instance;
  OnchainMonitoringService._internal();

  // Monitoring state
  Timer? _pollTimer;
  bool _isMonitoring = false;
  bool _isInitialized = false;

  // Callback for wallet refresh
  VoidCallback? onWalletRefreshNeeded;

  // Poll interval - 10 seconds (onchain is slower than swaps)
  static const int _pollIntervalSeconds = 10;

  // Track pending transaction IDs to detect when they confirm
  final Set<String> _pendingTxIds = {};

  /// Whether the service is currently monitoring
  bool get isMonitoring => _isMonitoring;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the onchain monitoring service.
  /// Call this once after the wallet is loaded.
  Future<void> initialize({
    VoidCallback? onWalletRefresh,
  }) async {
    if (_isInitialized) {
      logger.d("[OnchainMonitor] Already initialized");
      return;
    }

    onWalletRefreshNeeded = onWalletRefresh;

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    _isInitialized = true;
    logger.i("[OnchainMonitor] Initialized");

    // Check for any existing pending transactions and start monitoring if needed
    await _checkForPendingTransactions();
  }

  /// Update the wallet refresh callback.
  void setWalletRefreshCallback(VoidCallback? callback) {
    onWalletRefreshNeeded = callback;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check for updates immediately
        logger.d("[OnchainMonitor] App resumed, checking transactions");
        _checkForPendingTransactions();
        break;
      case AppLifecycleState.paused:
        // App went to background - stop polling to save battery
        logger.d("[OnchainMonitor] App paused, stopping polling");
        _stopMonitoring();
        break;
      default:
        break;
    }
  }

  /// Check for pending transactions and start/stop monitoring as needed.
  Future<void> _checkForPendingTransactions() async {
    try {
      final transactions = await ark_api.txHistory();

      // Find all pending transactions (no confirmedAt)
      final Set<String> currentPendingIds = {};

      for (final tx in transactions) {
        tx.map(
          boarding: (boarding) {
            if (boarding.confirmedAt == null && boarding.txid != null) {
              currentPendingIds.add(boarding.txid!);
            }
          },
          round: (_) {
            // Round transactions are always confirmed (instant)
          },
          redeem: (_) {
            // Redeem transactions are handled differently
          },
          offboard: (offboard) {
            if (offboard.confirmedAt == null && offboard.txid != null) {
              currentPendingIds.add(offboard.txid!);
            }
          },
        );
      }

      // Check if any previously pending transactions are now confirmed
      final confirmedIds = _pendingTxIds.difference(currentPendingIds);
      if (confirmedIds.isNotEmpty) {
        logger.i(
            "[OnchainMonitor] ${confirmedIds.length} transaction(s) confirmed: $confirmedIds");

        // Trigger wallet refresh to update UI
        onWalletRefreshNeeded?.call();
      }

      // Update our tracking set
      _pendingTxIds.clear();
      _pendingTxIds.addAll(currentPendingIds);

      // Start or stop monitoring based on whether we have pending transactions
      if (currentPendingIds.isNotEmpty) {
        logger.d(
            "[OnchainMonitor] ${currentPendingIds.length} pending transaction(s), starting monitoring");
        _startMonitoring();
      } else {
        logger
            .d("[OnchainMonitor] No pending transactions, stopping monitoring");
        _stopMonitoring();
      }
    } catch (e) {
      logger.w("[OnchainMonitor] Error checking transactions: $e");
    }
  }

  /// Start polling for transaction updates.
  void _startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    logger.i(
        "[OnchainMonitor] Starting polling (every ${_pollIntervalSeconds}s)");

    // Start periodic polling
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: _pollIntervalSeconds),
      (_) => _checkForPendingTransactions(),
    );
  }

  /// Stop polling.
  void _stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    logger.d("[OnchainMonitor] Stopped polling");
  }

  /// Manually trigger a check for pending transactions.
  /// Useful when user initiates a transaction.
  Future<void> checkNow() async {
    logger.d("[OnchainMonitor] Manual check triggered");
    await _checkForPendingTransactions();
  }

  /// Dispose the service.
  @override
  void dispose() {
    _stopMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
