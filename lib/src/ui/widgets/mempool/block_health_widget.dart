import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';

class BlockHealthWidget extends StatelessWidget {
  final int actualTxCount;
  final int expectedTxCount;
  final BigInt timestamp;

  const BlockHealthWidget({
    super.key,
    required this.actualTxCount,
    required this.expectedTxCount,
    required this.timestamp,
  });

  double _calculateHealthScore() {
    final ratio = actualTxCount / expectedTxCount;

    if (ratio >= 1.0) {
      return 100.0;
    }

    return (ratio * 100).clamp(0.0, 100.0);
  }

  Color _getHealthColor(double score) {
    if (score >= 80) {
      return const Color(0xFF4CAF50);
    } else if (score >= 50) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFFFF5252);
    }
  }

  String _getHealthLabel(double score, BuildContext context) {
    if (score >= 80) {
      return AppLocalizations.of(context)!.healthy;
    } else if (score >= 50) {
      return AppLocalizations.of(context)!.fair;
    } else {
      return AppLocalizations.of(context)!.low;
    }
  }

  IconData _getHealthIcon(double score) {
    if (score >= 80) {
      return Icons.check_circle;
    } else if (score >= 50) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final healthScore = _calculateHealthScore();
    final healthColor = _getHealthColor(healthScore);
    final healthLabel = _getHealthLabel(healthScore, context);
    final healthIcon = _getHealthIcon(healthScore);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBlack,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.primaryWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.primaryBlack,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.favorite,
                  color: theme.primaryWhite,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                AppLocalizations.of(context)!.blockHealth,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(healthIcon, color: healthColor, size: 32),
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        healthLabel,
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${healthScore.toStringAsFixed(0)}% ${AppLocalizations.of(context)!.full}',
                        style: TextStyle(
                          color: theme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 6,
                        backgroundColor: theme.primaryBlack,
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      ),
                    ),
                    Text(
                      healthScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: healthColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.primaryBlack,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  AppLocalizations.of(context)!.actual,
                  actualTxCount.toString(),
                  theme.primaryWhite,
                  theme,
                ),
                Container(
                    width: 1,
                    height: 30,
                    color: theme.primaryWhite.withValues(alpha: 0.1)),
                _buildStatColumn(
                  AppLocalizations.of(context)!.expected,
                  '~$expectedTxCount',
                  theme.mutedText,
                  theme,
                ),
                Container(
                    width: 1,
                    height: 30,
                    color: theme.primaryWhite.withValues(alpha: 0.1)),
                _buildStatColumn(
                  AppLocalizations.of(context)!.difference,
                  actualTxCount >= expectedTxCount
                      ? '+${actualTxCount - expectedTxCount}'
                      : '${actualTxCount - expectedTxCount}',
                  actualTxCount >= expectedTxCount
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF5252),
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, Color valueColor, AppTheme theme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: theme.mutedText, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
