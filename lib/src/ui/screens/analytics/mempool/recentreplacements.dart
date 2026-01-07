import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/mempool_new/lnd_transaction_model.dart';
import 'package:ark_flutter/src/models/mempool_new/transactiondata.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/screens/analytics/mempool/single_transaction_screen.dart';
import 'package:flutter/material.dart';

/// Model for RBF transaction replacement
class TransactionReplacement {
  final String? txid;
  final bool? fullRbf;
  final bool? mined;

  TransactionReplacement({
    this.txid,
    this.fullRbf,
    this.mined,
  });

  factory TransactionReplacement.fromJson(Map<String, dynamic> json) {
    return TransactionReplacement(
      txid: json['txid']?.toString(),
      fullRbf: json['fullRbf'] ?? json['full_rbf'] ?? false,
      mined: json['mined'] ?? false,
    );
  }
}

class RecentReplacements extends StatefulWidget {
  const RecentReplacements({
    super.key,
    required this.ownedTransactions,
    required this.transactionReplacements,
    this.isLoading = false,
  });

  final List<BitcoinTransaction> ownedTransactions;
  final List<TransactionReplacement> transactionReplacements;
  final bool isLoading;

  @override
  State<RecentReplacements> createState() => _RecentReplacementsState();
}

class _RecentReplacementsState extends State<RecentReplacements> {
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
                l10n.status,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        _buildContent(context, l10n),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: AppTheme.colorBitcoin,
          ),
        ),
      );
    }

    if (widget.transactionReplacements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            l10n.noTransactionsYet,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      reverse: false,
      itemCount: widget.transactionReplacements.length,
      itemBuilder: (context, index) {
        final replacement = widget.transactionReplacements[index];

        // Find owned transaction matching this replacement
        BitcoinTransaction? ownedTransaction;
        for (final tx in widget.ownedTransactions) {
          if (tx.blockHash == replacement.txid ||
              tx.txHash == replacement.txid ||
              tx.rawTxHex == replacement.txid) {
            ownedTransaction = tx;
            break;
          }
        }

        return _buildReplacementItem(
          context,
          l10n,
          replacement,
          ownedTransaction,
        );
      },
    );
  }

  Widget _buildReplacementItem(
    BuildContext context,
    AppLocalizations l10n,
    TransactionReplacement replacement,
    BitcoinTransaction? ownedTransaction,
  ) {
    final txid = replacement.txid ?? '';
    final truncatedTxid = txid.length > 10
        ? '${txid.substring(0, 5)}...${txid.substring(txid.length - 5)}'
        : txid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(AppTheme.cardPadding * 0.5),
        child: Column(
          children: [
            ArkListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SingleTransactionScreen(
                      txid: txid,
                    ),
                  ),
                );
              },
              text: truncatedTxid,
              trailing: SizedBox(
                width: 200,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (ownedTransaction != null) ...[
                      Container(
                        width: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.colorBitcoin,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 2),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // RBF type badge
                        Container(
                          padding: const EdgeInsets.all(
                            AppTheme.elementSpacing / 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusSuperSmall,
                            ),
                            color: replacement.fullRbf == true
                                ? AppTheme.colorBitcoin
                                : AppTheme.successColor,
                          ),
                          child: Text(
                            replacement.fullRbf == true ? 'Full RBF' : 'RBF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Mined badge
                        if (replacement.mined == true)
                          Container(
                            padding: const EdgeInsets.all(
                              AppTheme.elementSpacing / 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSuperSmall,
                              ),
                              color: Colors.green,
                            ),
                            child: Text(
                              l10n.mined,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Show owned transaction details if present
            if (ownedTransaction != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black.withAlpha(50)
                          : Colors.white.withAlpha(50),
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardPadding * 0.2,
                    ),
                  ),
                  child: _buildOwnedTransactionDetails(
                    context,
                    l10n,
                    ownedTransaction,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOwnedTransactionDetails(
    BuildContext context,
    AppLocalizations l10n,
    BitcoinTransaction transaction,
  ) {
    final isSent = transaction.amount?.contains('-') ?? false;
    final status = (transaction.numConfirmations ?? 0) > 0
        ? TransactionStatus.confirmed
        : TransactionStatus.pending;
    final direction =
        isSent ? TransactionDirection.sent : TransactionDirection.received;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: direction == TransactionDirection.sent
                  ? AppTheme.errorColor.withAlpha(50)
                  : AppTheme.successColor.withAlpha(50),
            ),
            child: Icon(
              direction == TransactionDirection.sent
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: direction == TransactionDirection.sent
                  ? AppTheme.errorColor
                  : AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  direction == TransactionDirection.sent
                      ? l10n.sent
                      : l10n.received,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  status == TransactionStatus.confirmed
                      ? l10n.confirmed
                      : l10n.pending,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status == TransactionStatus.confirmed
                            ? AppTheme.successColor
                            : AppTheme.colorBitcoin,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.amount ?? "0"} sats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: direction == TransactionDirection.sent
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                ),
          ),
        ],
      ),
    );
  }
}
