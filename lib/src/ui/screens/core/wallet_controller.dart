import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart'
    show PendingTransactionStatus;
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/boarding_tracking_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/pending_transaction_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart'
    show TimeRange;
import 'package:ark_flutter/src/ui/widgets/wallet/balance_chart_calculator.dart'
    show BalanceChartCalculator;
import 'package:ark_flutter/src/ui/widgets/wallet/wallet_mini_chart.dart'
    show WalletChartData;
import 'package:ark_flutter/theme.dart';
import 'wallet_config.dart';
import 'wallet_state.dart';

/// Controller for wallet screen business logic.
class WalletController extends ChangeNotifier {
  final String aspId;
  final LendaSwapService _swapService;
  final LendasatService _lendasatService;
  final PendingTransactionService _pendingTransactionService;

  WalletState _state = WalletState.initial();
  bool _isRefreshing = false;
  BalanceChartCalculator? _chartCalculator;

  WalletController({
    required this.aspId,
    LendaSwapService? swapService,
    LendasatService? lendasatService,
    PendingTransactionService? pendingTransactionService,
  })  : _swapService = swapService ?? LendaSwapService(),
        _lendasatService = lendasatService ?? LendasatService(),
        _pendingTransactionService =
            pendingTransactionService ?? PendingTransactionService() {
    // Listen to swap service changes
    _swapService.addListener(_onSwapsChanged);
    // Listen to pending transaction service
    _pendingTransactionService.addListener(_onPendingTransactionChanged);
  }

  /// Current state.
  WalletState get state => _state;

  /// Chart calculator for performance.
  BalanceChartCalculator? get chartCalculator => _chartCalculator;

  @override
  void dispose() {
    _swapService.removeListener(_onSwapsChanged);
    _pendingTransactionService.removeListener(_onPendingTransactionChanged);
    super.dispose();
  }

  void _onSwapsChanged() {
    _updateState(_state.copyWith(swaps: List.from(_swapService.swaps)));
    logger.d("Swaps updated from service notification");
  }

  void _onPendingTransactionChanged() {
    final hasCompletedTx = _pendingTransactionService.pendingItems.any(
      (item) =>
          item.pending.status == PendingTransactionStatus.success ||
          item.pending.status == PendingTransactionStatus.failed,
    );

    if (hasCompletedTx) {
      logger.i("Pending transaction completed - refreshing wallet data");
      fetchWalletData();
    }

    notifyListeners();
  }

  /// Initialize wallet data.
  Future<void> initialize(UserPreferencesService userPrefs) async {
    await BoardingTrackingService.initialize();
    await loadCachedBalance();
    await fetchWalletData();
    await loadBitcoinPriceData(userPrefs);
    await loadRecoveryStatus();

    // Retry if initial data appears empty
    if (_state.totalBalance == 0 && _state.transactions.isEmpty) {
      logger.i("Initial data appears empty, retrying after delay...");
      await Future.delayed(
          const Duration(milliseconds: WalletConfig.initialRetryDelayMs));
      await fetchWalletData();
    }
  }

  /// Load cached balance for instant display.
  Future<void> loadCachedBalance() async {
    try {
      final cachedBalance = await SettingsService().getCachedBalance();
      if (cachedBalance != null) {
        _updateState(_state.copyWith(
          totalBalance: cachedBalance.total,
          confirmedBalance: cachedBalance.confirmed,
          pendingBalance: cachedBalance.pending,
        ));
        logger.i("Loaded cached balance: ${cachedBalance.total} BTC");
      }
    } catch (e) {
      logger.w("Could not load cached balance: $e");
    }
  }

  /// Load bitcoin price data.
  Future<void> loadBitcoinPriceData(UserPreferencesService userPrefs) async {
    try {
      final timeRange = _convertChartTimeRange(userPrefs.chartTimeRange);
      final priceData = await fetchBitcoinPriceData(timeRange);

      _updateState(_state.copyWith(bitcoinPriceData: priceData));
      _updateGradientColors();

      // Update global price cache
      if (priceData.isNotEmpty) {
        BitcoinPriceCache.updatePrice(priceData.last.price);
      }
    } catch (e) {
      logger.e('Error loading bitcoin price data: $e');
    }
  }

  /// Load word recovery status.
  Future<void> loadRecoveryStatus() async {
    try {
      final wordRecovery = await SettingsService().isWordRecoverySet();
      _updateState(_state.copyWith(wordRecoverySet: wordRecovery));
    } catch (e) {
      logger.e('Error loading recovery status: $e');
    }
  }

  TimeRange _convertChartTimeRange(ChartTimeRange range) {
    switch (range) {
      case ChartTimeRange.day:
        return TimeRange.day;
      case ChartTimeRange.week:
        return TimeRange.week;
      case ChartTimeRange.month:
        return TimeRange.month;
      case ChartTimeRange.year:
        return TimeRange.year;
      case ChartTimeRange.max:
        return TimeRange.max;
    }
  }

  void _updateGradientColors() {
    final isPositive = isPriceChangePositive();
    _updateState(_state.copyWith(
      gradientTopColor: isPositive
          ? AppTheme.successColor.withValues(alpha: 0.3)
          : AppTheme.errorColor.withValues(alpha: 0.3),
      gradientBottomColor: isPositive
          ? AppTheme.successColorGradient.withValues(alpha: 0.15)
          : AppTheme.errorColorGradient.withValues(alpha: 0.15),
    ));
  }

  /// Check if price change is positive.
  bool isPriceChangePositive() {
    if (_state.bitcoinPriceData.isEmpty) return true;
    _updateChartCalculator();
    return _chartCalculator!.isPriceChangePositive(_state.currentBtcPrice);
  }

  void _updateChartCalculator() {
    if (_chartCalculator != null) return;
    _chartCalculator = BalanceChartCalculator(
      transactions: _state.transactions,
      priceData: _state.bitcoinPriceData,
      currentBalance: _state.totalBalance,
    );
  }

  /// Get chart data for display.
  List<WalletChartData> getChartData() {
    if (_state.bitcoinPriceData.isEmpty) return [];
    _updateChartCalculator();
    return _chartCalculator!.getChartData();
  }

  /// Get price change metrics.
  (double, bool, double) getPriceChangeMetrics() {
    if (_state.bitcoinPriceData.isEmpty) return (0.0, true, 0.0);
    _updateChartCalculator();
    return _chartCalculator!
        .calculatePriceChangeMetrics(_state.currentBtcPrice);
  }

  /// Fetch all wallet data.
  Future<void> fetchWalletData() async {
    if (_isRefreshing) {
      logger.d("Skipping refresh - already in progress");
      return;
    }

    _isRefreshing = true;
    _chartCalculator = null;

    try {
      await Future.wait([
        _fetchBalance(),
        _fetchTransactions(),
        _fetchSwaps(),
        _fetchLockedCollateral(),
        _fetchBoardingBalance(),
      ]);

      if (_state.bitcoinPriceData.isNotEmpty) {
        _updateGradientColors();
      }

      // Auto-settle if needed
      if (_state.boardingBalanceSats > 0 && !_state.isSettling) {
        settleBoarding();
      }

      if (_state.hasRecoverableVtxos && !_state.isSettling) {
        _settleRecoverableVtxos();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refresh swaps only.
  Future<void> refreshSwapsOnly() async {
    await _fetchSwaps();
  }

  Future<void> _fetchSwaps() async {
    try {
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }
      await _swapService.refreshSwaps();
      _updateState(_state.copyWith(swaps: List.from(_swapService.swaps)));
      logger.i("Fetched ${_state.swaps.length} swaps");
    } catch (e) {
      logger.w("Could not fetch swaps: $e");
    }
  }

  Future<void> _fetchLockedCollateral() async {
    try {
      if (!_lendasatService.isInitialized) {
        await _lendasatService.initialize();
      }
      if (_lendasatService.isAuthenticated) {
        await _lendasatService.refreshContracts();
        int totalLocked = 0;
        for (final contract in _lendasatService.activeContracts) {
          totalLocked += contract.effectiveCollateralSats;
        }
        _updateState(_state.copyWith(lockedCollateralSats: totalLocked));
        logger.i(
            "Locked collateral: $totalLocked sats from ${_lendasatService.activeContracts.length} active contracts");
      }
    } catch (e) {
      logger.w("Could not fetch locked collateral: $e");
    }
  }

  Future<void> _fetchBoardingBalance() async {
    try {
      final pendingBalance = await ark_api.getPendingBalance();
      _updateState(
          _state.copyWith(boardingBalanceSats: pendingBalance.toInt()));
      if (pendingBalance > BigInt.zero) {
        logger.i("Boarding balance: $pendingBalance sats (pending settle)");
      }
    } catch (e) {
      logger.w("Could not fetch boarding balance: $e");
    }
  }

  /// Settle boarding UTXOs.
  Future<void> settleBoarding({bool manual = false}) async {
    if (_state.isSettling || _state.boardingBalanceSats == 0) return;

    if (!manual && _state.skipAutoSettle) {
      final lastAttempt = _state.lastSettleAttempt;
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt).inMinutes <
              WalletConfig.autoSettleCooldownMinutes) {
        logger.d("Skipping auto-settle - waiting for more confirmations");
        return;
      }
      _updateState(_state.copyWith(skipAutoSettle: false));
    }

    _updateState(_state.copyWith(isSettling: true));

    try {
      logger.i(
          "Settling ${_state.boardingBalanceSats} sats from boarding address...");
      await ark_api.settle();
      logger.i("Settle completed successfully!");
      _updateState(_state.copyWith(skipAutoSettle: false));
      await _fetchBalance();
      await _fetchBoardingBalance();
      OverlayService().showSuccess('Funds settled successfully!');
    } catch (e) {
      logger.e("Error settling boarding UTXOs: $e");
      _updateState(_state.copyWith(lastSettleAttempt: DateTime.now()));

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not yet valid') ||
          errorStr.contains('invalid_intent_timerange')) {
        _updateState(_state.copyWith(skipAutoSettle: true));
        if (manual) {
          OverlayService().showError(
            'Funds need more confirmations before they can be settled. Please wait a few minutes and try again.',
          );
        }
      }
    } finally {
      _updateState(_state.copyWith(isSettling: false));
    }
  }

  Future<void> _settleRecoverableVtxos() async {
    if (_state.isSettling || !_state.hasRecoverableVtxos) return;

    _updateState(_state.copyWith(isSettling: true));

    final totalToRecover = _state.recoverableSats + _state.expiredSats;
    try {
      logger
          .i("Settling $totalToRecover sats from recoverable/expired VTXOs...");
      await ark_api.settle();
      logger.i("Recoverable VTXOs settled successfully!");
      await _fetchBalance();

      if (totalToRecover > 0) {
        OverlayService().showSuccess('Recovered $totalToRecover sats!');
      }
    } catch (e) {
      logger.e("Error settling recoverable VTXOs: $e");
    } finally {
      _updateState(_state.copyWith(isSettling: false));
    }
  }

  Future<void> _fetchTransactions() async {
    _updateState(_state.copyWith(isTransactionFetching: true));

    try {
      final transactions = await ark_api.txHistory();
      await BoardingTrackingService.processTransactions(transactions);
      _updateState(_state.copyWith(
        isTransactionFetching: false,
        transactions: transactions,
      ));
      logger.i("Fetched ${transactions.length} transactions");
    } catch (e) {
      logger.e("Error fetching transaction history: $e");
      _updateState(_state.copyWith(isTransactionFetching: false));
      OverlayService().showError("Couldn't update transactions: $e");
    }
  }

  Future<void> _fetchBalance() async {
    _updateState(_state.copyWith(isBalanceLoading: true));

    try {
      final balanceResult = await ark_api.balance();

      final newPendingBalance = balanceResult.offchain.pendingSats.toDouble() /
          BitcoinConstants.satsPerBtc;
      final newConfirmedBalance =
          balanceResult.offchain.confirmedSats.toDouble() /
              BitcoinConstants.satsPerBtc;
      final newTotalBalance = balanceResult.offchain.totalSats.toDouble() /
          BitcoinConstants.satsPerBtc;

      _updateState(_state.copyWith(
        pendingBalance: newPendingBalance,
        confirmedBalance: newConfirmedBalance,
        totalBalance: newTotalBalance,
        recoverableSats: balanceResult.offchain.recoverableSats.toInt(),
        expiredSats: balanceResult.offchain.expiredSats.toInt(),
        isBalanceLoading: false,
      ));

      await SettingsService().setCachedBalance(
        total: newTotalBalance,
        confirmed: newConfirmedBalance,
        pending: newPendingBalance,
      );

      logger.i(
          "Balance updated: Total: $newTotalBalance BTC, Confirmed: $newConfirmedBalance BTC, Pending: $newPendingBalance BTC");
    } catch (e) {
      logger.e("Error fetching balance: $e");
      _updateState(_state.copyWith(isBalanceLoading: false));
      OverlayService().showError("Couldn't update balance: $e");
    }
  }

  void _updateState(WalletState newState) {
    _state = newState;
    notifyListeners();
  }
}
