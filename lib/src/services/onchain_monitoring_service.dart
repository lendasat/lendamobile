import 'dart:async';

import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
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

  // Track pending transactions with their amounts to detect when they confirm
  // Key: txid, Value: amount in sats
  final Map<String, BigInt> _pendingTransactions = {};

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

      // Find all pending boarding transactions (incoming onchain payments)
      // We track boarding separately because we want to show bottom sheet for incoming
      final Map<String, BigInt> currentPendingBoarding = {};
      final Set<String> currentPendingOffboard = {};

      for (final tx in transactions) {
        tx.map(
          boarding: (boarding) {
            if (boarding.confirmedAt == null && boarding.txid != null) {
              // Track pending boarding with amount
              currentPendingBoarding[boarding.txid!] = boarding.amountSats;
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
              currentPendingOffboard.add(offboard.txid!);
            }
          },
        );
      }

      // Check if any previously pending BOARDING transactions are now confirmed
      // These are incoming payments - show bottom sheet!
      final confirmedBoardingIds = _pendingTransactions.keys
          .where((txid) => !currentPendingBoarding.containsKey(txid))
          .toList();

      if (confirmedBoardingIds.isNotEmpty) {
        logger.i(
            "[OnchainMonitor] ${confirmedBoardingIds.length} boarding transaction(s) confirmed: $confirmedBoardingIds");

        // Show bottom sheet for each confirmed boarding transaction
        for (final txid in confirmedBoardingIds) {
          final amountSats = _pendingTransactions[txid];
          if (amountSats != null && amountSats > BigInt.zero) {
            _showPaymentReceivedBottomSheet(txid, amountSats);
          }
        }

        // Trigger wallet refresh to update UI
        onWalletRefreshNeeded?.call();
      }

      // Update our tracking map for boarding transactions
      _pendingTransactions.clear();
      _pendingTransactions.addAll(currentPendingBoarding);

      // Start or stop monitoring based on whether we have pending transactions
      final hasPending = currentPendingBoarding.isNotEmpty ||
          currentPendingOffboard.isNotEmpty;
      if (hasPending) {
        logger.d(
            "[OnchainMonitor] ${currentPendingBoarding.length} pending boarding, ${currentPendingOffboard.length} pending offboard, monitoring");
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

  /// Show payment received bottom sheet for confirmed onchain payment
  void _showPaymentReceivedBottomSheet(String txid, BigInt amountSats) {
    final overlayService = PaymentOverlayService();

    // Check if notifications are suppressed (e.g., during swap)
    if (overlayService.suppressPaymentNotifications) {
      logger.i("[OnchainMonitor] Payment notification suppressed for $txid");
      return;
    }

    // Use global navigator key to get context - works from any screen
    final context = OverlayService.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      logger
          .w("[OnchainMonitor] Cannot show payment overlay - no valid context");
      return;
    }

    // Create a PaymentReceived object for the overlay service
    final payment = ark_api.PaymentReceived(
      txid: txid,
      amountSats: amountSats,
    );

    logger.i(
        "[OnchainMonitor] Showing payment received bottom sheet for $amountSats sats (txid: $txid)");

    // Use post frame callback to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = OverlayService.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        logger.w(
            "[OnchainMonitor] Context became invalid before showing overlay");
        return;
      }

      try {
        overlayService.showPaymentReceivedBottomSheet(
          context: ctx,
          payment: payment,
          bitcoinPrice: BitcoinPriceCache.currentPrice,
          onDismiss: () {
            onWalletRefreshNeeded?.call();
          },
        );
      } catch (e) {
        logger.e("[OnchainMonitor] Error showing payment overlay: $e");
      }
    });
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
      (_) => _safeCheckForPendingTransactions(),
    );
  }

  /// Safe wrapper for _checkForPendingTransactions that catches all exceptions.
  /// This ensures the Timer doesn't cause issues if an unexpected error occurs.
  Future<void> _safeCheckForPendingTransactions() async {
    try {
      await _checkForPendingTransactions();
    } catch (e, stackTrace) {
      logger.e(
          "[OnchainMonitor] Unexpected error in polling callback: $e\n$stackTrace");
    }
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
