import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Simple data class for wallet chart points
class WalletChartData {
  final double time; // millisecondsSinceEpoch as double
  final double value;

  WalletChartData({required this.time, required this.value});
}

/// A simplified, non-interactive chart widget specifically for the wallet screen.
/// This is intentionally separate from BitcoinPriceChart to avoid coupling
/// wallet display with the full-featured bitcoin chart implementation.
///
/// Modeled after BitNetGithub's wallet screen approach - a clean, simple
/// SfCartesianChart without trackball or complex interactions.
class WalletMiniChart extends StatelessWidget {
  final List<WalletChartData> data;
  final Color lineColor;
  final double lineWidth;
  final double? height;

  const WalletMiniChart({
    super.key,
    required this.data,
    required this.lineColor,
    this.lineWidth = 3,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: SfCartesianChart(
          enableAxisAnimation: false,
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: const NumericAxis(
            isVisible: false,
            edgeLabelPlacement: EdgeLabelPlacement.none,
            majorGridLines: MajorGridLines(width: 0),
            minorGridLines: MinorGridLines(width: 0),
            majorTickLines: MajorTickLines(width: 0),
          ),
          primaryYAxis: const NumericAxis(
            isVisible: false,
            plotOffset: 0,
            edgeLabelPlacement: EdgeLabelPlacement.none,
            majorGridLines: MajorGridLines(width: 0),
            minorGridLines: MinorGridLines(width: 0),
            majorTickLines: MajorTickLines(width: 0),
          ),
          series: <SplineSeries<WalletChartData, double>>[
            SplineSeries<WalletChartData, double>(
              dataSource: data,
              xValueMapper: (WalletChartData point, _) => point.time,
              yValueMapper: (WalletChartData point, _) => point.value,
              color: lineColor,
              width: lineWidth,
              splineType: SplineType.natural,
              animationDuration: 0,
              opacity: 1.0,
            ),
          ],
        ),
      ),
    );
  }
}
