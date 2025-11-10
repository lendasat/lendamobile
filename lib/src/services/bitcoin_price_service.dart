import 'package:ark_flutter/src/rust/api/bitcoin_api.dart' as bitcoin_api;
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/bitcoin_chart/cards/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/ui/bitcoin_chart/cards/bitcoin_chart_card.dart';

/// Fetches Bitcoin price data from the backend historical price service
Future<List<PriceData>> fetchBitcoinPriceData(TimeRange timeRange) async {
  final String timeRangeParam = _getTimeRangeParam(timeRange);
  final settingsService = SettingsService();
  final serverUrl = await settingsService.getHistoricalPricesServerUrl();

  try {
    final response = await bitcoin_api.fetchHistoricalPrices(
      serverUrl: "http://192.168.1.125:7337",
      timeRange: timeRangeParam,
    );

    return response.prices
        .map((priceData) {
          // Parse timestamp (ISO 8601 format like "2017-03-15T00:00:00Z")
          final dateTime = DateTime.tryParse(priceData.timestamp);
          final price = double.tryParse(priceData.price);

          if (dateTime != null && price != null) {
            return PriceData(
              time: dateTime.millisecondsSinceEpoch,
              price: price,
            );
          }
          return null;
        })
        .where((data) => data != null)
        .cast<PriceData>()
        .toList();
  } catch (e) {
    throw Exception('Failed to load Bitcoin data: $e');
  }
}

String _getTimeRangeParam(TimeRange timeRange) {
  switch (timeRange) {
    case TimeRange.day:
      return '1D';
    case TimeRange.week:
      return '1W';
    case TimeRange.month:
      return '1M';
    case TimeRange.year:
      return '1Y';
    case TimeRange.max:
      return 'MAX';
  }
}
