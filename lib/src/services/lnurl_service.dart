import 'dart:convert';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:bech32/bech32.dart';
import 'package:http/http.dart' as http;

/// LNURL Pay parameters returned from an LNURL endpoint
class LnurlPayParams {
  final String callback;
  final int minSendable; // in millisatoshis
  final int maxSendable; // in millisatoshis
  final String? metadata;
  final String? description;
  final String? domain;

  LnurlPayParams({
    required this.callback,
    required this.minSendable,
    required this.maxSendable,
    this.metadata,
    this.description,
    this.domain,
  });

  /// Min amount in satoshis
  int get minSats => minSendable ~/ 1000;

  /// Max amount in satoshis
  int get maxSats => maxSendable ~/ 1000;

  factory LnurlPayParams.fromJson(Map<String, dynamic> json) {
    String? description;
    final metadata = json['metadata'] as String?;

    // Try to parse description from metadata
    if (metadata != null) {
      try {
        final metadataList = jsonDecode(metadata) as List;
        for (final item in metadataList) {
          if (item is List && item.length >= 2 && item[0] == 'text/plain') {
            description = item[1] as String;
            break;
          }
        }
      } catch (_) {
        // Ignore metadata parsing errors
      }
    }

    return LnurlPayParams(
      callback: json['callback'] as String,
      minSendable: json['minSendable'] as int,
      maxSendable: json['maxSendable'] as int,
      metadata: metadata,
      description: description,
    );
  }
}

/// Result of calling the LNURL callback with an amount
class LnurlInvoiceResult {
  final String pr; // BOLT11 payment request
  final Map<String, dynamic>? successAction;

  LnurlInvoiceResult({
    required this.pr,
    this.successAction,
  });

  factory LnurlInvoiceResult.fromJson(Map<String, dynamic> json) {
    return LnurlInvoiceResult(
      pr: json['pr'] as String,
      successAction: json['successAction'] as Map<String, dynamic>?,
    );
  }
}

/// Service for handling LNURL operations
class LnurlService {
  static const _timeout = Duration(seconds: 30);

  /// Check if a string is an LNURL (bech32 encoded with lnurl prefix)
  static bool isLnurl(String input) {
    final lower = input.toLowerCase().trim();
    // Remove lightning: prefix if present
    final cleaned = lower.startsWith('lightning:')
        ? lower.substring(10)
        : lower;
    return cleaned.startsWith('lnurl');
  }

  /// Check if a string is a Lightning Address (user@domain.com format)
  static bool isLightningAddress(String input) {
    final trimmed = input.trim();
    if (!trimmed.contains('@')) return false;

    final parts = trimmed.split('@');
    if (parts.length != 2) return false;

    final user = parts[0];
    final domain = parts[1];

    // Basic validation
    if (user.isEmpty || domain.isEmpty) return false;
    if (!domain.contains('.')) return false;

    // Check it's not an email (emails don't typically have valid domain for LNURL)
    // Lightning addresses should have a valid domain
    return true;
  }

  /// Decode an LNURL bech32 string to a URL
  static String? decodeLnurl(String lnurl) {
    try {
      String cleaned = lnurl.toLowerCase().trim();

      // Remove lightning: prefix if present
      if (cleaned.startsWith('lightning:')) {
        cleaned = cleaned.substring(10);
      }

      // Decode bech32
      final decoded = const Bech32Codec().decode(cleaned, 2000);

      // Convert 5-bit groups to 8-bit bytes
      final bytes = _convert5to8Bits(decoded.data);

      // Convert to UTF-8 string (the URL)
      return utf8.decode(bytes);
    } catch (e) {
      logger.e('Failed to decode LNURL: $e');
      return null;
    }
  }

  /// Convert Lightning Address to LNURL endpoint URL
  static String lightningAddressToUrl(String address) {
    final parts = address.trim().split('@');
    final user = parts[0];
    final domain = parts[1];
    return 'https://$domain/.well-known/lnurlp/$user';
  }

  /// Fetch LNURL pay parameters from an LNURL or Lightning Address
  static Future<LnurlPayParams?> fetchPayParams(String input) async {
    try {
      String url;

      if (isLightningAddress(input)) {
        url = lightningAddressToUrl(input);
        logger.i('Fetching LNURL params from Lightning Address: $url');
      } else if (isLnurl(input)) {
        final decoded = decodeLnurl(input);
        if (decoded == null) {
          logger.e('Failed to decode LNURL');
          return null;
        }
        url = decoded;
        logger.i('Fetching LNURL params from: $url');
      } else {
        logger.e('Input is not a valid LNURL or Lightning Address');
        return null;
      }

      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode != 200) {
        logger.e('LNURL endpoint returned status ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for error response
      if (json.containsKey('status') && json['status'] == 'ERROR') {
        final reason = json['reason'] ?? 'Unknown error';
        logger.e('LNURL error: $reason');
        return null;
      }

      // Check tag is payRequest
      final tag = json['tag'] as String?;
      if (tag != 'payRequest') {
        logger.e('LNURL is not a pay request (tag: $tag)');
        return null;
      }

      final params = LnurlPayParams.fromJson(json);

      // Extract domain for display
      final uri = Uri.parse(url);

      return LnurlPayParams(
        callback: params.callback,
        minSendable: params.minSendable,
        maxSendable: params.maxSendable,
        metadata: params.metadata,
        description: params.description,
        domain: uri.host,
      );
    } catch (e) {
      logger.e('Failed to fetch LNURL params: $e');
      return null;
    }
  }

  /// Request a BOLT11 invoice from LNURL callback
  /// Amount is in satoshis
  static Future<LnurlInvoiceResult?> requestInvoice(
    String callback,
    int amountSats,
  ) async {
    try {
      // LNURL uses millisatoshis
      final amountMsat = amountSats * 1000;

      // Build callback URL with amount
      final separator = callback.contains('?') ? '&' : '?';
      final url = '$callback${separator}amount=$amountMsat';

      logger.i('Requesting LNURL invoice: $url');

      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode != 200) {
        logger.e('LNURL callback returned status ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for error response
      if (json.containsKey('status') && json['status'] == 'ERROR') {
        final reason = json['reason'] ?? 'Unknown error';
        logger.e('LNURL callback error: $reason');
        return null;
      }

      // Check for invoice
      final pr = json['pr'] as String?;
      if (pr == null || pr.isEmpty) {
        logger.e('LNURL callback returned no invoice');
        return null;
      }

      logger.i('Got LNURL invoice: ${pr.substring(0, 30)}...');

      return LnurlInvoiceResult.fromJson(json);
    } catch (e) {
      logger.e('Failed to request LNURL invoice: $e');
      return null;
    }
  }

  /// Convert 5-bit groups to 8-bit bytes (bech32 data conversion)
  static List<int> _convert5to8Bits(List<int> data) {
    int acc = 0;
    int bits = 0;
    final result = <int>[];

    for (final value in data) {
      acc = (acc << 5) | value;
      bits += 5;

      while (bits >= 8) {
        bits -= 8;
        result.add((acc >> bits) & 0xFF);
      }
    }

    return result;
  }
}
