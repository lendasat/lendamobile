import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/settings_screen.dart';

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
  // Mock data - replace with actual data from Rust backend
  double _btcBalance = 0.12345678;
  double _usdValue = 7123.45;
  String _walletAddress = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

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
    // TODO: Fetch real wallet balance and transaction data using widget.aspId
    logger.i("Dashboard initialized with ASP ID: ${widget.aspId}");
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    // TODO: Implement actual data fetching from Rust backend
    // This would use the aspId to get real balance and transaction data
    logger.i("Fetching wallet data...");

    // For now, we'll simulate a delay and use mock data
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real implementation, you'd update with real data from backend
    setState(() {
      // Mock data would be replaced with real data
    });
  }

  void _handleSend() {
    // TODO: Navigate to send screen
    logger.i("Send button pressed");
  }

  void _handleReceive() {
    // TODO: Navigate to receive screen
    logger.i("Receive button pressed");

    // For now, just show a dialog with the QR code
    _showReceiveDialog();
  }

  void _showReceiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Receive Bitcoin',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code, size: 150, color: Colors.black),
              // TODO: Replace with actual QR code of the address
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Bitcoin Address:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _walletAddress));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied to clipboard')),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _walletAddress,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
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
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₿ $_btcBalance',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '≈ \$$_usdValue',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
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
