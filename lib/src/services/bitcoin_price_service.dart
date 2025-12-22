import 'package:ark_flutter/src/rust/api/bitcoin_api.dart' as bitcoin_api;
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';

/// Fetches Bitcoin price data from the backend historical price service
/// Includes retry logic for cold-start scenarios (server returning 500)
Future<List<PriceData>> fetchBitcoinPriceData(TimeRange timeRange) async {
  final String timeRangeParam = _getTimeRangeParam(timeRange);
  final settingsService = SettingsService();
  final serverUrl = await settingsService.getBackendUrl();

  const maxRetries = 3;
  const retryDelay = Duration(milliseconds: 500);

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final response = await bitcoin_api.fetchHistoricalPrices(
        serverUrl: serverUrl,
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
      // If this is a 500 error and we have retries left, wait and retry
      final errorStr = e.toString();
      if (attempt < maxRetries && errorStr.contains('500')) {
        await Future.delayed(retryDelay * attempt);
        continue;
      }
      throw Exception('Failed to load Bitcoin data: $e');
    }
  }

  throw Exception('Failed to load Bitcoin data after $maxRetries attempts');
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
