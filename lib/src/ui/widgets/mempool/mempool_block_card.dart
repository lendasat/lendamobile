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

  List<Color> _getGradientColors() {
    Color startColor = const Color.fromARGB(255, 62, 182, 68);
    Color endColor = const Color.fromARGB(255, 218, 182, 66);

    return [startColor, endColor];
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return AnimatedBuilder(
      animation: flashController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.8 + (flashController.value * 0.2),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
                          ? const Color(0xFF81C784)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pending',
                        style: TextStyle(
                          color: theme.primaryWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${block.medianFee.toStringAsFixed(1)} sat/vB',
                        style: TextStyle(
                          color: theme.primaryWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'In ~${_estimateMinutes(index)} ${AppLocalizations.of(context)!.min}',
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
