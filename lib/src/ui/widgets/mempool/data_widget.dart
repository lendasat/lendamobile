import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/mempool_new/bitcoin_data.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/colorhelper.dart';
import 'package:flutter/material.dart';

class DataWidget extends StatelessWidget {
  final bool isAccepted;

  // For accepted blocks
  final BlockData? blockData;
  final double? size;
  final String? time;

  // For not accepted yet
  final MempoolBlock? mempoolBlocks;
  final String? mins;

  // For both
  final int? index;
  final String? txId;
  final bool singleTx;
  final bool hasUserTxs;
  final num currentUSD;

  // Constructor for accepted blocks
  const DataWidget.accepted({
    super.key,
    required this.blockData,
    required this.size,
    required this.time,
    this.index,
    this.txId,
    required this.singleTx,
    required this.hasUserTxs,
    this.currentUSD = 0,
  })  : isAccepted = true,
        mempoolBlocks = null,
        mins = null;

  // Constructor for not accepted blocks
  const DataWidget.notAccepted({
    super.key,
    required this.mempoolBlocks,
    required this.mins,
    this.index,
    this.txId,
    required this.hasUserTxs,
    required this.singleTx,
    this.currentUSD = 0,
  })  : isAccepted = false,
        blockData = null,
        size = null,
        time = null;

  @override
  Widget build(BuildContext context) {
    final i = index;

    return GestureDetector(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                height: AppTheme.cardPadding * 5.75,
                width: AppTheme.cardPadding * 5.75,
                margin: const EdgeInsets.only(left: AppTheme.cardPadding),
                padding: const EdgeInsets.all(AppTheme.elementSpacing),
                decoration: getDecoration(
                  isAccepted
                      ? blockData?.extras?.medianFee ?? 0
                      : mempoolBlocks?.medianFee ?? 0,
                  isAccepted,
                  context: context,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isAccepted
                        ? Text(
                            blockData!.height.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontSize: 20,
                                ),
                          )
                        : Text(
                            "Pending",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontSize: 20,
                                ),
                          ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    isAccepted
                        ? Text(
                            '${AppLocalizations.of(context)!.fee}: ~\$${((blockData!.extras?.medianFee ?? 0) * 140 / 100000000 * currentUSD).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        : Text(
                            '${AppLocalizations.of(context)!.fee}: ~\$${(mempoolBlocks!.medianFee * 140 / 100000000 * currentUSD).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                    const SizedBox(height: AppTheme.elementSpacing * 0.3),
                    isAccepted
                        ? FittedBox(
                            child: Text(
                              time ?? '',
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    fontSize: 14,
                                  ),
                            ),
                          )
                        : FittedBox(
                            child: Text(
                              'In ~$mins ${AppLocalizations.of(context)!.minutes}',
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    fontSize: 14,
                                  ),
                            ),
                          ),
                  ],
                ),
              ),
              if (hasUserTxs)
                Positioned(
                  bottom: 0,
                  left: 40,
                  child: Container(
                    width: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Center(
                      child: Text(
                        'has Tx',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          i == 1 && txId == blockData?.id
              ? Container(
                  margin: isAccepted
                      ? const EdgeInsets.only(left: AppTheme.cardPadding)
                      : EdgeInsets.zero,
                  child: const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: AppTheme.cardPadding * 2,
                  ),
                )
              : const SizedBox(height: AppTheme.cardPadding),
        ],
      ),
    );
  }
}
