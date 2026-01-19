import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/boarding_tracking_service.dart';
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
    show PriceData;
import 'package:ark_flutter/src/ui/widgets/wallet/balance_chart_calculator.dart';
import 'package:ark_flutter/src/ui/widgets/wallet/wallet_header.dart';
import 'package:ark_flutter/src/ui/widgets/wallet/wallet_mini_chart.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Enum for balance type display
enum BalanceType { pending, confirmed, total }

/// WalletScreen - BitNet-style wallet interface with Provider state management
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
  // Loading states
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

  // Balance chart calculator for performance
  BalanceChartCalculator? _chartCalculator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logger.i("WalletScreen initialized with ASP ID: ${widget.aspId}");
    _loadCachedBalance();
    _initializeWalletData();
    _loadBitcoinPriceData();
    _loadRecoveryStatus();

    // Listen to swap service changes for automatic UI updates
    _swapService.addListener(_onSwapsChanged);

    // Fetch exchange rates and check for alpha warning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyPreferenceService>().fetchExchangeRates();
      _checkAndShowAlphaWarning();
    });
  }

  void _onSwapsChanged() {
    if (mounted) {
      setState(() {
        _swaps = List.from(_swapService.swaps);
      });
      logger.d("Swaps updated from service notification");
    }
  }

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
    if (state == AppLifecycleState.resumed) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _keyboardDebounceTimer?.cancel();
    _keyboardDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (_wasKeyboardVisible && !keyboardVisible) {
        _transactionHistoryKey.currentState?.unfocusSearch();
      }
      _wasKeyboardVisible = keyboardVisible;
    });
  }

  Future<void> _initializeWalletData() async {
    // Initialize boarding tracking service for onchain receive detection
    await BoardingTrackingService.initialize();

    await fetchWalletData();
    if (_totalBalance == 0 && _transactions.isEmpty && mounted) {
      logger.i("Initial data appears empty, retrying after delay...");
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        await fetchWalletData();
      }
    }
  }

  Future<void> _checkAndShowAlphaWarning() async {
    final hasBeenShown = await SettingsService().hasAlphaWarningBeenShown();
    if (!hasBeenShown && mounted) {
      await SettingsService().setAlphaWarningShown();
      if (mounted) {
        _showAlphaWarningSheet();
      }
    }
  }

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
    _swapService.removeListener(_onSwapsChanged);
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
          // Update global price cache for other screens
          if (priceData.isNotEmpty) {
            BitcoinPriceCache.updatePrice(priceData.last.price);
          }
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

  bool _isPriceChangePositive() {
    if (_bitcoinPriceData.isEmpty) return true;
    _updateChartCalculator();
    return _chartCalculator!.isPriceChangePositive(_getCurrentBtcPrice());
  }

  void _updateChartCalculator() {
    // Only create calculator if not already cached
    // It gets invalidated (set to null) in fetchWalletData() when data changes
    if (_chartCalculator != null) return;

    _chartCalculator = BalanceChartCalculator(
      transactions: _transactions,
      priceData: _bitcoinPriceData,
      currentBalance: _totalBalance,
    );
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> fetchWalletData() async {
    if (_isRefreshing) {
      logger.d("Skipping refresh - already in progress");
      return;
    }

    _isRefreshing = true;
    _chartCalculator = null; // Invalidate chart cache

    try {
      await Future.wait([
        _fetchBalance(),
        _fetchTransactions(),
        _fetchSwaps(),
        _fetchLockedCollateral(),
        _fetchBoardingBalance(),
      ]);

      if (_bitcoinPriceData.isNotEmpty && mounted) {
        _updateGradientColors();
      }

      if (_boardingBalanceSats > 0 && !_isSettling) {
        _settleBoarding();
      }

      if ((_recoverableSats > 0 || _expiredSats > 0) && !_isSettling) {
        _settleRecoverableVtxos();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refreshSwapsOnly() async {
    await _fetchSwaps();
  }

  Future<void> _fetchSwaps() async {
    try {
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }
      await _swapService.refreshSwaps();
      if (mounted) {
        setState(() {
          _swaps = List.from(_swapService.swaps);
        });
      }
      logger.i("Fetched ${_swaps.length} swaps");
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
        if (mounted) {
          setState(() {
            _lockedCollateralSats = totalLocked;
          });
        }
        logger.i(
            "Locked collateral: $_lockedCollateralSats sats from ${_lendasatService.activeContracts.length} active contracts");
      }
    } catch (e) {
      logger.w("Could not fetch locked collateral: $e");
    }
  }

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
      logger.w("Could not fetch boarding balance: $e");
    }
  }

  Future<void> _settleBoarding({bool manual = false}) async {
    if (_isSettling || _boardingBalanceSats == 0) return;

    if (!manual && _skipAutoSettle) {
      final lastAttempt = _lastSettleAttempt;
      if (lastAttempt != null &&
          DateTime.now().difference(lastAttempt).inMinutes < 5) {
        logger.d("Skipping auto-settle - waiting for more confirmations");
        return;
      }
      _skipAutoSettle = false;
    }

    setState(() {
      _isSettling = true;
    });

    try {
      logger.i("Settling $_boardingBalanceSats sats from boarding address...");
      await settle();
      logger.i("Settle completed successfully!");
      _skipAutoSettle = false;
      await _fetchBalance();
      await _fetchBoardingBalance();

      if (mounted) {
        OverlayService().showSuccess('Funds settled successfully!');
      }
    } catch (e) {
      logger.e("Error settling boarding UTXOs: $e");
      _lastSettleAttempt = DateTime.now();

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not yet valid') ||
          errorStr.contains('invalid_intent_timerange')) {
        _skipAutoSettle = true;
        if (manual && mounted) {
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
      await _fetchBalance();

      if (mounted && totalToRecover > 0) {
        OverlayService().showSuccess('Recovered $totalToRecover sats!');
      }
    } catch (e) {
      logger.e("Error settling recoverable VTXOs: $e");
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

      // Track boarding transactions for onchain receive detection
      // This allows us to show settled boarding txs as "Onchain" in history
      await BoardingTrackingService.processTransactions(transactions);

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
        OverlayService().showError(
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

      await SettingsService().setCachedBalance(
        total: newTotalBalance,
        confirmed: newConfirmedBalance,
        pending: newPendingBalance,
      );

      logger.i(
          "Balance updated: Total: $_totalBalance BTC, Confirmed: $_confirmedBalance BTC, Pending: $_pendingBalance BTC");
    } catch (e) {
      logger.e("Error fetching balance: $e");
      if (mounted) {
        setState(() {
          _isBalanceLoading = false;
        });
        OverlayService().showError(
            "${AppLocalizations.of(context)!.couldntUpdateBalance} ${e.toString()}");
      }
    }
  }

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
          availableSats: _totalBalance * BitcoinConstants.satsPerBtc,
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendScreen(
            aspId: widget.aspId,
            availableSats: _totalBalance * BitcoinConstants.satsPerBtc,
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
          BitNetAppBar(
            context: context,
            hasBackButton: false,
            text: l10n.bitcoinPriceChart,
          ),
          SizedBox(height: AppTheme.cardPadding * 1.5),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
              child: const BitcoinChartCard(),
            ),
          ),
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
    FocusScope.of(context).unfocus();

    final settingsController = context.read<SettingsController>();
    settingsController.resetToMain();

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Settings(aspId: widget.aspId),
    ).then((_) {
      _loadRecoveryStatus();
    });
  }

  List<WalletChartData> _getChartData() {
    if (_bitcoinPriceData.isEmpty) return [];
    _updateChartCalculator();
    return _chartCalculator!.getChartData();
  }

  (double, bool, double) _getPriceChangeMetrics() {
    if (_bitcoinPriceData.isEmpty) return (0.0, true, 0.0);
    _updateChartCalculator();
    return _chartCalculator!.calculatePriceChangeMetrics(_getCurrentBtcPrice());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (percentChange, isPositive, balanceChangeInFiat) =
        _getPriceChangeMetrics();

    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
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
          extendBodyBehindAppBar: true,
          body: RefreshIndicator(
            onRefresh: fetchWalletData,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Main wallet header with gradient and chart
                SliverToBoxAdapter(
                  child: WalletHeader(
                    totalBalance: _totalBalance,
                    btcPrice: _getCurrentBtcPrice(),
                    lockedCollateralSats: _lockedCollateralSats,
                    boardingBalanceSats: _boardingBalanceSats,
                    isSettling: _isSettling,
                    skipAutoSettle: _skipAutoSettle,
                    chartData: _getChartData(),
                    isBalanceLoading: _isBalanceLoading,
                    percentChange: percentChange,
                    isPositive: isPositive,
                    balanceChangeInFiat: balanceChangeInFiat,
                    gradientTopColor: _gradientTopColor,
                    gradientBottomColor: _gradientBottomColor,
                    hasAnyRecovery: _wordRecoverySet,
                    onSend: _handleSend,
                    onReceive: _handleReceive,
                    onScan: _handleScan,
                    onBuy: _handleBuy,
                    onChart: _handleBitcoinChart,
                    onSettings: _handleSettings,
                    onSettleBoarding: () => _settleBoarding(manual: true),
                  ),
                ),

                // Sticky header for transaction history
                _buildStickyTransactionHeader(),

                // Transaction list content
                SliverToBoxAdapter(
                  child: _buildTransactionList(),
                ),

                // Bottom padding with SafeArea
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
      showHeader: false,
    );
  }

  Widget _buildStickyTransactionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasTransactions = _transactions.isNotEmpty || _swaps.isNotEmpty;

    final double headerHeight = (!_isTransactionFetching && hasTransactions)
        ? 112.0 + AppTheme.cardPadding
        : 40.0 + AppTheme.cardPadding;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: headerHeight,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgColor,
                bgColor,
                bgColor.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.92, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    GestureDetector(
                      onTap: _isTransactionFetching
                          ? null
                          : () async {
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
                        Icons.tune,
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
