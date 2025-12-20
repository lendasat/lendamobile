import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/models/mempool_new/chartline.dart';
import 'package:ark_flutter/src/models/mempool_new/hash_chart_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Card displaying Bitcoin network hashrate information
class HashrateCard extends StatelessWidget {
  final List<ChartLine> hashrateChartData;
  final List<Difficulty> hashrateChartDifficulty;
  final bool isLoading;
  final String currentHashrate;
  final String changePercentage;
  final bool isPositive;
  final String selectedTimePeriod;
  final Function(String) onTimePeriodChanged;

  const HashrateCard({
    super.key,
    required this.hashrateChartData,
    required this.hashrateChartDifficulty,
    required this.isLoading,
    required this.currentHashrate,
    required this.changePercentage,
    required this.isPositive,
    required this.selectedTimePeriod,
    required this.onTimePeriodChanged,
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

              // Current hashrate display
              _buildHashrateDisplay(context),

              const SizedBox(height: 16),

              // Time period selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeButton(context, '1D'),
                  const SizedBox(width: 4),
                  _buildTimeButton(context, '1W'),
                  const SizedBox(width: 4),
                  _buildTimeButton(context, '1M'),
                  const SizedBox(width: 4),
                  _buildTimeButton(context, '1Y'),
                  const SizedBox(width: 4),
                  _buildTimeButton(context, 'MAX'),
                ],
              ),

              const SizedBox(height: 16),

              // Hashrate chart
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

  Widget _buildHashrateDisplay(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.colorBitcoin),
      );
    }

    return Center(
      child: Column(
        children: [
          Text(
            currentHashrate,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          if (hashrateChartData.isNotEmpty && changePercentage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
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
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          height: 180,
          child: CircularProgressIndicator(color: AppTheme.colorBitcoin),
        ),
      );
    }

    if (hashrateChartData.isEmpty) {
      return Center(
        child: Text(
          "Failed to load hashrate data",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: AppTheme.cardRadiusSmall,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.black70
            : AppTheme.white70,
      ),
      child: _buildHashrateChart(context),
    );
  }

  // Helper method to build time period buttons
  Widget _buildTimeButton(BuildContext context, String period) {
    final isActive = period == selectedTimePeriod;
    return InkWell(
      onTap: isLoading ? null : () => onTimePeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.colorBitcoin.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? AppTheme.colorBitcoin : AppTheme.white60,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isActive ? AppTheme.colorBitcoin : null,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Helper method to build the hashrate chart
  Widget _buildHashrateChart(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      enableAxisAnimation: false,
      trackballBehavior: TrackballBehavior(
        lineColor: Colors.grey[400],
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineWidth: 2,
        lineType: TrackballLineType.vertical,
        tooltipSettings: const InteractiveTooltip(enable: false),
        markerSettings: const TrackballMarkerSettings(
          color: Colors.white,
          borderColor: Colors.white,
          markerVisibility: TrackballVisibilityMode.visible,
        ),
      ),
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        edgeLabelPlacement: EdgeLabelPlacement.none,
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: AppTheme.white70,
          dashArray: const [5, 5],
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(color: AppTheme.white70, fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        plotOffset: 0,
        edgeLabelPlacement: EdgeLabelPlacement.none,
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: AppTheme.white70,
          dashArray: const [5, 5],
        ),
        majorTickLines: const MajorTickLines(width: 0),
        numberFormat: NumberFormat.compact(),
        labelStyle: TextStyle(color: AppTheme.white60, fontSize: 10),
      ),
      series: <CartesianSeries>[
        // Hashrate line
        SplineSeries<ChartLine, DateTime>(
          name: AppLocalizations.of(context)!.networkHashrate,
          enableTooltip: true,
          dataSource: hashrateChartData,
          splineType: SplineType.cardinal,
          cardinalSplineTension: 0.7,
          animationDuration: 0,
          width: 2,
          color: AppTheme.colorBitcoin,
          xValueMapper: (ChartLine sales, _) =>
              DateTime.fromMillisecondsSinceEpoch(
            sales.time.toInt() * 1000,
            isUtc: true,
          ),
          yValueMapper: (ChartLine sales, _) => double.parse(
            sales.price.toString().substring(
                  0,
                  sales.price.toString().length > 3
                      ? 3
                      : sales.price.toString().length,
                ),
          ),
        ),
        // Add difficulty markers as scatter series
        if (hashrateChartDifficulty.isNotEmpty)
          ScatterSeries<Difficulty, DateTime>(
            name: AppLocalizations.of(context)!.difficulty,
            enableTooltip: true,
            dataSource: hashrateChartDifficulty,
            color: Colors.white,
            markerSettings: const MarkerSettings(
              height: 6,
              width: 6,
              shape: DataMarkerType.circle,
              borderColor: AppTheme.colorBitcoin,
              borderWidth: 1,
            ),
            xValueMapper: (Difficulty diff, _) =>
                DateTime.fromMillisecondsSinceEpoch(
              diff.time!.toInt() * 1000,
              isUtc: true,
            ),
            yValueMapper: (Difficulty diff, _) => double.parse(
              (diff.difficulty! / 100000000000).toStringAsFixed(2),
            ),
          ),
      ],
    );
  }
}
