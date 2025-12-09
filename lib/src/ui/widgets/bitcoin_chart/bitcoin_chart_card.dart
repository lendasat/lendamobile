import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/percentage_change_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/time_chooser_button.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum TimeRange { day, week, month, year, max }

class BitcoinChartCard extends StatefulWidget {
  const BitcoinChartCard({
    super.key,
  });

  @override
  State<BitcoinChartCard> createState() => _BitcoinChartCardState();
}

class _BitcoinChartCardState extends State<BitcoinChartCard> {
  TimeRange _selectedTimeRange = TimeRange.day;
  late final ValueNotifier<PriceData?> _trackballDataNotifier;

  // Cache for each time range
  final Map<TimeRange, List<PriceData>> _dataCache = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _trackballDataNotifier = ValueNotifier<PriceData?>(null);
    _loadData();
  }

  @override
  void dispose() {
    _trackballDataNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_dataCache.containsKey(_selectedTimeRange)) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _trackballDataNotifier.value = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await fetchBitcoinPriceData(_selectedTimeRange);
      data.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        _dataCache[_selectedTimeRange] = data;
        _isLoading = false;
        _trackballDataNotifier.value = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getTimeRangeKey(TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return '1D';
      case TimeRange.week:
        return '1W';
      case TimeRange.month:
        return '1M';
      case TimeRange.year:
        return '1J';
      case TimeRange.max:
        return 'Max';
    }
  }

  TimeRange _getTimeRangeFromKey(String key) {
    switch (key) {
      case '1D':
        return TimeRange.day;
      case '1W':
        return TimeRange.week;
      case '1M':
        return TimeRange.month;
      case '1J':
        return TimeRange.year;
      case 'Max':
        return TimeRange.max;
      default:
        return TimeRange.day;
    }
  }

  String _formatDate(int milliseconds, BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final dateUtc =
        DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    final date = timezoneService.toSelectedTimezone(dateUtc);

    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatTime(int milliseconds, BuildContext context) {
    final timezoneService = context.watch<TimezoneService>();
    final dateUtc =
        DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    final date = timezoneService.toSelectedTimezone(dateUtc);

    return DateFormat('HH:mm').format(date);
  }

  String _formatPrice(double price, BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    return currencyService.formatAmount(price);
  }

  String _calculatePriceChange(List<PriceData>? data, PriceData? current) {
    if (data == null || data.isEmpty) return '+0.00%';

    final firstPrice = data.first.price;
    final currentPrice = current?.price ?? data.last.price;

    if (firstPrice == 0) return '+0.00%';

    final change = ((currentPrice - firstPrice) / firstPrice) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }

  bool _isPriceChangePositive(List<PriceData>? data, PriceData? current) {
    if (data == null || data.isEmpty) return true;

    final firstPrice = data.first.price;
    final currentPrice = current?.price ?? data.last.price;

    return currentPrice >= firstPrice;
  }

  @override
  Widget build(BuildContext context) {
    
    final cachedData = _dataCache[_selectedTimeRange];
    final latestData = cachedData?.isNotEmpty == true ? cachedData!.last : null;

    // No box around the chart - matches BitnetGithub style
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section - matching BitnetGithub style
            if (!_isLoading && _errorMessage == null)
              ValueListenableBuilder<PriceData?>(
                valueListenable: _trackballDataNotifier,
                builder: (context, trackballData, child) {
                  final displayData = trackballData ?? latestData;
                  if (displayData == null) return const SizedBox.shrink();

                  final priceChange =
                      _calculatePriceChange(cachedData, displayData);
                  final isPositive =
                      _isPriceChangePositive(cachedData, displayData);

                  return Column(
                    children: [
                      // Top row: Bitcoin info + Date/Time
                      Row(
                        children: [
                          // Bitcoin logo
                          SizedBox(
                            height: 45,
                            width: 45,
                            child: Image.asset(
                              'assets/images/bitcoin.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Bitcoin name and symbol
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Bitcoin',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(displayData.time, context),
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'BTC',
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(displayData.time, context),
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price row: Large price + Percentage change
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatPrice(displayData.price, context),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PercentageChangeWidget(
                            percentage: priceChange,
                            isPositive: isPositive,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              )
            else if (_isLoading)
              // Loading header placeholder
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 45,
                        width: 45,
                        child: Image.asset(
                          'assets/images/bitcoin.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bitcoin',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'BTC',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Chart Section
            SizedBox(
              height: 250,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: TextStyle(color: Theme.of(context).hintColor),
                          ),
                        )
                      : ValueListenableBuilder<PriceData?>(
                          valueListenable: _trackballDataNotifier,
                          builder: (context, trackballData, child) {
                            final isPositive = _isPriceChangePositive(
                                cachedData, trackballData);
                            return BitcoinPriceChart(
                              data: cachedData ?? [],
                              trackballDataNotifier: _trackballDataNotifier,
                              onChartTouchEnd: () =>
                                  _trackballDataNotifier.value = null,
                              lineColor:
                                  isPositive ? Colors.green : Colors.red,
                            );
                          },
                        ),
            ),

            // Time Period Chooser - matching BitnetGithub style
            CustomizableTimeChooser(
              timePeriods: const ['1D', '1W', '1M', '1J', 'Max'],
              initialSelectedPeriod: _getTimeRangeKey(_selectedTimeRange),
              onTimePeriodSelected: (String newTimeperiod) {
                setState(() {
                  _selectedTimeRange = _getTimeRangeFromKey(newTimeperiod);
                  _trackballDataNotifier.value = null;
                });
                _loadData();
              },
              buttonBuilder: (context, period, isSelected, onPressed) {
                return TimeChooserButton(
                  timeperiod: period,
                  timespan: isSelected ? period : null,
                  onPressed: onPressed,
                );
              },
            ),
          ],
        ),
    );
  }
}
