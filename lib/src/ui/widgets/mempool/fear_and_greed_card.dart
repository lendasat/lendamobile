import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

/// Data model for Fear and Greed index
class FearGreedData {
  final int? currentValue;
  final String? valueText;
  final int? previousClose;
  final int? oneWeekAgo;
  final int? oneMonthAgo;
  final String? formattedDate;

  const FearGreedData({
    this.currentValue,
    this.valueText,
    this.previousClose,
    this.oneWeekAgo,
    this.oneMonthAgo,
    this.formattedDate,
  });
}

/// Card displaying the Bitcoin Fear and Greed Index
class FearAndGreedCard extends StatelessWidget {
  final FearGreedData data;
  final bool isLoading;

  const FearAndGreedCard({
    super.key,
    required this.data,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BitNetTheme.cardPadding),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(BitNetTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.gaugeHigh,
                        size: BitNetTheme.cardPadding * 0.75,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: BitNetTheme.elementSpacing),
                      Text(
                        AppLocalizations.of(context)!.fearAndGreedIndex,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Gauge visualization
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          height: 100,
          child: CircularProgressIndicator(color: BitNetTheme.colorBitcoin),
        ),
      );
    }

    final currentValue = data.currentValue ?? 50;

    return Center(
      child: Column(
        children: [
          _buildRadialGauge(context, currentValue),
          // Value and sentiment text
          Text(
            data.valueText ?? "Neutral",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getFearGreedColor(currentValue),
                ),
          ),

          // Date of reading
          if (data.formattedDate != null && data.formattedDate!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Updated on ${data.formattedDate}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BitNetTheme.white60
                          : BitNetTheme.black60,
                    ),
              ),
            ),

          // Add historical comparison
          if (data.previousClose != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildHistoricalComparison(context, currentValue),
            ),
        ],
      ),
    );
  }

  // Build a custom radial gauge for fear & greed
  Widget _buildRadialGauge(BuildContext context, int value) {
    return SizedBox(
      height: 160,
      width: 160,
      child: AnimatedRadialGauge(
        duration: const Duration(seconds: 1),
        curve: Curves.elasticOut,
        radius: 80,
        value: value.toDouble(),
        axis: GaugeAxis(
          min: 0,
          max: 100,
          degrees: 180,
          style: GaugeAxisStyle(
            thickness: 20,
            background: Theme.of(context).brightness == Brightness.dark
                ? BitNetTheme.white70
                : BitNetTheme.black70,
            segmentSpacing: 4,
          ),
          progressBar: GaugeProgressBar.rounded(
            color: _getFearGreedColor(value),
          ),
          segments: [
            GaugeSegment(
              from: 0,
              to: 25,
              color: BitNetTheme.errorColor,
              cornerRadius: const Radius.circular(4),
            ),
            GaugeSegment(
              from: 25,
              to: 50,
              color: Colors.orange,
              cornerRadius: const Radius.circular(4),
            ),
            GaugeSegment(
              from: 50,
              to: 75,
              color: Colors.yellow,
              cornerRadius: const Radius.circular(4),
            ),
            GaugeSegment(
              from: 75,
              to: 100,
              color: BitNetTheme.successColor,
              cornerRadius: const Radius.circular(4),
            ),
          ],
        ),
        builder: (context, child, value) => RadialGaugeLabel(
          value: value,
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Build a widget showing historical comparison
  Widget _buildHistoricalComparison(BuildContext context, int currentValue) {
    final yesterday = data.previousClose;
    final lastWeek = data.oneWeekAgo;
    final lastMonth = data.oneMonthAgo;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        // Header row
        TableRow(
          children: [
            Text(
              'Period',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Value',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              'Change',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        // Yesterday row
        if (yesterday != null)
          _buildComparisonRow(context, 'Yesterday', yesterday, currentValue),

        // Last week row
        if (lastWeek != null)
          _buildComparisonRow(context, 'Last Week', lastWeek, currentValue),

        // Last month row
        if (lastMonth != null)
          _buildComparisonRow(context, 'Last Month', lastMonth, currentValue),
      ],
    );
  }

  // Build a row for the comparison table
  TableRow _buildComparisonRow(
    BuildContext context,
    String label,
    int value,
    int currentValue,
  ) {
    final change = currentValue - value;
    final isPositive = change > 0;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: _getFearGreedColor(value),
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color:
                    isPositive ? BitNetTheme.successColor : BitNetTheme.errorColor,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                '${change.abs()}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: isPositive
                          ? BitNetTheme.successColor
                          : BitNetTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to get color based on fear/greed value
  Color _getFearGreedColor(int value) {
    if (value <= 25) {
      return BitNetTheme.errorColor;
    } else if (value <= 50) {
      return Colors.orange;
    } else if (value <= 75) {
      return Colors.yellow;
    } else {
      return BitNetTheme.successColor;
    }
  }
}
