import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import '../../widgets/mempool/blocks_list_view.dart';
import '../../widgets/mempool/transaction_fee_card.dart';
import '../../widgets/mempool/difficulty_adjustment_card.dart';
import '../../widgets/mempool/hashrate_chart.dart';
import 'block_transactions_screen.dart';
import 'unaccepted_block_transactions_screen.dart';
import 'transaction_detail_screen.dart';

class MempoolHome extends StatefulWidget {
  const MempoolHome({super.key});

  @override
  State<MempoolHome> createState() => _MempoolHomeState();
}

class _MempoolHomeState extends State<MempoolHome> {
  List<MempoolBlock> _mempoolBlocks = [];
  List<Block> _confirmedBlocks = [];
  RecommendedFees? _fees;
  DifficultyAdjustment? _difficultyAdjustment;
  HashrateData? _hashrateData;
  Conversions? _conversions;
  List<BitcoinTransaction> _recentTransactions = [];
  bool _isLoading = true;
  bool _transactionsLoading = false;
  String? _error;
  int _selectedMempoolIndex = -1;
  int _selectedConfirmedIndex = -1;
  final ScrollController _blocksScrollController = ScrollController();
  bool _hasInitialScrolled = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchType = 'block'; // 'block' or 'transaction'

  @override
  void initState() {
    super.initState();
    _loadMempoolData();
    _loadRecentTransactions();
    _subscribeToWebSocket();

    Future.delayed(const Duration(seconds: 3), () {
      _scrollToDivider();
    });
  }

  @override
  void dispose() {
    _blocksScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBlock(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final isHeight = int.tryParse(query.trim()) != null;

      if (isHeight) {
        final height = int.parse(query.trim());
        final blocks = await rust_api.getBlocksAtHeight(
          height: BigInt.from(height),
        );

        if (mounted && blocks.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlockTransactionsScreen(
                block: blocks.first,
                conversions: _conversions,
                confirmedBlocks: _confirmedBlocks,
              ),
            ),
          );
        }
      } else {
        final block = await rust_api.getBlockByHash(hash: query.trim());

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlockTransactionsScreen(
                block: block,
                conversions: _conversions,
                confirmedBlocks: _confirmedBlocks,
              ),
            ),
          );
        }
      }

      _searchController.clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Block not found: ${e.toString()}';
        });
      }
      debugPrint('Error searching block: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _scrollToDivider() {
    if (!mounted ||
        !_blocksScrollController.hasClients ||
        _hasInitialScrolled ||
        _mempoolBlocks.isEmpty) {
      return;
    }

    // Calculate width: each card is ~148px (140px + 8px margin)
    const cardWidth = 148.0;
    final mempoolWidth = _mempoolBlocks.length * cardWidth;

    // Calculate position to center divider in viewport
    final screenWidth = MediaQuery.of(context).size.width;
    final targetScroll = mempoolWidth - (screenWidth / 2);

    _blocksScrollController.animateTo(
      targetScroll.clamp(0.0, _blocksScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _hasInitialScrolled = true;
  }

  Future<void> _loadMempoolData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final blocks = await rust_api.getBlocks();

      final fees = await rust_api.getRecommendedFees();
      final hashrateData = await rust_api.getHashrateData(period: '1M');

      if (mounted) {
        setState(() {
          _confirmedBlocks = blocks;
          _fees = fees;
          _hashrateData = hashrateData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading mempool data: $e');
    }
  }

  void _subscribeToWebSocket() {
    rust_api.subscribeMempoolUpdates().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          if (event.mempoolBlocks != null) {
            _mempoolBlocks = event.mempoolBlocks!;
          }

          if (event.blocks != null) {
            _confirmedBlocks = event.blocks!;
          }

          // Update fees
          if (event.fees != null) {
            _fees = event.fees;
          }

          if (event.da != null) {
            _difficultyAdjustment = event.da;
          }

          if (event.conversions != null) {
            _conversions = event.conversions;
          }
        });
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
      },
    );
  }

  Future<void> _loadRecentTransactions() async {
    setState(() {
      _transactionsLoading = true;
    });

    try {
      // Get ARK transaction history
      final arkTransactions = await ark_api.txHistory();

      // Fetch full Bitcoin transaction details for each txid
      final List<BitcoinTransaction> transactions = [];
      for (final arkTx in arkTransactions.take(10)) {
        try {
          final bitcoinTx = await rust_api.getTransaction(txid: arkTx.txid);
          transactions.add(bitcoinTx);
        } catch (e) {
          debugPrint('Error fetching transaction ${arkTx.txid}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _recentTransactions = transactions;
          _transactionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _transactionsLoading = false;
        });
      }
      debugPrint('Error loading recent transactions: $e');
    }
  }

  void _onMempoolBlockTap(int index) {
    // Navigate to unaccepted block transactions screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnacceptedBlockTransactionsScreen(
          block: _mempoolBlocks[index],
          blockIndex: index,
          difficultyAdjustment: _difficultyAdjustment,
        ),
      ),
    );
  }

  void _onConfirmedBlockTap(int index) {
    setState(() {
      _selectedMempoolIndex = -1;
      _selectedConfirmedIndex = index;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlockTransactionsScreen(
          block: _confirmedBlocks[index],
          conversions: _conversions,
          confirmedBlocks: _confirmedBlocks,
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final theme = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.secondaryBlack,
          title: Text(
            AppLocalizations.of(context)!.searchBlockchain,
            style: TextStyle(
              color: theme.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _searchType = 'block'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: _searchType == 'block'
                              ? theme.primaryWhite
                              : theme.primaryBlack,
                          borderRadius: BorderRadius.circular(
                            8.0,
                          ),
                          border: Border.all(
                            color: _searchType == 'block'
                                ? theme.primaryWhite
                                : theme.primaryWhite.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'Block',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _searchType == 'block'
                                ? theme.primaryBlack
                                : theme.primaryWhite,
                            fontSize: 14,
                            fontWeight: _searchType == 'block'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _searchType = 'transaction',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: _searchType == 'transaction'
                              ? theme.primaryWhite
                              : theme.primaryBlack,
                          borderRadius: BorderRadius.circular(
                            8.0,
                          ),
                          border: Border.all(
                            color: _searchType == 'transaction'
                                ? theme.primaryWhite
                                : theme.primaryWhite.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.transaction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _searchType == 'transaction'
                                ? theme.primaryBlack
                                : theme.primaryWhite,
                            fontSize: 14,
                            fontWeight: _searchType == 'transaction'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                _searchType == 'block'
                    ? AppLocalizations.of(context)!.enterBlockHeightOrBlockHash
                    : AppLocalizations.of(context)!.enterTransactionIdTxid,
                style: TextStyle(
                  color: theme.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _searchController,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: _searchType == 'block'
                      ? 'e.g. 800000 or 000000...'
                      : 'e.g. abc123...',
                  hintStyle: TextStyle(
                    color: theme.mutedText,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: theme.primaryBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      8.0,
                    ),
                    borderSide: BorderSide(
                        color: theme.primaryWhite.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      8.0,
                    ),
                    borderSide: BorderSide(
                        color: theme.primaryWhite.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      8.0,
                    ),
                    borderSide: BorderSide(
                      color: theme.primaryWhite,
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop();
                  if (_searchType == 'block') {
                    _searchBlock(value);
                  } else {
                    _searchTransaction(value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: theme.mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_searchType == 'block') {
                  _searchBlock(_searchController.text);
                } else {
                  _searchTransaction(_searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryWhite,
                foregroundColor: theme.primaryBlack,
              ),
              child: _isSearching
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryBlack,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.search),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchTransaction(String txid) async {
    if (txid.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(txid: txid.trim()),
          ),
        );
        _searchController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error searching transaction: ${e.toString()}';
        });
      }
      debugPrint('Error searching transaction: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: theme.primaryBlack,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.blockchain,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.primaryWhite),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.primaryWhite),
            onPressed: _loadMempoolData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.primaryWhite),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        AppLocalizations.of(context)!.errorLoadingData,
                        style: TextStyle(
                          color: theme.primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.mutedText,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: _loadMempoolData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondaryBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMempoolData,
                  backgroundColor: theme.secondaryBlack,
                  color: theme.primaryWhite,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Blocks List
                        if (_mempoolBlocks.isNotEmpty ||
                            _confirmedBlocks.isNotEmpty)
                          BlocksListView(
                            mempoolBlocks: _mempoolBlocks,
                            confirmedBlocks: _confirmedBlocks,
                            selectedMempoolIndex: _selectedMempoolIndex,
                            selectedConfirmedIndex: _selectedConfirmedIndex,
                            onMempoolBlockTap: _onMempoolBlockTap,
                            onConfirmedBlockTap: _onConfirmedBlockTap,
                            scrollController: _blocksScrollController,
                            difficultyAdjustment: _difficultyAdjustment,
                          ),

                        const SizedBox(height: 24.0),

                        // Statistics Cards
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          child: Column(
                            children: [
                              if (_fees != null)
                                TransactionFeeCard(fees: _fees!),
                              const SizedBox(height: 16.0),
                              if (_difficultyAdjustment != null)
                                DifficultyAdjustmentCard(
                                  difficultyAdjustment: _difficultyAdjustment!,
                                ),
                              const SizedBox(height: 16.0),
                              if (_hashrateData != null)
                                HashrateChartCard(initialData: _hashrateData!),
                              const SizedBox(height: 16.0),
                              _buildRecentTransactions(theme),
                              const SizedBox(height: 32.0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRecentTransactions(AppTheme theme) {
    if (_transactionsLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: theme.primaryWhite),
        ),
      );
    }

    if (_recentTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recentTransactions,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentTransactions.length,
          itemBuilder: (context, index) {
            final tx = _recentTransactions[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        TransactionDetailScreen(txid: tx.txid),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.secondaryBlack,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.primaryWhite.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      color: theme.mutedText,
                      size: 20,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.txid.length > 16
                                ? '${tx.txid.substring(0, 8)}...${tx.txid.substring(tx.txid.length - 8)}'
                                : tx.txid,
                            style: TextStyle(
                              color: theme.primaryWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppLocalizations.of(context)!.inputs}: ${tx.vin.length} • ${AppLocalizations.of(context)!.outputs}: ${tx.vout.length}',
                            style: TextStyle(
                              color: theme.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.primaryWhite.withValues(alpha: 0.5),
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
