import 'dart:convert';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of recipient addresses
enum RecipientType {
  ark,
  lightning, // LNURL or Lightning Address (reusable)
  lightningInvoice, // BOLT11 invoice (NOT reusable)
  onchain,
}

/// Stored recipient data
class StoredRecipient {
  final String address;
  final RecipientType type;
  final int amountSats;
  final int timestamp;
  final String? txid;
  final String? label;

  const StoredRecipient({
    required this.address,
    required this.type,
    required this.amountSats,
    required this.timestamp,
    this.txid,
    this.label,
  });

  /// Check if this recipient can be reused for sending
  bool get isReusable => type != RecipientType.lightningInvoice;

  Map<String, dynamic> toJson() => {
        'address': address,
        'type': type.index,
        'amountSats': amountSats,
        'timestamp': timestamp,
        'txid': txid,
        'label': label,
      };

  factory StoredRecipient.fromJson(Map<String, dynamic> json) {
    return StoredRecipient(
      address: json['address'] as String,
      type: RecipientType.values[json['type'] as int],
      amountSats: json['amountSats'] as int,
      timestamp: json['timestamp'] as int,
      txid: json['txid'] as String?,
      label: json['label'] as String?,
    );
  }
}

/// Service for storing and retrieving recipient addresses
class RecipientStorageService {
  static const String _recipientsKey = 'stored_recipients';
  static const int _maxRecipients = 50; // Keep last 50 recipients

  /// Save a recipient after initiating a send
  static Future<void> saveRecipient({
    required String address,
    required RecipientType type,
    required int amountSats,
    String? txid,
    String? label,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipients = await _loadRecipients(prefs);

      final newRecipient = StoredRecipient(
        address: address,
        type: type,
        amountSats: amountSats,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        txid: txid,
        label: label,
      );

      // Add new recipient at the beginning (allow multiple transactions to same address)
      recipients.insert(0, newRecipient);

      // Trim to max size
      if (recipients.length > _maxRecipients) {
        recipients.removeRange(_maxRecipients, recipients.length);
      }

      await _saveRecipients(prefs, recipients);
      logger.i('Saved recipient: ${_truncateAddress(address)} (${type.name})');
    } catch (e) {
      logger.e('Error saving recipient: $e');
    }
  }

  /// Update a recipient with txid after transaction completes
  static Future<void> updateRecipientTxid(String address, String txid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipients = await _loadRecipients(prefs);

      final index = recipients.indexWhere((r) => r.address == address);
      if (index != -1) {
        final old = recipients[index];
        recipients[index] = StoredRecipient(
          address: old.address,
          type: old.type,
          amountSats: old.amountSats,
          timestamp: old.timestamp,
          txid: txid,
          label: old.label,
        );
        await _saveRecipients(prefs, recipients);
        logger.i('Updated recipient txid: ${_truncateAddress(address)}');
      }
    } catch (e) {
      logger.e('Error updating recipient txid: $e');
    }
  }

  /// Get all stored recipients (most recent first)
  static Future<List<StoredRecipient>> getRecipients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await _loadRecipients(prefs);
    } catch (e) {
      logger.e('Error loading recipients: $e');
      return [];
    }
  }

  /// Get only reusable recipients (excludes Lightning invoices)
  static Future<List<StoredRecipient>> getReusableRecipients() async {
    final recipients = await getRecipients();
    return recipients.where((r) => r.isReusable).toList();
  }

  /// Clear all stored recipients
  static Future<void> clearRecipients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recipientsKey);
      logger.i('Cleared all stored recipients');
    } catch (e) {
      logger.e('Error clearing recipients: $e');
    }
  }

  /// Determine recipient type from address string
  static RecipientType determineType(String address) {
    final lower = address.toLowerCase();

    // Ark address
    if (lower.startsWith('ark1') || lower.startsWith('tark1')) {
      return RecipientType.ark;
    }

    // Lightning invoice (BOLT11)
    if (lower.startsWith('lnbc') ||
        lower.startsWith('lntb') ||
        lower.startsWith('lnbcrt') ||
        lower.startsWith('lntbs')) {
      return RecipientType.lightningInvoice;
    }

    // LNURL
    if (lower.startsWith('lnurl')) {
      return RecipientType.lightning;
    }

    // Lightning Address (user@domain.com format)
    if (address.contains('@') && address.contains('.')) {
      return RecipientType.lightning;
    }

    // On-chain Bitcoin address
    if (lower.startsWith('bc1') ||
        lower.startsWith('tb1') ||
        lower.startsWith('bcrt1') ||
        lower.startsWith('1') ||
        lower.startsWith('3') ||
        lower.startsWith('m') ||
        lower.startsWith('n') ||
        lower.startsWith('2')) {
      return RecipientType.onchain;
    }

    // Default to on-chain
    return RecipientType.onchain;
  }

  // Private helpers

  static Future<List<StoredRecipient>> _loadRecipients(
      SharedPreferences prefs) async {
    final jsonString = prefs.getString(_recipientsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => StoredRecipient.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error parsing recipients JSON: $e');
      return [];
    }
  }

  static Future<void> _saveRecipients(
      SharedPreferences prefs, List<StoredRecipient> recipients) async {
    final jsonList = recipients.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_recipientsKey, jsonString);
  }

  static String _truncateAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }
}
