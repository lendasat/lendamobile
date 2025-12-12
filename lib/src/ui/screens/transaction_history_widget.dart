import 'dart:async';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/mempool/single_transaction_screen.dart';
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
  final bool loading;
  final bool hideAmounts;
  final bool showBtcAsMain;

  const TransactionHistoryWidget({
    super.key,
    required this.aspId,
    required this.transactions,
    required this.loading,
    this.hideAmounts = false,
    this.showBtcAsMain = true,
  });

  @override
  TransactionHistoryWidgetState createState() =>
      TransactionHistoryWidgetState();
}

class TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  List<Transaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _filteredTransactions = widget.transactions;
  }

  @override
  void didUpdateWidget(TransactionHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
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
      var filtered = widget.transactions;

      if (searchText.isNotEmpty) {
        filtered = filtered.where((tx) {
          return tx.map(
            boarding: (tx) => tx.txid.toLowerCase().contains(lowerSearch),
            round: (tx) => tx.txid.toLowerCase().contains(lowerSearch),
            redeem: (tx) => tx.txid.toLowerCase().contains(lowerSearch),
          );
        }).toList();
      }

      final hasTypeFilter = filterService.selectedFilters.any(
        (f) => ['Onchain', 'Round', 'Redeem'].contains(f),
      );
      if (hasTypeFilter) {
        filtered = filtered.where((tx) {
          return tx.map(
            boarding: (_) => filterService.selectedFilters.contains('Onchain'),
            round: (_) => filterService.selectedFilters.contains('Round'),
            redeem: (_) => filterService.selectedFilters.contains('Redeem'),
          );
        }).toList();
      }

      final filterSent = filterService.selectedFilters.contains('Sent');
      final filterReceived = filterService.selectedFilters.contains('Received');
      if (filterSent && !filterReceived) {
        filtered = filtered.where((tx) {
          return tx.map(
            boarding: (tx) => tx.amountSats.isNegative,
            round: (tx) => tx.amountSats.isNegative,
            redeem: (tx) => tx.amountSats.isNegative,
          );
        }).toList();
      } else if (filterReceived && !filterSent) {
        filtered = filtered.where((tx) {
          return tx.map(
            boarding: (tx) => !tx.amountSats.isNegative,
            round: (tx) => tx.amountSats >= 0,
            redeem: (tx) => tx.amountSats >= 0,
          );
        }).toList();
      }

      if (filterService.hasTimeframeFilter) {
        filtered = filtered.where((tx) {
          final timestamp = tx.map(
            boarding: (_) => 0,
            round: (tx) => tx.createdAt,
            redeem: (tx) => tx.createdAt,
          );

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

      _filteredTransactions = filtered;
    });
  }

  List<Widget> _arrangeTransactionsByTime() {
    if (_filteredTransactions.isEmpty) return [];

    Map<String, List<Transaction>> categorizedTransactions = {};
    DateTime now = DateTime.now();
    DateTime startOfThisMonth = DateTime(now.year, now.month, 1);

    for (Transaction tx in _filteredTransactions) {
      final timestamp = tx.map(
        boarding: (tx) => DateTime.now().millisecondsSinceEpoch ~/ 1000,
        round: (tx) => tx.createdAt,
        redeem: (tx) => tx.createdAt,
      );

      if (timestamp == 0) {
        categorizedTransactions.putIfAbsent('Unknown Date', () => []).add(tx);
        continue;
      }

      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      if (date.isAfter(startOfThisMonth)) {
        String timeTag = _displayTimeAgo(timestamp);
        categorizedTransactions.putIfAbsent(timeTag, () => []).add(tx);
      } else {
        String yearMonth = '${date.year}, ${DateFormat('MMMM').format(date)}';
        categorizedTransactions.putIfAbsent(yearMonth, () => []).add(tx);
      }
    }

    List<Widget> finalWidgets = [];
    categorizedTransactions.forEach((category, transactions) {
      if (transactions.isEmpty) return;

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
        _TransactionContainer(
          key: ValueKey('container_$category'),
          transactions: transactions,
          aspId: widget.aspId,
          hideAmounts: widget.hideAmounts,
          showBtcAsMain: widget.showBtcAsMain,
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
        if (!widget.loading && widget.transactions.isNotEmpty)
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
        else if (_filteredTransactions.isEmpty)
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
                    'No matching transactions',
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
            children: _arrangeTransactionsByTime(),
          ),
      ],
    );
  }
}

class _TransactionContainer extends StatelessWidget {
  final List<Transaction> transactions;
  final String aspId;
  final bool hideAmounts;
  final bool showBtcAsMain;

  const _TransactionContainer({
    super.key,
    required this.transactions,
    required this.aspId,
    required this.hideAmounts,
    required this.showBtcAsMain,
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
              children: transactions
                  .map((tx) => _TransactionItem(
                        transaction: tx,
                        aspId: aspId,
                        hideAmounts: hideAmounts,
                        showBtcAsMain: showBtcAsMain,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding * 0.5),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String aspId;
  final bool hideAmounts;
  final bool showBtcAsMain;

  const _TransactionItem({
    required this.transaction,
    required this.aspId,
    required this.hideAmounts,
    required this.showBtcAsMain,
  });

  void _navigateToTransactionDetail(BuildContext context, String txid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleTransactionScreen(txid: txid),
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
        tx.confirmedAt,
        showBtcAsMain,
        hideAmounts,
      ),
      round: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.roundTransaction,
        tx.txid,
        tx.createdAt,
        tx.amountSats,
        true,
        null,
        showBtcAsMain,
        hideAmounts,
      ),
      redeem: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.redeemTransaction,
        tx.txid,
        tx.createdAt,
        tx.amountSats,
        tx.isSettled,
        null,
        showBtcAsMain,
        hideAmounts,
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
  ) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final amountBtc = amountSats / 100000000;

    final exchangeRates = currencyService.exchangeRates;
    final btcToFiatRate =
        (exchangeRates?.rates[currencyService.code] ?? 1) * 93000.0;
    final amountFiat = amountBtc * btcToFiatRate;

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
          onTap: () => _navigateToTransactionDetail(context, txid),
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
                                transactionType,
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
