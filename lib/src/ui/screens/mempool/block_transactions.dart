import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/blinking_dot.dart' as dot;
import 'package:ark_flutter/src/ui/screens/mempool/single_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BlockTransactions extends StatefulWidget {
  final bool isConfirmed;
  final String? blockHash;
  final int? txCount;
  final List<List<dynamic>>? pendingTransactions;

  const BlockTransactions({
    super.key,
    this.isConfirmed = true,
    this.blockHash,
    this.txCount,
    this.pendingTransactions,
  });

  @override
  State<BlockTransactions> createState() => _BlockTransactionsState();
}

class _BlockTransactionsState extends State<BlockTransactions> {
  late final ScrollController scrollController;
  final TextEditingController textController = TextEditingController();

  List<BitcoinTransaction> transactions = [];
  List<BitcoinTransaction> filteredTransactions = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 0;
  bool reachedFinalPage = false;
  String lastQuery = '';
  late FocusNode searchNode;

  @override
  void initState() {
    super.initState();
    searchNode = FocusNode();
    searchNode.requestFocus();
    scrollController = ScrollController();
    scrollController.addListener(_loadMoreTransactions);
    if (widget.isConfirmed && widget.blockHash != null) {
      _loadInitialTransactions();
    } else {
      isLoading = false;
    }
  }

  @override
  void dispose() {
    searchNode.dispose();
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialTransactions() async {
    try {
      final txs = await mempool_api.getBlockTransactions(
        hash: widget.blockHash!,
        startIndex: 0,
      );
      if (mounted) {
        setState(() {
          transactions = txs;
          filteredTransactions = txs;
          isLoading = false;
          if (txs.length < 25) {
            reachedFinalPage = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _loadMoreTransactions() async {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !isLoadingMore &&
        !reachedFinalPage) {
      setState(() {
        isLoadingMore = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      try {
        final txs = await mempool_api.getBlockTransactions(
          hash: widget.blockHash!,
          startIndex: (currentPage + 1) * 25,
        );

        if (mounted) {
          setState(() {
            transactions.addAll(txs);
            filteredTransactions = _filterTransactions(lastQuery);
            currentPage++;
            isLoadingMore = false;
            if (txs.length < 25) {
              reachedFinalPage = true;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoadingMore = false;
          });
        }
      }
    }
  }

  List<BitcoinTransaction> _filterTransactions(String query) {
    if (query.isEmpty) {
      return transactions;
    }
    return transactions.where((tx) {
      return tx.txid.contains(query);
    }).toList();
  }

  void handleSearch(String query) {
    setState(() {
      lastQuery = query;
      filteredTransactions = _filterTransactions(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        text: widget.isConfirmed
            ? l10n.transactions
            : '${l10n.transactions} ${l10n.pending}',
        context: context,
        onTap: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: AppTheme.cardPadding * 3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
              ),
              child: SearchFieldWidget(
                node: searchNode,
                hintText: widget.isConfirmed
                    ? '${widget.txCount ?? filteredTransactions.length} ${l10n.transactions.toLowerCase()}'
                    : '${widget.pendingTransactions?.length ?? 0} ${l10n.transactions.toLowerCase()}',
                handleSearch: handleSearch,
                isSearchEnabled: true,
              ),
            ),

            // Content based on transaction type
            widget.isConfirmed
                ? _buildConfirmedTransactions(context)
                : _buildPendingTransactions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedTransactions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(l10n.noTransactionsYet),
        ),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredTransactions.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (isLoadingMore && index == filteredTransactions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final tx = filteredTransactions[index];
          BigInt volume = BigInt.zero;
          for (var vout in tx.vout) {
            volume += vout.value;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
              vertical: 8,
            ),
            child: GestureDetector(
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
              child: GlassContainer(
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusSmall,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: AppTheme.cardPadding * 2,
                        height: AppTheme.cardPadding * 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.cube,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tx.txid.substring(0, 10)}...${tx.txid.substring(tx.txid.length - 10)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    dot.BlinkingDot(
                                      color: AppTheme.successColor,
                                      size: 10,
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                ),
                                Text(
                                  '${(volume.toDouble() / 100000000).toStringAsFixed(8)} BTC',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTransactions(BuildContext context) {
    final pendingTxs = widget.pendingTransactions ?? [];

    if (pendingTxs.isEmpty) {
      return const SizedBox();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingTxs.length,
      itemBuilder: (context, index) {
        final txData = pendingTxs[index];
        // Format: [txid, value, vsize, feerate]
        final txid = txData[0] as String;
        final value = (txData[1] as num).toDouble();
        final btcValue = value / 100000000;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding,
            vertical: 8,
          ),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(
              AppTheme.borderRadiusSmall,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.cube,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: txid),
                            );
                            if (context.mounted) {
                              OverlayService().showSuccess(
                                AppLocalizations.of(context)!.copiedToClipboard,
                              );
                            }
                          },
                          child: Text(
                            '${txid.substring(0, 10)}...${txid.substring(txid.length - 10)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const dot.BlinkingDot(
                                  color: AppTheme.colorBitcoin,
                                  size: 10,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${btcValue.toStringAsFixed(8)} BTC',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
