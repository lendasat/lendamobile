import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'transaction_detail_screen.dart';

class UnacceptedBlockTransactionsScreen extends StatefulWidget {
  final MempoolBlock block;
  final int blockIndex;
  final DifficultyAdjustment? difficultyAdjustment;

  const UnacceptedBlockTransactionsScreen({
    super.key,
    required this.block,
    required this.blockIndex,
    this.difficultyAdjustment,
  });

  @override
  State<UnacceptedBlockTransactionsScreen> createState() =>
      _UnacceptedBlockTransactionsScreenState();
}

class _UnacceptedBlockTransactionsScreenState
    extends State<UnacceptedBlockTransactionsScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<ProjectedTransaction> _allTransactions = [];
  List<ProjectedTransaction> _displayedTransactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  static const int _pageSize = 30;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _trackMempoolBlock();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  void _loadMoreTransactions() {
    if (_isLoadingMore ||
        _displayedTransactions.length >= _allTransactions.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final currentDisplayedLength = _displayedTransactions.length;
    final currentAllTransactions = List<ProjectedTransaction>.from(
      _allTransactions,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      if (currentDisplayedLength >= currentAllTransactions.length) {
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }

      final startIndex = currentDisplayedLength;
      final endIndex = (startIndex + _pageSize).clamp(
        0,
        currentAllTransactions.length,
      );

      setState(() {
        _displayedTransactions.addAll(
          currentAllTransactions.sublist(startIndex, endIndex),
        );
        _isLoadingMore = false;
      });
    });
  }

  void _trackMempoolBlock() {
    rust_api.trackMempoolBlock(blockIndex: widget.blockIndex).listen(
      (data) {
        if (!mounted) return;

        if (data.transactions.isEmpty && !_isLoading) {
          debugPrint(
            'Ignoring empty transaction update for block ${data.index}',
          );
          return;
        }

        setState(() {
          _allTransactions = data.transactions;
          final firstPageEnd = _pageSize.clamp(0, _allTransactions.length);
          _displayedTransactions = _allTransactions.sublist(
            0,
            firstPageEnd,
          );
          _isLoading = false;
          _error = null;
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
        debugPrint('Error tracking mempool block: $error');
      },
    );
  }

  String _formatFees(BigInt satoshis) {
    final btc = satoshis.toInt() / 100000000;
    return '${btc.toStringAsFixed(8)} BTC';
  }

  String _formatSize(double bytes) {
    final mb = bytes / 1000000;
    return '${mb.toStringAsFixed(2)} MB';
  }

  int _estimateMinutes() {
    if (widget.difficultyAdjustment != null) {
      final minutesPerBlock =
          widget.difficultyAdjustment!.timeAvg.toInt() ~/ 60000;
      return (widget.blockIndex + 1) * minutesPerBlock;
    }

    // Fallback to ~10 min per block if no data
    return (widget.blockIndex + 1) * 10;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: theme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.pendingBlock,
              style: TextStyle(
                color: theme.primaryWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${AppLocalizations.of(context)!.nextBlock} #${widget.blockIndex + 1}',
              style: TextStyle(color: theme.mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFA500)),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2400),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: const Color(0xFFFFA500),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          AppLocalizations.of(context)!.status,
                          AppLocalizations.of(context)!.pendingConfirmation,
                          const Color(0xFFFFA500),
                          theme,
                        ),
                        const SizedBox(height: 8.0),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.transactions,
                          '${widget.block.nTx}',
                          theme.primaryWhite,
                          theme,
                        ),
                        const SizedBox(height: 8.0),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.totalFees,
                          _formatFees(widget.block.totalFees),
                          theme.primaryWhite,
                          theme,
                        ),
                        const SizedBox(height: 8.0),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.medianFee,
                          '${widget.block.medianFee.toStringAsFixed(1)} sat/vB',
                          theme.primaryWhite,
                          theme,
                        ),
                        const SizedBox(height: 8.0),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.blockSize,
                          _formatSize(widget.block.blockVsize),
                          theme.primaryWhite,
                          theme,
                        ),
                        const SizedBox(height: 8.0),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.estimatedTime,
                          '~${_estimateMinutes()} ${AppLocalizations.of(context)!.minutes}',
                          const Color(0xFFFFA500),
                          theme,
                        ),
                      ],
                    ),
                  ),
                  if (widget.block.feeRange.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.feeDistribution,
                            style: TextStyle(
                              color: theme.primaryWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          _buildFeeDistribution(theme),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.transactions,
                          style: TextStyle(
                            color: theme.primaryWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: theme.secondaryBlack,
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_allTransactions.isEmpty && !_isLoading)
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: theme.secondaryBlack,
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ),
                              border: Border.all(
                                  color: theme.primaryWhite
                                      .withValues(alpha: 0.1)),
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.noTransactionsYet,
                                style: TextStyle(
                                  color: theme.mutedText,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _displayedTransactions.length,
                                itemBuilder: (context, index) {
                                  final tx = _displayedTransactions[index];
                                  return _buildTransactionCard(tx, theme);
                                },
                              ),
                              if (_isLoadingMore)
                                Padding(
                                  padding: const EdgeInsets.all(
                                    16.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFFFA500),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8.0,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .loadingMoreTransactions,
                                        style: TextStyle(
                                          color: theme.mutedText,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!_isLoadingMore &&
                                  _displayedTransactions.length <
                                      _allTransactions.length)
                                Padding(
                                  padding: const EdgeInsets.all(
                                    8.0,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .scrollDownToLoadMore,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, Color valueColor, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.mutedText, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeDistribution(AppTheme theme) {
    final feeRange = widget.block.feeRange;
    final labels = [
      AppLocalizations.of(context)!.min,
      '10%',
      '25%',
      AppLocalizations.of(context)!.med,
      '75%',
      '90%',
      AppLocalizations.of(context)!.max
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBlack,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.primaryWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: List.generate(feeRange.length, (index) {
          final fee = feeRange[index];
          final maxFee = feeRange.last;
          final widthPercent = maxFee > 0 ? (fee / maxFee) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: theme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.primaryBlack,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: widthPercent,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA500),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${fee.toStringAsFixed(1)} s/vB',
                    style: TextStyle(
                      color: theme.primaryWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionCard(ProjectedTransaction tx, AppTheme theme) {
    final hasFlag = tx.flags > 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(txid: tx.txid),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: hasFlag ? const Color(0xFF2D2400) : theme.secondaryBlack,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: hasFlag
                ? const Color(0xFFFFA500)
                : theme.primaryWhite.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${tx.txid.substring(0, 16)}...${tx.txid.substring(tx.txid.length - 8)}',
                    style: TextStyle(
                      color: theme.primaryWhite,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasFlag)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      'RBF',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTxDetail(
                  AppLocalizations.of(context)!.feeRate,
                  '${tx.feeRate.toStringAsFixed(1)} sat/vB',
                  theme,
                ),
                _buildTxDetail(AppLocalizations.of(context)!.size,
                    '${tx.vsize} vB', theme),
                _buildTxDetail(
                  AppLocalizations.of(context)!.value,
                  '${(tx.value.toDouble() / 100000000).toStringAsFixed(5)} BTC',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxDetail(String label, String value, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.mutedText, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
