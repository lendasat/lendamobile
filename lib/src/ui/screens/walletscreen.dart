import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/screens/bitcoin_chart/bitcoin_chart_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/buy/buy_screen.dart';
import 'package:ark_flutter/src/ui/screens/receivescreen.dart';
import 'package:ark_flutter/src/ui/screens/sell/sell_screen.dart';
import 'package:ark_flutter/src/ui/screens/send_screen.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings.dart';
import 'package:ark_flutter/src/ui/screens/transaction_history_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_image_text_button.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/crypto_info_item.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/price_widgets.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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

class WalletScreenState extends State<WalletScreen> {
  // Loading states
  bool _isBalanceLoading = false;
  bool _isTransactionFetching = true;
  List<Transaction> _transactions = [];

  // Balance values
  double _pendingBalance = 0.0;
  double _confirmedBalance = 0.0;
  double _totalBalance = 0.0;

  // Display preferences
  BalanceType _currentBalanceType = BalanceType.total;

  // Bitcoin chart data
  List<PriceData> _bitcoinPriceData = [];

  // Gradient colors (cached for performance)
  Color _gradientTopColor = AppTheme.successColor.withValues(alpha: 0.3);
  Color _gradientBottomColor =
      AppTheme.successColorGradient.withValues(alpha: 0.15);

  // Scroll controller for nested scrolling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    logger.i("WalletScreen initialized with ASP ID: ${widget.aspId}");
    _fetchWalletData();
    _loadBitcoinPriceData();

    // Fetch exchange rates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyPreferenceService>().fetchExchangeRates();
    });
  }

  @override
  void dispose() {
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

    final firstPrice = _bitcoinPriceData.first.price;
    final lastPrice = _bitcoinPriceData.last.price;
    final diff = lastPrice - firstPrice;

    return diff >= 0 || diff.abs() < 0.001;
  }

  Future<void> _fetchWalletData() async {
    await Future.wait([
      _fetchBalance(),
      _fetchTransactions(),
    ]);
  }

  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        _isTransactionFetching = true;
      });

      final transactions = await txHistory();
      setState(() {
        _isTransactionFetching = false;
        _transactions = transactions;
      });
      logger.i("Fetched ${transactions.length} transactions");
    } catch (e) {
      logger.e("Error fetching transaction history: $e");
      if (mounted) {
        _showErrorSnackbar(
            "${AppLocalizations.of(context)!.couldntUpdateTransactions} ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTransactionFetching = false;
        });
      }
    }
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isBalanceLoading = true;
    });

    try {
      final balanceResult = await balance();

      setState(() {
        _pendingBalance =
            balanceResult.offchain.pendingSats.toDouble() / 100000000;
        _confirmedBalance =
            balanceResult.offchain.confirmedSats.toDouble() / 100000000;
        _totalBalance = balanceResult.offchain.totalSats.toDouble() / 100000000;
        _isBalanceLoading = false;
      });

      logger.i(
          "Balance updated: Total: $_totalBalance BTC, Confirmed: $_confirmedBalance BTC, Pending: $_pendingBalance BTC");
    } catch (e) {
      logger.e("Error fetching balance: $e");
      setState(() {
        _isBalanceLoading = false;
      });

      if (mounted) {
        _showErrorSnackbar(
            "${AppLocalizations.of(context)!.couldntUpdateBalance} ${e.toString()}");
      }
    }
  }

  void _toggleBalanceType() {
    setState(() {
      switch (_currentBalanceType) {
        case BalanceType.total:
          _currentBalanceType = BalanceType.pending;
          break;
        case BalanceType.pending:
          _currentBalanceType = BalanceType.confirmed;
          break;
        case BalanceType.confirmed:
          _currentBalanceType = BalanceType.total;
          break;
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!
            .showingBalanceType(_currentBalanceType.name)),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.colorBitcoin,
      ),
    );
  }

  void _toggleDisplayUnit() {
    context.read<CurrencyPreferenceService>().toggleShowCoinBalance();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.retry,
          textColor: Colors.white,
          onPressed: _fetchWalletData,
        ),
      ),
    );
  }

  double _getSelectedBalance() {
    switch (_currentBalanceType) {
      case BalanceType.pending:
        return _pendingBalance;
      case BalanceType.confirmed:
        return _confirmedBalance;
      case BalanceType.total:
        return _totalBalance;
    }
  }

  /// Get current BTC price in USD from price data
  double _getCurrentBtcPrice() {
    if (_bitcoinPriceData.isEmpty) return 65000.0; // Fallback
    return _bitcoinPriceData.last.price;
  }

  // Navigation handlers
  void _handleSend() {
    logger.i("Send button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendScreen(
          aspId: widget.aspId,
          availableSats: _getSelectedBalance() * 100000000,
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
        ),
      ),
    );
    // Refresh wallet data when returning
    logger.i("Returned from receive flow, refreshing wallet data");
    _fetchWalletData();
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

  void _handleSell() {
    logger.i("Sell button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellScreen(),
      ),
    );
  }

  void _handleBitcoinChart() {
    logger.i("Bitcoin chart button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BitcoinChartDetailScreen(),
      ),
    );
  }

  void _handleSettings() {
    final settingsController = context.read<SettingsController>();
    settingsController.resetToMain();

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Settings(aspId: widget.aspId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Main wallet header with gradient and chart
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Dynamic gradient background
                  _buildDynamicGradient(),

                  // Chart overlay
                  Opacity(
                    opacity: 0.1,
                    child: _buildChartWidget(),
                  ),

                  // Main content
                  SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: AppTheme.cardPadding),
                        _buildTopBar(),
                        const SizedBox(height: AppTheme.cardPadding * 1.5),
                        _buildBalanceDisplay(),
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

            // Cryptos section
            SliverToBoxAdapter(
              child: _buildCryptosSection(),
            ),

            // Spacing before transaction list
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.cardPadding),
            ),

            // Transaction list (TransactionHistoryWidget has its own header)
            SliverToBoxAdapter(
              child: _buildTransactionList(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.cardPadding * 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicGradient() {
    return Container(
      height: 320,
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

  Widget _buildChartWidget() {
    if (_bitcoinPriceData.isEmpty || _isBalanceLoading) {
      return const SizedBox(height: 320);
    }

    return SizedBox(
      height: 320,
      child: BitcoinPriceChart(
        data: _bitcoinPriceData,
        alpha: 255,
        trackballActivationMode: null,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar - larger size
          Avatar(
            onTap: () {},
            size: AppTheme.cardPadding * 2.25,
            type: ProfilePictureType.lightning,
          ),

          // Action buttons
          Row(
            children: [
              // Hide balance button
              Consumer<UserPreferencesService>(
                builder: (context, userPrefs, _) => RoundedButtonWidget(
                  size: AppTheme.cardPadding * 1.5,
                  buttonType: ButtonType.transparent,
                  iconData: userPrefs.balancesVisible
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  onTap: userPrefs.toggleBalancesVisible,
                ),
              ),
              const SizedBox(width: AppTheme.elementSpacing * 0.5),

              // Settings button
              RoundedButtonWidget(
                size: AppTheme.cardPadding * 1.5,
                buttonType: ButtonType.transparent,
                iconData: Icons.settings,
                onTap: _handleSettings,
              ),
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
    final balanceInSats = (_getSelectedBalance() * 100000000).round();
    final formattedSats = _formatSatsAmount(balanceInSats);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _toggleDisplayUnit,
            onLongPress: _toggleBalanceType,
            behavior: HitTestBehavior.opaque,
            child: currencyService.showCoinBalance
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userPrefs.balancesVisible ? formattedSats : '********',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        AppTheme.satoshiIcon,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  )
                : Text(
                    userPrefs.balancesVisible
                        ? currencyService.formatAmount(
                            _getSelectedBalance() * _getCurrentBtcPrice())
                        : '${currencyService.symbol}****.**',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildPriceChangeIndicators() {
    final currencyService = context.watch<CurrencyPreferenceService>();

    // Default values when no data is available
    double percentChange = 0.0;
    bool isPositive = true;
    double balanceChangeInFiat = 0.0;
    double balanceChange = 0.0;

    if (_bitcoinPriceData.isNotEmpty) {
      final firstPrice = _bitcoinPriceData.first.price;
      final lastPrice = _bitcoinPriceData.last.price;
      final diff = lastPrice - firstPrice;
      percentChange = firstPrice != 0 ? (diff / firstPrice) * 100 : 0.0;
      isPositive = diff >= 0;

      balanceChange = firstPrice != 0
          ? _getSelectedBalance() * (diff / firstPrice)
          : 0.0;
      final btcToFiat = _getCurrentBtcPrice();
      balanceChangeInFiat = balanceChange * btcToFiat;
    }

    // Convert balance change to sats
    final balanceChangeInSats = (balanceChange.abs() * 100000000).round();

    return GestureDetector(
      onTap: _toggleDisplayUnit,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
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
                        _formatSatsAmount(balanceChangeInSats),
                        style: TextStyle(
                          color: isPositive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        AppTheme.satoshiIcon,
                        size: 14,
                        color: isPositive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ],
                  )
                : ColoredPriceWidget(
                    price: currencyService.formatAmount(balanceChangeInFiat.abs()),
                    isPositive: isPositive,
                    shouldHideAmount: true,
                  ),
            const SizedBox(width: 8),
            BitNetPercentWidget(
              priceChange:
                  '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
              shouldHideAmount: true,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.send ?? "Send",
              _handleSend,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_upward_rounded,
            ),
          ),
          Flexible(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.receive ?? "Receive",
              _handleReceive,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_downward_rounded,
            ),
          ),
          Flexible(
            child: BitNetImageWithTextButton(
              "Sell",
              _handleSell,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.sell_outlined,
            ),
          ),
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

  Widget _buildCryptosSection() {
    // Convert total balance to sats for display
    final balanceInSats = (_totalBalance * 100000000).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.cardPadding * 1.75),
          Text(
            "Cryptos",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.paddingM),
          CryptoInfoItem(
            balance: balanceInSats.toString(),
            defaultUnit: BitcoinUnits.SAT,
            currency: Currency(
              code: 'BTC',
              name: 'Bitcoin (Onchain)',
              icon: Image.asset("assets/images/bitcoin.png"),
            ),
            context: context,
            onTap: _handleBitcoinChart,
            bitcoinPrice: _getCurrentBtcPrice(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final userPrefs = context.watch<UserPreferencesService>();
    final currencyService = context.watch<CurrencyPreferenceService>();

    return TransactionHistoryWidget(
      aspId: widget.aspId,
      transactions: _transactions,
      loading: _isTransactionFetching,
      hideAmounts: !userPrefs.balancesVisible,
      showBtcAsMain: currencyService.showCoinBalance,
    );
  }
}

/// Widget for displaying the price chart in the wallet
/// Extracted to reduce rebuild scope and improve performance
class WalletChartWidget extends StatelessWidget {
  final List<PriceData> priceData;
  final bool isPositive;

  const WalletChartWidget({
    super.key,
    required this.priceData,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (priceData.isEmpty) {
      return const SizedBox(height: 250);
    }

    return SizedBox(
      height: 250,
      child: SfCartesianChart(
        enableAxisAnimation: false,
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          labelPlacement: LabelPlacement.onTicks,
          edgeLabelPlacement: EdgeLabelPlacement.none,
          isVisible: false,
          majorGridLines: MajorGridLines(width: 0),
          majorTickLines: MajorTickLines(width: 0),
        ),
        primaryYAxis: const NumericAxis(
          plotOffset: 0,
          edgeLabelPlacement: EdgeLabelPlacement.none,
          isVisible: false,
          majorGridLines: MajorGridLines(width: 0),
          majorTickLines: MajorTickLines(width: 0),
        ),
        series: <CartesianSeries>[
          SplineSeries<PriceData, double>(
            dataSource: priceData,
            animationDuration: 0,
            xValueMapper: (PriceData data, _) => data.time.toDouble(),
            yValueMapper: (PriceData data, _) => data.price,
            color:
                isPositive ? AppTheme.successColor : AppTheme.errorColor,
            width: 3,
            splineType: SplineType.natural,
          ),
        ],
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
