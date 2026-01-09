import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

class PercentageChangeWidget extends StatelessWidget {
  final String percentage;
  final bool isPositive;
  final bool showIcon;
  final double fontSize;

  const PercentageChangeWidget({
    super.key,
    required this.percentage,
    required this.isPositive,
    this.showIcon = false,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    // Hide widget if percentage contains infinity
    final lowerPercentage = percentage.toLowerCase();
    if (lowerPercentage.contains('∞') ||
        lowerPercentage.contains('infinity') ||
        lowerPercentage.contains('inf')) {
      return const SizedBox.shrink();
    }

    // Fixed logic: Only treat zero percentages as positive, not all positive values
    final isReallyPositive = isPositive && !percentage.trim().startsWith('-');
    final color =
        isReallyPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.elementSpacing * 0.5,
        vertical: AppTheme.elementSpacing / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              isReallyPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: fontSize * 1.1,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            // Fix -0% display: always show 0% as positive
            percentage.trim() == "-0%"
                ? "0%"
                : percentage.trim() == "0%"
                    ? "0%"
                    : percentage,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
