import 'package:animate_do/animate_do.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/data_widget.dart';
import 'package:ark_flutter/src/models/mempool_new/bitcoin_data.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable list view that displays both mempool blocks
/// and confirmed blocks
class BlocksListView extends StatelessWidget {
  final ScrollController scrollController;
  final Function(int) onMempoolBlockTap;
  final Function(int) onConfirmedBlockTap;
  final bool isLoading;
  final bool Function(String) hasUserTxs;

  // Data to display
  final List<MempoolBlock> mempoolBlocks;
  final List<Block> confirmedBlocks;
  final DifficultyAdjustment? difficultyAdjustment;
  final int selectedMempoolIndex;
  final int selectedConfirmedIndex;
  final String? selectedBlockId;
  final double currentUSD;
  final String Function(DateTime) formatTimeAgo;

  // Back button state
  final int? blockHeight;
  final VoidCallback? onBackPressed;

  const BlocksListView({
    super.key,
    required this.scrollController,
    required this.onMempoolBlockTap,
    required this.onConfirmedBlockTap,
    required this.isLoading,
    required this.hasUserTxs,
    required this.mempoolBlocks,
    required this.confirmedBlocks,
    required this.difficultyAdjustment,
    required this.selectedMempoolIndex,
    required this.selectedConfirmedIndex,
    this.selectedBlockId,
    required this.currentUSD,
    required this.formatTimeAgo,
    this.blockHeight,
    this.onBackPressed,
  });

  /// Convert Rust Block model to BlockData model for the DataWidget
  BlockData _convertBlockToBlockData(Block block) {
    return BlockData(
      id: block.id,
      height: block.height.toInt(),
      version: block.version,
      timestamp: block.timestamp.toInt(),
      bits: block.bits,
      nonce: block.nonce,
      difficulty: block.difficulty,
      merkleRoot: block.merkleRoot,
      txCount: block.txCount,
      size: block.size.toInt(),
      weight: block.weight.toInt(),
      previousblockhash: block.previousblockhash,
      mediantime: block.mediantime?.toInt(),
      stale: block.stale,
      extras: block.extras != null
          ? Extras(
              medianFee: block.extras!.medianFee,
              totalFees: block.extras!.totalFees?.toInt(),
              avgFee: block.extras!.avgFee?.toInt(),
              avgFeeRate: block.extras!.avgFeeRate?.toInt(),
              pool: block.extras!.pool != null
                  ? Pool(
                      id: block.extras!.pool!.id?.toInt(),
                      name: block.extras!.pool!.name,
                      slug: block.extras!.pool!.slug,
                    )
                  : null,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<TimezoneService>(
      context,
      listen: false,
    ).location;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SingleChildScrollView(
          primary: false,
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Mempool blocks section
              _buildMempoolBlocks(context),

              // Divider between sections
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppTheme.cardRadiusCircular,
                  color: Colors.grey,
                ),
                height: AppTheme.cardPadding * 6,
                width: AppTheme.elementSpacing / 3,
              ),

              // Confirmed blocks section
              _buildConfirmedBlocks(context, loc),
            ],
          ),
        ),

        // Back button for blockHeight navigation
        _buildBackButton(),
      ],
    );
  }

  Widget _buildMempoolBlocks(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator(color: AppTheme.colorBitcoin);
    }

    if (mempoolBlocks.isEmpty) {
      return const Text(
        'Something went wrong!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      );
    }

    return SizedBox(
      height: 255,
      child: ListView.builder(
        primary: false,
        shrinkWrap: true,
        reverse: true,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: mempoolBlocks.length,
        itemBuilder: (context, index) {
          final timeAvg = difficultyAdjustment?.timeAvg.toInt() ?? 600000;
          var min = (index + 1) * (timeAvg / 60000);

          return GestureDetector(
            onTap: () => onMempoolBlockTap(index),
            child: Flash(
              infinite: true,
              delay: const Duration(seconds: 10),
              duration: const Duration(seconds: 5),
              child: DataWidget.notAccepted(
                key: GlobalKey(),
                mempoolBlocks: mempoolBlocks[index],
                mins: min.toStringAsFixed(0),
                index: selectedMempoolIndex == index ? 1 : 0,
                singleTx: false,
                hasUserTxs: false,
                currentUSD: currentUSD,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmedBlocks(
    BuildContext context,
    dynamic loc,
  ) {
    if (isLoading) {
      return const CircularProgressIndicator(color: AppTheme.colorBitcoin);
    }

    if (confirmedBlocks.isEmpty) {
      return const Text(
        'Something went wrong!',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      );
    }

    return SizedBox(
      height: 255,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: confirmedBlocks.length,
        itemBuilder: (context, index) {
          final block = confirmedBlocks[index];
          final blockData = _convertBlockToBlockData(block);
          double size = block.size.toInt() / 1000000;

          return GestureDetector(
            onTap: () => onConfirmedBlockTap(index),
            child: DataWidget.accepted(
              blockData: blockData,
              txId: block.id,
              size: size,
              time: formatTimeAgo(
                DateTime.fromMillisecondsSinceEpoch(
                  (block.timestamp.toInt() * 1000),
                ).toUtc().add(
                      Duration(
                        milliseconds: loc.currentTimeZone.offset,
                      ),
                    ),
              ),
              index: selectedConfirmedIndex == index ? 1 : 0,
              singleTx: false,
              hasUserTxs: hasUserTxs(block.id),
              currentUSD: currentUSD,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackButton() {
    if (blockHeight == null || onBackPressed == null) {
      return const SizedBox();
    }

    return Align(
      alignment: Alignment.bottomLeft,
      child: GestureDetector(
        onTap: onBackPressed,
        child: Opacity(
          opacity: 0.75,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.white60,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.colorBackground,
            ),
          ),
        ),
      ),
    );
  }
}
