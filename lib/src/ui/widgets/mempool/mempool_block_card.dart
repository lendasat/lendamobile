import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class MempoolBlockCard extends StatelessWidget {
  final MempoolBlock block;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final AnimationController flashController;
  final DifficultyAdjustment? difficultyAdjustment;

  const MempoolBlockCard({
    super.key,
    required this.block,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.flashController,
    this.difficultyAdjustment,
  });

  String _formatFees(BigInt satoshis) {
    final btc = satoshis.toInt() / 100000000;
    return '${btc.toStringAsFixed(4)} BTC';
  }

  String _formatSize(double bytes) {
    final mb = bytes / 1000000;
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return AnimatedBuilder(
      animation: flashController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (flashController.value * 0.7),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D2400) : theme.secondaryBlack,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFA500)
                  : const Color(0xFF4D4D00),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA500).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.pending_outlined,
                    color: Color(0xFFFFA500),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '${block.nTx} tx',
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                _formatFees(block.totalFees),
                style: const TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${block.medianFee.toStringAsFixed(1)} sat/vB',
                style: TextStyle(
                  color: theme.mutedText,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                _formatSize(block.blockVsize),
                style: TextStyle(color: theme.mutedText, fontSize: 10),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFFFFA500),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${_estimateMinutes(index)} ${AppLocalizations.of(context)!.min}',
                    style: const TextStyle(
                      color: Color(0xFFFFA500),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _estimateMinutes(int blockIndex) {
    if (difficultyAdjustment != null) {
      final minutesPerBlock = difficultyAdjustment!.timeAvg.toInt() ~/ 60000;
      return (blockIndex + 1) * minutesPerBlock;
    }

    return (blockIndex + 1) * 10;
  }
}
