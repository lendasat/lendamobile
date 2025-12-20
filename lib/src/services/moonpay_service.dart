import 'dart:convert';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'package:ark_flutter/src/rust/models/moonpay.dart';
import 'package:ark_flutter/src/services/settings_service.dart';

class MoonPayService {
  static final MoonPayService _instance = MoonPayService._internal();

  factory MoonPayService() => _instance;

  MoonPayService._internal();

  /// Encrypt query parameters before sending to MoonPay
  Future<MoonPayEncryptedData> encryptData(Map<String, dynamic> data) async {
    try {
      final settingsService = SettingsService();
      final serverUrl = await settingsService.getBackendUrl();

      final dataJson = jsonEncode(data);

      final encrypted = await rust_api.moonpayEncryptData(
        serverUrl: serverUrl,
        data: dataJson,
      );

      return encrypted;
    } catch (e) {
      logger.e('Error encrypting MoonPay data: $e');
      rethrow;
    }
  }

  /// Get buy/sell limits for a currency and payment method
  Future<MoonPayCurrencyLimits> getCurrencyLimits({
    String baseCurrencyCode = 'usd',
    String paymentMethod = 'credit_debit_card',
  }) async {
    try {
      final settingsService = SettingsService();
      final serverUrl = await settingsService.getBackendUrl();

      final limits = await rust_api.moonpayGetCurrencyLimits(
        serverUrl: serverUrl,
        baseCurrencyCode: baseCurrencyCode,
        paymentMethod: paymentMethod,
      );

      return limits;
    } catch (e) {
      logger.e('Error getting MoonPay currency limits: $e');
      rethrow;
    }
  }

  /// Get current Bitcoin exchange rate
  Future<MoonPayQuote> getQuote() async {
    try {
      final settingsService = SettingsService();
      final serverUrl = await settingsService.getBackendUrl();

      final quote = await rust_api.moonpayGetQuote(serverUrl: serverUrl);

      return quote;
    } catch (e) {
      logger.e('Error getting MoonPay quote: $e');
      rethrow;
    }
  }
}

/// Extension methods for MoonPayQuote
extension MoonPayQuoteExtension on MoonPayQuote {
  String get pricePerBtc => '\$${exchangeRate.toStringAsFixed(2)}';

  DateTime get timestampAsDateTime => DateTime.parse(timestamp);
}
