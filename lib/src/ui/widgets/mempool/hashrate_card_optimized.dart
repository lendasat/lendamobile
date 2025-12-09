import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/models/mempool_new/chartline.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';

/// Optimized Hashrate Card with better performance
class HashrateCardOptimized extends StatelessWidget {
  final List<ChartLine> hashrateChartData;
  final bool isLoading;
  final String currentHashrate;
  final String changePercentage;
  final bool isPositive;

  const HashrateCardOptimized({
    super.key,
    required this.hashrateChartData,
    required this.isLoading,
    required this.currentHashrate,
    required this.changePercentage,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.server,
                        size: AppTheme.cardPadding * 0.75,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: AppTheme.elementSpacing),
                      Text(
                        AppLocalizations.of(context)!.networkHashrate,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Optimized hashrate display
              isLoading ? _buildLoadingState() : _buildHashrateDisplay(context),

              const SizedBox(height: 16),

              // Simplified chart display
              _buildChartSection(context),

              const SizedBox(height: 16),

              // Hashrate explanation
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: AppTheme.cardRadiusSmall,
                  color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
                ),
                child: Text(
                  "Higher hashrate = stronger network security",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: AppTheme.colorBitcoin),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Placeholder for hashrate value
        Container(
          height: 32,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Placeholder for percentage
        Container(
          height: 20,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildHashrateDisplay(BuildContext context) {
    return Column(
      children: [
        Text(
          currentHashrate,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        if (changePercentage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  changePercentage,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: isPositive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    if (isLoading) {
      return const SizedBox(height: 80);
    }

    if (hashrateChartData.isEmpty) {
      return _buildErrorState(context);
    }

    return _buildSimplifiedChart(context);
  }

  Widget _buildErrorState(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              "No data available",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedChart(BuildContext context) {
    // Sample data to reduce points for better performance
    final sampledData = _sampleData(hashrateChartData, maxPoints: 50);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SfSparkLineChart(
        data: sampledData.map((e) => e.price).toList(),
        color: AppTheme.colorBitcoin,
        marker: const SparkChartMarker(
            displayMode: SparkChartMarkerDisplayMode.none),
        labelDisplayMode: SparkChartLabelDisplayMode.none,
        axisLineWidth: 0,
      ),
    );
  }

  // Helper method to sample data for better performance
  List<ChartLine> _sampleData(List<ChartLine> data, {int maxPoints = 50}) {
    if (data.length <= maxPoints) return data;

    final List<ChartLine> sampled = [];
    final step = data.length ~/ maxPoints;

    for (int i = 0; i < data.length; i += step) {
      sampled.add(data[i]);
    }

    // Always include the last point
    if (sampled.last != data.last) {
      sampled.add(data.last);
    }

    return sampled;
  }
}
