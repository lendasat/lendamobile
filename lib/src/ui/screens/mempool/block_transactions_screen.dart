import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import '../../widgets/mempool/mining_info_card.dart';
import '../../widgets/mempool/block_size_widget.dart';
import '../../widgets/mempool/block_health_widget.dart';
import 'transaction_detail_screen.dart';

class BlockTransactionsScreen extends StatefulWidget {
  final Block block;
  final Conversions? conversions;
  final List<Block>? confirmedBlocks;

  const BlockTransactionsScreen({
    super.key,
    required this.block,
    this.conversions,
    this.confirmedBlocks,
  });

  @override
  State<BlockTransactionsScreen> createState() =>
      _BlockTransactionsScreenState();
}

class _BlockTransactionsScreenState extends State<BlockTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<BitcoinTransaction> _transactions = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  Set<String> _userTxIds = {};

  int _calculateExpectedTxCount() {
    if (widget.confirmedBlocks == null || widget.confirmedBlocks!.isEmpty) {
      return 2500; // Fallback to default if no historical data
    }

    final totalTxs = widget.confirmedBlocks!.fold<int>(
      0,
      (sum, block) => sum + block.txCount.toInt(),
    );

    return (totalTxs / widget.confirmedBlocks!.length).round();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserTransactions();
    _loadTransactions();
  }

  Future<void> _loadUserTransactions() async {
    try {
      final transactions = await ark_api.txHistory();
      final txIds = transactions.map((tx) => tx.txid).toSet();

      if (mounted) {
        setState(() {
          _userTxIds = txIds;
        });
      }
    } catch (e) {
      debugPrint('Error loading user transactions: $e');
      if (mounted) {
        setState(() {
          _userTxIds = {};
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await rust_api.getBlockTransactions(
        hash: widget.block.id,
        startIndex: 0,
      );

      if (mounted) {
        setState(() {
          _transactions.clear();
          _transactions.addAll(transactions);
          _currentPage = 0;
          _hasMore = transactions.length >= 25;
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
      debugPrint('Error loading transactions: $e');
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final transactions = await rust_api.getBlockTransactions(
        hash: widget.block.id,
        startIndex: nextPage * 25,
      );

      if (mounted) {
        setState(() {
          _transactions.addAll(transactions);
          _currentPage = nextPage;
          _hasMore = transactions.length >= 25;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
      debugPrint('Error loading more transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Block #${widget.block.height}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.block.txCount} Transactions',
              style: const TextStyle(color: Color(0xFFC6C6C6), fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
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
                      const Text(
                        'Error loading transactions',
                        style: TextStyle(
                          color: Colors.white,
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
                          style: const TextStyle(
                            color: Color(0xFFC6C6C6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  backgroundColor: const Color(0xFF1A1A1A),
                  color: Colors.white,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MiningInfoCard(
                                block: widget.block,
                                conversions: widget.conversions,
                              ),
                              const SizedBox(height: 16.0),
                              BlockSizeWidget(
                                sizeBytes: widget.block.size,
                                weightUnits: widget.block.weight,
                                txCount: widget.block.txCount.toInt(),
                              ),
                              const SizedBox(height: 16.0),
                              BlockHealthWidget(
                                actualTxCount: widget.block.txCount.toInt(),
                                expectedTxCount: _calculateExpectedTxCount(),
                                timestamp: widget.block.timestamp,
                              ),
                              const SizedBox(height: 24.0),
                              const Text(
                                'Transactions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _transactions.length) {
                                return _isLoadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final tx = _transactions[index];
                              final isUserTx = _userTxIds.contains(tx.txid);
                              return TransactionCard(
                                transaction: tx,
                                isUserTransaction: isUserTx,
                              );
                            },
                            childCount:
                                _transactions.length + (_hasMore ? 1 : 0),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32.0),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final BitcoinTransaction transaction;
  final bool isUserTransaction;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.isUserTransaction = false,
  });

  String _formatSats(BigInt value) {
    return '${(value.toInt() / 100000000).toStringAsFixed(8)} BTC';
  }

  int _getTotalOutput() {
    int total = 0;
    for (var vout in transaction.vout) {
      total += vout.value.toInt();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalOutput = _getTotalOutput();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailScreen(txid: transaction.txid),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isUserTransaction
              ? const Color(0xFF1B3A1B)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isUserTransaction
                ? const Color(0xFF4CAF50)
                : Colors.white.withValues(alpha: 0.1),
            width: isUserTransaction ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt,
                  color: Color(0xFFC6C6C6),
                  size: 16,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    transaction.txid.length > 16
                        ? '${transaction.txid.substring(0, 8)}...${transaction.txid.substring(transaction.txid.length - 8)}'
                        : transaction.txid,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                // Your TX badge
                if (isUserTransaction)
                  Container(
                    margin: const EdgeInsets.only(left: 8.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      'Your TX',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: transaction.status.confirmed
                        ? const Color(0x334CAF50)
                        : const Color(0x33FF9800),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: transaction.status.confirmed
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    transaction.status.confirmed ? 'Confirmed' : 'Pending',
                    style: TextStyle(
                      color: transaction.status.confirmed
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inputs: ${transaction.vin.length}',
                      style: const TextStyle(
                        color: Color(0xFFC6C6C6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Outputs: ${transaction.vout.length}',
                      style: const TextStyle(
                        color: Color(0xFFC6C6C6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatSats(BigInt.from(totalOutput)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fee: ${_formatSats(BigInt.from(transaction.fee.toInt()))}',
                      style: const TextStyle(
                        color: Color(0xFFC6C6C6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
