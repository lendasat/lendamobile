import 'dart:async';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' show PaymentReceived;
import 'package:ark_flutter/src/services/payment_monitoring_service.dart'
    show PaymentMonitoringService;
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
import 'package:ark_flutter/src/services/transaction_filter_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/wallet/wallet_header.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'wallet_config.dart';
import 'wallet_controller.dart';

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
  late final WalletController _controller;

  // UI controllers
  final GlobalKey<TransactionHistoryWidgetState> _transactionHistoryKey =
      GlobalKey<TransactionHistoryWidgetState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _keyboardDebounceTimer;
  bool _wasKeyboardVisible = false;

  // Payment stream subscription
  StreamSubscription<PaymentReceived>? _paymentSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WalletController(aspId: widget.aspId);
    logger.i("WalletScreen initialized with ASP ID: ${widget.aspId}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final userPrefs = context.read<UserPreferencesService>();
    context.read<CurrencyPreferenceService>().fetchExchangeRates();
    await _controller.initialize(userPrefs);
    _checkAndShowAlphaWarning();

    // Subscribe to payment stream for auto-refresh
    final paymentService = context.read<PaymentMonitoringService>();
    _paymentSubscription = paymentService.paymentStream.listen((payment) {
      logger.i(
          "WalletScreen received payment notification: ${payment.amountSats} sats");
      if (mounted) {
        _controller.fetchWalletData();
      }
    });
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
    _keyboardDebounceTimer = Timer(
      const Duration(milliseconds: WalletConfig.keyboardDebounceMs),
      () {
        if (!mounted) return;
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        if (_wasKeyboardVisible && !keyboardVisible) {
          _transactionHistoryKey.currentState?.unfocusSearch();
        }
        _wasKeyboardVisible = keyboardVisible;
      },
    );
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
              onTap: () => Navigator.of(context).pop(),
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
    _paymentSubscription?.cancel();
    _keyboardDebounceTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Public methods for external refresh
  Future<void> fetchWalletData() => _controller.fetchWalletData();
  Future<void> refreshSwapsOnly() => _controller.refreshSwapsOnly();

  // Navigation handlers
  void _handleSend() {
    final state = _controller.state;
    logger.i("Send button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipientSearchScreen(
          aspId: widget.aspId,
          availableSats: state.totalBalance * BitcoinConstants.satsPerBtc,
          spendableSats: (state.confirmedBalance + state.pendingBalance) *
              BitcoinConstants.satsPerBtc,
          bitcoinPrice: state.currentBtcPrice,
        ),
      ),
    );
  }

  Future<void> _handleReceive() async {
    final state = _controller.state;
    logger.i("Receive button pressed");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiveScreen(
          aspId: widget.aspId,
          amount: 0,
          bitcoinPrice: state.currentBtcPrice,
        ),
      ),
    );
    logger.i("Returned from receive flow, refreshing wallet data");
    _controller.fetchWalletData();
  }

  Future<void> _handleScan() async {
    final state = _controller.state;
    logger.i("Scan button pressed");
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      logger.i("Scanned QR code: $result");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendScreen(
            aspId: widget.aspId,
            availableSats: state.totalBalance * BitcoinConstants.satsPerBtc,
            spendableSats: (state.confirmedBalance + state.pendingBalance) *
                BitcoinConstants.satsPerBtc,
            initialAddress: result,
            bitcoinPrice: state.currentBtcPrice,
          ),
        ),
      );
    }
  }

  void _handleBuy() {
    logger.i("Buy button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BuyScreen()),
    );
  }

  void _handleBitcoinChart() {
    final l10n = AppLocalizations.of(context)!;

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height *
          WalletConfig.chartSheetHeightRatio,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          BitNetAppBar(
            context: context,
            hasBackButton: false,
            text: l10n.bitcoinPriceChart,
          ),
          SizedBox(height: AppTheme.cardPadding * 1.5),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
              child: BitcoinChartCard(),
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
      height: MediaQuery.of(context).size.height *
          WalletConfig.settingsSheetHeightRatio,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Settings(aspId: widget.aspId),
    ).then((_) {
      _controller.loadRecoveryStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          body: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final state = _controller.state;
              final (percentChange, isPositive, balanceChangeInFiat) =
                  _controller.getPriceChangeMetrics();

              return RefreshIndicator(
                onRefresh: _controller.fetchWalletData,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: WalletHeader(
                        totalBalance: state.totalBalance,
                        btcPrice: state.currentBtcPrice,
                        lockedCollateralSats: state.lockedCollateralSats,
                        boardingBalanceSats: state.boardingBalanceSats,
                        isSettling: state.isSettling,
                        skipAutoSettle: state.skipAutoSettle,
                        chartData: _controller.getChartData(),
                        isBalanceLoading: state.isBalanceLoading,
                        percentChange: percentChange,
                        isPositive: isPositive,
                        balanceChangeInFiat: balanceChangeInFiat,
                        gradientTopColor: state.gradientTopColor,
                        gradientBottomColor: state.gradientBottomColor,
                        hasAnyRecovery: state.wordRecoverySet,
                        onSend: _handleSend,
                        onReceive: _handleReceive,
                        onScan: _handleScan,
                        onBuy: _handleBuy,
                        onChart: _handleBitcoinChart,
                        onSettings: _handleSettings,
                        onSettleBoarding: () =>
                            _controller.settleBoarding(manual: true),
                      ),
                    ),
                    _StickyTransactionHeader(
                      isTransactionFetching: state.isTransactionFetching,
                      hasTransactions: state.hasTransactions,
                      transactionHistoryKey: _transactionHistoryKey,
                      onRefresh: () async {
                        await _controller.fetchWalletData();
                      },
                    ),
                    _TransactionList(
                      transactionHistoryKey: _transactionHistoryKey,
                      aspId: widget.aspId,
                      transactions: state.transactions,
                      swaps: state.swaps,
                      isLoading: state.isTransactionFetching,
                      bitcoinPrice: state.currentBtcPrice,
                    ),
                    SliverToBoxAdapter(
                      child: SafeArea(
                        top: false,
                        child: SizedBox(height: AppTheme.cardPadding * 2),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sticky header for transaction list.
class _StickyTransactionHeader extends StatelessWidget {
  final bool isTransactionFetching;
  final bool hasTransactions;
  final GlobalKey<TransactionHistoryWidgetState> transactionHistoryKey;
  final VoidCallback onRefresh;

  const _StickyTransactionHeader({
    required this.isTransactionFetching,
    required this.hasTransactions,
    required this.transactionHistoryKey,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final double headerHeight = (!isTransactionFetching && hasTransactions)
        ? WalletConfig.headerHeightWithSearch + AppTheme.cardPadding
        : WalletConfig.headerHeightBasic + AppTheme.cardPadding;

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
                isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.6),
                isDark
                    ? Colors.black.withValues(alpha: 0)
                    : Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.75, 0.9, 1.0],
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
                      onTap: isTransactionFetching ? null : onRefresh,
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
              if (!isTransactionFetching && hasTransactions)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.cardPadding,
                    right: AppTheme.cardPadding,
                    top: AppTheme.elementSpacing,
                    bottom: AppTheme.elementSpacing,
                  ),
                  child: Consumer<TransactionFilterService>(
                    builder: (context, filterService, _) {
                      final hasActiveFilter = filterService.hasAnyFilter;
                      return SearchFieldWidget(
                        hintText: l10n.search,
                        isSearchEnabled: true,
                        handleSearch: (value) {
                          transactionHistoryKey.currentState
                              ?.applySearchFromExternal(value);
                        },
                        onChanged: (value) {
                          transactionHistoryKey.currentState
                              ?.applySearchFromExternal(value);
                        },
                        suffixIcon: IconButton(
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.tune,
                                color: hasActiveFilter
                                    ? AppTheme.colorBitcoin
                                    : isDark
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                size: AppTheme.cardPadding * 0.75,
                              ),
                              if (hasActiveFilter)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.colorBitcoin,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            await arkBottomSheet(
                              context: context,
                              height: MediaQuery.of(context).size.height *
                                  WalletConfig.filterSheetHeightRatio,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              child: const TransactionFilterScreen(),
                            );
                            transactionHistoryKey.currentState?.refreshFilter();
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transaction list widget.
class _TransactionList extends StatelessWidget {
  final GlobalKey<TransactionHistoryWidgetState> transactionHistoryKey;
  final String aspId;
  final List transactions;
  final List swaps;
  final bool isLoading;
  final double bitcoinPrice;

  const _TransactionList({
    required this.transactionHistoryKey,
    required this.aspId,
    required this.transactions,
    required this.swaps,
    required this.isLoading,
    required this.bitcoinPrice,
  });

  @override
  Widget build(BuildContext context) {
    final balancesVisible = context.select<UserPreferencesService, bool>(
      (service) => service.balancesVisible,
    );
    final showCoinBalance = context.select<CurrencyPreferenceService, bool>(
      (service) => service.showCoinBalance,
    );

    return TransactionHistoryWidget(
      key: transactionHistoryKey,
      aspId: aspId,
      transactions: transactions.cast(),
      swaps: swaps.cast(),
      loading: isLoading,
      hideAmounts: !balancesVisible,
      showBtcAsMain: showCoinBalance,
      bitcoinPrice: bitcoinPrice,
      showHeader: false,
      asSliverList: true,
    );
  }
}
