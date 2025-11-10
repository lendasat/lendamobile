import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';

class HashrateChartCard extends StatefulWidget {
  final HashrateData initialData;

  const HashrateChartCard({super.key, required this.initialData});

  @override
  State<HashrateChartCard> createState() => _HashrateChartCardState();
}

class _HashrateChartCardState extends State<HashrateChartCard> {
  late HashrateData _data;
  String _selectedPeriod = '1M';
  bool _isLoading = false;

  final List<String> _periods = ['1M', '3M', '6M', '1Y', '3Y'];

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final data = await rust_api.getHashrateData(period: '1m');
      if (mounted) {
        setState(() {
          _data = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial hashrate data: $e');
    }
  }

  Future<void> _loadPeriodData(String period) async {
    if (_selectedPeriod == period) return;

    setState(() {
      _isLoading = true;
      _selectedPeriod = period;
    });

    try {
      debugPrint('Loading hashrate data for period: $period');

      final data = await rust_api.getHashrateData(period: period.toLowerCase());
      debugPrint(
        'Received ${data.hashrates.length} hashrate data points for period $period',
      );

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading hashrate data for period $period: $e');
    }
  }

  String _formatHashrate(double hashrate) {
    final eh = hashrate / 1000000000000000000;
    return '${eh.toStringAsFixed(2)} EH/s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final currentHashrate = _data.currentHashrate ?? 0.0;

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
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.currentNetworkHashrate,
                  style: TextStyle(color: theme.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          if (_isLoading)
            SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: theme.primaryWhite),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: HashrateChart(
                data: _data.hashrates,
                period: _selectedPeriod,
              ),
            ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return GestureDetector(
                onTap: () => _loadPeriodData(period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.primaryWhite : theme.primaryBlack,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryWhite
                          : theme.primaryWhite.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      color:
                          isSelected ? theme.primaryBlack : theme.primaryWhite,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class HashrateChart extends StatelessWidget {
  final List<HashratePoint> data;
  final String period;

  const HashrateChart({super.key, required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noDataAvailable,
          style: TextStyle(color: theme.mutedText, fontSize: 14),
        ),
      );
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.all(0),
      primaryXAxis: const DateTimeAxis(
        isVisible: false,
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        isVisible: false,
        majorGridLines: MajorGridLines(width: 0),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: theme.secondaryBlack,
        textStyle: TextStyle(color: theme.primaryWhite, fontSize: 12),
        borderColor: theme.primaryWhite.withValues(alpha: 0.1),
        borderWidth: 1,
        format: 'point.y EH/s',
      ),
      series: <CartesianSeries<HashratePoint, DateTime>>[
        AreaSeries<HashratePoint, DateTime>(
          dataSource: data,
          xValueMapper: (HashratePoint point, _) =>
              DateTime.fromMillisecondsSinceEpoch(point.timestamp.toInt()),
          yValueMapper: (HashratePoint point, _) =>
              point.avgHashrate / 1000000000000000000,
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          borderColor: const Color(0xFF4CAF50),
          borderWidth: 2,
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      ],
    );
  }
}
