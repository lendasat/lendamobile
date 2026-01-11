import 'dart:async';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/services/pending_transaction_service.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:ark_flutter/src/ui/widgets/transaction/transaction_detail_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_detail_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/utils/date_formatter.dart';
import 'package:ark_flutter/src/utils/number_formatter.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:intl/intl.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:provider/provider.dart';
import 'package:ark_flutter/src/services/transaction_filter_service.dart';
import 'package:ark_flutter/src/ui/screens/transactions/history/transaction_filter_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TransactionHistoryWidget extends StatefulWidget {
  final String aspId;
  final List<Transaction> transactions;
  final List<SwapInfo> swaps;
  final bool loading;
  final bool hideAmounts;
  final bool showBtcAsMain;
  final double? bitcoinPrice;

  /// When false, the header (title + search bar) is not rendered.
  /// Use this when the header is rendered separately as a sticky sliver.
  final bool showHeader;

  const TransactionHistoryWidget({
    super.key,
    required this.aspId,
    required this.transactions,
    this.swaps = const [],
    required this.loading,
    this.hideAmounts = false,
    this.showBtcAsMain = true,
    this.bitcoinPrice,
    this.showHeader = true,
  });

  @override
  TransactionHistoryWidgetState createState() =>
      TransactionHistoryWidgetState();
}

class TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchTimer;
  List<WalletActivityItem> _filteredActivity = [];

  // Cache for combined activity list (memoization for performance)
  List<WalletActivityItem>? _cachedCombinedActivity;

  // Cache for payment info (network type lookup)
  Map<String, StoredRecipient> _paymentInfoCache = {};

  // Listen to pending transaction updates
  final PendingTransactionService _pendingService = PendingTransactionService();

  // Reference to filter service for listening to changes
  TransactionFilterService? _filterService;

  @override
  void initState() {
    super.initState();
    // Listen to pending transaction changes
    _pendingService.addListener(_onPendingTransactionsChanged);

    _filteredActivity = _combineAllActivity();

    // Reconcile pending with real transactions when widget loads
    _pendingService.reconcileWithRealTransactions(widget.transactions);

    // Load payment info for all transactions
    _loadPaymentInfoCache();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to filter service changes
    final newFilterService =
        Provider.of<TransactionFilterService>(context, listen: false);
    if (_filterService != newFilterService) {
      _filterService?.removeListener(_onFilterChanged);
      _filterService = newFilterService;
      _filterService?.addListener(_onFilterChanged);
      // Apply any existing filters when first connected
      if (_filterService?.hasAnyFilter == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _applySearch(_searchController.text);
          }
        });
      }
    }
  }

  void _onFilterChanged() {
    // Filter service changed, refresh the filter
    if (mounted) {
      _cachedCombinedActivity = null;
      _applySearch(_searchController.text);
    }
  }

  /// Load payment info for all transactions to enable proper filtering
  Future<void> _loadPaymentInfoCache() async {
    final recipients = await RecipientStorageService.getRecipients();
    final cache = <String, StoredRecipient>{};
    for (final r in recipients) {
      if (r.txid != null) {
        cache[r.txid!] = r;
      }
    }
    if (mounted) {
      setState(() {
        _paymentInfoCache = cache;
      });
    }
  }

  /// Get the network type for a transaction based on cached payment info
  String _getNetworkTypeForTxid(String txid, String defaultNetwork) {
    final paymentInfo = _paymentInfoCache[txid];
    if (paymentInfo != null) {
      if (paymentInfo.isLightning) return 'Lightning';
      if (paymentInfo.isOnchain) return 'Onchain';
      if (paymentInfo.isArkade) return 'Arkade';
    }
    return defaultNetwork;
  }

  void _onPendingTransactionsChanged() {
    // Invalidate cache when pending transactions change
    _cachedCombinedActivity = null;
    if (mounted) {
      _applySearch(_searchController.text);
    }
  }

  /// Combine transactions, swaps, and pending items into a unified list
  /// Uses cached result if available, otherwise computes and caches
  List<WalletActivityItem> _combineAllActivity() {
    if (_cachedCombinedActivity != null) {
      return _cachedCombinedActivity!;
    }

    final List<WalletActivityItem> items = [];

    // Add pending transactions first (they'll float to top due to high timestamp)
    items.addAll(_pendingService.pendingItems);

    // Add regular transactions
    for (final tx in widget.transactions) {
      items.add(TransactionActivityItem(tx));
    }

    // Add swaps
    for (final swap in widget.swaps) {
      items.add(SwapActivityItem(swap));
    }

    // Sort by timestamp (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _cachedCombinedActivity = items;
    return items;
  }

  @override
  void didUpdateWidget(TransactionHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.swaps != widget.swaps) {
      // Invalidate cache when source data changes
      _cachedCombinedActivity = null;
      // Reconcile pending with real transactions when data updates
      _pendingService.reconcileWithRealTransactions(widget.transactions);
      // Reload payment info cache
      _loadPaymentInfoCache();
      _applySearch(_searchController.text);
    }
  }

  @override
  void dispose() {
    _pendingService.removeListener(_onPendingTransactionsChanged);
    _filterService?.removeListener(_onFilterChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// Unfocus search field - can be called from parent (e.g., WalletScreen)
  void unfocusSearch() {
    _searchFocusNode.unfocus();
  }

  /// Apply search from external source (e.g., sticky header)
  /// Updates the search controller and triggers filtering
  void applySearchFromExternal(String value) {
    _searchController.text = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _applySearch(value);
    });
  }

  /// Refresh filter after filter screen is closed
  /// Invalidates cache to ensure filters are applied to full transaction list
  void refreshFilter() {
    // Invalidate cache to ensure we filter the complete list
    _cachedCombinedActivity = null;
    _applySearch(_searchController.text);
  }

  void _applySearch(String searchText) {
    // Use Provider.of to ensure we get the latest filter state
    final filterService =
        Provider.of<TransactionFilterService>(context, listen: false);
    final lowerSearch = searchText.toLowerCase();

    setState(() {
      var allActivity = _combineAllActivity();

      // Search filter
      if (searchText.isNotEmpty) {
        allActivity = allActivity.where((item) {
          if (item is PendingActivityItem) {
            // Allow searching by address for pending items
            return item.address.toLowerCase().contains(lowerSearch) ||
                'sending'.contains(lowerSearch) ||
                'pending'.contains(lowerSearch);
          } else if (item is TransactionActivityItem) {
            return item.id.toLowerCase().contains(lowerSearch);
          } else if (item is SwapActivityItem) {
            return item.id.toLowerCase().contains(lowerSearch) ||
                item.tokenSymbol.toLowerCase().contains(lowerSearch);
          }
          return false;
        }).toList();
      }

      // Type filter by network (Onchain, Lightning, Arkade, Swap)
      // Only apply if user has explicitly filtered (not default "all enabled" state)
      if (filterService.hasNetworkFilter) {
        allActivity = allActivity.where((item) {
          if (item is PendingActivityItem) {
            // Pending sends could be onchain, lightning, or arkade based on address type
            final recipientType =
                RecipientStorageService.determineType(item.address);
            if (recipientType == RecipientType.lightningInvoice ||
                recipientType == RecipientType.lightning) {
              return filterService.selectedFilters.contains('Lightning');
            }
            if (recipientType == RecipientType.ark) {
              return filterService.selectedFilters.contains('Arkade');
            }
            return filterService.selectedFilters.contains('Onchain');
          } else if (item is TransactionActivityItem) {
            return item.transaction.map(
              // Boarding is always displayed as Onchain
              boarding: (_) =>
                  filterService.selectedFilters.contains('Onchain'),
              // Round: use same logic as display (_getNetworkType with 'Arkade' default)
              round: (tx) {
                final networkType = _getNetworkTypeForTxid(tx.txid, 'Arkade');
                return filterService.selectedFilters.contains(networkType);
              },
              // Redeem: use same logic as display (_getNetworkType with 'Arkade' default)
              redeem: (tx) {
                final networkType = _getNetworkTypeForTxid(tx.txid, 'Arkade');
                return filterService.selectedFilters.contains(networkType);
              },
              // Offboard is always displayed as Onchain
              offboard: (_) =>
                  filterService.selectedFilters.contains('Onchain'),
            );
          } else if (item is SwapActivityItem) {
            return filterService.selectedFilters.contains('Swap');
          }
          return false;
        }).toList();
      }

      // Direction filter (Sent/Received)
      // Only apply if user has explicitly filtered (not default "all enabled" state)
      if (filterService.hasDirectionFilter) {
        final showSent = filterService.selectedFilters.contains('Sent');
        final showReceived = filterService.selectedFilters.contains('Received');

        allActivity = allActivity.where((item) {
          if (item is PendingActivityItem) {
            // Pending sends are always outgoing
            return showSent;
          } else if (item is TransactionActivityItem) {
            final isSent = item.amountSats < 0;
            return isSent ? showSent : showReceived;
          } else if (item is SwapActivityItem) {
            final isSent = item.isBtcToEvm; // Sending BTC
            return isSent ? showSent : showReceived;
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

  /// Check if a transaction is pending (unconfirmed)
  bool _isPendingTransaction(WalletActivityItem item) {
    if (item is PendingActivityItem) {
      return true; // Pending sends are always pending
    }
    if (item is TransactionActivityItem) {
      return item.transaction.map(
        boarding: (tx) =>
            tx.confirmedAt == null, // Unconfirmed boarding = pending receive
        round: (_) => false, // Round transactions are instant
        redeem: (_) => false, // Redeem transactions handled differently
        offboard: (tx) =>
            tx.confirmedAt == null, // Unconfirmed offboard = pending send
      );
    }
    if (item is SwapActivityItem) {
      // Swaps are pending if they're waiting for deposit or still processing
      final status = item.displayStatus;
      return status == SwapDisplayStatus.pending ||
          status == SwapDisplayStatus.processing;
    }
    return false;
  }

  List<Widget> _arrangeActivityByTime() {
    if (_filteredActivity.isEmpty) return [];

    // Separate pending items from confirmed items
    final List<WalletActivityItem> pendingItems = [];
    final List<WalletActivityItem> confirmedItems = [];

    for (final item in _filteredActivity) {
      if (_isPendingTransaction(item)) {
        pendingItems.add(item);
      } else {
        confirmedItems.add(item);
      }
    }

    Map<String, List<WalletActivityItem>> categorizedActivity = {};
    DateTime now = DateTime.now();
    DateTime startOfThisMonth = DateTime(now.year, now.month, 1);

    // Categorize confirmed items by time
    for (WalletActivityItem item in confirmedItems) {
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

    // Add "Pending" section first if there are pending items
    if (pendingItems.isNotEmpty) {
      finalWidgets.add(
        Padding(
          key: const ValueKey('header_Pending'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding,
            vertical: AppTheme.elementSpacing,
          ),
          child: Text(
            'Pending',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );

      finalWidgets.add(
        _ActivityContainer(
          key: const ValueKey('container_Pending'),
          activityItems: pendingItems,
          aspId: widget.aspId,
          hideAmounts: widget.hideAmounts,
          showBtcAsMain: widget.showBtcAsMain,
          bitcoinPrice: widget.bitcoinPrice,
        ),
      );
    }

    // Add categorized confirmed items
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

  /// Build the header widget (title + search bar)
  /// This can be used externally for sticky header implementation
  Widget buildHeader({bool includeBottomPadding = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
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
        if (!widget.loading &&
            (widget.transactions.isNotEmpty || widget.swaps.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
              vertical: AppTheme.elementSpacing,
            ),
            child: SearchFieldWidget(
              hintText: AppLocalizations.of(context)!.search,
              isSearchEnabled: true,
              node: _searchFocusNode,
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
                  // Unfocus search field before opening filter
                  _searchFocusNode.unfocus();
                  await arkBottomSheet(
                    context: context,
                    height: MediaQuery.of(context).size.height * 0.7,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: const TransactionFilterScreen(),
                  );
                  _applySearch(_searchController.text);
                },
              ),
            ),
          ),
        if (includeBottomPadding)
          const SizedBox(height: AppTheme.elementSpacing),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show header if showHeader is true
        if (widget.showHeader) buildHeader(),
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
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
                if (item is PendingActivityItem) {
                  return _PendingTransactionItemWidget(
                    pendingItem: item,
                    hideAmounts: hideAmounts,
                    showBtcAsMain: showBtcAsMain,
                    bitcoinPrice: bitcoinPrice,
                  );
                } else if (item is TransactionActivityItem) {
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

class _TransactionItemWidget extends StatefulWidget {
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

  @override
  State<_TransactionItemWidget> createState() => _TransactionItemWidgetState();
}

class _TransactionItemWidgetState extends State<_TransactionItemWidget> {
  StoredRecipient? _paymentInfo;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  Future<void> _loadPaymentInfo() async {
    final txid = widget.transaction.map(
      boarding: (tx) => tx.txid,
      round: (tx) => tx.txid,
      redeem: (tx) => tx.txid,
      offboard: (tx) => tx.txid,
    );
    final info = await RecipientStorageService.getByTxid(txid);
    if (mounted) {
      setState(() {
        _paymentInfo = info;
      });
    }
  }

  /// Get the network type based on payment info
  String _getNetworkType(String defaultNetwork) {
    if (_paymentInfo != null) {
      if (_paymentInfo!.isLightning) {
        return 'Lightning';
      }
      if (_paymentInfo!.isOnchain) {
        return 'Onchain';
      }
    }
    return defaultNetwork;
  }

  void _navigateToTransactionDetail(
    BuildContext context,
    String txid, {
    int? amountSats,
    int? createdAt,
    String? transactionType,
    String? networkType,
    bool? isConfirmed,
    bool isSettleable = false,
  }) {
    // Unfocus any text field before opening bottom sheet
    FocusScope.of(context).unfocus();
    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: TransactionDetailSheet(
        txid: txid,
        amountSats: amountSats,
        createdAt: createdAt,
        transactionType: transactionType,
        networkType: networkType,
        isConfirmed: isConfirmed,
        isSettleable: isSettleable,
        bitcoinPrice: widget.bitcoinPrice,
        paymentInfo: _paymentInfo,
      ),
    );
  }

  // NOTE: All Arkade transactions are shown as "confirmed" immediately, even if
  // the underlying on-chain transaction is still pending. This was requested by
  // users - since funds are spendable in Arkade right away, showing "pending"
  // states only confuses users with technical complexity they don't need to see.
  @override
  Widget build(BuildContext context) {
    return widget.transaction.map(
      boarding: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.boardingTransaction,
        tx.txid,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tx.amountSats.toInt(),
        widget.showBtcAsMain,
        widget.hideAmounts,
        'Onchain', // Boarding is always an onchain deposit into Arkade
        isConfirmed: true, // Always confirmed - funds are spendable immediately
        isSettleable: tx.confirmedAt != null,
      ),
      round: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.roundTransaction,
        tx.txid,
        tx.createdAt,
        tx.amountSats,
        widget.showBtcAsMain,
        widget.hideAmounts,
        _getNetworkType('Arkade'),
        isConfirmed: true, // Always confirmed - instant in Arkade
        isSettleable: true, // Round transactions are instantly settled
      ),
      redeem: (tx) => _buildTransactionTile(
        context,
        AppLocalizations.of(context)!.redeemTransaction,
        tx.txid,
        tx.createdAt,
        tx.amountSats,
        widget.showBtcAsMain,
        widget.hideAmounts,
        _getNetworkType('Arkade'),
        isConfirmed: true, // Always confirmed - funds are spendable immediately
        isSettleable: tx.isSettled, // True when fully settled on-chain
      ),
      offboard: (tx) => _buildTransactionTile(
        context,
        'Onchain Send', // Offboard = collaborative redeem to on-chain
        tx.txid,
        tx.confirmedAt ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        tx.amountSats,
        widget.showBtcAsMain,
        widget.hideAmounts,
        'Onchain', // Offboard is always onchain, never Lightning
        isConfirmed: tx.confirmedAt != null, // Only on-chain sends show pending
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    String dialogTitle,
    String txid,
    int createdAt,
    int amountSats,
    bool showBtcAsMain,
    bool hideAmounts,
    String network, {
    bool isConfirmed = true,
    bool isSettleable = false,
  }) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final amountBtc = amountSats / BitcoinConstants.satsPerBtc;

    // Use actual BTC price, with fallback only if not available
    final btcPrice = widget.bitcoinPrice ?? 0;
    // formatAmount handles currency conversion internally
    final fiatAmount = amountBtc * btcPrice;

    String transactionType = dialogTitle.replaceAll(' Transaction', '');

    // Check network type for icon display
    final isLightning = network == 'Lightning';
    final isArkade = network == 'Arkade';

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
            isConfirmed: isConfirmed,
            isSettleable: isSettleable,
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
                      RoundedButtonWidget(
                        iconData: amountSats >= 0
                            ? Icons.south_west
                            : Icons.north_east,
                        iconColor: amountSats >= 0
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        backgroundColor: (amountSats >= 0
                                ? AppTheme.successColor
                                : AppTheme.errorColor)
                            .withValues(alpha: 0.15),
                        buttonType: ButtonType.secondary,
                        size: AppTheme.cardPadding * 2,
                        iconSize: AppTheme.cardPadding * 0.9,
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
                          const SizedBox(height: AppTheme.elementSpacing / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                DateFormatter.formatTimeAgoFromTimestamp(
                                    createdAt),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.elementSpacing / 2,
                                ),
                                child: Text(
                                  '·',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              // Show network-specific icon (all gray)
                              if (isArkade)
                                SvgPicture.asset(
                                  'assets/images/tokens/arkade.svg',
                                  width: AppTheme.cardPadding * 0.5,
                                  height: AppTheme.cardPadding * 0.5,
                                  colorFilter: ColorFilter.mode(
                                    isDark
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                    BlendMode.srcIn,
                                  ),
                                )
                              else
                                FaIcon(
                                  isLightning
                                      ? FontAwesomeIcons.bolt
                                      : FontAwesomeIcons.link,
                                  size: AppTheme.cardPadding * 0.5,
                                  color: isDark
                                      ? AppTheme.white60
                                      : AppTheme.black60,
                                ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 4),
                              Text(
                                network,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
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
                                      ? NumberFormatter.formatSats(amountSats,
                                          showSign: true)
                                      : '${amountSats.isNegative ? "-" : "+"}${currencyService.formatAmount(fiatAmount.abs())}',
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
    // Unfocus any text field before opening bottom sheet
    FocusScope.of(context).unfocus();
    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.75,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SwapDetailSheet(
        swapId: swapItem.id,
        initialSwapItem: swapItem,
      ),
    );
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
    final amountSats = swapItem.amountSats;
    final usdAmount = swapItem.usdAmount;
    final isExpired = swapItem.displayStatus == SwapDisplayStatus.expired;

    // Use grey color for expired swaps, bitcoin color otherwise
    final iconColor = isExpired
        ? (isDark ? AppTheme.white60 : AppTheme.black60)
        : AppTheme.colorBitcoin;

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
                      // Swap icon - greyed out for expired swaps
                      RoundedButtonWidget(
                        iconData: swapItem.isBtcToEvm
                            ? Icons.north_east
                            : Icons.south_west,
                        iconColor: iconColor,
                        backgroundColor: iconColor.withValues(alpha: 0.15),
                        buttonType: ButtonType.secondary,
                        size: AppTheme.cardPadding * 2,
                        iconSize: AppTheme.cardPadding * 0.9,
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
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: AppTheme.cardPadding * 0.6,
                                color: iconColor,
                              ),
                              const SizedBox(
                                  width: AppTheme.elementSpacing / 2),
                              Text(
                                _getSwapTypeLabel(),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // RIGHT SIDE - Show "Expired" for expired swaps instead of amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isExpired)
                        Text(
                          'Expired',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDark
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                  ),
                        )
                      else if (hideAmounts)
                        Text(
                          '*****',
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      else
                        Row(
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

/// Widget for displaying a pending transaction with a loading spinner
class _PendingTransactionItemWidget extends StatelessWidget {
  final PendingActivityItem pendingItem;
  final bool hideAmounts;
  final bool showBtcAsMain;
  final double? bitcoinPrice;

  const _PendingTransactionItemWidget({
    required this.pendingItem,
    required this.hideAmounts,
    required this.showBtcAsMain,
    this.bitcoinPrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountSats = pendingItem.amountSats;

    // Determine status
    final isSending = pendingItem.isSending;
    final isSuccess = pendingItem.isSuccess;

    // Status text
    String statusText;
    Color statusColor;
    if (isSending) {
      statusText = l10n.sendingStatus;
      statusColor = AppTheme.colorBitcoin;
    } else if (isSuccess) {
      statusText = l10n.sentStatus;
      statusColor = AppTheme.successColor;
    } else {
      statusText = l10n.failedStatus;
      statusColor = AppTheme.errorColor;
    }

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
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
                    RoundedButtonWidget(
                      iconData: Icons.north_east,
                      iconColor: isSending
                          ? AppTheme.colorBitcoin
                          : (isSuccess
                              ? AppTheme.successColor
                              : AppTheme.errorColor),
                      backgroundColor: (isSending
                              ? AppTheme.colorBitcoin
                              : (isSuccess
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor))
                          .withValues(alpha: 0.15),
                      buttonType: ButtonType.secondary,
                      size: AppTheme.cardPadding * 2,
                      iconSize: AppTheme.cardPadding * 0.9,
                    ),
                    const SizedBox(width: AppTheme.elementSpacing * 0.75),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: AppTheme.cardPadding * 6.5,
                          child: Text(
                            l10n.send,
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
                        Text(
                          statusText,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: statusColor,
                                  ),
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
                                '${amountSats.abs()}',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
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
    );
  }
}
