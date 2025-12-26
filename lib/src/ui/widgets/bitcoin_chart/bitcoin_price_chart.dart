import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PriceData {
  final int time; // millisecondsSinceEpoch
  final double price;

  PriceData({required this.time, required this.price});
}

class BitcoinPriceChart extends StatefulWidget {
  final List<PriceData> data;
  final ValueNotifier<PriceData?>? trackballDataNotifier;
  final int alpha;
  final ActivationMode? trackballActivationMode;
  final VoidCallback? onChartTouchEnd;
  final Color? lineColor;

  /// Unique key for forcing chart rebuild (e.g., when time period changes)
  final String? chartKey;

  const BitcoinPriceChart({
    super.key,
    required this.data,
    this.trackballDataNotifier,
    this.alpha = 255,
    this.trackballActivationMode = ActivationMode.singleTap,
    this.onChartTouchEnd,
    this.lineColor,
    this.chartKey,
  });

  @override
  State<BitcoinPriceChart> createState() => _BitcoinPriceChartState();
}

class _BitcoinPriceChartState extends State<BitcoinPriceChart> {
  double? _fixedYMin;
  double? _fixedYMax;

  @override
  void initState() {
    super.initState();
    _calculateYAxisRange();
  }

  @override
  void didUpdateWidget(BitcoinPriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if data structure changed significantly
    if (oldWidget.data.length != widget.data.length ||
        (widget.data.isNotEmpty && oldWidget.data.isEmpty) ||
        oldWidget.chartKey != widget.chartKey) {
      _calculateYAxisRange();
    }
  }

  void _calculateYAxisRange() {
    if (widget.data.isEmpty) {
      _fixedYMin = 0.0;
      _fixedYMax = 100.0;
      return;
    }

    final prices = widget.data.map((d) => d.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    // Add 5% padding to top and bottom
    final padding = (maxPrice - minPrice) * 0.05;
    _fixedYMin = minPrice - padding;
    _fixedYMax = maxPrice + padding;
  }

  double? _getAveragePrice() {
    if (widget.data.isEmpty) return null;
    final sum = widget.data.fold<double>(0, (sum, d) => sum + d.price);
    return sum / widget.data.length;
  }

  @override
  Widget build(BuildContext context) {
    final averagePrice = _getAveragePrice();

    // Determine line color: use provided lineColor or default to green
    final chartLineColor = widget.lineColor ?? Colors.green;

    // Build trackball behavior matching bitnetgithub implementation exactly
    final trackballBehavior = widget.trackballActivationMode != null
        ? TrackballBehavior(
            enable: true,
            activationMode: widget.trackballActivationMode!,
            lineColor: Colors.grey[400],
            lineWidth: 2,
            lineType: TrackballLineType.vertical,
            tooltipSettings: const InteractiveTooltip(
              enable: false, // Disable tooltip since we use custom header
            ),
            markerSettings: TrackballMarkerSettings(
              markerVisibility: TrackballVisibilityMode.visible,
              color: chartLineColor, // Use chart line color for better visibility
              borderColor: Colors.white,
              borderWidth: 2,
              height: 10,
              width: 10,
            ),
          )
        : null;

    // Wrap in RepaintBoundary to isolate repaints - prevents jank
    return RepaintBoundary(
      child: SfCartesianChart(
        // Use key to force rebuild when data changes significantly
        key: widget.chartKey != null ? ValueKey(widget.chartKey) : null,
        plotAreaBorderWidth: 0,
        // Disable axis animation to prevent visual glitches during hover
        enableAxisAnimation: false,
        // Use NumericAxis like BitNetGithub for consistent trackball behavior
        primaryXAxis: const NumericAxis(
          isVisible: false,
          edgeLabelPlacement: EdgeLabelPlacement.none,
          majorGridLines: MajorGridLines(width: 0),
          minorGridLines: MinorGridLines(width: 0),
          majorTickLines: MajorTickLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          isVisible: false,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          minorGridLines: const MinorGridLines(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          plotOffset: 0,
          edgeLabelPlacement: EdgeLabelPlacement.none,
          minimum: _fixedYMin,
          maximum: _fixedYMax,
          plotBands: averagePrice != null
              ? <PlotBand>[
                  PlotBand(
                    isVisible: true,
                    dashArray: const <double>[2, 5],
                    start: averagePrice,
                    end: averagePrice,
                    borderColor: Colors.grey,
                    borderWidth: 1.5,
                  ),
                ]
              : <PlotBand>[],
        ),
        trackballBehavior: trackballBehavior,
        // Track when trackball position changes - matching BitNetGithub implementation
        // Use label/header instead of dataPointIndex for reliable fast-swipe support
        onTrackballPositionChanging: (TrackballArgs args) {
          if (widget.trackballDataNotifier != null &&
              args.chartPointInfo.yPosition != null) {
            // Parse the values directly from chart point info (like BitNetGithub)
            // label = y-axis value (price), header = x-axis value (time)
            final label = args.chartPointInfo.label;
            final header = args.chartPointInfo.header;
            if (label != null && header != null) {
              final price = double.tryParse(label);
              final time = double.tryParse(header)?.round();
              if (price != null && time != null) {
                widget.trackballDataNotifier!.value = PriceData(
                  time: time,
                  price: price,
                );
              }
            }
          }
        },
        onChartTouchInteractionUp: (ChartTouchInteractionArgs args) {
          widget.onChartTouchEnd?.call();
        },
        margin: EdgeInsets.zero,
        // Use SplineSeries with double for X-axis like BitNetGithub
        series: <SplineSeries<PriceData, double>>[
          SplineSeries<PriceData, double>(
            dataSource: widget.data,
            // Map time as double (milliseconds) like BitNetGithub
            xValueMapper: (PriceData price, _) => price.time.toDouble(),
            yValueMapper: (PriceData price, _) => price.price,
            color: chartLineColor,
            width: 2,
            splineType: SplineType.natural,
            cardinalSplineTension: 0.6, // Smoother curves like bitnetgithub
            animationDuration: 0, // No animation for consistent UX
          ),
        ],
      ),
    );
  }
}
