import 'dart:async';

import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:flutter/material.dart';

/// Service responsible for monitoring incoming payments globally.
///
/// This service:
/// - Monitors for incoming payments using the Ark waitForPayment API
/// - Handles app lifecycle (pause/resume) automatically
/// - Detects payments received while the app was backgrounded
/// - Emits payment events via a stream for UI components to listen to
/// - Integrates with PaymentOverlayService for notifications
///
/// Usage:
/// ```dart
/// // In a widget, listen to payment events:
/// context.read<PaymentMonitoringService>().paymentStream.listen((payment) {
///   // Handle payment received
/// });
/// ```
class PaymentMonitoringService extends ChangeNotifier
    with WidgetsBindingObserver {
  // Singleton instance
  static final PaymentMonitoringService _instance =
      PaymentMonitoringService._internal();
  factory PaymentMonitoringService() => _instance;
  PaymentMonitoringService._internal();

  // Stream controller for payment events
  final _paymentController = StreamController<PaymentReceived>.broadcast();

  /// Stream of incoming payments. Subscribe to receive payment notifications.
  Stream<PaymentReceived> get paymentStream => _paymentController.stream;

  // Monitoring state
  bool _isMonitoringPayments = false;
  bool _isInitialized = false;
  String? _arkAddress;
  String? _boardingAddress;

  // Balance tracking for detecting missed payments
  BigInt? _lastKnownBalance;

  // Callback for wallet refresh (set by BottomNav or other parent widget)
  VoidCallback? onWalletRefreshNeeded;

  // Callback for switching to wallet tab (set by BottomNav)
  VoidCallback? onSwitchToWalletTab;

  // Context for showing overlays (set when starting monitoring)
  BuildContext? _overlayContext;

  /// Whether the service is currently monitoring for payments
  bool get isMonitoring => _isMonitoringPayments;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the payment monitoring service.
  /// Call this once after the wallet is loaded.
  Future<void> initialize({
    required BuildContext context,
    VoidCallback? onWalletRefresh,
  }) async {
    if (_isInitialized) {
      logger.d("PaymentMonitoringService already initialized");
      return;
    }

    _overlayContext = context;
    onWalletRefreshNeeded = onWalletRefresh;

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    try {
      // Get wallet addresses for monitoring
      final addresses = await address();
      _arkAddress = addresses.offchain;
      _boardingAddress = addresses.boarding;

      logger.i("PaymentMonitoringService initialized");
      logger.i("Ark address: $_arkAddress");
      logger.i("Boarding address: $_boardingAddress");

      _isInitialized = true;

      // Start monitoring
      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error initializing PaymentMonitoringService: $e");
    }
  }

  /// Update the context used for showing overlays.
  /// Call this if the context changes (e.g., after navigation).
  void updateContext(BuildContext context) {
    _overlayContext = context;
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
        logger.i("App resumed, restarting payment monitoring");
        _checkForMissedPayments();
        _restartPaymentMonitoring();
        break;
      case AppLifecycleState.paused:
        logger.i("App paused, storing balance and stopping monitoring");
        _storeCurrentBalance();
        _stopPaymentMonitoring();
        break;
      default:
        break;
    }
  }

  /// Store the current balance before the app goes to background
  Future<void> _storeCurrentBalance() async {
    try {
      final balanceResult = await balance();
      _lastKnownBalance = balanceResult.offchain.totalSats;
      logger.i("Stored balance before pause: $_lastKnownBalance sats");
    } catch (e) {
      logger.e("Error storing balance before pause: $e");
    }
  }

  /// Check if any payments were received while the app was backgrounded
  Future<void> _checkForMissedPayments() async {
    if (_lastKnownBalance == null) return;

    try {
      final balanceResult = await balance();
      final currentBalance = balanceResult.offchain.totalSats;
      final previousBalance = _lastKnownBalance!;

      logger.i(
          "Checking for missed payments - Previous: $previousBalance, Current: $currentBalance");

      if (currentBalance > previousBalance) {
        final difference = currentBalance - previousBalance;
        logger.i("Balance increased by $difference sats while backgrounded!");

        // Get the latest transaction to show in the overlay
        final transactions = await txHistory();
        if (transactions.isNotEmpty) {
          // Find the most recent incoming transaction
          for (final tx in transactions) {
            final BigInt txAmount = tx.map(
              boarding: (t) => t.amountSats,
              round: (t) => t.amountSats,
              redeem: (t) => t.amountSats,
              offboard: (t) => BigInt.from(t.amountSats),
            ) as BigInt;

            final txid = tx.map(
              boarding: (t) => t.txid,
              round: (t) => t.txid,
              redeem: (t) => t.txid,
              offboard: (t) => t.txid,
            );

            // Check if this is a positive (incoming) transaction
            if (txAmount > BigInt.zero) {
              final payment = PaymentReceived(
                txid: txid,
                amountSats: txAmount,
              );

              // Emit to stream
              _paymentController.add(payment);

              // Show overlay if not suppressed
              _showPaymentOverlay(payment);

              break; // Only handle the most recent incoming tx
            }
          }
        }

        // Trigger wallet refresh
        onWalletRefreshNeeded?.call();
      }

      // Update the last known balance
      _lastKnownBalance = currentBalance;
    } catch (e) {
      logger.e("Error checking for missed payments: $e");
    }
  }

  Future<void> _restartPaymentMonitoring() async {
    if (_arkAddress == null && _boardingAddress == null) {
      // Re-initialize if addresses are not set
      if (_overlayContext != null) {
        await initialize(
          context: _overlayContext!,
          onWalletRefresh: onWalletRefreshNeeded,
        );
      }
    } else {
      await Future.delayed(AppTimeouts.quoteDebounce);
      _startPaymentMonitoring();
    }
  }

  Future<void> _startPaymentMonitoring() async {
    if (_isMonitoringPayments) return;
    if (_arkAddress == null && _boardingAddress == null) return;

    _isMonitoringPayments = true;
    notifyListeners();

    while (_isMonitoringPayments) {
      try {
        logger.d("Waiting for payment...");

        final payment = await waitForPayment(
          arkAddress: _arkAddress,
          boardingAddress: _boardingAddress,
          timeoutSeconds: BigInt.from(300), // 5 minute timeout
        );

        if (!_isMonitoringPayments) return;

        logger.i(
            "Payment received! TXID: ${payment.txid}, Amount: ${payment.amountSats} sats");

        // Emit to stream
        _paymentController.add(payment);

        // Show overlay if not suppressed
        _showPaymentOverlay(payment);

        // Trigger wallet refresh
        onWalletRefreshNeeded?.call();

        // Small delay before restarting monitoring
        await Future.delayed(AppTimeouts.shortDelay);
      } catch (e) {
        final errorStr = e.toString().toLowerCase();

        // Expected errors - just restart monitoring
        final isExpectedError = errorStr.contains('timeout') ||
            errorStr.contains('timed out') ||
            errorStr.contains('transport error') ||
            errorStr.contains('connectionaborted') ||
            errorStr.contains('connection aborted') ||
            errorStr.contains('stream ended') ||
            errorStr.contains('h2 protocol error') ||
            errorStr.contains('canceled') ||
            errorStr.contains('cancelled');

        if (!isExpectedError) {
          logger.e("Error in payment monitoring: $e");
        }

        // Small delay before retrying
        await Future.delayed(AppTimeouts.shortDelay);
      }
    }
  }

  void _stopPaymentMonitoring() {
    _isMonitoringPayments = false;
    notifyListeners();
  }

  void _showPaymentOverlay(PaymentReceived payment) {
    final overlayService = PaymentOverlayService();

    // Check if notifications are suppressed
    if (overlayService.suppressPaymentNotifications) {
      logger.i(
          "Payment notification suppressed (likely change from outgoing tx)");
      return;
    }

    // Check if we have a valid context
    if (_overlayContext == null || !_overlayContext!.mounted) {
      logger.w("Cannot show payment overlay - no valid context");
      return;
    }

    overlayService.showPaymentReceivedOverlay(
      context: _overlayContext!,
      payment: payment,
      onDismiss: () {
        onWalletRefreshNeeded?.call();
      },
    );
  }

  /// Manually trigger a wallet refresh.
  /// Useful when other parts of the app detect balance changes.
  void triggerWalletRefresh() {
    onWalletRefreshNeeded?.call();
  }

  /// Switch to the wallet tab.
  /// Useful after completing actions like swaps that should return user to wallet.
  void switchToWalletTab() {
    onSwitchToWalletTab?.call();
  }

  /// Stop monitoring and clean up resources.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPaymentMonitoring();
    _paymentController.close();
    super.dispose();
  }
}
