import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';

class HashrateCard extends StatelessWidget {
  final HashrateData hashrateData;

  const HashrateCard({super.key, required this.hashrateData});

  String _formatHashrate(double hashrate) {
    final eh = hashrate / 1000000000000000000;
    return '${eh.toStringAsFixed(2)} EH/s';
  }

  String _formatDifficulty(double difficulty) {
    return '${(difficulty / 1000000000000).toStringAsFixed(2)}T';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final currentHashrate = hashrateData.currentHashrate ?? 0.0;
    final currentDifficulty = hashrateData.currentDifficulty ?? 0.0;

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
              Icon(Icons.speed, color: theme.primaryWhite, size: 20),
              const SizedBox(width: 8.0),
              Text(
                AppLocalizations.of(context)!.networkHashrate,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Center(
            child: Column(
              children: [
                Text(
                  _formatHashrate(currentHashrate),
                  style: TextStyle(
                    color: theme.primaryWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  AppLocalizations.of(context)!.currentNetworkHashrate,
                  style: TextStyle(color: theme.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          _buildStatRow(AppLocalizations.of(context)!.difficulty,
              _formatDifficulty(currentDifficulty), theme),
          const SizedBox(height: 8.0),
          _buildStatRow(AppLocalizations.of(context)!.dataPoints,
              '${hashrateData.hashrates.length}', theme),
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
