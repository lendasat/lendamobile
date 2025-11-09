import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/transaction_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:intl/intl.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:ark_flutter/services/timezone_service.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final String aspId;
  final List<Transaction> transactions;
  final bool loading;

  const TransactionHistoryWidget({
    super.key,
    required this.aspId,
    required this.transactions,
    required this.loading,
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
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.transactionHistory,
              style: TextStyle(
                color: theme.primaryWhite,
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
                    AppLocalizations.of(context)!.errorLoadingTransactions,
                    style: TextStyle(color: theme.mutedText),
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
                  Icon(Icons.history, color: theme.mutedText, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noTransactionHistoryYet,
                    style: TextStyle(color: theme.mutedText),
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
                Divider(color: theme.mutedText),
            itemBuilder: (context, index) =>
                _buildTransactionItem(widget.transactions[index]),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return transaction.map(
      boarding: (tx) => _buildTransactionDetailsItem(
        AppLocalizations.of(context)!.boardingTransaction,
        tx.txid,
        DateTime.now().second,
        tx.amountSats.toInt(),
        // TODO: we need to figure out if this was settled or not
        false,
        tx.confirmedAt,
      ),
      round: (tx) => _buildTransactionDetailsItem(
          AppLocalizations.of(context)!.roundTransaction,
          tx.txid,
          tx.createdAt,
          tx.amountSats,
          true,
          null),
      redeem: (tx) => _buildTransactionDetailsItem(
          AppLocalizations.of(context)!.redeemTransaction,
          tx.txid,
          tx.createdAt,
          tx.amountSats,
          tx.isSettled,
          null),
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
    final theme = AppTheme.of(context);
    final timezoneService = context.watch<TimezoneService>();

    final createdTimeUtc =
        DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true);
    final createdTime = timezoneService.toSelectedTimezone(createdTimeUtc);
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
          color: theme.primaryWhite,
        ),
      ),
      title: Text(
        amountSats.isNegative
            ? AppLocalizations.of(context)!.sent
            : AppLocalizations.of(context)!.received,
        style: TextStyle(
          color: theme.primaryWhite,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${txid.substring(0, 10)}... • $formattedDate',
        style: TextStyle(color: theme.mutedText, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₿${amountBtc.toStringAsFixed(8)}',
            style: TextStyle(
              color: isSettled
                  ? amountSats.isNegative
                      ? Colors.purple[400]
                      : Colors.green[400]
                  : theme.mutedText,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            isSettled
                ? AppLocalizations.of(context)!.settled
                : AppLocalizations.of(context)!.pending,
            style: TextStyle(
              color: isSettled ? theme.mutedText : Colors.amber[400],
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
