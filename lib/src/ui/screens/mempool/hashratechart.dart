import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/screens/mempool/hash_chart_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Chart data point model
class ChartLine {
  final double time;
  final double price;

  ChartLine({required this.time, required this.price});
}

GlobalKey<_HashRealTimeValuesState> hashKey =
    GlobalKey<_HashRealTimeValuesState>();
var datetime = DateTime.now();
DateFormat dateFormat = DateFormat("dd.MM.yyyy");
DateFormat timeFormat = DateFormat("HH:mm");
String initialDate = dateFormat.format(datetime);
String initialTime = timeFormat.format(datetime);
String hashTrackBallValuePrice = "-----.--";
String hashTrackBallValueTime = initialTime;
String hashTrackBallValueDate = initialDate;
String hashTrackBallValuePricechange = "+0";

String toPercent(double value) {
  final percent = value * 100;
  if (percent >= 0) {
    return '+${percent.toStringAsFixed(2)}%';
  }
  return '${percent.toStringAsFixed(2)}%';
}

class HashrateChart extends StatefulWidget {
  final List<ChartLine> chartData;
  final List<Difficulty> difficulty;

  const HashrateChart({
    required this.chartData,
    required this.difficulty,
    super.key,
  });

  @override
  State<HashrateChart> createState() => _HashrateChartState();
}

class _HashrateChartState extends State<HashrateChart> {
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final timezoneService =
        Provider.of<TimezoneService>(context, listen: false);
    final loc = timezoneService.location;
    final l10n = AppLocalizations.of(context)!;

    final chartData = widget.chartData;

    double lastPriceExact =
        chartData.isEmpty ? 1 : chartData[chartData.length - 1].price;
    double lastTimeExact =
        chartData.isEmpty ? 1 : chartData[chartData.length - 1].time;
    double lastPriceRounded = double.parse(
      lastPriceExact.toString().length >= 3
          ? lastPriceExact.toString().substring(0, 3)
          : lastPriceExact.toString(),
    );
    double firstPriceExact = chartData.isEmpty ? 0 : chartData[0].price;
    hashTrackBallValuePrice = lastPriceRounded.toString();

    var dateTime = DateTime.fromMillisecondsSinceEpoch(
      (lastTimeExact * 1000).round(),
      isUtc: false,
    ).toUtc().add(Duration(milliseconds: loc.currentTimeZone.offset));

    DateFormat dateFormatLocal = DateFormat("dd.MM.yyyy");
    String date = dateFormatLocal.format(dateTime);
    hashTrackBallValueDate = date;

    DateFormat timeFormatLocal = DateFormat("HH:mm");
    String time = timeFormatLocal.format(dateTime);
    hashTrackBallValueTime = time;

    return Column(
      children: [
        Container(
          margin:
              const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: HashRealTimeValues(key: hashKey),
        ),
        widget.chartData.isEmpty
            ? const SizedBox(
                height: AppTheme.cardPadding * 16,
                child: Center(child: CircularProgressIndicator()),
              )
            : SizedBox(
                height: AppTheme.cardPadding * 16,
                child: SfCartesianChart(
                  trackballBehavior: _trackballBehavior,
                  onTrackballPositionChanging: (args) {
                    if (args.chartPointInfo.yPosition != null) {
                      final pointInfoPrice = args.chartPointInfo.label!;

                      var trackDateTime = DateTime.fromMillisecondsSinceEpoch(
                        (chartData[args.chartPointInfo.dataPointIndex!].time *
                                1000)
                            .round(),
                        isUtc: false,
                      ).toUtc().add(
                            Duration(milliseconds: loc.currentTimeZone.offset),
                          );

                      DateFormat trackDateFormat = DateFormat("dd.MM.yyyy");
                      DateFormat trackTimeFormat = DateFormat("HH:mm");
                      String trackTime = trackTimeFormat.format(trackDateTime);
                      hashTrackBallValueTime = trackTime;

                      String trackDate = trackDateFormat.format(trackDateTime);
                      hashTrackBallValueDate = trackDate;
                      hashTrackBallValuePrice = pointInfoPrice.replaceAll(
                        'EH/s',
                        '',
                      );
                      double priceChange =
                          (double.parse(hashTrackBallValuePrice) -
                                  firstPriceExact) /
                              firstPriceExact;
                      hashTrackBallValuePricechange = toPercent(priceChange);
                      hashKey.currentState?.refresh();
                    }
                  },
                  onChartTouchInteractionUp: (ChartTouchInteractionArgs args) {
                    hashTrackBallValuePrice = lastPriceRounded.toString();
                    double priceChange =
                        (lastPriceExact - firstPriceExact) / firstPriceExact;
                    hashTrackBallValuePricechange = toPercent(priceChange);
                    hashKey.currentState?.refresh();

                    var endDateTime = DateTime.fromMillisecondsSinceEpoch(
                      (lastTimeExact * 1000).round(),
                      isUtc: false,
                    ).toUtc().add(
                          Duration(milliseconds: loc.currentTimeZone.offset),
                        );
                    DateFormat endDateFormat = DateFormat("dd.MM.yyyy");
                    DateFormat endTimeFormat = DateFormat("HH:mm");
                    String endTime = endTimeFormat.format(endDateTime);
                    String endDate = endDateFormat.format(endDateTime);
                    hashTrackBallValueDate = endDate;
                    hashTrackBallValueTime = endTime;
                  },
                  plotAreaBorderWidth: 0,
                  enableAxisAnimation: false,
                  primaryXAxis: const DateTimeAxis(
                    intervalType: DateTimeIntervalType.days,
                    edgeLabelPlacement: EdgeLabelPlacement.none,
                    isVisible: false,
                    majorGridLines: MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    axisLine: const AxisLine(width: 0),
                    plotOffset: 0,
                    edgeLabelPlacement: EdgeLabelPlacement.none,
                    isVisible: false,
                    majorGridLines: const MajorGridLines(width: 0),
                    majorTickLines: const MajorTickLines(width: 0),
                    numberFormat: NumberFormat.compact(),
                  ),
                  series: <CartesianSeries>[
                    SplineSeries<ChartLine, DateTime>(
                      name: l10n.hashrate,
                      enableTooltip: true,
                      dataSource: widget.chartData,
                      splineType: SplineType.cardinal,
                      cardinalSplineTension: 0.7,
                      animationDuration: 0,
                      xValueMapper: (ChartLine sales, _) =>
                          DateTime.fromMillisecondsSinceEpoch(
                        sales.time.toInt() * 1000,
                        isUtc: true,
                      ),
                      yValueMapper: (ChartLine sales, _) => double.parse(
                        sales.price.toString().length >= 3
                            ? sales.price.toString().substring(0, 3)
                            : sales.price.toString(),
                      ),
                    ),
                    SplineSeries<Difficulty, DateTime>(
                      name: l10n.difficulty,
                      enableTooltip: true,
                      splineType: SplineType.cardinal,
                      cardinalSplineTension: 0.3,
                      animationDuration: 0,
                      dataSource: widget.difficulty,
                      xValueMapper: (Difficulty sales, _) =>
                          DateTime.fromMillisecondsSinceEpoch(
                        sales.time!.toInt() * 1000,
                        isUtc: true,
                      ),
                      yValueMapper: (Difficulty sales, _) => double.parse(
                        (sales.difficulty! / 100000000000).toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}

class HashRealTimeValues extends StatefulWidget {
  const HashRealTimeValues({super.key});

  @override
  State<HashRealTimeValues> createState() => _HashRealTimeValuesState();
}

class _HashRealTimeValuesState extends State<HashRealTimeValues> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "${hashTrackBallValuePrice}EH/s",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
            Text(
              hashTrackBallValueDate,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ],
    );
  }
}
