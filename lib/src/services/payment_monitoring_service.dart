import 'dart:async';

import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
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

  // Tracking for detecting missed payments
  BigInt? _lastKnownBalance;
  Set<String> _knownTxIds = {};
  int? _pausedAtTimestamp;

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

  /// Store the current state before the app goes to background
  Future<void> _storeCurrentBalance() async {
    try {
      final balanceResult = await balance();
      _lastKnownBalance = balanceResult.offchain.totalSats;

      // Store current timestamp
      _pausedAtTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Store known transaction IDs
      final transactions = await txHistory();
      _knownTxIds = transactions.map((tx) {
        return tx.map(
          boarding: (t) => t.txid,
          round: (t) => t.txid,
          redeem: (t) => t.txid,
          offboard: (t) => t.txid,
        );
      }).toSet();

      logger.i(
          "Stored state before pause: balance=$_lastKnownBalance sats, ${_knownTxIds.length} known txs");
    } catch (e) {
      logger.e("Error storing state before pause: $e");
    }
  }

  /// Check if any payments were received while the app was backgrounded
  Future<void> _checkForMissedPayments() async {
    if (_lastKnownBalance == null) return;

    try {
      // Small delay to allow state to update after app resume
      await Future.delayed(const Duration(milliseconds: 800));

      // First check if balance increased
      final balanceResult = await balance();
      final currentBalance = balanceResult.offchain.totalSats;
      final previousBalance = _lastKnownBalance!;

      logger.i(
          "Checking for missed payments - Previous: $previousBalance, Current: $currentBalance");

      if (currentBalance <= previousBalance) {
        // No balance increase, update state and return
        _lastKnownBalance = currentBalance;
        return;
      }

      // Balance increased - find the new incoming transaction(s)
      final transactions = await txHistory();
      PaymentReceived? missedPayment;

      for (final tx in transactions) {
        final txid = tx.map(
          boarding: (t) => t.txid,
          round: (t) => t.txid,
          redeem: (t) => t.txid,
          offboard: (t) => t.txid,
        );

        // Skip if we already knew about this transaction
        if (_knownTxIds.contains(txid)) continue;

        // Check if this is an incoming transaction
        final isIncoming = tx.map(
          boarding: (t) => true, // Boarding is always incoming
          round: (t) => t.amountSats > 0, // Positive round = incoming
          redeem: (t) => t.amountSats > 0, // Positive redeem = incoming
          offboard: (t) => false, // Offboard is always outgoing
        );

        if (!isIncoming) continue;

        // Get the amount
        final amountSats = tx.map(
          boarding: (t) => t.amountSats,
          round: (t) => BigInt.from(t.amountSats),
          redeem: (t) => BigInt.from(t.amountSats),
          offboard: (t) => BigInt.zero,
        );

        // Check timestamp if available (prefer newer transactions)
        final txTimestamp = tx.map(
          boarding: (t) => t.confirmedAt,
          round: (t) => t.createdAt,
          redeem: (t) => t.createdAt,
          offboard: (t) => t.confirmedAt,
        );

        // If we have a timestamp and it's before we paused, skip
        if (txTimestamp != null &&
            _pausedAtTimestamp != null &&
            txTimestamp < _pausedAtTimestamp!) {
          continue;
        }

        logger.i("Found missed incoming tx: $txid, amount: $amountSats sats");

        missedPayment = PaymentReceived(
          txid: txid,
          amountSats: amountSats,
        );

        // Only show the first (most recent) missed payment
        break;
      }

      if (missedPayment != null) {
        logger.i(
            "Showing notification for missed payment: ${missedPayment.amountSats} sats");

        // Emit to stream
        _paymentController.add(missedPayment);

        // Show overlay with delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          _showPaymentOverlay(missedPayment!);
        });

        // Trigger wallet refresh
        onWalletRefreshNeeded?.call();
      }

      // Update stored state
      _lastKnownBalance = currentBalance;
      _knownTxIds = transactions.map((tx) {
        return tx.map(
          boarding: (t) => t.txid,
          round: (t) => t.txid,
          redeem: (t) => t.txid,
          offboard: (t) => t.txid,
        );
      }).toSet();
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

    // Use global navigator key to get context - works from any screen
    final context = OverlayService.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      logger.w("Cannot show payment overlay - no valid context");
      return;
    }

    // Use post frame callback to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-check context is still valid after the frame
      final ctx = OverlayService.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        logger.w("Context became invalid before showing overlay");
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
        logger.e("Error showing payment overlay: $e");
      }
    });
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
