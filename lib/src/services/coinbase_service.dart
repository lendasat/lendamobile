import 'dart:convert';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service for Coinbase Onramp integration
///
/// This service communicates with the LendaSat backend to get
/// session tokens for the Coinbase Onramp API, which allows users
/// to buy Bitcoin directly in the app.
class CoinbaseService {
  static final CoinbaseService _instance = CoinbaseService._internal();

  factory CoinbaseService() => _instance;

  CoinbaseService._internal();

  // Use same backend URL as MoonPay (both are on the same backend)
  static const String _backendUrl = String.fromEnvironment(
    'MOONPAY_BACKEND_API',
    defaultValue: 'https://apiborrow.lendasat.com',
  );

  // Coinbase fee structure by payment method
  static const Map<String, CoinbaseFee> feesByMethod = {
    'credit_debit_card': CoinbaseFee(percentage: 3.99, spread: 0.5),
    'google_pay': CoinbaseFee(percentage: 3.99, spread: 0.5),
    'apple_pay': CoinbaseFee(percentage: 3.99, spread: 0.5),
    'paypal': CoinbaseFee(percentage: 3.99, spread: 0.5),
    'sepa_bank_transfer': CoinbaseFee(percentage: 1.49, spread: 0.5),
    'ach_bank_transfer': CoinbaseFee(percentage: 1.49, spread: 0.5),
  };

  /// Get the fee for a specific payment method
  CoinbaseFee? getFeeForMethod(String methodId) {
    // Try exact match first
    if (feesByMethod.containsKey(methodId)) {
      return feesByMethod[methodId];
    }
    // Fallback for bank transfers
    if (methodId.contains('bank') || methodId.contains('sepa')) {
      return feesByMethod['sepa_bank_transfer'];
    }
    // Default to card fee
    return feesByMethod['credit_debit_card'];
  }

  /// Check if Coinbase Onramp is available on the backend
  Future<CoinbaseStatus> checkStatus() async {
    try {
      final backendUrl = _backendUrl;
      final response = await http.get(
        Uri.parse('$backendUrl/api/coinbase/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CoinbaseStatus(
          available: data['available'] ?? false,
          message: data['message'] ?? 'Unknown status',
        );
      }

      return CoinbaseStatus(
        available: false,
        message: 'Failed to check status: HTTP ${response.statusCode}',
      );
    } catch (e) {
      logger.e('[Coinbase] Error checking status: $e');
      return CoinbaseStatus(
        available: false,
        message: 'Connection error: $e',
      );
    }
  }

  /// Get a session token and onramp URL from the backend
  ///
  /// [walletAddress] - The Bitcoin wallet address to receive BTC
  /// [btcAmount] - Optional preset BTC amount
  /// [fiatAmount] - Optional preset fiat amount (if btcAmount not provided)
  /// [fiatCurrency] - Optional fiat currency code (e.g., "USD", "EUR")
  Future<CoinbaseSessionResponse> getSessionToken({
    required String walletAddress,
    double? btcAmount,
    double? fiatAmount,
    String? fiatCurrency,
  }) async {
    try {
      final backendUrl = _backendUrl;

      final body = <String, dynamic>{
        'wallet_address': walletAddress,
      };

      if (btcAmount != null) {
        body['btc_amount'] = btcAmount;
      }
      if (fiatAmount != null) {
        body['fiat_amount'] = fiatAmount;
      }
      if (fiatCurrency != null) {
        body['fiat_currency'] = fiatCurrency;
      }

      logger
          .i('[Coinbase] Requesting session token for address: $walletAddress');
      logger.d('[Coinbase] Backend URL: $backendUrl');

      final response = await http.post(
        Uri.parse('$backendUrl/api/coinbase/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      logger.d('[Coinbase] Response status: ${response.statusCode}');
      logger.d('[Coinbase] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CoinbaseSessionResponse(
          success: true,
          onrampUrl: data['onramp_url'],
          sessionToken: data['session_token'],
        );
      } else if (response.statusCode == 503) {
        return CoinbaseSessionResponse(
          success: false,
          errorMessage: 'Coinbase Onramp is not configured',
        );
      } else {
        // Handle empty response body
        if (response.body.isEmpty) {
          return CoinbaseSessionResponse(
            success: false,
            errorMessage:
                'Server returned empty response (status: ${response.statusCode})',
          );
        }
        final errorData = jsonDecode(response.body);
        return CoinbaseSessionResponse(
          success: false,
          errorMessage: errorData['message'] ??
              'Failed to get session token (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      logger.e('[Coinbase] Error getting session token: $e');
      return CoinbaseSessionResponse(
        success: false,
        errorMessage: 'Connection error: $e',
      );
    }
  }

  /// Launch Coinbase Onramp to buy Bitcoin
  ///
  /// [walletAddress] - The wallet address to receive BTC
  /// [btcAmount] - Optional preset BTC amount
  /// [fiatAmount] - Optional preset fiat amount
  /// [fiatCurrency] - Optional fiat currency code (e.g., "USD", "EUR")
  Future<bool> launchBuyBitcoin({
    required String walletAddress,
    double? btcAmount,
    double? fiatAmount,
    String? fiatCurrency,
  }) async {
    logger.i('[Coinbase] Launching buy Bitcoin flow...');

    // Get session token from backend
    final sessionResponse = await getSessionToken(
      walletAddress: walletAddress,
      btcAmount: btcAmount,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
    );

    if (!sessionResponse.success || sessionResponse.onrampUrl == null) {
      logger.e(
          '[Coinbase] Failed to get session: ${sessionResponse.errorMessage}');
      return false;
    }

    // Open the Coinbase Onramp URL
    try {
      final uri = Uri.parse(sessionResponse.onrampUrl!);
      logger.i('[Coinbase] Opening Coinbase Onramp URL...');

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        logger.e('[Coinbase] Failed to launch URL');
        return false;
      }

      return true;
    } catch (e) {
      logger.e('[Coinbase] Error launching Coinbase: $e');
      return false;
    }
  }

  /// Debug: Print current configuration
  void printConfig() {
    logger.i('=== Coinbase Service Configuration ===');
    logger.i('Using backend API for session tokens');
    logger.i('======================================');
  }
}

/// Coinbase fee structure
class CoinbaseFee {
  final double percentage;
  final double spread;

  const CoinbaseFee({
    required this.percentage,
    required this.spread,
  });

  /// Total fee including spread
  double get totalFee => percentage + spread;
}

/// Coinbase availability status
class CoinbaseStatus {
  final bool available;
  final String message;

  const CoinbaseStatus({
    required this.available,
    required this.message,
  });
}

/// Response from session token request
class CoinbaseSessionResponse {
  final bool success;
  final String? onrampUrl;
  final String? sessionToken;
  final String? errorMessage;

  const CoinbaseSessionResponse({
    required this.success,
    this.onrampUrl,
    this.sessionToken,
    this.errorMessage,
  });
}
