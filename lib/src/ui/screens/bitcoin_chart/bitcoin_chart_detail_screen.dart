import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/app_theme.dart';

class BitcoinChartDetailScreen extends StatelessWidget {
  const BitcoinChartDetailScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: theme.primaryBlack,
        title: Text(
          AppLocalizations.of(context)!.bitcoinPriceChart,
          style: TextStyle(
            color: theme.primaryWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Bitcoin Chart Card
            const BitcoinChartCard(),

            const SizedBox(height: 24),

            // Additional information section
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.tertiaryBlack, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.aboutBitcoinPriceData,
            style: TextStyle(
              color: theme.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.thePriceDataShown,
            style: TextStyle(
              color: theme.mutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(AppLocalizations.of(context)!.dataSource,
              AppLocalizations.of(context)!.liveBitcoinMarketData),
          const SizedBox(height: 8),
          _buildInfoRow(AppLocalizations.of(context)!.currency, 'USD'),
          const SizedBox(height: 8),
          _buildInfoRow(AppLocalizations.of(context)!.updateFrequency,
              AppLocalizations.of(context)!.realTime),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) {
        final theme = AppTheme.of(context);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.mutedText, fontSize: 14)),
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
      },
    );
  }
}
