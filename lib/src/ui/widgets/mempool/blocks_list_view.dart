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
                width: 3,
                height: 160,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.0),
                  color: Colors.grey.withValues(alpha: 0.3),
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
    final dateUtc = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt() * 1000,
        isUtc: true);
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

  List<Color> _getGradientColors() {
    Color startColor = const Color.fromARGB(255, 30, 32, 204);
    Color endColor = const Color(0xFF9C27B0);

    return [startColor, endColor];
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: 180,
      height: 180,
      margin: const EdgeInsets.only(right: 16.0),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getGradientColors()
                      .map((c) => c.withValues(alpha: c.a * 0.4))
                      .toList(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getGradientColors(),
                ),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFBA68C8)
                      : const Color(0xFF9C27B0).withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${block.height}',
                    style: TextStyle(
                      color: theme.primaryWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (block.extras?.avgFeeRate != null)
                    Text(
                      '${block.extras!.avgFeeRate!.toStringAsFixed(1)} sat/vB',
                      style: TextStyle(
                        color: theme.primaryWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (block.extras?.medianFee != null)
                    Text(
                      '${block.extras!.medianFee!.toStringAsFixed(1)} sat/vB',
                      style: TextStyle(
                        color: theme.primaryWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(block.timestamp, context),
                    style: TextStyle(
                      color: theme.primaryWhite.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
