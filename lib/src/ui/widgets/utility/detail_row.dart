import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// A reusable row widget for displaying label-value pairs with optional subtitle.
/// Used for fee breakdowns, transaction details, loan details, etc.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool isBold;
  final Widget? labelWidget;
  final Widget? valueWidget;
  final double bottomPadding;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.isBold = false,
    this.labelWidget,
    this.valueWidget,
    this.bottomPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget ??
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Value
          valueWidget ??
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
        ],
      ),
    );
  }
}

/// Simplified detail row without subtitle, matching the common _buildDetailRow pattern.
class SimpleDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? labelColor;
  final Color? valueColor;

  const SimpleDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultLabelColor = isDarkMode ? AppTheme.white60 : AppTheme.black60;
    final defaultValueColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: labelColor ?? defaultLabelColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? defaultValueColor,
            ),
          ),
        ],
      ),
    );
  }
}
