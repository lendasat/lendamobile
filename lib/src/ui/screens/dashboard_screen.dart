import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/ui/screens/transaction_history_widget.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/settings_screen.dart';
import 'package:ark_flutter/src/ui/screens/send_screen.dart';
import 'package:ark_flutter/src/ui/screens/receive_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'WTFark',
          style: TextStyle(
            color: theme.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildTimeRangeSelector(),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.view_module_outlined,
              color: theme.primaryWhite,
            ),
            onPressed: _handleMempool,
            tooltip: 'Mempool',
          ),
          IconButton(
            icon: Icon(
              _balancesVisible ? Icons.visibility_off : Icons.visibility,
              color: theme.primaryWhite,
            ),
            onPressed: _toggleBalanceVisibility,
            tooltip: _balancesVisible ? 'Hide balances' : 'Show balances',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.primaryWhite),
            onPressed: _fetchWalletData,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.primaryWhite),
            onPressed: () {
              // Navigate to settings
              logger.i("Settings button pressed");
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(aspId: widget.aspId)),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final theme = AppTheme.of(context);
    final currencyService = context.watch<CurrencyPreferenceService>();

    return GestureDetector(
      onTap: _handleViewChart,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
            color: theme.primaryGray, borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (_bitcoinPriceData.isNotEmpty && !_isBalanceLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: BitcoinPriceChart(
                      data: _bitcoinPriceData,
                      alpha: 30,
                      trackballActivationMode: null,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getBalanceTypeText(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        if (_isBalanceLoading)
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                    if (_balanceError != null)
                      const Text(
                        'Error loading balance',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (_isBalanceLoading)
                      _buildBalanceSkeleton()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _showBtcAsMain
                                ? [
                                    // BTC as main, USD as secondary
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _toggleBalanceType,
                                        behavior: HitTestBehavior.opaque,
                                        child: Text(
                                          _balancesVisible
                                              ? '₿ ${_getSelectedBalance().toStringAsFixed(_getSelectedBalance() < 0.001 ? 8 : 5)}'
                                              : '₿ ********',
                                          style: TextStyle(
                                            color: theme.primaryWhite,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_balancesVisible)
                                      GestureDetector(
                                        onTap: _toggleDisplayUnit,
                                        behavior: HitTestBehavior.opaque,
                                        child: Text(
                                          '≈ ${currencyService.formatAmount(_getSelectedBalance() * _btcToUsdRate)}',
                                          style: TextStyle(
                                            color: theme.secondaryWhite,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                  ]
                                : [
                                    // USD as main, BTC as secondary
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _toggleBalanceType,
                                        behavior: HitTestBehavior.opaque,
                                        child: Text(
                                          _balancesVisible
                                              ? currencyService.formatAmount(
                                                  _getSelectedBalance() *
                                                      _btcToUsdRate)
                                              : '${currencyService.symbol}****.**',
                                          style: TextStyle(
                                            color: theme.primaryWhite,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_balancesVisible)
                                      GestureDetector(
                                        onTap: _toggleDisplayUnit,
                                        behavior: HitTestBehavior.opaque,
                                        child: Text(
                                          '≈ ₿${_getSelectedBalance().toStringAsFixed(_getSelectedBalance() < 0.001 ? 8 : 5)}',
                                          style: TextStyle(
                                            color: theme.secondaryWhite,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 1)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSkeleton() {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32,
          width: 150,
          decoration: BoxDecoration(
            color: theme.mutedText.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 100,
          decoration: BoxDecoration(
            color: theme.mutedText.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
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

    return PopupMenuButton<TimeRange>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[850]!.withOpacity(0.95),
      elevation: 8,
      offset: const Offset(0, 45),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TimeRange.day,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTimeRange == TimeRange.day
                  ? Colors.amber[500]!.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '1D',
              style: TextStyle(
                color: _selectedTimeRange == TimeRange.day
                    ? Colors.amber[500]
                    : Colors.white,
                fontWeight: _selectedTimeRange == TimeRange.day
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: TimeRange.week,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTimeRange == TimeRange.week
                  ? Colors.amber[500]!.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '1W',
              style: TextStyle(
                color: _selectedTimeRange == TimeRange.week
                    ? Colors.amber[500]
                    : Colors.white,
                fontWeight: _selectedTimeRange == TimeRange.week
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: TimeRange.month,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTimeRange == TimeRange.month
                  ? Colors.amber[500]!.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '1M',
              style: TextStyle(
                color: _selectedTimeRange == TimeRange.month
                    ? Colors.amber[500]
                    : Colors.white,
                fontWeight: _selectedTimeRange == TimeRange.month
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: TimeRange.year,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTimeRange == TimeRange.year
                  ? Colors.amber[500]!.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '1Y',
              style: TextStyle(
                color: _selectedTimeRange == TimeRange.year
                    ? Colors.amber[500]
                    : Colors.white,
                fontWeight: _selectedTimeRange == TimeRange.year
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: TimeRange.max,
          child: Container(
            decoration: BoxDecoration(
              color: _selectedTimeRange == TimeRange.max
                  ? Colors.amber[500]!.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Max',
              style: TextStyle(
                color: _selectedTimeRange == TimeRange.max
                    ? Colors.amber[500]
                    : Colors.white,
                fontWeight: _selectedTimeRange == TimeRange.max
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
      onSelected: (TimeRange range) {
        _changeTimeRange(range);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[800]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.grey[700]!.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTimeRangeLabel(_selectedTimeRange),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = AppTheme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.tertiaryBlack,
                  foregroundColor: theme.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_upward),
                label: Text(
                  AppLocalizations.of(context)!.send,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleReceive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[500],
                  foregroundColor: theme.primaryBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_downward),
                label: Text(
                  AppLocalizations.of(context)!.receive,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.tertiaryBlack,
                  foregroundColor: theme.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text(
                  'BUY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleSell,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[500],
                  foregroundColor: theme.primaryBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.sell_outlined),
                label: const Text(
                  'SELL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return TransactionHistoryWidget(
        aspId: widget.aspId,
        transactions: _transactions,
        loading: _isTransactionFetching,
        hideAmounts: !_balancesVisible);
  }
}
