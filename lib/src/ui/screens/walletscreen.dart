import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/screens/bitcoin_chart/bitcoin_chart_detail_screen.dart';
import 'package:ark_flutter/src/ui/screens/buy/buy_screen.dart';
import 'package:ark_flutter/src/ui/screens/mempool/mempoolhome.dart';
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
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
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
  bool _isBalanceLoading = true;
  bool _isTransactionFetching = true;
  String? _balanceError;
  List<Transaction> _transactions = [];

  // Balance values
  double _pendingBalance = 0.0;
  double _confirmedBalance = 0.0;
  double _totalBalance = 0.0;

  // Display preferences
  BalanceType _currentBalanceType = BalanceType.total;

  // Bitcoin chart data
  TimeRange _selectedTimeRange = TimeRange.day;
  List<PriceData> _bitcoinPriceData = [];

  // Gradient colors (cached for performance)
  Color _gradientTopColor = BitNetTheme.successColor.withValues(alpha: 0.3);
  Color _gradientBottomColor =
      BitNetTheme.successColorGradient.withValues(alpha: 0.15);

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
      final priceData = await fetchBitcoinPriceData(_selectedTimeRange);
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

  void _updateGradientColors() {
    final isPositive = _isPriceChangePositive();
    setState(() {
      _gradientTopColor = isPositive
          ? BitNetTheme.successColor.withValues(alpha: 0.3)
          : BitNetTheme.errorColor.withValues(alpha: 0.3);
      _gradientBottomColor = isPositive
          ? BitNetTheme.successColorGradient.withValues(alpha: 0.15)
          : BitNetTheme.errorColorGradient.withValues(alpha: 0.15);
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
      _balanceError = null;
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
        _balanceError = e.toString();
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
        backgroundColor: BitNetTheme.colorBitcoin,
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
        backgroundColor: BitNetTheme.errorColor,
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

  String _formatBitcoinAmount(double amount) {
    String formatted = amount.toStringAsFixed(8);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');

    int decimalIndex = formatted.indexOf('.');
    if (decimalIndex == -1) {
      formatted = '$formatted.00';
    } else {
      int decimalPlaces = formatted.length - decimalIndex - 1;
      if (decimalPlaces < 2) {
        formatted = formatted.padRight(decimalIndex + 3, '0');
      }
    }

    return formatted;
  }

  /// Get current BTC price in USD from price data
  double _getCurrentBtcPrice() {
    if (_bitcoinPriceData.isEmpty) return 65000.0; // Fallback
    return _bitcoinPriceData.last.price;
  }

  void _cycleTimeRange() {
    setState(() {
      switch (_selectedTimeRange) {
        case TimeRange.day:
          _selectedTimeRange = TimeRange.week;
          break;
        case TimeRange.week:
          _selectedTimeRange = TimeRange.month;
          break;
        case TimeRange.month:
          _selectedTimeRange = TimeRange.year;
          break;
        case TimeRange.year:
          _selectedTimeRange = TimeRange.max;
          break;
        case TimeRange.max:
          _selectedTimeRange = TimeRange.day;
          break;
      }
    });
    _loadBitcoinPriceData();
  }

  String _getTimeRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return '1D';
      case TimeRange.week:
        return '1W';
      case TimeRange.month:
        return '1M';
      case TimeRange.year:
        return '1Y';
      case TimeRange.max:
        return 'Max';
    }
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

  void _handleMempool() {
    logger.i("Mempool button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MempoolHome(),
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
    final theme = AppTheme.of(context, listen: false);
    final settingsController = context.read<SettingsController>();
    settingsController.resetToMain();

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: theme.primaryBlack,
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
                        const SizedBox(height: BitNetTheme.cardPadding),
                        _buildTopBar(),
                        const SizedBox(height: BitNetTheme.cardPadding * 1.5),
                        _buildBalanceDisplay(),
                        const SizedBox(height: BitNetTheme.elementSpacing),
                        _buildPriceChangeIndicators(),
                        const SizedBox(height: BitNetTheme.cardPadding * 1.5),
                        _buildActionButtons(),
                        const SizedBox(height: BitNetTheme.cardPadding),
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
              child: SizedBox(height: BitNetTheme.cardPadding),
            ),

            // Transaction list (TransactionHistoryWidget has its own header)
            SliverToBoxAdapter(
              child: _buildTransactionList(),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: BitNetTheme.cardPadding * 2),
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
      padding: const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar
          Avatar(
            onTap: () {},
            size: BitNetTheme.cardPadding * 1.5,
            type: ProfilePictureType.lightning,
          ),

          // Action buttons
          Row(
            children: [
              // Time range button
              LongButtonWidget(
                padding: EdgeInsetsGeometry.zero,
                title: _getTimeRangeLabel(_selectedTimeRange),
                buttonType: ButtonType.transparent,
                onTap: _cycleTimeRange,
                customHeight: BitNetTheme.cardPadding * 1.5,
                customWidth: BitNetTheme.cardPadding * 2.5,
                leadingIcon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                ),
              ),
              const SizedBox(width: BitNetTheme.elementSpacing * 0.75),

              // Hide balance button
              Consumer<UserPreferencesService>(
                builder: (context, userPrefs, _) => RoundedButtonWidget(
                  size: BitNetTheme.cardPadding * 1.5,
                  buttonType: ButtonType.transparent,
                  iconData: userPrefs.balancesVisible
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  onTap: userPrefs.toggleBalancesVisible,
                ),
              ),
              const SizedBox(width: BitNetTheme.elementSpacing * 0.5),

              // Refresh button
              RoundedButtonWidget(
                size: BitNetTheme.cardPadding * 1.5,
                buttonType: ButtonType.transparent,
                iconData: Icons.refresh,
                onTap: _fetchWalletData,
              ),
              const SizedBox(width: BitNetTheme.elementSpacing * 0.5),

              // Mempool button
              RoundedButtonWidget(
                size: BitNetTheme.cardPadding * 1.5,
                buttonType: ButtonType.transparent,
                iconData: Icons.memory_rounded,
                onTap: _handleMempool,
              ),
              const SizedBox(width: BitNetTheme.elementSpacing * 0.5),

              // Settings button
              RoundedButtonWidget(
                size: BitNetTheme.cardPadding * 1.5,
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
    final theme = AppTheme.of(context);
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_isBalanceLoading)
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_balanceError != null)
            const Text(
              'Error loading balance',
              style: TextStyle(
                color: BitNetTheme.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            GestureDetector(
              onTap: _toggleDisplayUnit,
              onLongPress: _toggleBalanceType,
              behavior: HitTestBehavior.opaque,
              child: currencyService.showCoinBalance
                  ? Text(
                      userPrefs.balancesVisible
                          ? '₿ ${_formatBitcoinAmount(_getSelectedBalance())}'
                          : '₿ ********',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: theme.primaryWhite,
                          ),
                    )
                  : Text(
                      userPrefs.balancesVisible
                          ? currencyService.formatAmount(
                              _getSelectedBalance() * _getCurrentBtcPrice())
                          : '${currencyService.symbol}****.**',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: theme.primaryWhite,
                          ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceChangeIndicators() {
    if (_bitcoinPriceData.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyService = context.watch<CurrencyPreferenceService>();
    final firstPrice = _bitcoinPriceData.first.price;
    final lastPrice = _bitcoinPriceData.last.price;
    final diff = lastPrice - firstPrice;
    final percentChange = firstPrice != 0 ? (diff / firstPrice) * 100 : 0.0;
    final isPositive = diff >= 0;

    final balanceChange = _getSelectedBalance() * (diff / firstPrice);
    final btcToFiat = _getCurrentBtcPrice();
    final balanceChangeInFiat = balanceChange * btcToFiat;

    return GestureDetector(
      onTap: _toggleDisplayUnit,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColoredPriceWidget(
              price: currencyService.showCoinBalance
                  ? '${_formatBitcoinAmount(balanceChange.abs())} ₿'
                  : currencyService.formatAmount(balanceChangeInFiat.abs()),
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
      padding: const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.send ?? "Send",
              _handleSend,
              width: BitNetTheme.cardPadding * 2.5,
              height: BitNetTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_upward_rounded,
            ),
          ),
          Flexible(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.receive ?? "Receive",
              _handleReceive,
              width: BitNetTheme.cardPadding * 2.5,
              height: BitNetTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_downward_rounded,
            ),
          ),
          Flexible(
            child: BitNetImageWithTextButton(
              "Sell",
              _handleSell,
              width: BitNetTheme.cardPadding * 2.5,
              height: BitNetTheme.cardPadding * 2.5,
              fallbackIcon: Icons.sell_outlined,
            ),
          ),
          Flexible(
            child: BitNetImageWithTextButton(
              "Buy",
              _handleBuy,
              width: BitNetTheme.cardPadding * 2.5,
              height: BitNetTheme.cardPadding * 2.5,
              fallbackIcon: FontAwesomeIcons.btc,
              fallbackIconSize: BitNetTheme.iconSize * 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptosSection() {
    final theme = AppTheme.of(context);
    // Convert total balance to sats for display
    final balanceInSats = (_totalBalance * 100000000).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: BitNetTheme.cardPadding * 1.75),
          Text(
            "Cryptos",
            style: TextStyle(
              color: theme.primaryWhite,
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
                isPositive ? BitNetTheme.successColor : BitNetTheme.errorColor,
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
  final theme = AppTheme.of(context);

  showModalBottomSheet(
    context: context,
    elevation: 0.0,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(BitNetTheme.borderRadiusBig),
        topRight: Radius.circular(BitNetTheme.borderRadiusBig),
      ),
    ),
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: theme.primaryBlack,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(BitNetTheme.borderRadiusBig),
            topRight: Radius.circular(BitNetTheme.borderRadiusBig),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: BitNetTheme.elementSpacing),
            Container(
              height: BitNetTheme.elementSpacing / 1.375,
              width: BitNetTheme.cardPadding * 2.25,
              decoration: BoxDecoration(
                color: theme.mutedText.withValues(alpha: 0.5),
                borderRadius:
                    BorderRadius.circular(BitNetTheme.borderRadiusCircular),
              ),
            ),
            const SizedBox(height: BitNetTheme.cardPadding),
            Text(
              "Select Timeframe",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: theme.primaryWhite,
                  ),
            ),
            const SizedBox(height: BitNetTheme.cardPadding),
            ...TimeRange.values.map((range) {
              final isSelected = currentRange == range;
              return ListTile(
                leading: Icon(
                  _getTimeframeIcon(range),
                  color: isSelected
                      ? BitNetTheme.colorBitcoin
                      : theme.primaryWhite,
                ),
                title: Text(
                  _getTimeframeLabel(range),
                  style: TextStyle(
                    color: theme.primaryWhite,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: BitNetTheme.colorBitcoin)
                    : null,
                onTap: () {
                  onSelect(range);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: BitNetTheme.cardPadding),
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
