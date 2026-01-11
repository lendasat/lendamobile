import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/screens/buy/buy_screen.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/receivescreen.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/qr_scanner_screen.dart';
import 'package:ark_flutter/src/ui/screens/transactions/send/recipient_search_screen.dart';
import 'package:ark_flutter/src/ui/screens/transactions/send/send_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings.dart';
import 'package:ark_flutter/src/ui/screens/transactions/history/transaction_history_widget.dart';
import 'package:ark_flutter/src/ui/screens/transactions/history/transaction_filter_screen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart'
    show PriceData; // Only import the data type, not the chart widget
import 'package:ark_flutter/src/ui/widgets/wallet/wallet_mini_chart.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_image_text_button.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/price_widgets.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

/// Enum for balance type display
enum BalanceType { pending, confirmed, total }

/// WalletScreen - BitNet-style wallet interface with Provider state management
/// This screen combines the visual design from the BitNet project with
/// the functionality from the current ark-flutter project
class WalletScreen extends StatefulWidget {
  final String aspId;

  const WalletScreen({
    super.key,
    required this.aspId,
  });

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  // Loading states - start as true since we fetch data in initState
  bool _isBalanceLoading = true;
  bool _isTransactionFetching = true;
  List<Transaction> _transactions = [];

  // Key for transaction history widget to control its focus
  final GlobalKey<TransactionHistoryWidgetState> _transactionHistoryKey =
      GlobalKey<TransactionHistoryWidgetState>();
  bool _wasKeyboardVisible = false;
  Timer? _keyboardDebounceTimer;

  // Swap history
  final LendaSwapService _swapService = LendaSwapService();
  List<SwapInfo> _swaps = [];

  // Lendasat loans (for locked collateral display)
  final LendasatService _lendasatService = LendasatService();
  int _lockedCollateralSats = 0;

  // On-chain boarding balance (pending settle)
  int _boardingBalanceSats = 0;
  bool _isSettling = false;
  bool _skipAutoSettle = false;
  DateTime? _lastSettleAttempt;

  // Balance values
  double _pendingBalance = 0.0;
  double _confirmedBalance = 0.0;
  double _totalBalance = 0.0;

  // Recoverable/expired VTXOs (need settle to recover)
  int _recoverableSats = 0;
  int _expiredSats = 0;

  // Display preferences
  BalanceType _currentBalanceType = BalanceType.total;

  // Bitcoin chart data
  List<PriceData> _bitcoinPriceData = [];

  // Gradient colors (cached for performance)
  Color _gradientTopColor = AppTheme.successColor.withValues(alpha: 0.3);
  Color _gradientBottomColor =
      AppTheme.successColorGradient.withValues(alpha: 0.15);

  // Recovery status
  bool _wordRecoverySet = false;

  // Scroll controller for nested scrolling
  final ScrollController _scrollController = ScrollController();

  // Refresh guard to prevent multiple simultaneous refreshes
  bool _isRefreshing = false;

  // Chart data cache (memoization for performance)
  // Avoids recalculating balance history on every build
  List<WalletChartData>? _cachedBalanceChartData;
  int _lastTransactionCount = 0;
  int _lastPriceDataCount = 0;
  double _lastTotalBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logger.i("WalletScreen initialized with ASP ID: ${widget.aspId}");
    _loadCachedBalance(); // Load cached balance first for instant display
    _initializeWalletData();
    _loadBitcoinPriceData();
    _loadRecoveryStatus();

    // Fetch exchange rates and check for alpha warning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyPreferenceService>().fetchExchangeRates();
      _checkAndShowAlphaWarning();
    });
  }

  /// Load cached balance from local storage for instant display
  Future<void> _loadCachedBalance() async {
    try {
      final cachedBalance = await SettingsService().getCachedBalance();
      if (cachedBalance != null && mounted) {
        setState(() {
          _totalBalance = cachedBalance.total;
          _confirmedBalance = cachedBalance.confirmed;
          _pendingBalance = cachedBalance.pending;
        });
        logger.i("Loaded cached balance: ${cachedBalance.total} BTC");
      }
    } catch (e) {
      logger.w("Could not load cached balance: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Clear any lingering keyboard when app resumes
    if (state == AppLifecycleState.resumed) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Debounce keyboard detection to avoid ~60 callbacks during animation
    _keyboardDebounceTimer?.cancel();
    _keyboardDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (_wasKeyboardVisible && !keyboardVisible) {
        // Keyboard was just dismissed - unfocus search field
        _transactionHistoryKey.currentState?.unfocusSearch();
      }
      _wasKeyboardVisible = keyboardVisible;
    });
  }

  /// Initialize wallet data with retry to ensure fresh data is loaded
  /// The Ark SDK may need time to sync after connection, so we fetch twice
  Future<void> _initializeWalletData() async {
    // First fetch attempt
    await fetchWalletData();

    // If balance is still zero after initial fetch, the SDK might not be synced yet
    // Retry after a short delay to ensure we get fresh data from the server
    if (_totalBalance == 0 && _transactions.isEmpty && mounted) {
      logger.i("Initial data appears empty, retrying after delay...");
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        await fetchWalletData();
      }
    }
  }

  /// Check if alpha warning needs to be shown and display it
  Future<void> _checkAndShowAlphaWarning() async {
    final hasBeenShown = await SettingsService().hasAlphaWarningBeenShown();
    if (!hasBeenShown && mounted) {
      // Mark as shown immediately to prevent race conditions
      await SettingsService().setAlphaWarningShown();
      if (mounted) {
        _showAlphaWarningSheet();
      }
    }
  }

  /// Show the alpha warning bottom sheet
  void _showAlphaWarningSheet() {
    arkBottomSheet(
      context: context,
      isDismissible: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade700,
              size: 56,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              "Early Alpha Version",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              "This wallet is in early alpha. Please only use amounts you can afford to lose.\n\n"
              "This is not a stable wallet - we are actively experimenting and improving. "
              "Features may change, and there may be bugs.\n\n"
              "We accept no liability for any loss of funds or damages that may occur while using this application.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: "I Understand",
              customWidth: double.infinity,
              customHeight: 56,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppTheme.elementSpacing),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBitcoinPriceData() async {
    try {
      final userPrefs = context.read<UserPreferencesService>();
      final timeRange = _convertChartTimeRange(userPrefs.chartTimeRange);
      final priceData = await fetchBitcoinPriceData(timeRange);
      if (mounted) {
        setState(() {
          _bitcoinPriceData = priceData;
          _updateGradientColors();
        });
      }
    } catch (e) {
      logger.e('Error loading bitcoin price data: $e');
    }
  }

  Future<void> _loadRecoveryStatus() async {
    try {
      final wordRecovery = await SettingsService().isWordRecoverySet();
      if (mounted) {
        setState(() {
          _wordRecoverySet = wordRecovery;
        });
      }
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
    final isPositive = _isPriceChangePositive();
    setState(() {
      _gradientTopColor = isPositive
          ? AppTheme.successColor.withValues(alpha: 0.3)
          : AppTheme.errorColor.withValues(alpha: 0.3);
      _gradientBottomColor = isPositive
          ? AppTheme.successColorGradient.withValues(alpha: 0.15)
          : AppTheme.errorColorGradient.withValues(alpha: 0.15);
    });
  }

  /// Determines if a balance change should be considered positive (green) or negative (red).
  /// Uses balance-aware logic to properly handle edge cases:
  /// - Both balances zero: neutral (green) - new user or always empty
  /// - Had balance, now zero: loss (red) - user withdrew/spent everything
  /// - Had zero, now have balance: gain (green) - user received first deposit
  /// - Otherwise: compare portfolio values
  bool _isBalanceChangePositive(double firstBalance, double lastBalance,
      double firstValue, double lastValue) {
    // 1 satoshi threshold for "essentially zero" (handles floating point precision)
    const satoshiThreshold = 0.00000001;

    // Case 1: Both balances essentially zero - neutral state, show green
    if (firstBalance < satoshiThreshold && lastBalance < satoshiThreshold) {
      return true;
    }

    // Case 2: Had balance, now zero - definite loss (-100%), show red
    if (firstBalance >= satoshiThreshold && lastBalance < satoshiThreshold) {
      return false;
    }

    // Case 3: Had zero, now have balance - definite gain, show green
    if (firstBalance < satoshiThreshold && lastBalance >= satoshiThreshold) {
      return true;
    }

    // Case 4: Normal portfolio value comparison
    return lastValue >= firstValue;
  }

  bool _isPriceChangePositive() {
    if (_bitcoinPriceData.isEmpty) return true;

    // Calculate portfolio value change (balance at time × price)
    final firstData = _bitcoinPriceData.first;

    // Compare first point with the ACTUAL current state (not the last price point which might be stale)
    final firstBalance = _getBalanceAtTimestamp(firstData.time);
    final currentBalance = _getSelectedBalance();
    final currentPrice = _getCurrentBtcPrice();

    final firstValue = firstData.price * firstBalance;
    final currentValue = currentPrice * currentBalance;

    return _isBalanceChangePositive(
        firstBalance, currentBalance, firstValue, currentValue);
  }

  /// Scrolls to the top of the wallet screen with a smooth animation
  /// Called when user taps the wallet tab while already on the wallet screen
  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Fetches all wallet data (balance, transactions, swaps, and locked collateral)
  /// This is public so it can be called from parent widgets (e.g., after payment received)
  Future<void> fetchWalletData() async {
    // Guard against multiple simultaneous refreshes
    if (_isRefreshing) {
      logger.d("Skipping refresh - already in progress");
      return;
    }

    _isRefreshing = true;

    // Invalidate chart cache - will be recomputed with fresh data
    _cachedBalanceChartData = null;

    try {
      await Future.wait([
        _fetchBalance(),
        _fetchTransactions(),
        _fetchSwaps(),
        _fetchLockedCollateral(),
        _fetchBoardingBalance(),
      ]);

      // Update gradient colors AFTER all data is fetched to ensure
      // balance, transactions, and swaps are all up-to-date for the calculation
      if (_bitcoinPriceData.isNotEmpty && mounted) {
        _updateGradientColors();
      }

      // Auto-settle if there are confirmed boarding UTXOs
      if (_boardingBalanceSats > 0 && !_isSettling) {
        _settleBoarding();
      }

      // Auto-settle if there are recoverable or expired VTXOs
      // These VTXOs can't be spent normally and need to be settled to recover
      if ((_recoverableSats > 0 || _expiredSats > 0) && !_isSettling) {
        _settleRecoverableVtxos();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _fetchSwaps() async {
    try {
      // Initialize swap service if needed
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }

      await _swapService.refreshSwaps();
      if (mounted) {
        setState(() {
          _swaps = _swapService.swaps;
        });
      }
      logger.i("Fetched ${_swaps.length} swaps");
    } catch (e) {
      // Silently handle swap fetch errors - swaps are optional
      logger.w("Could not fetch swaps: $e");
    }
  }

  Future<void> _fetchLockedCollateral() async {
    try {
      // Initialize Lendasat service if needed
      if (!_lendasatService.isInitialized) {
        await _lendasatService.initialize();
      }

      // Only fetch contracts if authenticated
      if (_lendasatService.isAuthenticated) {
        await _lendasatService.refreshContracts();

        // Calculate total locked collateral from active contracts
        int totalLocked = 0;
        for (final contract in _lendasatService.activeContracts) {
          totalLocked += contract.effectiveCollateralSats;
        }

        if (mounted) {
          setState(() {
            _lockedCollateralSats = totalLocked;
          });
        }
        logger.i(
            "Locked collateral: $_lockedCollateralSats sats from ${_lendasatService.activeContracts.length} active contracts");
      }
    } catch (e) {
      // Silently handle errors - locked collateral display is optional
      logger.w("Could not fetch locked collateral: $e");
    }
  }

  /// Fetch on-chain boarding balance (funds waiting to be settled into Ark)
  Future<void> _fetchBoardingBalance() async {
    try {
      final pendingBalance = await getPendingBalance();
      if (mounted) {
        setState(() {
          _boardingBalanceSats = pendingBalance.toInt();
        });
      }
      if (pendingBalance > BigInt.zero) {
        logger.i("Boarding balance: $pendingBalance sats (pending settle)");
      }
    } catch (e) {
      // Silently handle errors - boarding balance display is optional
      logger.w("Could not fetch boarding balance: $e");
    }
  }

  /// Settle boarding UTXOs (convert on-chain funds to Ark VTXOs)
  Future<void> _settleBoarding({bool manual = false}) async {
    if (_isSettling || _boardingBalanceSats == 0) return;

    // Skip auto-settle if we recently failed due to timelock
    // But always allow manual settle attempts
    if (!manual && _skipAutoSettle) {
      final lastAttempt = _lastSettleAttempt;
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt).inMinutes < 5) {
        logger.d("Skipping auto-settle - waiting for more confirmations");
        return;
      }
      // Reset skip flag after 5 minutes
      _skipAutoSettle = false;
    }

    setState(() {
      _isSettling = true;
    });

    try {
      logger.i("Settling $_boardingBalanceSats sats from boarding address...");
      await settle();
      logger.i("Settle completed successfully!");

      // Reset skip flag on success
      _skipAutoSettle = false;

      // Refresh balance after settle
      await _fetchBalance();
      await _fetchBoardingBalance();

      if (mounted) {
        OverlayService().showSuccess('Funds settled successfully!');
      }
    } catch (e) {
      logger.e("Error settling boarding UTXOs: $e");
      _lastSettleAttempt = DateTime.now();

      final errorStr = e.toString().toLowerCase();
      // Check if error is due to timelock not yet valid
      if (errorStr.contains('not yet valid') ||
          errorStr.contains('invalid_intent_timerange')) {
        _skipAutoSettle = true;
        if (manual && mounted) {
          // Show user-friendly message for manual attempts
          OverlayService().showError(
            'Funds need more confirmations before they can be settled. Please wait a few minutes and try again.',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettling = false;
        });
      }
    }
  }

  /// Settle recoverable/expired VTXOs back into spendable balance
  Future<void> _settleRecoverableVtxos() async {
    if (_isSettling || (_recoverableSats == 0 && _expiredSats == 0)) return;

    setState(() {
      _isSettling = true;
    });

    final totalToRecover = _recoverableSats + _expiredSats;
    try {
      logger
          .i("Settling $totalToRecover sats from recoverable/expired VTXOs...");
      await settle();
      logger.i("Recoverable VTXOs settled successfully!");

      // Refresh balance after settle
      await _fetchBalance();

      if (mounted && totalToRecover > 0) {
        OverlayService().showSuccess('Recovered $totalToRecover sats!');
      }
    } catch (e) {
      logger.e("Error settling recoverable VTXOs: $e");
      // Don't show error to user - settle will be retried on next refresh
    } finally {
      if (mounted) {
        setState(() {
          _isSettling = false;
        });
      }
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        _isTransactionFetching = true;
      });

      final transactions = await txHistory();
      if (mounted) {
        setState(() {
          _isTransactionFetching = false;
          _transactions = transactions;
        });
      }
      logger.i("Fetched ${transactions.length} transactions");
    } catch (e) {
      logger.e("Error fetching transaction history: $e");
      if (mounted) {
        setState(() {
          _isTransactionFetching = false;
        });
        _showError(
            "${AppLocalizations.of(context)!.couldntUpdateTransactions} ${e.toString()}");
      }
    }
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isBalanceLoading = true;
    });

    try {
      final balanceResult = await balance();

      final newPendingBalance = balanceResult.offchain.pendingSats.toDouble() /
          BitcoinConstants.satsPerBtc;
      final newConfirmedBalance =
          balanceResult.offchain.confirmedSats.toDouble() /
              BitcoinConstants.satsPerBtc;
      final newTotalBalance = balanceResult.offchain.totalSats.toDouble() /
          BitcoinConstants.satsPerBtc;

      if (mounted) {
        setState(() {
          _pendingBalance = newPendingBalance;
          _confirmedBalance = newConfirmedBalance;
          _totalBalance = newTotalBalance;
          _recoverableSats = balanceResult.offchain.recoverableSats.toInt();
          _expiredSats = balanceResult.offchain.expiredSats.toInt();
          _isBalanceLoading = false;
        });
      }

      // Cache the balance for instant display on next app launch
      await SettingsService().setCachedBalance(
        total: newTotalBalance,
        confirmed: newConfirmedBalance,
        pending: newPendingBalance,
      );

      logger.i(
          "Balance updated: Total: $_totalBalance BTC, Confirmed: $_confirmedBalance BTC, Pending: $_pendingBalance BTC, Recoverable: $_recoverableSats sats, Expired: $_expiredSats sats");
    } catch (e) {
      logger.e("Error fetching balance: $e");
      if (mounted) {
        setState(() {
          _isBalanceLoading = false;
        });
        _showError(
            "${AppLocalizations.of(context)!.couldntUpdateBalance} ${e.toString()}");
      }
    }
  }

  void _toggleBalanceVisibility() {
    HapticFeedback.lightImpact();
    context.read<UserPreferencesService>().toggleBalancesVisible();
  }

  void _toggleDisplayUnit() {
    context.read<CurrencyPreferenceService>().toggleShowCoinBalance();
  }

  void _showError(String message) {
    OverlayService().showError(message);
  }

  double _getSelectedBalance() {
    // Always show total balance - detailed breakdown available in Developer Settings
    return _totalBalance;
  }

  /// Get current BTC price in USD from price data.
  /// Returns 0 if price data is not yet loaded - UI should handle this case.
  double _getCurrentBtcPrice() {
    if (_bitcoinPriceData.isEmpty) return 0;
    return _bitcoinPriceData.last.price;
  }

  // Navigation handlers
  void _handleSend() {
    logger.i("Send button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipientSearchScreen(
          aspId: widget.aspId,
          availableSats: _getSelectedBalance() * BitcoinConstants.satsPerBtc,
          bitcoinPrice: _getCurrentBtcPrice(),
        ),
      ),
    );
  }

  Future<void> _handleReceive() async {
    logger.i("Receive button pressed");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiveScreen(
          aspId: widget.aspId,
          amount: 0,
          bitcoinPrice: _getCurrentBtcPrice(),
        ),
      ),
    );
    // Refresh wallet data when returning
    logger.i("Returned from receive flow, refreshing wallet data");
    fetchWalletData();
  }

  Future<void> _handleScan() async {
    logger.i("Scan button pressed");
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      logger.i("Scanned QR code: $result");
      // Navigate to send screen with scanned address
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendScreen(
            aspId: widget.aspId,
            availableSats: _getSelectedBalance() * BitcoinConstants.satsPerBtc,
            initialAddress: result,
            bitcoinPrice: _getCurrentBtcPrice(),
          ),
        ),
      );
    }
  }

  void _handleBuy() {
    logger.i("Buy button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuyScreen(),
      ),
    );
  }

  void _handleBitcoinChart() {
    logger.i("Bitcoin chart button pressed");
    final l10n = AppLocalizations.of(context)!;

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.9,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // App bar at top
          BitNetAppBar(
            context: context,
            hasBackButton: false,
            text: l10n.bitcoinPriceChart,
          ),
          // Top spacing
          SizedBox(height: AppTheme.cardPadding * 1.5),
          // Chart content
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
              child: const BitcoinChartCard(),
            ),
          ),
          // About Bitcoin section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aboutBitcoin,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.bitcoinDescription,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
        ],
      ),
    );
  }

  void _handleSettings() {
    // Dismiss any active keyboard/focus before opening settings
    FocusScope.of(context).unfocus();

    final settingsController = context.read<SettingsController>();
    settingsController.resetToMain();

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Settings(aspId: widget.aspId),
    ).then((_) {
      // Refresh recovery status when settings is closed
      // (user may have set up recovery while in settings)
      _loadRecoveryStatus();
    });
  }

  /// Builds the settings button with a recovery status indicator dot
  /// Shows RED dot only when NO recovery option has been set up
  Widget _buildSettingsButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if word recovery is set up (email recovery coming soon)
    final bool hasAnyRecovery = _wordRecoverySet;

    return Stack(
      children: [
        RoundedButtonWidget(
          size: AppTheme.cardPadding * 1.5,
          buttonType: ButtonType.transparent,
          hitSlop: 4,
          iconData: Icons.settings,
          onTap: _handleSettings,
        ),
        // Only show red dot if NO recovery option has been set up
        if (!hasAnyRecovery)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorColor,
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Create system UI overlay style that matches the gradient color
    // This makes the notch/dynamic island area match the wallet gradient
    final systemUiStyle = SystemUiOverlayStyle(
      // Status bar (top) - use gradient color
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      // Navigation bar (bottom) - match scaffold background
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // Extend body behind status bar so gradient fills notch area
          extendBodyBehindAppBar: true,
          body: RefreshIndicator(
            onRefresh: fetchWalletData,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Main wallet header with gradient and chart
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Dynamic gradient background - extends into status bar area
                      _buildDynamicGradient(),

                      // Chart overlay
                      Opacity(
                        opacity: 0.1,
                        child: _buildChartWidget(),
                      ),

                      // Main content with SafeArea for proper padding
                      SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: AppTheme.cardPadding),
                            _buildTopBar(),
                            const SizedBox(height: AppTheme.cardPadding * 1.5),
                            _buildBalanceDisplay(),
                            if (_lockedCollateralSats > 0) ...[
                              const SizedBox(
                                  height: AppTheme.elementSpacing * 0.5),
                              _buildLockedCollateralDisplay(),
                            ],
                            if (_boardingBalanceSats > 0) ...[
                              const SizedBox(
                                  height: AppTheme.elementSpacing * 0.5),
                              _buildBoardingBalanceDisplay(),
                            ],
                            const SizedBox(height: AppTheme.elementSpacing),
                            _buildPriceChangeIndicators(),
                            const SizedBox(height: AppTheme.cardPadding * 1.5),
                            _buildActionButtons(),
                            const SizedBox(height: AppTheme.cardPadding),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky header for transaction history (includes top spacing)
                _buildStickyTransactionHeader(),

                // Transaction list content (without header)
                SliverToBoxAdapter(
                  child: _buildTransactionList(),
                ),

                // Bottom padding with SafeArea for bottom inset
                SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    child: SizedBox(height: AppTheme.cardPadding * 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicGradient() {
    // Get the top padding (status bar / notch / dynamic island height)
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      // Add top padding to gradient height so it fills the notch/dynamic island area
      height: AppTheme.cardPadding * 12 + topPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.75, 1.0],
          colors: [
            _gradientTopColor,
            _gradientBottomColor,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  /// Calculate the user's BTC balance at a specific point in time
  /// by working backwards from current balance using transaction history.
  double _getBalanceAtTimestamp(int timestampMs) {
    final currentBalance = _getSelectedBalance();
    final timestampSec = timestampMs ~/ 1000;

    // Sum all transaction amounts that occurred AFTER the target timestamp
    double amountAfterTimestamp = 0.0;

    // Process regular transactions from the rust backend
    // These include all boarding, round, and redeem transactions
    for (final tx in _transactions) {
      final txTimestamp = tx.map(
        boarding: (t) =>
            (t.confirmedAt is BigInt
                ? (t.confirmedAt as BigInt).toInt()
                : t.confirmedAt) ??
            (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        round: (t) => t.createdAt is BigInt
            ? (t.createdAt as BigInt).toInt()
            : t.createdAt,
        redeem: (t) => t.createdAt is BigInt
            ? (t.createdAt as BigInt).toInt()
            : t.createdAt,
        offboard: (t) =>
            (t.confirmedAt is BigInt
                ? (t.confirmedAt as BigInt).toInt()
                : t.confirmedAt) ??
            (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );

      // Only count transactions that happened AFTER our target point
      if (txTimestamp > timestampSec) {
        final amountSats = tx.map(
          boarding: (t) => t.amountSats.toInt(),
          round: (t) => t.amountSats is BigInt
              ? (t.amountSats as BigInt).toInt()
              : t.amountSats,
          // Redeem transactions already have the correct sign from the backend (negative for outgoing)
          redeem: (t) => t.amountSats is BigInt
              ? (t.amountSats as BigInt).toInt()
              : t.amountSats,
          offboard: (t) => t.amountSats.toInt(),
        );
        amountAfterTimestamp += amountSats / BitcoinConstants.satsPerBtc;
      }
    }

    // NOTE: Swaps are NOT processed here because they result in boarding/round transactions
    // which are already captured in the _transactions list. Processing them again results in double-counting.

    // Balance at timestamp = current balance - changes that happened after
    // Current: 100. Received: 50. Before: 100 - 50 = 50.
    // Current: 50. Sent: 50. Before: 50 - (-50) = 100.
    return (currentBalance - amountAfterTimestamp).clamp(0.0, double.infinity);
  }

  /// Get cached balance chart data or compute if cache is invalid
  /// This avoids expensive _getBalanceAtTimestamp calculations on every rebuild
  List<WalletChartData> _getBalanceChartData() {
    // Check if cache is valid
    final needsRecompute = _cachedBalanceChartData == null ||
        _transactions.length != _lastTransactionCount ||
        _bitcoinPriceData.length != _lastPriceDataCount ||
        _totalBalance != _lastTotalBalance;

    if (needsRecompute) {
      // Compute chart data - this is the expensive operation
      _cachedBalanceChartData = _bitcoinPriceData.map((priceData) {
        final balanceAtTime = _getBalanceAtTimestamp(priceData.time);
        return WalletChartData(
          time: priceData.time.toDouble(),
          value: priceData.price * balanceAtTime,
        );
      }).toList();

      // Update cache keys
      _lastTransactionCount = _transactions.length;
      _lastPriceDataCount = _bitcoinPriceData.length;
      _lastTotalBalance = _totalBalance;
    }

    // Always append current state as the final point for immediate visual updates
    // This is cheap to compute and ensures the chart reflects the current balance
    final result = List<WalletChartData>.from(_cachedBalanceChartData!);
    final currentBalance = _getSelectedBalance();
    final currentPrice = _getCurrentBtcPrice();
    result.add(WalletChartData(
      time: DateTime.now().millisecondsSinceEpoch.toDouble(),
      value: currentPrice * currentBalance,
    ));

    return result;
  }

  Widget _buildChartWidget() {
    // Get the top padding (status bar / notch / dynamic island height)
    final topPadding = MediaQuery.of(context).padding.top;

    if (_bitcoinPriceData.isEmpty || _isBalanceLoading) {
      return SizedBox(height: AppTheme.cardPadding * 10 + topPadding);
    }

    // Use cached chart data for better performance
    final balanceChartData = _getBalanceChartData();

    return WalletMiniChart(
      data: balanceChartData,
      lineColor: _isPriceChangePositive()
          ? AppTheme.successColor
          : AppTheme.errorColor,
      // Add top padding to chart height so it aligns with gradient
      height: AppTheme.cardPadding * 10 + topPadding,
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TODO: Avatar temporarily commented out - will be reintroduced later
          // Avatar(
          //   onTap: () {},
          //   size: AppTheme.cardPadding * 2.25,
          //   type: ProfilePictureType.lightning,
          // ),
          const Spacer(), // Keep buttons right-aligned while Avatar is commented out

          // Action buttons
          Row(
            children: [
              // Hide balance button
              Consumer<UserPreferencesService>(
                builder: (context, userPrefs, _) => RoundedButtonWidget(
                  size: AppTheme.cardPadding * 1.5,
                  iconSize: AppTheme.cardPadding * 0.65,
                  buttonType: ButtonType.transparent,
                  hitSlop: 4,
                  iconData: userPrefs.balancesVisible
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  onTap: userPrefs.toggleBalancesVisible,
                ),
              ),

              // Chart button
              RoundedButtonWidget(
                size: AppTheme.cardPadding * 1.5,
                iconSize: AppTheme.cardPadding * 0.65,
                buttonType: ButtonType.transparent,
                hitSlop: 4,
                iconData: FontAwesomeIcons.chartLine,
                onTap: _handleBitcoinChart,
              ),
              const SizedBox(width: AppTheme.elementSpacing * 0.5),

              // Settings button with recovery status indicator
              _buildSettingsButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    // Convert BTC to satoshis for display
    final balanceInSats =
        (_getSelectedBalance() * BitcoinConstants.satsPerBtc).round();
    final formattedSats = _formatSatsAmount(balanceInSats);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Balance display masked for PostHog session replay
          PostHogMaskWidget(
            child: GestureDetector(
              onTap: _toggleDisplayUnit,
              onLongPress: _toggleBalanceVisibility,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: double.infinity,
                child: currencyService.showCoinBalance
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userPrefs.balancesVisible ? formattedSats : '****',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Icon(
                            AppTheme.satoshiIcon,
                            size: 58,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          userPrefs.balancesVisible
                              ? currencyService.formatAmount(
                                  _getSelectedBalance() * _getCurrentBtcPrice())
                              : '${currencyService.symbol}****',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format satoshi amount with thousand separators
  String _formatSatsAmount(int sats) {
    final formatted = sats.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return formatted;
  }

  Widget _buildLockedCollateralDisplay() {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    final formattedSats = _formatSatsAmount(_lockedCollateralSats);
    final lockedBtc = _lockedCollateralSats / BitcoinConstants.satsPerBtc;
    final btcPrice = _getCurrentBtcPrice();
    // formatAmount handles currency conversion internally
    final lockedFiatAmount = lockedBtc * btcPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: PostHogMaskWidget(
        child: GestureDetector(
          onTap: _toggleDisplayUnit,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.lock,
                size: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                userPrefs.balancesVisible
                    ? (currencyService.showCoinBalance
                        ? '$formattedSats sats'
                        : currencyService.formatAmount(lockedFiatAmount))
                    : '****',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                'locked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardingBalanceDisplay() {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    final formattedSats = _formatSatsAmount(_boardingBalanceSats);
    final boardingBtc = _boardingBalanceSats / BitcoinConstants.satsPerBtc;
    final btcPrice = _getCurrentBtcPrice();
    // formatAmount handles currency conversion internally
    final boardingFiatAmount = boardingBtc * btcPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: PostHogMaskWidget(
        child: GestureDetector(
          onTap: _isSettling ? null : () => _settleBoarding(manual: true),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSettling)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                )
              else
                Icon(
                  FontAwesomeIcons.arrowDown,
                  size: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              const SizedBox(width: 6),
              Text(
                userPrefs.balancesVisible
                    ? (currencyService.showCoinBalance
                        ? '$formattedSats sats'
                        : currencyService.formatAmount(boardingFiatAmount))
                    : '****',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                _isSettling
                    ? 'settling...'
                    : _skipAutoSettle
                        ? 'confirming...'
                        : 'incoming',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChangeIndicators() {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();
    final isObscured = !userPrefs.balancesVisible;

    // Default values when no data is available
    double percentChange = 0.0;
    bool isPositive = true;
    double balanceChangeInFiat = 0.0;
    double balanceChange = 0.0;

    if (_bitcoinPriceData.isNotEmpty) {
      // Calculate portfolio value change (balance at time x price) to match the chart and gradient
      final firstData = _bitcoinPriceData.first;

      // Use the ACTUAL current state (not the last price point which might be stale)
      final firstBalance = _getBalanceAtTimestamp(firstData.time);
      final currentBalance = _getSelectedBalance();
      final currentPrice = _getCurrentBtcPrice();

      final firstValue = firstData.price * firstBalance;
      final currentValue = currentPrice * currentBalance;

      final valueDiff = currentValue - firstValue;

      // Use the same balance-aware logic for consistency with gradient/chart
      isPositive = _isBalanceChangePositive(
          firstBalance, currentBalance, firstValue, currentValue);

      // Calculate percent change with proper edge case handling
      // Must be consistent with _isBalanceChangePositive and gradient
      const satoshiThreshold = 0.00000001;
      if (firstBalance < satoshiThreshold &&
          currentBalance < satoshiThreshold) {
        // No balance before or now - neutral state, show 0%
        // Consistent with gradient showing green (neutral)
        percentChange = 0.0;
      } else if (firstBalance >= satoshiThreshold &&
          currentBalance < satoshiThreshold) {
        percentChange = -100.0;
      } else if (firstBalance < satoshiThreshold &&
          currentBalance >= satoshiThreshold) {
        // Went from zero to having balance - use special infinity marker
        percentChange = double.infinity;
      } else if (firstValue != 0) {
        percentChange = (valueDiff / firstValue) * 100;
      } else {
        percentChange = 0.0;
      }

      // Balance change in fiat is the portfolio value difference
      balanceChangeInFiat = valueDiff;
      // Balance change in BTC
      balanceChange = currentPrice > 0 ? valueDiff / currentPrice : 0.0;
    }

    // Convert balance change to sats
    final balanceChangeInSats =
        (balanceChange.abs() * BitcoinConstants.satsPerBtc).round();

    return GestureDetector(
      onTap: _toggleDisplayUnit,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show sats with satoshi icon when in coin mode
            currencyService.showCoinBalance
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: isPositive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 16,
                      ),
                      Text(
                        isObscured
                            ? '****'
                            : _formatSatsAmount(balanceChangeInSats),
                        style: TextStyle(
                          color: isPositive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isObscured) ...[
                        const SizedBox(width: 2),
                        Icon(
                          AppTheme.satoshiIcon,
                          size: 14,
                          color: isPositive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ],
                    ],
                  )
                : ColoredPriceWidget(
                    price:
                        currencyService.formatAmount(balanceChangeInFiat.abs()),
                    isPositive: isPositive,
                    shouldHideAmount: isObscured,
                  ),
            const SizedBox(width: 8),
            BitNetPercentWidget(
              priceChange: percentChange.isInfinite
                  ? '+∞%'
                  : '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
              shouldHideAmount: isObscured,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Row(
        children: [
          Expanded(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.send ?? "Send",
              _handleSend,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_upward_rounded,
            ),
          ),
          Expanded(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.receive ?? "Receive",
              _handleReceive,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_downward_rounded,
            ),
          ),
          // Scan button (replaces Sell)
          Expanded(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.scan ?? "Scan",
              _handleScan,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.qr_code_scanner_rounded,
            ),
          ),
          // Sell button - commented out for now
          // Flexible(
          //   child: BitNetImageWithTextButton(
          //     "Sell",
          //     _handleSell,
          //     width: AppTheme.cardPadding * 2.5,
          //     height: AppTheme.cardPadding * 2.5,
          //     fallbackIcon: Icons.sell_outlined,
          //   ),
          // ),
          Flexible(
            child: BitNetImageWithTextButton(
              "Buy",
              _handleBuy,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: FontAwesomeIcons.btc,
              fallbackIconSize: AppTheme.iconSize * 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final userPrefs = context.watch<UserPreferencesService>();
    final currencyService = context.watch<CurrencyPreferenceService>();

    return TransactionHistoryWidget(
      key: _transactionHistoryKey,
      aspId: widget.aspId,
      transactions: _transactions,
      swaps: _swaps,
      loading: _isTransactionFetching,
      hideAmounts: !userPrefs.balancesVisible,
      showBtcAsMain: currencyService.showCoinBalance,
      bitcoinPrice: _getCurrentBtcPrice(),
      showHeader: false, // Header is rendered as sticky SliverAppBar
    );
  }

  /// Builds the sticky transaction history header using SliverAppBar
  Widget _buildStickyTransactionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasTransactions = _transactions.isNotEmpty || _swaps.isNotEmpty;

    // Calculate header height based on content (includes top spacing)
    // Top spacing: cardPadding (~24)
    // Title: ~24, spacing: ~8, search bar: ~56, padding: ~24 = ~136 when search visible
    // Title: ~24, padding: ~16 = ~64 when no search
    final double headerHeight = (!_isTransactionFetching && hasTransactions)
        ? 112.0 + AppTheme.cardPadding
        : 40.0 + AppTheme.cardPadding;

    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: headerHeight,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top spacing (previously separate SliverToBoxAdapter)
              const SizedBox(height: AppTheme.cardPadding * 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.transactionHistory,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Reload button for transaction history only
                    GestureDetector(
                      onTap: _isTransactionFetching
                          ? null
                          : () async {
                              // Reload only transactions and swaps, not the entire wallet
                              await Future.wait([
                                _fetchTransactions(),
                                _fetchSwaps(),
                              ]);
                            },
                      child: Icon(
                        Icons.refresh,
                        size: 20,
                        color: isDark ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              if (!_isTransactionFetching && hasTransactions)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.cardPadding,
                    right: AppTheme.cardPadding,
                    top: AppTheme.elementSpacing,
                    bottom: AppTheme.elementSpacing,
                  ),
                  child: SearchFieldWidget(
                    hintText: l10n.search,
                    isSearchEnabled: true,
                    handleSearch: (value) {
                      _transactionHistoryKey.currentState
                          ?.applySearchFromExternal(value);
                    },
                    onChanged: (value) {
                      _transactionHistoryKey.currentState
                          ?.applySearchFromExternal(value);
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: isDark ? AppTheme.white60 : AppTheme.black60,
                        size: AppTheme.cardPadding * 0.75,
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await arkBottomSheet(
                          context: context,
                          height: MediaQuery.of(context).size.height * 0.7,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          child: const TransactionFilterScreen(),
                        );
                        _transactionHistoryKey.currentState?.refreshFilter();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper method to show timeframe selection bottom sheet
void showTimeframeBottomSheet(
  BuildContext context,
  TimeRange currentRange,
  Function(TimeRange) onSelect,
) {
  showModalBottomSheet(
    context: context,
    elevation: 0.0,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppTheme.borderRadiusBig),
        topRight: Radius.circular(AppTheme.borderRadiusBig),
      ),
    ),
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.borderRadiusBig),
            topRight: Radius.circular(AppTheme.borderRadiusBig),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.elementSpacing),
            Container(
              height: AppTheme.elementSpacing / 1.375,
              width: AppTheme.cardPadding * 2.25,
              decoration: BoxDecoration(
                color: Theme.of(ctx).hintColor.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusCircular),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              "Select Timeframe",
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            ...TimeRange.values.map((range) {
              final isSelected = currentRange == range;
              return ListTile(
                leading: Icon(
                  _getTimeframeIcon(range),
                  color: isSelected
                      ? AppTheme.colorBitcoin
                      : Theme.of(ctx).colorScheme.onSurface,
                ),
                title: Text(
                  _getTimeframeLabel(range),
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.colorBitcoin)
                    : null,
                onTap: () {
                  onSelect(range);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      );
    },
  );
}

String _getTimeframeLabel(TimeRange range) {
  switch (range) {
    case TimeRange.day:
      return "1 Day";
    case TimeRange.week:
      return "1 Week";
    case TimeRange.month:
      return "1 Month";
    case TimeRange.year:
      return "1 Year";
    case TimeRange.max:
      return "All Time";
  }
}

IconData _getTimeframeIcon(TimeRange range) {
  switch (range) {
    case TimeRange.day:
      return Icons.today;
    case TimeRange.week:
      return Icons.date_range;
    case TimeRange.month:
      return Icons.calendar_month;
    case TimeRange.year:
      return Icons.calendar_today;
    case TimeRange.max:
      return Icons.all_inclusive;
  }
}
