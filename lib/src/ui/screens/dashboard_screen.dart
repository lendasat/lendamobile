import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/settings_screen.dart';
import 'package:ark_flutter/src/ui/screens/send_screen.dart';
import 'package:ark_flutter/src/ui/screens/receive_screen.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart'; // Import the Rust API

enum BalanceType { pending, confirmed, total }

class DashboardScreen extends StatefulWidget {
  final String aspId;

  const DashboardScreen({
    Key? key,
    required this.aspId,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceLoading = true;
  String? _balanceError;

  // Store all balance types
  double _pendingBalance = 0.0;
  double _confirmedBalance = 0.0;
  double _totalBalance = 0.0;

  // Current selections
  BalanceType _currentBalanceType = BalanceType.total;
  bool _showBtcAsMain = true; // Toggle between BTC and USD as main display

  // Exchange rate
  final double _btcToUsdRate = 65000.0;

  // Transaction history - replace with actual data
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'type': 'received',
      'amount': 0.05,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'address': 'bc1q...v3m4',
      'status': 'completed',
    },
    {
      'type': 'sent',
      'amount': 0.025,
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'address': 'bc1q...k7j9',
      'status': 'completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    logger.i("Dashboard initialized with ASP ID: ${widget.aspId}");
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    _fetchBalance();
    // In the future, also fetch transactions and other data
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
        _pendingBalance = balanceResult.offchain.pendingSats.toDouble() / 100000000;
        _confirmedBalance = balanceResult.offchain.confirmedSats.toDouble() / 100000000;
        _totalBalance = balanceResult.offchain.totalSats.toDouble() / 100000000;
        _isBalanceLoading = false;
      });

      logger.i("Balance updated: Total: $_totalBalance BTC, Confirmed: $_confirmedBalance BTC, Pending: $_pendingBalance BTC");
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
          availableSats: _getSelectedBalance() * 100000000, // Convert BTC to SATS
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
            color: Colors.amber.withOpacity(0.3),
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
            Text(
              'Error loading balance',
              style: const TextStyle(
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Icon(Icons.history, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No transaction history yet',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTransactions.length,
            separatorBuilder: (context, index) =>
            const Divider(color: Colors.grey),
            itemBuilder: (context, index) {
              final tx = _recentTransactions[index];
              final bool isReceived = tx['type'] == 'received';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isReceived ? Colors.green[900] : Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  isReceived ? 'Received Bitcoin' : 'Sent Bitcoin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${tx['address']} • ${tx['date'].toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isReceived ? '+' : '-'} ₿${tx['amount']}',
                      style: TextStyle(
                        color: isReceived ? Colors.green[400] : Colors.red[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tx['status'],
                      style: TextStyle(
                        color: tx['status'] == 'completed'
                            ? Colors.grey[400]
                            : Colors.amber[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // TODO: Show transaction details
                  logger.i("Transaction tapped: ${tx['address']}");
                },
              );
            },
          ),
      ],
    );
  }
}