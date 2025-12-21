import 'dart:async';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/ui/screens/mempool/single_transaction_screen.dart';
import 'package:ark_flutter/src/ui/screens/swap_detail_screen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:intl/intl.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:provider/provider.dart';
import 'package:ark_flutter/src/services/transaction_filter_service.dart';
import 'package:ark_flutter/src/ui/screens/transaction_filter_screen.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final String aspId;
  final List<Transaction> transactions;
  final List<SwapInfo> swaps;
  final bool loading;
  final bool hideAmounts;
  final bool showBtcAsMain;
  final double? bitcoinPrice;

  const TransactionHistoryWidget({
    super.key,
    required this.aspId,
    required this.transactions,
    this.swaps = const [],
    required this.loading,
    this.hideAmounts = false,
    this.showBtcAsMain = true,
    this.bitcoinPrice,
  });

  @override
  TransactionHistoryWidgetState createState() =>
      TransactionHistoryWidgetState();
}

class TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  List<WalletActivityItem> _filteredActivity = [];

  @override
  void initState() {
    super.initState();
    // Debug: Print transaction types to diagnose network label bug
    for (final tx in widget.transactions) {
      tx.map(
        boarding: (t) => debugPrint('TX DEBUG: Boarding (Onchain) - ${t.txid.substring(0, 8)}...'),
        round: (t) => debugPrint('TX DEBUG: Round (Arkade) - ${t.txid.substring(0, 8)}...'),
        redeem: (t) => debugPrint('TX DEBUG: Redeem isSettled=${t.isSettled} (${t.isSettled ? "Onchain" : "Arkade"}) - ${t.txid.substring(0, 8)}...'),
      );
    }
    _filteredActivity = combineActivity(widget.transactions, widget.swaps);
  }

  @override
  void didUpdateWidget(TransactionHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.swaps != widget.swaps) {
      _applySearch(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _applySearch(String searchText) {
    final filterService = context.read<TransactionFilterService>();
    final lowerSearch = searchText.toLowerCase();

    setState(() {
      var allActivity = combineActivity(widget.transactions, widget.swaps);

      // Search filter
      if (searchText.isNotEmpty) {
        allActivity = allActivity.where((item) {
          if (item is TransactionActivityItem) {
            return item.id.toLowerCase().contains(lowerSearch);
          } else if (item is SwapActivityItem) {
            return item.id.toLowerCase().contains(lowerSearch) ||
                item.tokenSymbol.toLowerCase().contains(lowerSearch);
          }
          return false;
        }).toList();
      }

      // Type filter by network (Onchain, Arkade, Swap)
      final hasTypeFilter = filterService.selectedFilters.any(
        (f) => ['Onchain', 'Arkade', 'Swap'].contains(f),
      );
      if (hasTypeFilter) {
        allActivity = allActivity.where((item) {
          if (item is TransactionActivityItem) {
            return item.transaction.map(
              boarding: (_) => filterService.selectedFilters.contains('Onchain'),
              round: (_) => filterService.selectedFilters.contains('Arkade'),
              redeem: (tx) {
                // If not settled, it's still a virtual Ark transaction (Arkade)
                // Only filter as Onchain if it's been settled/redeemed
                if (tx.isSettled) {
                  return filterService.selectedFilters.contains('Onchain');
                } else {
                  return filterService.selectedFilters.contains('Arkade');
                }
              },
            );
          } else if (item is SwapActivityItem) {
            return filterService.selectedFilters.contains('Swap');
          }
          return false;
        }).toList();
      }

      // Direction filter (Sent/Received)
      final filterSent = filterService.selectedFilters.contains('Sent');
      final filterReceived = filterService.selectedFilters.contains('Received');
      if (filterSent && !filterReceived) {
        allActivity = allActivity.where((item) {
          if (item is TransactionActivityItem) {
            return item.amountSats < 0;
          } else if (item is SwapActivityItem) {
            return item.isBtcToEvm; // Sending BTC
          }
          return false;
        }).toList();
      } else if (filterReceived && !filterSent) {
        allActivity = allActivity.where((item) {
          if (item is TransactionActivityItem) {
            return item.amountSats >= 0;
          } else if (item is SwapActivityItem) {
            return !item.isBtcToEvm; // Receiving BTC
          }
          return false;
        }).toList();
      }

      // Time filter
      if (filterService.hasTimeframeFilter) {
        allActivity = allActivity.where((item) {
          final timestamp = item.timestamp;
          if (timestamp == 0) return true;

          bool passesFilter = true;
          if (filterService.startDate != null) {
            final startTimestamp =
                filterService.startDate!.millisecondsSinceEpoch ~/ 1000;
            passesFilter = passesFilter && timestamp >= startTimestamp;
          }
          if (filterService.endDate != null) {
            final endTimestamp =
                filterService.endDate!.millisecondsSinceEpoch ~/ 1000;
            passesFilter = passesFilter && timestamp <= endTimestamp;
          }
          return passesFilter;
        }).toList();
      }

      // Always ensure sorted by timestamp (newest first) after all filtering
      allActivity.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _filteredActivity = allActivity;
    });
  }

  List<Widget> _arrangeActivityByTime() {
    if (_filteredActivity.isEmpty) return [];

    Map<String, List<WalletActivityItem>> categorizedActivity = {};
    DateTime now = DateTime.now();
    DateTime startOfThisMonth = DateTime(now.year, now.month, 1);

    for (WalletActivityItem item in _filteredActivity) {
      final timestamp = item.timestamp;

      if (timestamp == 0) {
        categorizedActivity.putIfAbsent('Unknown Date', () => []).add(item);
        continue;
      }

      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      if (date.isAfter(startOfThisMonth)) {
        String timeTag = _displayTimeAgo(timestamp);
        categorizedActivity.putIfAbsent(timeTag, () => []).add(item);
      } else {
        String yearMonth = '${date.year}, ${DateFormat('MMMM').format(date)}';
        categorizedActivity.putIfAbsent(yearMonth, () => []).add(item);
      }
    }

    List<Widget> finalWidgets = [];
    categorizedActivity.forEach((category, activityItems) {
      if (activityItems.isEmpty) return;

      finalWidgets.add(
        Padding(
          key: ValueKey('header_$category'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding,
            vertical: AppTheme.elementSpacing,
          ),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );

      finalWidgets.add(
        _ActivityContainer(
          key: ValueKey('container_$category'),
          activityItems: activityItems,
          aspId: widget.aspId,
          hideAmounts: widget.hideAmounts,
          showBtcAsMain: widget.showBtcAsMain,
          bitcoinPrice: widget.bitcoinPrice,
        ),
      );
    });

    return finalWidgets;
  }

  String _displayTimeAgo(int timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    Duration difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return 'This Week';
    } else if (difference.inDays < 14) {
      return 'Last Week';
    } else {
      return 'This Month';
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transactionHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.elementSpacing),
        if (!widget.loading && (widget.transactions.isNotEmpty || widget.swaps.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
              vertical: AppTheme.elementSpacing,
            ),
            child: SearchFieldWidget(
              hintText: AppLocalizations.of(context)!.search,
              isSearchEnabled: true,
              handleSearch: (value) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 300), () {
                  _applySearch(value);
                });
              },
              onChanged: (value) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 300), () {
                  _applySearch(value);
                });
              },
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                  size: AppTheme.cardPadding * 0.75,
                ),
                onPressed: () async {
                  await arkBottomSheet(
                    context: context,
                    height: MediaQuery.of(context).size.height * 0.6,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: const TransactionFilterScreen(),
                  );
                  _applySearch(_searchController.text);
                },
              ),
            ),
          ),
        const SizedBox(height: AppTheme.elementSpacing),
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
                    style: TextStyle(
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                    ),
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
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
              ),
            ),
          )
        else if (widget.transactions.isEmpty && widget.swaps.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noTransactionHistoryYet,
                    style: TextStyle(
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredActivity.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No matching activity',
                    style: TextStyle(
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _arrangeActivityByTime(),
          ),
      ],
    );
  }
}

class _ActivityContainer extends StatelessWidget {
  final List<WalletActivityItem> activityItems;
  final String aspId;
  final bool hideAmounts;
  final bool showBtcAsMain;
  final double? bitcoinPrice;

  const _ActivityContainer({
    super.key,
    required this.activityItems,
    required this.aspId,
    required this.hideAmounts,
    required this.showBtcAsMain,
    this.bitcoinPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Column(
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: activityItems.map((item) {
                if (item is TransactionActivityItem) {
                  return _TransactionItemWidget(
                    transaction: item.transaction,
                    aspId: aspId,
                    hideAmounts: hideAmounts,
                    showBtcAsMain: showBtcAsMain,
                    bitcoinPrice: bitcoinPrice,
                  );
                } else if (item is SwapActivityItem) {
                  return _SwapItemWidget(
                    swapItem: item,
                    hideAmounts: hideAmounts,
                    showBtcAsMain: showBtcAsMain,
                    bitcoinPrice: bitcoinPrice,
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding * 0.5),
        ],
      ),
    );
  }
}

class _TransactionItemWidget extends StatelessWidget {
  final Transaction transaction;
  final String aspId;
  final bool hideAmounts;
  final bool showBtcAsMain;
  final double? bitcoinPrice;

  const _TransactionItemWidget({
    required this.transaction,
    required this.aspId,
    required this.hideAmounts,
    required this.showBtcAsMain,
    this.bitcoinPrice,
  });

  void _navigateToTransactionDetail(
    BuildContext context,
    String txid, {
    int? amountSats,
    int? createdAt,
    String? transactionType,
    String? networkType,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleTransactionScreen(
          txid: txid,
          amountSats: amountSats,
          createdAt: createdAt,
          transactionType: transactionType,
          networkType: networkType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return transaction.map(
      boarding: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.boardingTransaction,
        tx.txid,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tx.amountSats.toInt(),
        false,
        tx.confirmedAt is BigInt ? (tx.confirmedAt as BigInt).toInt() : tx.confirmedAt as int?,
        showBtcAsMain,
        hideAmounts,
        'Onchain',
      ),
      round: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.roundTransaction,
        tx.txid,
        tx.createdAt is BigInt ? (tx.createdAt as BigInt).toInt() : tx.createdAt as int,
        tx.amountSats is BigInt ? (tx.amountSats as BigInt).toInt() : tx.amountSats as int,
        true,
        null,
        showBtcAsMain,
        hideAmounts,
        'Arkade',
      ),
      redeem: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.redeemTransaction,
        tx.txid,
        tx.createdAt is BigInt ? (tx.createdAt as BigInt).toInt() : tx.createdAt as int,
        tx.amountSats is BigInt ? (tx.amountSats as BigInt).toInt() : tx.amountSats as int,
        tx.isSettled,
        null,
        showBtcAsMain,
        hideAmounts,
        // If not settled, it's still a virtual Ark transaction (Arkade)
        // Only show as Onchain if it's been settled/redeemed
        tx.isSettled ? 'Onchain' : 'Arkade',
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    String dialogTitle,
    String txid,
    int createdAt,
    int amountSats,
    bool isSettled,
    int? confirmedAt,
    bool showBtcAsMain,
    bool hideAmounts,
    String network,
  ) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final amountBtc = amountSats / 100000000;

    // Use actual BTC price, with fallback only if not available
    final btcPriceUsd = bitcoinPrice ?? 0;
    final exchangeRates = currencyService.exchangeRates;
    final fiatRate = exchangeRates?.rates[currencyService.code] ?? 1;
    final amountFiat = amountBtc * btcPriceUsd * fiatRate;

    Color statusColor;
    if (isSettled) {
      statusColor = AppTheme.successColor;
    } else if (confirmedAt != null) {
      statusColor = AppTheme.colorBitcoin;
    } else {
      statusColor = AppTheme.errorColor;
    }

    String transactionType = dialogTitle.replaceAll(' Transaction', '');

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTransactionDetail(
            context,
            txid,
            amountSats: amountSats,
            createdAt: createdAt,
            transactionType: transactionType,
            networkType: network,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.elementSpacing,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.elementSpacing * 0.75,
                right: AppTheme.elementSpacing * 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Avatar(
                        size: AppTheme.cardPadding * 2,
                        isNft: false,
                      ),
                      const SizedBox(width: AppTheme.elementSpacing * 0.75),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: AppTheme.cardPadding * 6.5,
                            child: Text(
                              txid,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: isDark
                                        ? AppTheme.white90
                                        : AppTheme.black90,
                                  ),
                            ),
                          ),
                          const SizedBox(
                              height: AppTheme.elementSpacing / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.elementSpacing / 2,
                                ),
                                child: Image.asset(
                                  "assets/images/bitcoin.png",
                                  width: AppTheme.cardPadding * 0.6,
                                  height: AppTheme.cardPadding * 0.6,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.currency_bitcoin,
                                      size: AppTheme.cardPadding * 0.6,
                                      color: AppTheme.colorBitcoin,
                                    );
                                  },
                                ),
                              ),
                              Text(
                                network,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(
                                width: AppTheme.elementSpacing / 2,
                              ),
                              Icon(
                                Icons.circle,
                                color: statusColor,
                                size: AppTheme.cardPadding * 0.4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // RIGHT SIDE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      hideAmounts
                          ? Text(
                              '*****',
                              style: Theme.of(context).textTheme.titleMedium,
                            )
                          : Row(
                              children: [
                                Text(
                                  showBtcAsMain
                                      ? '${amountSats.isNegative ? "" : "+"}${amountSats.abs()}'
                                      : '${amountSats.isNegative ? "-" : "+"}${currencyService.formatAmount(amountFiat.abs())}',
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (showBtcAsMain)
                                  Icon(
                                    AppTheme.satoshiIcon,
                                  ),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying a swap item in the activity list.
class _SwapItemWidget extends StatelessWidget {
  final SwapActivityItem swapItem;
  final bool hideAmounts;
  final bool showBtcAsMain;
  final double? bitcoinPrice;

  const _SwapItemWidget({
    required this.swapItem,
    required this.hideAmounts,
    required this.showBtcAsMain,
    this.bitcoinPrice,
  });

  void _navigateToSwapDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SwapDetailScreen(
          swapId: swapItem.id,
          initialSwapItem: swapItem,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (swapItem.displayStatus) {
      case SwapDisplayStatus.completed:
        return AppTheme.successColor;
      case SwapDisplayStatus.processing:
      case SwapDisplayStatus.pending:
        return AppTheme.colorBitcoin;
      case SwapDisplayStatus.refundable:
        return Colors.orange;
      case SwapDisplayStatus.expired:
      case SwapDisplayStatus.failed:
        return AppTheme.errorColor;
      case SwapDisplayStatus.refunded:
        return AppTheme.white60;
    }
  }

  String _getSwapTypeLabel() {
    if (swapItem.isBtcToEvm) {
      return 'BTC → ${swapItem.tokenSymbol}';
    } else {
      return '${swapItem.tokenSymbol} → BTC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    final amountSats = swapItem.amountSats;
    final usdAmount = swapItem.usdAmount;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSwapDetail(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.elementSpacing,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.elementSpacing * 0.75,
                right: AppTheme.elementSpacing * 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Swap icon
                      Container(
                        width: AppTheme.cardPadding * 2,
                        height: AppTheme.cardPadding * 2,
                        decoration: BoxDecoration(
                          color: AppTheme.colorBitcoin.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.cardPadding),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppTheme.colorBitcoin,
                          size: AppTheme.cardPadding * 1.2,
                        ),
                      ),
                      const SizedBox(width: AppTheme.elementSpacing * 0.75),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: AppTheme.cardPadding * 6.5,
                            child: Text(
                              'Swap',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: isDark
                                        ? AppTheme.white90
                                        : AppTheme.black90,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.elementSpacing / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: AppTheme.cardPadding * 0.6,
                                color: AppTheme.colorBitcoin,
                              ),
                              const SizedBox(width: AppTheme.elementSpacing / 2),
                              Text(
                                _getSwapTypeLabel(),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(width: AppTheme.elementSpacing / 2),
                              Icon(
                                Icons.circle,
                                color: statusColor,
                                size: AppTheme.cardPadding * 0.4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // RIGHT SIDE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      hideAmounts
                          ? Text(
                              '*****',
                              style: Theme.of(context).textTheme.titleMedium,
                            )
                          : Row(
                              children: [
                                Text(
                                  showBtcAsMain
                                      ? '${amountSats.isNegative ? "" : "+"}${amountSats.abs()}'
                                      : '${amountSats.isNegative ? "-" : "+"}\$${usdAmount.toStringAsFixed(2)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (showBtcAsMain)
                                  Icon(
                                    AppTheme.satoshiIcon,
                                  ),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
