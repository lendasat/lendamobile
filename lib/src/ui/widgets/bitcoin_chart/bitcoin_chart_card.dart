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
    _loadAllData();
  }

  @override
  void dispose() {
    _trackballDataNotifier.dispose();
    super.dispose();
  }

  /// Load all time ranges in parallel for instant switching.
  Future<void> _loadAllData() async {
    // Capture the initial range to avoid race conditions
    final initialRange = _selectedTimeRange;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Load the selected time range first for quick display
    try {
      final data = await fetchBitcoinPriceData(initialRange);
      data.sort((a, b) => a.time.compareTo(b.time));

      if (mounted) {
        // Always cache the data
        _dataCache[initialRange] = data;

        // Only update loading state if still on the same range
        if (_selectedTimeRange == initialRange) {
          setState(() {
            _isLoading = false;
            _trackballDataNotifier.value = null;
          });
        }
      }
    } catch (e) {
      if (mounted && _selectedTimeRange == initialRange) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      return; // Don't load others if first one fails
    }

    // Load remaining time ranges in parallel (background)
    final remainingRanges =
        TimeRange.values.where((r) => r != initialRange).toList();

    // Fire off all requests in parallel without awaiting
    for (final range in remainingRanges) {
      _loadSingleRange(range);
    }
  }

  /// Load a single time range (used for background loading).
  Future<void> _loadSingleRange(TimeRange range) async {
    if (_dataCache.containsKey(range)) return;

    try {
      final data = await fetchBitcoinPriceData(range);
      data.sort((a, b) => a.time.compareTo(b.time));

      if (mounted) {
        setState(() {
          _dataCache[range] = data;
        });
      }
    } catch (e) {
      // Silently fail for background loads - user can retry by selecting
    }
  }

  /// Load data for current selection (fallback if not cached).
  Future<void> _loadData() async {
    // Capture the range at start to avoid race conditions
    final rangeToLoad = _selectedTimeRange;

    if (_dataCache.containsKey(rangeToLoad)) {
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
      final data = await fetchBitcoinPriceData(rangeToLoad);
      data.sort((a, b) => a.time.compareTo(b.time));

      // Only update if still on the same range (user didn't switch)
      if (mounted && _selectedTimeRange == rangeToLoad) {
        setState(() {
          _dataCache[rangeToLoad] = data;
          _isLoading = false;
          _trackballDataNotifier.value = null;
        });
      } else if (mounted) {
        // Still cache the data for later use, but don't update loading state
        _dataCache[rangeToLoad] = data;
      }
    } catch (e) {
      // Only show error if still on the same range
      if (mounted && _selectedTimeRange == rangeToLoad) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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

  String _formatPrice(double priceUsd, BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    // formatAmount handles USD to selected currency conversion
    return currencyService.formatAmount(priceUsd);
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
            height: AppTheme.cardPadding * 12,
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
                    : BitcoinPriceChart(
                        data: cachedData ?? [],
                        trackballDataNotifier: _trackballDataNotifier,
                        onChartTouchEnd: () =>
                            _trackballDataNotifier.value = null,
                        lineColor: _isPriceChangePositive(cachedData, null)
                            ? Colors.green
                            : Colors.red,
                        // Key for forcing rebuild on time range change
                        chartKey:
                            'btc-chart-${_getTimeRangeKey(_selectedTimeRange)}',
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
