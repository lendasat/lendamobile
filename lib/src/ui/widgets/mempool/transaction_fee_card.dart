import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class TransactionFeeCard extends StatelessWidget {
  final RecommendedFees fees;

  const TransactionFeeCard({
    super.key,
    required this.fees,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

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
              Icon(
                Icons.paid,
                color: theme.primaryWhite,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              Text(
                AppLocalizations.of(context)!.transactionFees,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildFeeRow(AppLocalizations.of(context)!.fastest10Min,
              fees.fastestFee, Colors.green, theme),
          const SizedBox(height: 8.0),
          _buildFeeRow(AppLocalizations.of(context)!.halfHour, fees.halfHourFee,
              Colors.blue, theme),
          const SizedBox(height: 8.0),
          _buildFeeRow(AppLocalizations.of(context)!.oneHour, fees.hourFee,
              Colors.orange, theme),
          const SizedBox(height: 8.0),
          _buildFeeRow(AppLocalizations.of(context)!.economy, fees.economyFee,
              Colors.grey, theme),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, int feeRate, Color color, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                color: theme.mutedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          '$feeRate sat/vB',
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
