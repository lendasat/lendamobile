import 'package:flutter/material.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:intl/intl.dart';

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

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    switch (_selectedTimeRange) {
      case TimeRange.day:
        return DateFormat('MMM d, HH:mm').format(date);
      case TimeRange.week:
        return DateFormat('MMM d, HH:mm').format(date);
      case TimeRange.month:
        return DateFormat('MMM d').format(date);
      case TimeRange.year:
        return DateFormat('MMM d, yyyy').format(date);
      case TimeRange.max:
        return DateFormat('MMM yyyy').format(date);
    }
  }

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final cachedData = _dataCache[_selectedTimeRange];
    final latestData = cachedData?.isNotEmpty == true ? cachedData!.last : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bitcoin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!_isLoading && _errorMessage == null)
                  ValueListenableBuilder<PriceData?>(
                    valueListenable: _trackballDataNotifier,
                    builder: (context, trackballData, child) {
                      final displayData = trackballData ?? latestData;
                      if (displayData == null) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatPrice(displayData.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(displayData.time),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : BitcoinPriceChart(
                          data: cachedData ?? [],
                          trackballDataNotifier: _trackballDataNotifier,
                          onChartTouchEnd: () =>
                              _trackballDataNotifier.value = null,
                        ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimeRangeButton('1D', TimeRange.day),
                  _buildTimeRangeButton('1W', TimeRange.week),
                  _buildTimeRangeButton('1M', TimeRange.month),
                  _buildTimeRangeButton('1Y', TimeRange.year),
                  _buildTimeRangeButton('MAX', TimeRange.max),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, TimeRange range) {
    final isSelected = _selectedTimeRange == range;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTimeRange = range;
            _trackballDataNotifier.value = null;
          });
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[800] : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[500],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
