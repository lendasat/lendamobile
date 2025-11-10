import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:provider/provider.dart';
import 'mempool_block_card.dart';

class BlocksListView extends StatefulWidget {
  final List<MempoolBlock> mempoolBlocks;
  final List<Block> confirmedBlocks;
  final int selectedMempoolIndex;
  final int selectedConfirmedIndex;
  final Function(int) onMempoolBlockTap;
  final Function(int) onConfirmedBlockTap;
  final ScrollController? scrollController;
  final DifficultyAdjustment? difficultyAdjustment;

  const BlocksListView({
    super.key,
    required this.mempoolBlocks,
    required this.confirmedBlocks,
    required this.selectedMempoolIndex,
    required this.selectedConfirmedIndex,
    required this.onMempoolBlockTap,
    required this.onConfirmedBlockTap,
    this.scrollController,
    this.difficultyAdjustment,
  });

  @override
  State<BlocksListView> createState() => _BlocksListViewState();
}

class _BlocksListViewState extends State<BlocksListView>
    with SingleTickerProviderStateMixin {
  late AnimationController _masterFlashController;

  @override
  void initState() {
    super.initState();
    _masterFlashController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _masterFlashController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _masterFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: 16.0),
            if (widget.mempoolBlocks.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  shrinkWrap: true,
                  reverse: true,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.mempoolBlocks.length,
                  itemBuilder: (context, index) {
                    final block = widget.mempoolBlocks[index];

                    return GestureDetector(
                      onTap: () => widget.onMempoolBlockTap(index),
                      child: MempoolBlockCard(
                        key: ValueKey('mempool_$index'),
                        block: block,
                        index: index,
                        isSelected: index == widget.selectedMempoolIndex,
                        onTap: () => widget.onMempoolBlockTap(index),
                        flashController: _masterFlashController,
                        difficultyAdjustment: widget.difficultyAdjustment,
                      ),
                    );
                  },
                ),
              ),
            if (widget.mempoolBlocks.isNotEmpty)
              Container(
                width: 2,
                height: 140,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFA500).withValues(alpha: 0.1),
                      const Color(0xFFFFA500).withValues(alpha: 0.5),
                      const Color(0xFFFFA500).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.confirmedBlocks.length,
                itemBuilder: (context, index) {
                  final block = widget.confirmedBlocks[index];
                  return GestureDetector(
                    onTap: () => widget.onConfirmedBlockTap(index),
                    child: BlockCard(
                      key: ValueKey('confirmed_${block.id}'),
                      block: block,
                      isSelected: index == widget.selectedConfirmedIndex,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16.0),
          ],
        ),
      ),
    );
  }
}

class BlockCard extends StatelessWidget {
  final Block block;
  final bool isSelected;

  const BlockCard({super.key, required this.block, required this.isSelected});

  String _formatTime(BigInt timestamp, BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final dateUtc = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000, isUtc: true);
    final date = timezoneService.toSelectedTimezone(dateUtc);
    final now = timezoneService.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppLocalizations.of(context)!.mAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${AppLocalizations.of(context)!.hAgo}';
    } else {
      return '${difference.inDays}${AppLocalizations.of(context)!.dAgo}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isSelected ? theme.tertiaryBlack : theme.secondaryBlack,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected
              ? theme.primaryWhite
              : theme.primaryWhite.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryBlack,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '#${block.height}',
                  style: TextStyle(
                    color: theme.primaryWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: theme.mutedText,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${block.txCount} txs',
                    style: TextStyle(
                      color: theme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (block.extras?.totalFees != null)
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: theme.mutedText,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(block.extras!.totalFees!.toInt() / 100000000).toStringAsFixed(4)} BTC',
                      style: TextStyle(
                        color: theme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.mutedText,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(block.timestamp, context),
                    style: TextStyle(
                      color: theme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
