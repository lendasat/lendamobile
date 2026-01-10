import 'dart:convert';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust_api;
import 'package:ark_flutter/src/rust/models/moonpay.dart';

class MoonPayService {
  static final MoonPayService _instance = MoonPayService._internal();

  factory MoonPayService() => _instance;

  MoonPayService._internal();

  // Environment variables for MoonPay configuration
  // MOONPAY_BACKEND_API: The backend API URL for encryption, limits, and quotes
  // - WSL (Windows): Use WSL IP (e.g., http://172.20.192.246:7337)
  // - Native Linux/Mac: http://localhost:7337
  // - Production: https://apiborrow.lendasat.com
  static const String _moonpayBackendApi = String.fromEnvironment(
    'MOONPAY_BACKEND_API',
    defaultValue: 'https://apiborrow.lendasat.com',
  );

  // MOONPAY_WEBVIEW_LINK: The website URL where MoonPay widget is displayed
  // - WSL (Windows): Use WSL IP (e.g., http://172.20.192.246:3000)
  // - Native Linux/Mac: http://localhost:3000
  // - Production: https://lendasat.com
  static const String _moonpayWebviewLink = String.fromEnvironment(
    'MOONPAY_WEBVIEW_LINK',
    defaultValue: 'https://lendasat.com',
  );

  /// Get the MoonPay backend API URL
  String get backendApiUrl {
    logger.d('[MoonPay] Backend API URL: $_moonpayBackendApi');
    return _moonpayBackendApi;
  }

  /// Get the MoonPay webview link (website URL)
  String get webviewLink {
    logger.d('[MoonPay] Webview Link: $_moonpayWebviewLink');
    return _moonpayWebviewLink;
  }

  /// Encrypt query parameters before sending to MoonPay
  Future<MoonPayEncryptedData> encryptData(Map<String, dynamic> data) async {
    final serverUrl = _moonpayBackendApi;
    logger.i('[MoonPay] Encrypting data...');
    logger.d('[MoonPay] Server URL: $serverUrl');
    logger.d('[MoonPay] Data to encrypt: $data');

    try {
      final dataJson = jsonEncode(data);

      final encrypted = await rust_api.moonpayEncryptData(
        serverUrl: serverUrl,
        data: dataJson,
      );

      logger.i('[MoonPay] Data encrypted successfully');
      logger.d('[MoonPay] Ciphertext length: ${encrypted.ciphertext.length}');
      logger.d('[MoonPay] IV length: ${encrypted.iv.length}');

      return encrypted;
    } catch (e, stackTrace) {
      logger.e('[MoonPay] Error encrypting data: $e');
      logger.e('[MoonPay] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get buy/sell limits for a currency and payment method
  Future<MoonPayCurrencyLimits> getCurrencyLimits({
    String baseCurrencyCode = 'usd',
    String paymentMethod = 'credit_debit_card',
  }) async {
    final serverUrl = _moonpayBackendApi;
    logger.i('[MoonPay] Fetching currency limits...');
    logger.d('[MoonPay] Server URL: $serverUrl');
    logger.d('[MoonPay] Base currency: $baseCurrencyCode');
    logger.d('[MoonPay] Payment method: $paymentMethod');

    try {
      final limits = await rust_api.moonpayGetCurrencyLimits(
        serverUrl: serverUrl,
        baseCurrencyCode: baseCurrencyCode,
        paymentMethod: paymentMethod,
      );

      logger.i('[MoonPay] Currency limits fetched successfully');
      logger.d('[MoonPay] Min buy: ${limits.quoteCurrency.minBuyAmount} BTC');
      logger.d('[MoonPay] Max buy: ${limits.quoteCurrency.maxBuyAmount} BTC');

      return limits;
    } catch (e, stackTrace) {
      logger.e('[MoonPay] Error getting currency limits: $e');
      logger.e('[MoonPay] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get current Bitcoin exchange rate
  Future<MoonPayQuote> getQuote() async {
    final serverUrl = _moonpayBackendApi;
    logger.i('[MoonPay] Fetching BTC quote...');
    logger.d('[MoonPay] Server URL: $serverUrl');

    try {
      final quote = await rust_api.moonpayGetQuote(serverUrl: serverUrl);

      logger.i('[MoonPay] Quote fetched successfully');
      logger.d('[MoonPay] Exchange rate: ${quote.exchangeRate} USD/BTC');
      logger.d('[MoonPay] Timestamp: ${quote.timestamp}');

      return quote;
    } catch (e, stackTrace) {
      logger.e('[MoonPay] Error getting quote: $e');
      logger.e('[MoonPay] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Debug: Print current configuration
  void printConfig() {
    logger.i('=== MoonPay Service Configuration ===');
    logger.i('Backend API: $_moonpayBackendApi');
    logger.i('Webview Link: $_moonpayWebviewLink');
    logger.i('=====================================');
  }
}

/// Extension methods for MoonPayQuote
extension MoonPayQuoteExtension on MoonPayQuote {
  String get pricePerBtc => '\$${exchangeRate.toStringAsFixed(2)}';

  DateTime get timestampAsDateTime => DateTime.parse(timestamp);
}
