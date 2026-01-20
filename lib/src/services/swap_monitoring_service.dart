import 'dart:async';

import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:flutter/material.dart';

/// Event emitted when a swap is auto-claimed.
class SwapClaimEvent {
  final String swapId;
  final ClaimType type;
  final bool success;
  final String? errorMessage;
  final double? amountUsd;

  SwapClaimEvent({
    required this.swapId,
    required this.type,
    required this.success,
    this.errorMessage,
    this.amountUsd,
  });
}

enum ClaimType { gelato, vhtlc }

/// Service responsible for monitoring swaps and auto-claiming when ready.
///
/// This service:
/// - Polls for swap status updates in the background
/// - Automatically claims swaps when they become claimable
/// - Handles app lifecycle (pause/resume) automatically
/// - Shows notifications when swaps are claimed
///
/// Usage:
/// ```dart
/// // Initialize in BottomNav or MyApp:
/// SwapMonitoringService().initialize(context: context);
///
/// // Listen to claim events:
/// SwapMonitoringService().claimEvents.listen((event) {
///   // Handle claim event
/// });
/// ```
class SwapMonitoringService extends ChangeNotifier with WidgetsBindingObserver {
  // Singleton instance
  static final SwapMonitoringService _instance =
      SwapMonitoringService._internal();
  factory SwapMonitoringService() => _instance;
  SwapMonitoringService._internal();

  // Dependencies
  final LendaSwapService _swapService = LendaSwapService();

  // Stream controller for claim events
  final _claimEventController = StreamController<SwapClaimEvent>.broadcast();

  /// Stream of claim events. Subscribe to receive notifications when swaps are claimed.
  Stream<SwapClaimEvent> get claimEvents => _claimEventController.stream;

  // Monitoring state
  Timer? _pollTimer;
  Timer? _delayedRefreshTimer;
  bool _isMonitoring = false;
  bool _isInitialized = false;

  // Track swaps currently being claimed to prevent duplicate claims
  final Set<String> _claimingSwapIds = {};

  // Track swaps that have been claimed to avoid re-processing
  final Set<String> _claimedSwapIds = {};

  // Context for showing overlays
  BuildContext? _overlayContext;

  // Callback for wallet refresh (set by BottomNav or other parent widget)
  VoidCallback? onWalletRefreshNeeded;

  // Poll interval - faster polling when actively monitoring pending swaps
  static const int _pollIntervalSeconds = 5;

  // Track swap IDs that we're actively monitoring
  final Set<String> _pendingSwapIds = {};

  /// Whether the service is currently monitoring
  bool get isMonitoring => _isMonitoring;

  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the swap monitoring service.
  /// Call this once after the wallet is loaded.
  Future<void> initialize({
    required BuildContext context,
    VoidCallback? onWalletRefresh,
  }) async {
    if (_isInitialized) {
      logger.d("[SwapMonitor] Already initialized");
      return;
    }

    _overlayContext = context;
    onWalletRefreshNeeded = onWalletRefresh;

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    _isInitialized = true;
    logger.i("[SwapMonitor] Initialized");

    // Initialize LendaSwapService if needed
    if (!_swapService.isInitialized) {
      try {
        await _swapService.initialize();
        logger.i("[SwapMonitor] LendaSwapService initialized");
      } catch (e) {
        logger.w("[SwapMonitor] Failed to initialize LendaSwapService: $e");
        return;
      }
    }

    // Check for any existing pending swaps and start monitoring if needed
    await _checkForPendingSwaps();
  }

  /// Start monitoring a specific swap (call this when a new swap is created)
  void startMonitoringSwap(String swapId) {
    logger.i("[SwapMonitor] Starting to monitor swap: $swapId");
    _pendingSwapIds.add(swapId);
    _startMonitoring();
  }

  /// Update the context used for showing overlays.
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
        logger.i("[SwapMonitor] App resumed");
        // Check for pending swaps and start monitoring if needed
        _checkForPendingSwaps();
        break;
      case AppLifecycleState.paused:
        logger.i("[SwapMonitor] App paused, stopping monitoring");
        _stopMonitoring();
        break;
      default:
        break;
    }
  }

  /// Check if there are any pending swaps that need monitoring
  Future<void> _checkForPendingSwaps() async {
    if (!_swapService.isInitialized) return;

    try {
      await _swapService.refreshSwaps();
      final swaps = _swapService.swaps;

      // Find pending/processing swaps
      _pendingSwapIds.clear();
      for (final swap in swaps) {
        if (swap.status == SwapStatusSimple.waitingForDeposit ||
            swap.status == SwapStatusSimple.processing) {
          _pendingSwapIds.add(swap.id);
        }
      }

      if (_pendingSwapIds.isNotEmpty) {
        logger.i(
            "[SwapMonitor] Found ${_pendingSwapIds.length} pending swaps, starting monitoring");
        _startMonitoring();
      } else {
        logger.d("[SwapMonitor] No pending swaps, not starting monitoring");
        _stopMonitoring();
      }
    } catch (e) {
      logger.w("[SwapMonitor] Failed to check for pending swaps: $e");
    }
  }

  Future<void> _startMonitoring() async {
    if (_isMonitoring) return;
    if (_pendingSwapIds.isEmpty) {
      logger.d("[SwapMonitor] No pending swaps to monitor");
      return;
    }

    // Try to initialize LendaSwapService if not already done
    if (!_swapService.isInitialized) {
      try {
        await _swapService.initialize();
        logger.i(
            "[SwapMonitor] LendaSwapService initialized in _startMonitoring");
      } catch (e) {
        logger.d("[SwapMonitor] SwapService not initialized, skipping: $e");
        return;
      }
    }

    _isMonitoring = true;
    notifyListeners();

    // Check immediately
    _checkAndClaimSwaps();

    // Start periodic polling (every 5 seconds for pending swaps)
    _pollTimer = Timer.periodic(
      Duration(seconds: _pollIntervalSeconds),
      (_) => _checkAndClaimSwaps(),
    );

    logger.i(
        "[SwapMonitor] Started monitoring ${_pendingSwapIds.length} swaps (interval: ${_pollIntervalSeconds}s)");
  }

  void _stopMonitoring() {
    if (!_isMonitoring) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _isMonitoring = false;
    notifyListeners();
    logger.i("[SwapMonitor] Stopped monitoring");
  }

  Future<void> _checkAndClaimSwaps() async {
    if (!_swapService.isInitialized) return;

    try {
      // Refresh swap list from server
      await _swapService.refreshSwaps();

      final swaps = _swapService.swaps;
      logger.d(
          "[SwapMonitor] Checking ${swaps.length} swaps, monitoring ${_pendingSwapIds.length} pending");

      // Update pending swap IDs - remove completed ones, add new pending ones
      final stillPending = <String>{};

      for (final swap in swaps) {
        // Skip if currently claiming
        if (_claimingSwapIds.contains(swap.id)) {
          stillPending.add(swap.id);
          continue;
        }

        // Check if a swap just completed
        if (swap.status == SwapStatusSimple.completed) {
          if (_pendingSwapIds.contains(swap.id)) {
            logger.i("[SwapMonitor] Swap ${swap.id} has completed!");
            _claimedSwapIds.add(swap.id);
          }
          continue;
        }

        // Track pending/processing swaps
        if (swap.status == SwapStatusSimple.waitingForDeposit ||
            swap.status == SwapStatusSimple.processing) {
          stillPending.add(swap.id);
        }

        // Skip if already processed
        if (_claimedSwapIds.contains(swap.id)) continue;

        // BTC → Polygon: Auto-claim via Gelato (gasless)
        if (swap.canClaimGelato) {
          // Check if this is a Polygon target (gasless) or Ethereum (requires gas)
          final isPolygonTarget = _isPolygonTarget(swap);

          if (isPolygonTarget) {
            logger.i(
                "[SwapMonitor] Found claimable BTC→Polygon swap: ${swap.id}");
            await _claimGelato(swap);
          } else {
            // Ethereum targets require WalletConnect - can't auto-claim
            logger.i(
                "[SwapMonitor] Swap ${swap.id} requires manual claim (Ethereum target)");
          }
        }

        // EVM → BTC: Auto-claim VHTLC
        if (swap.canClaimVhtlc) {
          logger.i("[SwapMonitor] Found claimable EVM→BTC swap: ${swap.id}");
          await _claimVhtlc(swap);
        }
      }

      // Update pending set
      _pendingSwapIds.clear();
      _pendingSwapIds.addAll(stillPending);

      // Stop monitoring if no more pending swaps
      if (_pendingSwapIds.isEmpty && _isMonitoring) {
        logger.i("[SwapMonitor] All swaps completed, stopping monitoring");
        _stopMonitoring();
      }
    } catch (e) {
      logger.e("[SwapMonitor] Error checking swaps: $e");
    }
  }

  bool _isPolygonTarget(SwapInfo swap) {
    // BTC→EVM swaps have targetToken set to the EVM token
    final targetTokenId = swap.targetToken.toLowerCase();
    return targetTokenId.contains('pol') || targetTokenId.contains('polygon');
  }

  Future<void> _claimGelato(SwapInfo swap) async {
    _claimingSwapIds.add(swap.id);

    try {
      logger.i("[SwapMonitor] Auto-claiming swap ${swap.id} via Gelato");
      await _swapService.claimGelato(swap.id);

      logger.i("[SwapMonitor] Successfully claimed swap ${swap.id} via Gelato");
      _claimedSwapIds.add(swap.id);

      // Track swap transaction for analytics (BTC → EVM)
      await AnalyticsService().trackSwapTransaction(
        amountSats: swap.sourceAmountSats.toInt(),
        fromAsset: swap.sourceToken,
        toAsset: swap.targetToken,
        swapId: swap.id,
      );

      // Emit event
      _claimEventController.add(SwapClaimEvent(
        swapId: swap.id,
        type: ClaimType.gelato,
        success: true,
        amountUsd: swap.targetAmountUsd,
      ));

      // Show success notification
      _showClaimSuccessNotification(swap, ClaimType.gelato);

      // Trigger wallet refresh immediately
      onWalletRefreshNeeded?.call();

      // Schedule a delayed refresh to catch the updated swap status
      // (server may take a moment to update after claim transaction)
      _scheduleDelayedRefresh();
    } catch (e) {
      logger.e("[SwapMonitor] Failed to auto-claim via Gelato: $e");

      _claimEventController.add(SwapClaimEvent(
        swapId: swap.id,
        type: ClaimType.gelato,
        success: false,
        errorMessage: e.toString(),
      ));
    } finally {
      _claimingSwapIds.remove(swap.id);
    }
  }

  Future<void> _claimVhtlc(SwapInfo swap) async {
    _claimingSwapIds.add(swap.id);

    try {
      logger.i("[SwapMonitor] Auto-claiming swap ${swap.id} via VHTLC");
      final txid = await _swapService.claimVhtlc(swap.id);

      logger.i(
          "[SwapMonitor] Successfully claimed swap ${swap.id} via VHTLC, txid: $txid");
      _claimedSwapIds.add(swap.id);

      // Track swap transaction for analytics (EVM → BTC)
      await AnalyticsService().trackSwapTransaction(
        amountSats: swap.sourceAmountSats.toInt(),
        fromAsset: swap.sourceToken,
        toAsset: swap.targetToken,
        swapId: swap.id,
      );

      // Emit event
      _claimEventController.add(SwapClaimEvent(
        swapId: swap.id,
        type: ClaimType.vhtlc,
        success: true,
        amountUsd: swap.targetAmountUsd,
      ));

      // Show success notification
      _showClaimSuccessNotification(swap, ClaimType.vhtlc);

      // Trigger wallet refresh immediately
      onWalletRefreshNeeded?.call();

      // Schedule a delayed refresh to catch the updated swap status
      // (server may take a moment to update after claim transaction)
      _scheduleDelayedRefresh();
    } catch (e) {
      logger.e("[SwapMonitor] Failed to auto-claim VHTLC: $e");

      _claimEventController.add(SwapClaimEvent(
        swapId: swap.id,
        type: ClaimType.vhtlc,
        success: false,
        errorMessage: e.toString(),
      ));
    } finally {
      _claimingSwapIds.remove(swap.id);
    }
  }

  void _showClaimSuccessNotification(SwapInfo swap, ClaimType type) {
    if (_overlayContext == null || !_overlayContext!.mounted) {
      logger.w("[SwapMonitor] Cannot show notification - no valid context");
      return;
    }

    final overlayService = PaymentOverlayService();

    // For EVM→BTC swaps, suppress payment notifications to avoid showing both
    // "Payment Received" and "Swap Complete" bottom sheets
    if (swap.direction == 'evm_to_btc') {
      overlayService.startSuppression();
      // Stop suppression after 5 seconds to allow future payment notifications
      Future.delayed(const Duration(seconds: 5), () {
        overlayService.stopSuppression();
      });
    }

    // Show bottom sheet if user is not viewing this swap's screen
    if (!overlayService.isSwapCurrentlyViewed(swap.id)) {
      overlayService.showSwapCompletedBottomSheet(
        context: _overlayContext!,
        swap: swap,
      );
    } else {
      // User is viewing the swap screen - just show a simple toast
      final amount = swap.direction == 'btc_to_evm'
          ? '\$${swap.targetAmountUsd.toStringAsFixed(2)}'
          : '${(swap.sourceAmountSats.toInt() / 100000000).toStringAsFixed(8)} BTC';
      OverlayService().showSuccess('Swap completed! Received $amount');
    }
  }

  /// Schedule a delayed wallet refresh after a claim.
  /// This gives the server time to update the swap status before we refresh.
  void _scheduleDelayedRefresh() {
    _delayedRefreshTimer?.cancel();
    _delayedRefreshTimer = Timer(const Duration(seconds: 3), () {
      logger.d("[SwapMonitor] Triggering delayed wallet refresh after claim");
      onWalletRefreshNeeded?.call();
    });
  }

  /// Manually trigger a check for claimable swaps.
  Future<void> checkNow() async {
    await _checkAndClaimSwaps();
  }

  /// Attempt to claim a specific swap immediately.
  /// Returns true if claim was initiated, false if not claimable or already claiming.
  /// For Ethereum targets, returns false (requires WalletConnect UI).
  Future<bool> claimSwapIfReady(SwapInfo swap) async {
    // Skip if already claimed or currently claiming
    if (_claimedSwapIds.contains(swap.id)) return false;
    if (_claimingSwapIds.contains(swap.id)) return false;

    // BTC → Polygon: Auto-claim via Gelato (gasless)
    if (swap.canClaimGelato) {
      final isPolygonTarget = _isPolygonTarget(swap);
      if (isPolygonTarget) {
        await _claimGelato(swap);
        return true;
      }
      // Ethereum targets require WalletConnect - return false
      return false;
    }

    // EVM → BTC: Auto-claim VHTLC
    if (swap.canClaimVhtlc) {
      await _claimVhtlc(swap);
      return true;
    }

    return false;
  }

  /// Check if a swap is currently being claimed.
  bool isClaimingSwap(String swapId) => _claimingSwapIds.contains(swapId);

  /// Check if a swap requires WalletConnect (Ethereum target).
  bool requiresWalletConnect(SwapInfo swap) {
    if (!swap.canClaimGelato) return false;
    return !_isPolygonTarget(swap);
  }

  /// Clear the claimed swaps cache (useful after wallet reset).
  void clearCache() {
    _claimedSwapIds.clear();
    _claimingSwapIds.clear();
    _pendingSwapIds.clear();
    _stopMonitoring();
    logger.i("[SwapMonitor] Cache cleared");
  }

  /// Stop monitoring and clean up resources.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
    _delayedRefreshTimer?.cancel();
    _claimEventController.close();
    super.dispose();
  }
}
