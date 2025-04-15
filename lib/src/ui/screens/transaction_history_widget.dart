import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:intl/intl.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final String aspId;
  final List<Transaction> transactions;
  final bool loading;

  const TransactionHistoryWidget({
    Key? key,
    required this.aspId,
    required this.transactions, required this.loading,
  }) : super(key: key);

  @override
  _TransactionHistoryWidgetState createState() =>
      _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          )
        else if (widget.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          )
        else if (widget.transactions.isEmpty)
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
              itemCount: widget.transactions.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.grey),
              itemBuilder: (context, index) => _buildTransactionItem(widget.transactions[index]),
            ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return transaction.map(
      boarding: (tx) => _buildBoardingTransactionItem(tx),
      round: (tx) => _buildRoundTransactionItem(tx),
      redeem: (tx) => _buildRedeemTransactionItem(tx),
    );
  }

  Widget _buildBoardingTransactionItem(Transaction_Boarding tx) {
    final confirmedTime = tx.confirmedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(tx.confirmedAt!.toInt() * 1000)
        : null;
    final formattedDate = confirmedTime != null
        ? DateFormat('MMM d, y').format(confirmedTime)
        : 'Pending';
    final amountBtc = tx.amountSats.toDouble() / 100000000;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.download,
          color: Colors.white,
        ),
      ),
      title: const Text(
        'Boarding Transaction',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${tx.txid.substring(0, 10)}... • $formattedDate',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '+ ₿${amountBtc.toStringAsFixed(8)}',
            style: TextStyle(
              color: Colors.blue[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tx.confirmedAt != null ? 'Confirmed' : 'Pending',
            style: TextStyle(
              color: tx.confirmedAt != null ? Colors.grey[400] : Colors.amber[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _showTransactionDetails(tx),
    );
  }

  Widget _buildRoundTransactionItem(Transaction_Round tx) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(tx.createdAt.toInt() * 1000);
    final formattedDate = DateFormat('MMM d, y').format(createdTime);
    final amountBtc = tx.amountSats.toInt() / 100000000;
    final isPositive = amountBtc > 0;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPositive ? Colors.green[900] : Colors.red[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
          color: Colors.white,
        ),
      ),
      title: Text(
        isPositive ? 'Received Bitcoin' : 'Sent Bitcoin',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${tx.txid.substring(0, 10)}... • $formattedDate',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : '-'} ₿${amountBtc.abs().toStringAsFixed(8)}',
            style: TextStyle(
              color: isPositive ? Colors.green[400] : Colors.red[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Completed',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _showTransactionDetails(tx),
    );
  }

  Widget _buildRedeemTransactionItem(Transaction_Redeem tx) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(tx.createdAt.toInt() * 1000);
    final formattedDate = DateFormat('MMM d, y').format(createdTime);
    final amountBtc = tx.amountSats.toInt() / 100000000;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          tx.amountSats.toInt().isNegative ? Icons.upload : Icons.download,
          color: Colors.white,
        ),
      ),
      title: Text(
        tx.amountSats.toInt().isNegative ? 'Sent' : "Received",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${tx.txid.substring(0, 10)}... • $formattedDate',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '- ₿${amountBtc.toStringAsFixed(8)}',
            style: TextStyle(
              color: Colors.purple[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            tx.isSettled ? 'Settled' : 'Pending',
            style: TextStyle(
              color: tx.isSettled ? Colors.grey[400] : Colors.amber[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _showTransactionDetails(tx),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => _TransactionDetailsDialog(
        transaction: transaction,
      ),
    );
  }
}

class _TransactionDetailsDialog extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetailsDialog({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  Future<void> _handleSettlement(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              SizedBox(height: 16),
              Text(
                'Settling transaction...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Perform settlement
      await settle();
      logger.i("Transaction settled successfully");

      // Close loading dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text(
              'Success',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Transaction settled successfully!',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  Navigator.of(context).pop(); // Close transaction details
                  Navigator.of(context).pop(); // Go to home screen
                },
                child: const Text(
                  'Go to Home',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              'Failed to settle transaction: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
        );
      }
      logger.e("Error settling transaction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getTransactionTypeTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),

            _buildTransactionDetailsContent(context),

            const SizedBox(height: 24),

            transaction.map(
              boarding: (tx) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Transaction pending. Funds will be non-reversible after settlement.',
                      style: TextStyle(color: Colors.amber, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleSettlement(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('SETTLE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              round: (_) => const SizedBox(),
              redeem: (_) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  String _getTransactionTypeTitle() {
    return transaction.map(
      boarding: (_) => 'Boarding Transaction',
      round: (_) => 'Settle Transaction',
      redeem: (tx) => tx.amountSats.isNegative ? 'Sent Offchain' : 'Received Offchain',
    );
  }

  Widget _buildTransactionDetailsContent(BuildContext context) {
    return transaction.map(
      boarding: (tx) {
        final confirmedTime = tx.confirmedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(tx.confirmedAt!.toInt() * 1000)
            : null;
        final formattedDate = confirmedTime != null
            ? DateFormat('MMMM d, y - h:mm a').format(confirmedTime)
            : 'Pending confirmation';
        final amountBtc = tx.amountSats.toDouble() / 100000000;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Transaction ID', tx.txid),
            _buildDetailRow('Status', tx.confirmedAt != null ? 'Confirmed' : 'Pending'),
            _buildDetailRow('Amount (BTC)', '₿${amountBtc.toStringAsFixed(8)}'),
            _buildDetailRow('Date', formattedDate),
            if (tx.confirmedAt != null)
              _buildDetailRow('Confirmed At', formattedDate),

          ],
        );
      },
      round: (tx) {
        final createdTime = DateTime.fromMillisecondsSinceEpoch(tx.createdAt.toInt() * 1000);
        final formattedDate = DateFormat('MMMM d, y - h:mm a').format(createdTime);
        final amountBtc = tx.amountSats.toInt() / 100000000;
        final amountSats = tx.amountSats.toString();
        final isPositive = amountBtc > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Transaction ID', tx.txid),
            _buildDetailRow('Type', isPositive ? 'Received' : 'Sent'),
            _buildDetailRow('Amount (BTC)', '${isPositive ? '+' : '-'} ₿${amountBtc.abs().toStringAsFixed(8)}'),
            _buildDetailRow('Date', formattedDate),
          ],
        );
      },
      redeem: (tx) {
        final createdTime = DateTime.fromMillisecondsSinceEpoch(tx.createdAt.toInt() * 1000);
        final formattedDate = DateFormat('MMMM d, y - h:mm a').format(createdTime);
        final amountBtc = tx.amountSats.toInt() / 100000000;
        final amountSats = tx.amountSats.toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Transaction ID', tx.txid),
            _buildDetailRow('Status', tx.isSettled ? 'Settled' : 'Pending'),
            _buildDetailRow('Amount (BTC)', '₿${amountBtc.abs().toStringAsFixed(8)}'),
            _buildDetailRow('Date', formattedDate),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}