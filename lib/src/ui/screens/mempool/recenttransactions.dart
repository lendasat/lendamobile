/// Recent Transactions Widget for Mempool
/// Displays recent mempool transactions with optional filtering for owned transactions
library;

import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/screens/mempool/single_transaction_screen.dart';
import 'package:flutter/material.dart';

/// Data model for transaction display
class TransactionDisplayData {
  final String txid;
  final double value;
  final double? fee;
  final int? vsize;

  TransactionDisplayData({
    required this.txid,
    required this.value,
    this.fee,
    this.vsize,
  });
}

class RecentTransactions extends StatefulWidget {
  const RecentTransactions({
    super.key,
    required this.transactions,
    this.ownedTxids = const [],
  });

  final List<TransactionDisplayData> transactions;
  final List<String> ownedTxids;

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: AppTheme.cardPadding),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TXID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                l10n.amount,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        widget.transactions.isEmpty
            ? Center(
                child: Text(l10n.noTransactionsYet),
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                reverse: true,
                itemCount: widget.transactions.length,
                itemBuilder: (context, index) {
                  final tx = widget.transactions[index];
                  double btcValue = tx.value / BitcoinConstants.satsPerBtc;
                  bool isOwned = widget.ownedTxids.contains(tx.txid);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: GlassContainer(
                      borderRadius:
                          BorderRadius.circular(AppTheme.cardPadding * 0.5),
                      child: Column(
                        children: [
                          ArkListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleTransactionScreen(
                                    txid: tx.txid,
                                  ),
                                ),
                              );
                            },
                            text:
                                '${tx.txid.substring(0, 5)}...${tx.txid.substring(tx.txid.length - 5)}',
                            trailing: SizedBox(
                              width: 145,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isOwned) ...[
                                    Container(
                                      width: 45,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppTheme.colorBitcoin,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Center(
                                        child: Text(
                                          l10n.yourTx,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    '${btcValue.toStringAsFixed(4)} BTC',
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
