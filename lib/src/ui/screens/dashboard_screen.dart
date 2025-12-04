import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/screens/transaction_history_widget.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/settings/settings.dart';
import 'package:ark_flutter/src/ui/screens/send_screen.dart';
import 'package:ark_flutter/src/ui/screens/receive_screen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/screens/bitcoin_chart/bitcoin_chart_detail_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/ui/screens/buy/buy_screen.dart';
import 'package:ark_flutter/src/ui/screens/sell/sell_screen.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/ui/screens/mempool/mempool_home.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:provider/provider.dart';

enum BalanceType { pending, confirmed, total }

class DashboardScreen extends StatefulWidget {
  final String aspId;

  const DashboardScreen({
    super.key,
    required this.aspId,
  });

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceLoading = true;
  bool _isTransactionFetching = true;
  String? _balanceError;
  List<Transaction> _transactions = [];

  // Store all balance types
  double _pendingBalance = 0.0;
  double _confirmedBalance = 0.0;
  double _totalBalance = 0.0;

  // Current selections
  BalanceType _currentBalanceType = BalanceType.total;
  bool _showBtcAsMain = true; // Toggle between BTC and USD as main display

  // Exchange rate
  final double _btcToUsdRate = 65000.0;

  // Balance visibility and bitcoin chart
  bool _balancesVisible = true;
  TimeRange _selectedTimeRange = TimeRange.day;
  List<PriceData> _bitcoinPriceData = [];

  @override
  void initState() {
    super.initState();
    logger.i("Dashboard initialized with ASP ID: ${widget.aspId}");
    _loadBalanceVisibility();
    _fetchWalletData();

    // Fetch exchange rates when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyPreferenceService>().fetchExchangeRates();
    });
    _loadBitcoinPriceData();
  }

  Future<void> _loadBalanceVisibility() async {
    try {
      final balancesVisible = await UserPreferencesService.getBalancesVisible();
      if (mounted) {
        setState(() {
          _balancesVisible = balancesVisible;
        });
      }
    } catch (e) {
      logger.e('Error loading balance visibility: $e');
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    final newVisibility = !_balancesVisible;
    setState(() {
      _balancesVisible = newVisibility;
    });

    try {
      await UserPreferencesService.setBalancesVisible(newVisibility);
    } catch (e) {
      logger.e('Error saving balance visibility: $e');
    }
  }

  Future<void> _loadBitcoinPriceData() async {
    try {
      final priceData = await fetchBitcoinPriceData(_selectedTimeRange);
      if (mounted) {
        setState(() {
          _bitcoinPriceData = priceData;
        });
      }
    } catch (e) {
      logger.e('Error loading bitcoin price data: $e');
      // Don't show error to user, just log it
    }
  }

  void _changeTimeRange(TimeRange newRange) {
    setState(() {
      _selectedTimeRange = newRange;
    });
    // Schedule data loading after 1 second to ensure popup closes first
    Future.delayed(const Duration(seconds: 1), () => _loadBitcoinPriceData());
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
      setState(() {
        _isTransactionFetching = false;
      });
    }
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isBalanceLoading = true;
      _balanceError = null;
    });

    try {
      // Call the Rust balance function
      final balanceResult = await balance();

      // Store all balance types (converting from sats to BTC)
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

      _showErrorSnackbar(
          "${AppLocalizations.of(context)!.couldntUpdateBalance} ${e.toString()}");
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

    // Show a toast to indicate the change
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!
            .showingBalanceType(_currentBalanceType.name)),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _toggleDisplayUnit() {
    setState(() {
      _showBtcAsMain = !_showBtcAsMain;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.retry,
          textColor: Colors.white,
          onPressed: _fetchWalletData,
        ),
      ),
    );
  }

  void _handleSend() {
    // Navigate to send screen
    logger.i("Send button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendScreen(
          aspId: widget.aspId,
          availableSats:
              _getSelectedBalance() * 100000000, // Convert BTC to SATS
        ),
      ),
    );
  }

  Future<void> _handleReceive() async {
    // Navigate directly to receive screen
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

    // Refresh wallet data when returning from receive flow
    // This will update the transaction history if a payment was received
    logger.i("Returned from receive flow, refreshing wallet data");
    _fetchWalletData();
  }

  void _handleViewChart() {
    // Navigate to bitcoin chart screen
    logger.i("Bitcoin chart button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BitcoinChartDetailScreen(),
      ),
    );
  }

  void _handleMempool() {
    // Navigate to mempool screen
    logger.i("Mempool button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MempoolHome(),
      ),
    );
  }

  void _handleBuy() {
    // Navigate to buy screen
    logger.i("Buy button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuyScreen(),
      ),
    );
  }

  void _handleSell() {
    // Navigate to sell screen
    logger.i("Sell button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellScreen(),
      ),
    );
  }

  // Helper methods for the balance display
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

  String _getBalanceTypeText() {
    switch (_currentBalanceType) {
      case BalanceType.pending:
        return AppLocalizations.of(context)!.pendingBalance;
      case BalanceType.confirmed:
        return AppLocalizations.of(context)!.confirmedBalance;
      case BalanceType.total:
        return AppLocalizations.of(context)!.totalBalance;
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  _buildDynamicGradient(),
                  Opacity(
                    opacity: 0.1,
                    child: _buildChartWidget(),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTopBar(),
                        const SizedBox(height: 40),
                        _buildBalanceDisplay(),
                        const SizedBox(height: 24),
                        _buildPriceChangeIndicators(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                child: _buildRecentTransactions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _successColor = Color(0xFF5DE165);
  static const Color _successColorGradient = Color(0xFF148C1A);
  static const Color _errorColor = Color(0xFFFF6363);
  static const Color _errorColorGradient = Color(0xFFC54545);

  bool _isPriceChangePositive() {
    if (_bitcoinPriceData.isEmpty) return true;

    final firstPrice = _bitcoinPriceData.first.price;
    final lastPrice = _bitcoinPriceData.last.price;
    final diff = lastPrice - firstPrice;

    return diff >= 0 || diff.abs() < 0.001;
  }

  Widget _buildDynamicGradient() {
    final isPositive = _isPriceChangePositive();

    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.75, 1.0],
          colors: [
            isPositive
                ? _successColor.withValues(alpha: 0.3)
                : _errorColor.withValues(alpha: 0.3),
            isPositive
                ? _successColorGradient.withValues(alpha: 0.15)
                : _errorColorGradient.withValues(alpha: 0.15),
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
    final theme = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile picture icon (decorative)
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.tertiaryBlack.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(40 / 3),
              ),
              child: Icon(
                Icons.person,
                color: theme.primaryWhite,
                size: 24,
              ),
            ),
          ),

          Row(
            children: [
              _buildTimeRangeCycleButton(),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.view_module_outlined,
                onPressed: _handleMempool,
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon:
                    _balancesVisible ? Icons.visibility_off : Icons.visibility,
                onPressed: _toggleBalanceVisibility,
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.refresh,
                onPressed: _fetchWalletData,
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.settings,
                onPressed: () {
                  final settingsController = context.read<SettingsController>();
                  settingsController.resetToMain();

                  arkBottomSheet(
                    context: context,
                    height: MediaQuery.of(context).size.height * 0.85,
                    backgroundColor: theme.primaryBlack,
                    child: Settings(aspId: widget.aspId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeCycleButton() {
    final theme = AppTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    String getTimeRangeLabel(TimeRange range) {
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

    return GestureDetector(
      onTap: _cycleTimeRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(40 / 3),
          border: isLight
              ? Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                getTimeRangeLabel(_selectedTimeRange),
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = AppTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(40 / 3),
          border: isLight
              ? Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: theme.primaryWhite,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    final theme = AppTheme.of(context);
    final currencyService = context.watch<CurrencyPreferenceService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            GestureDetector(
              onTap: _toggleDisplayUnit,
              behavior: HitTestBehavior.opaque,
              child: _showBtcAsMain
                  ? Text(
                      _balancesVisible
                          ? '₿ ${_formatBitcoinAmount(_getSelectedBalance())}'
                          : '₿ ********',
                      style: TextStyle(
                        color: theme.primaryWhite,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      _balancesVisible
                          ? currencyService.formatAmount(
                              _getSelectedBalance() * _btcToUsdRate)
                          : '${currencyService.symbol}****.**',
                      style: TextStyle(
                        color: theme.primaryWhite,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
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
    final balanceChangeInFiat = balanceChange * _btcToUsdRate;

    return GestureDetector(
      onTap: _toggleDisplayUnit,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: isPositive ? _successColor : _errorColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _showBtcAsMain
                  ? '${_formatBitcoinAmount(balanceChange.abs())} ₿'
                  : currencyService.formatAmount(balanceChangeInFiat.abs()),
              style: TextStyle(
                color: isPositive ? _successColor : _errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                  color: isPositive ? _successColor : _errorColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Send button
          _buildActionButton(
            label: AppLocalizations.of(context)!.send,
            icon: Icons.arrow_upward_rounded,
            onTap: _handleSend,
          ),
          const SizedBox(width: 12),

          // Receive button
          _buildActionButton(
            label: AppLocalizations.of(context)!.receive,
            icon: Icons.arrow_downward_rounded,
            onTap: _handleReceive,
          ),
          const SizedBox(width: 12),

          // Sell button
          _buildActionButton(
            label: 'Sell',
            icon: Icons.sell_outlined,
            onTap: _handleSell,
          ),
          const SizedBox(width: 12),

          // Buy button
          _buildActionButton(
            label: 'Buy',
            icon: Icons.shopping_cart_outlined,
            onTap: _handleBuy,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = AppTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    const double buttonSize = 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(buttonSize / 3),
              border: isLight
                  ? Border.all(
                      color: Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: isLight
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: theme.primaryWhite,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: buttonSize * 1.2,
            child: Text(
              label,
              style: TextStyle(
                color: theme.primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return TransactionHistoryWidget(
        aspId: widget.aspId,
        transactions: _transactions,
        loading: _isTransactionFetching,
        hideAmounts: !_balancesVisible,
        showBtcAsMain: _showBtcAsMain);
  }
}
