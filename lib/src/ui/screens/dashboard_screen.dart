import 'package:ark_flutter/src/ui/screens/transaction_history_widget.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/settings_screen.dart';
import 'package:ark_flutter/src/ui/screens/send_screen.dart';
import 'package:ark_flutter/src/ui/screens/receive_screen.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';

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

  @override
  void initState() {
    super.initState();
    logger.i("Dashboard initialized with ASP ID: ${widget.aspId}");
    _fetchWalletData();
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
      _showErrorSnackbar("Couldn't update transactions: ${e.toString()}");
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

      _showErrorSnackbar("Couldn't update balance: ${e.toString()}");
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
        content: Text('Showing ${_currentBalanceType.name} balance'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.amber[700],
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
        backgroundColor: Colors.red[700],
        action: SnackBarAction(
          label: 'RETRY',
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

  void _handleReceive() {
    // Navigate to receive screen
    logger.i("Receive button pressed");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiveScreen(
          aspId: widget.aspId,
        ),
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
        return 'Pending Balance';
      case BalanceType.confirmed:
        return 'Confirmed Balance';
      case BalanceType.total:
        return 'Total Balance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'WTFark',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchWalletData,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
              // Balance Card
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9900), Color(0xFFFFB700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha((0.3 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getBalanceTypeText(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              if (_isBalanceLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _showBtcAsMain
                  ? [
                      // BTC as main, USD as secondary
                      Expanded(
                        child: InkWell(
                          onTap: _toggleBalanceType,
                          child: Text(
                            '₿ ${_getSelectedBalance().toStringAsFixed(_getSelectedBalance() < 0.001 ? 8 : 5)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _toggleDisplayUnit,
                        child: Text(
                          '≈ \$${(_getSelectedBalance() * _btcToUsdRate).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ]
                  : [
                      // USD as main, BTC as secondary
                      Expanded(
                        child: InkWell(
                          onTap: _toggleBalanceType,
                          child: Text(
                            '\$${(_getSelectedBalance() * _btcToUsdRate).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _toggleDisplayUnit,
                        child: Text(
                          '≈ ₿${_getSelectedBalance().toStringAsFixed(_getSelectedBalance() < 0.001 ? 8 : 5)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.15 * 255).round()),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.arrow_upward),
            label: const Text(
              'SEND',
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
            onPressed: _handleReceive,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[500],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.arrow_downward),
            label: const Text(
              'RECEIVE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return TransactionHistoryWidget(
        aspId: widget.aspId,
        transactions: _transactions,
        loading: _isTransactionFetching);
  }
}
