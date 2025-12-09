import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/percentage_change_widget.dart';
import 'package:flutter/material.dart';

/// Widget for displaying price with color based on positive/negative change
class ColoredPriceWidget extends StatelessWidget {
  final String price;
  final bool isPositive;
  final String? currencySymbol;
  final bool shouldHideAmount;
  final TextStyle? textStyle;

  const ColoredPriceWidget({
    super.key,
    required this.price,
    required this.isPositive,
    this.currencySymbol,
    this.shouldHideAmount = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    if (shouldHideAmount) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: color,
            size: 16,
          ),
          Text(
            '${currencySymbol ?? ''}$price',
            style: textStyle ??
                TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      );
    }

    return Text(
      '${isPositive ? '+' : ''}${currencySymbol ?? ''}$price',
      style: textStyle ??
          TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

/// Widget for displaying percentage change with background color
/// Uses PercentageChangeWidget for consistent styling with semi-transparent background
class BitNetPercentWidget extends StatelessWidget {
  final String priceChange;
  final bool shouldHideAmount;
  final TextStyle? textStyle;

  const BitNetPercentWidget({
    super.key,
    required this.priceChange,
    this.shouldHideAmount = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if positive based on the price change string
    final isPositive = !priceChange.startsWith('-') ||
        priceChange.trim() == '-0%' ||
        priceChange.trim() == '0%';

    // Use PercentageChangeWidget for consistent styling (matches BitnetGithub)
    return Container(
      margin: const EdgeInsets.only(
        top: AppTheme.elementSpacing,
        bottom: AppTheme.elementSpacing,
      ),
      child: PercentageChangeWidget(
        percentage: priceChange,
        isPositive: isPositive,
        fontSize: 14,
      ),
    );
  }
}
