import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/mempool/fear_and_greed_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Optimized and simplified Fear and Greed Index card
class FearAndGreedCardOptimized extends StatelessWidget {
  final FearGreedData data;
  final bool isLoading;

  const FearAndGreedCardOptimized({
    super.key,
    required this.data,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.gaugeHigh,
                        size: AppTheme.cardPadding * 0.75,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: AppTheme.elementSpacing),
                      Text(
                        AppLocalizations.of(context)!.fearAndGreedIndex,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Simplified content
              isLoading ? _buildLoadingState() : _buildIndexDisplay(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Placeholder for value
        Container(
          height: 80,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        // Placeholder for sentiment
        Container(
          height: 24,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildIndexDisplay(BuildContext context) {
    final currentValue = data.currentValue ?? 50;

    return Column(
      children: [
        // Horizontal slider/gauge representation
        SizedBox(
          height: 60,
          child: Column(
            children: [
              // Value display above the slider
              Text(
                currentValue.toString(),
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getFearGreedColor(currentValue),
                    ),
              ),

              const SizedBox(height: 8),

              // Horizontal gradient slider
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.errorColor,
                      AppTheme.errorColor.withValues(alpha: 0.7),
                      Colors.orange,
                      AppTheme.successColor.withValues(alpha: 0.7),
                      AppTheme.successColor,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final indicatorPosition =
                        (currentValue / 100) * constraints.maxWidth - 6;
                    return Stack(
                      children: [
                        // Position indicator
                        Positioned(
                          left: indicatorPosition.clamp(
                              0, constraints.maxWidth - 12),
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .shadowColor
                                      .withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Sentiment text and change indicator in one row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Sentiment text
            Text(
              data.valueText ?? "Neutral",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getFearGreedColor(currentValue),
                  ),
            ),

            // Change indicator
            if (data.previousClose != null)
              _buildSimpleComparison(context, currentValue),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleComparison(BuildContext context, int currentValue) {
    final previousValue = data.previousClose ?? currentValue;
    final change = currentValue - previousValue;
    final isPositive = change > 0;

    if (change == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          '${isPositive ? '+' : ''}$change',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: isPositive
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  // Helper to get color based on fear/greed value
  Color _getFearGreedColor(int value) {
    if (value <= 25) {
      return AppTheme.errorColor;
    } else if (value <= 50) {
      return Colors.orange;
    } else if (value <= 75) {
      return Colors.yellow;
    } else {
      return AppTheme.successColor;
    }
  }
}
