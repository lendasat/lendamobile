import 'package:ark_flutter/src/ui/screens/transaction_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:intl/intl.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final String aspId;
  final List<Transaction> transactions;
  final bool loading;
  final bool hideAmounts;

  const TransactionHistoryWidget({
    super.key,
    required this.aspId,
    required this.transactions,
    required this.loading,
    this.hideAmounts = false,
  });

  @override
  TransactionHistoryWidgetState createState() =>
      TransactionHistoryWidgetState();
}

class TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
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
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.grey),
            itemBuilder: (context, index) =>
                _buildTransactionItem(widget.transactions[index]),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return transaction.map(
      boarding: (tx) => _buildTransactionDetailsItem(
        "Boarding Transaction",
        tx.txid,
        DateTime.now().second,
        tx.amountSats.toInt(),
        // TODO: we need to figure out if this was settled or not
        false,
        tx.confirmedAt,
      ),
      round: (tx) => _buildTransactionDetailsItem("Round Transaction", tx.txid,
          tx.createdAt, tx.amountSats, true, null),
      redeem: (tx) => _buildTransactionDetailsItem("Redeem Transaction",
          tx.txid, tx.createdAt, tx.amountSats, tx.isSettled, null),
    );
  }

  Widget _buildTransactionDetailsItem(
    String dialogTitle,
    String txid,
    int createdAt,
    int amountSats,
    bool isSettled,
    int? confirmedAt,
  ) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final formattedDate = DateFormat('MMM d, y').format(createdTime);
    final amountBtc = amountSats / 100000000;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSettled
              ? amountSats.isNegative
                  ? Colors.purple[900]
                  : Colors.green[900]
              : Colors.amber[500],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isSettled
              ? amountSats.isNegative
                  ? Icons.upload
                  : Icons.download
              : Icons.watch_later,
          color: Colors.white,
        ),
      ),
      title: Text(
        amountSats.isNegative ? 'Sent' : "Received",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${txid.substring(0, 10)}... • $formattedDate',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.hideAmounts
                ? '₿********'
                : '₿${amountBtc.toStringAsFixed(8)}',
            style: TextStyle(
              color: isSettled
                  ? amountSats.isNegative
                      ? Colors.purple[400]
                      : Colors.green[400]
                  : Colors.grey[300],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            isSettled ? 'Settled' : 'Pending',
            style: TextStyle(
              color: isSettled ? Colors.grey[400] : Colors.amber[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _showTransactionDetails(
        txid,
        createdAt,
        amountSats,
        isSettled,
        dialogTitle,
        confirmedAt,
      ),
    );
  }

  void _showTransactionDetails(
    String txid,
    int createdAt,
    int amountSats,
    bool isSettled,
    String dialogTitle,
    int? confirmedAt,
  ) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(
        dialogTitle: dialogTitle,
        txid: txid,
        createdAt: createdAt,
        amountSats: amountSats,
        isSettled: isSettled,
      ),
    );
  }
}
