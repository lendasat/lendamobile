import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:provider/provider.dart';

class DifficultyAdjustmentCard extends StatelessWidget {
  final DifficultyAdjustment difficultyAdjustment;

  const DifficultyAdjustmentCard({
    super.key,
    required this.difficultyAdjustment,
  });

  String _formatDate(BigInt timestamp, BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final dateUtc = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt(), isUtc: true);
    final date = timezoneService.toSelectedTimezone(dateUtc);
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTimeRemaining(BigInt milliseconds, BuildContext context) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    if (days > 0) {
      return '$days ${AppLocalizations.of(context)!.days}, $hours ${AppLocalizations.of(context)!.hours}';
    } else if (hours > 0) {
      return '$hours ${AppLocalizations.of(context)!.hours}';
    } else {
      return '${duration.inMinutes} ${AppLocalizations.of(context)!.minutes}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final progressPercent = difficultyAdjustment.progressPercent;
    final difficultyChange = difficultyAdjustment.difficultyChange;
    final isIncrease = difficultyChange >= 0;

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
                Icons.bar_chart,
                color: theme.primaryWhite,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              Text(
                AppLocalizations.of(context)!.difficultyAdjustment,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progressPercent.toStringAsFixed(1)}% ${AppLocalizations.of(context)!.complete}',
                    style: TextStyle(
                      color: theme.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${isIncrease ? '+' : ''}${difficultyChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isIncrease ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  backgroundColor: theme.primaryBlack,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isIncrease ? Colors.green : Colors.red,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildStatRow(
            AppLocalizations.of(context)!.remainingBlocks,
            '${difficultyAdjustment.remainingBlocks}',
            theme,
          ),
          const SizedBox(height: 8.0),
          _buildStatRow(
            AppLocalizations.of(context)!.estTime,
            _formatTimeRemaining(difficultyAdjustment.remainingTime, context),
            theme,
          ),
          const SizedBox(height: 8.0),
          _buildStatRow(
            AppLocalizations.of(context)!.estDate,
            _formatDate(difficultyAdjustment.estimatedRetargetDate, context),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, AppTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.mutedText, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
