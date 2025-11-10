import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:provider/provider.dart';

class MiningInfoCard extends StatelessWidget {
  final Block block;
  final Conversions? conversions;

  const MiningInfoCard({super.key, required this.block, this.conversions});

  String _formatTimestamp(BigInt timestamp, BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final dateUtc = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt() * 1000,
        isUtc: true);
    final date = timezoneService.toSelectedTimezone(dateUtc);
    final now = timezoneService.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${AppLocalizations.of(context)!.minutesAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${AppLocalizations.of(context)!.hoursAgo}';
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.oneDayAgo;
    } else {
      return '${difference.inDays} ${AppLocalizations.of(context)!.daysAgo}';
    }
  }

  String _formatReward(double rewardBtc, BuildContext context) {
    if (conversions != null && conversions!.usd > 0) {
      final rewardUsd = rewardBtc * conversions!.usd;
      final currencyService = context.watch<CurrencyPreferenceService>();
      return currencyService.formatAmount(rewardUsd);
    }
    return '${rewardBtc.toStringAsFixed(8)} BTC';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final pool = block.extras?.pool;
    final reward = block.extras?.reward;

    if (pool == null && reward == null) {
      return const SizedBox.shrink();
    }

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
                  Icons.architecture,
                  color: theme.primaryWhite,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                AppLocalizations.of(context)!.miningInformation,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (pool != null) ...[
            _buildInfoRow(AppLocalizations.of(context)!.miningPool, pool.name,
                Icons.groups, theme),
            const SizedBox(height: 8.0),
          ],
          _buildInfoRow(
            AppLocalizations.of(context)!.mined,
            _formatTimestamp(block.timestamp, context),
            Icons.access_time,
            theme,
          ),
          if (reward != null) ...[
            const SizedBox(height: 8.0),
            _buildInfoRow(AppLocalizations.of(context)!.blockReward,
                _formatReward(reward, context), Icons.paid, theme),
          ],
          if (block.extras?.totalFees != null) ...[
            const SizedBox(height: 8.0),
            _buildInfoRow(
              AppLocalizations.of(context)!.totalFees,
              '${(block.extras!.totalFees!.toInt() / 100000000).toStringAsFixed(8)} BTC',
              Icons.account_balance_wallet,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, AppTheme theme) {
    return Row(
      children: [
        Icon(icon, color: theme.mutedText, size: 16),
        const SizedBox(width: 8.0),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.mutedText,
                  fontSize: 14,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: theme.primaryWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
