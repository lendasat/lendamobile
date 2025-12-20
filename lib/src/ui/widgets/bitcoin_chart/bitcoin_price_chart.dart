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
  bool _isTrackballActive = false;

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

    // Build trackball behavior matching bitnetgithub implementation
    final trackballBehavior = widget.trackballActivationMode != null
        ? TrackballBehavior(
            enable: true,
            activationMode: widget.trackballActivationMode!,
            // Use tooltipSettings instead of tooltipDisplayMode for proper control
            tooltipSettings: const InteractiveTooltip(
              enable: false, // Disable tooltip since we use custom header
            ),
            hideDelay: 1000, // Auto-hide after 1 second - CRITICAL for proper UX
            lineType: TrackballLineType.vertical,
            lineColor: Colors.grey[400],
            lineWidth: 2,
            markerSettings: const TrackballMarkerSettings(
              markerVisibility: TrackballVisibilityMode.visible,
              color: Colors.white,
              borderColor: Colors.white,
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
        primaryXAxis: const DateTimeAxis(
          isVisible: false,
          axisLine: AxisLine(width: 0),
          majorGridLines: MajorGridLines(width: 0),
          minorGridLines: MinorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          isVisible: false,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          minorGridLines: const MinorGridLines(width: 0),
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
        // Track when touch starts
        onChartTouchInteractionDown: (ChartTouchInteractionArgs args) {
          _isTrackballActive = true;
        },
        onTrackballPositionChanging: (TrackballArgs args) {
          if (widget.trackballDataNotifier != null && _isTrackballActive) {
            final pointIndex = args.chartPointInfo.dataPointIndex;
            if (pointIndex != null && pointIndex < widget.data.length) {
              widget.trackballDataNotifier!.value = widget.data[pointIndex];
            }
          }
        },
        onChartTouchInteractionUp: (ChartTouchInteractionArgs args) {
          _isTrackballActive = false;
          widget.onChartTouchEnd?.call();
        },
        margin: EdgeInsets.zero,
        series: <CartesianSeries<PriceData, DateTime>>[
          SplineSeries<PriceData, DateTime>(
            dataSource: widget.data,
            xValueMapper: (PriceData price, _) =>
                DateTime.fromMillisecondsSinceEpoch(price.time),
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
