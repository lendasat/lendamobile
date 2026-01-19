import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for tracking boarding transactions and linking them to their
/// settled round transactions.
///
/// When an onchain payment is received, it creates a "boarding" transaction.
/// After settlement, this becomes a "round" transaction with a DIFFERENT txid.
/// This service tracks this conversion so we can display both as "Onchain"
/// in the transaction history.
class BoardingTrackingService {
  static const String _boardingTxKey = 'boarding_tx_tracking';
  static const String _settledOnchainKey = 'settled_onchain_txids';

  // In-memory cache of known boarding txids -> amount
  static Map<String, int> _knownBoardingTxs = {};

  // Track boarding txids that have been settled (converted to round)
  static Set<String> _settledBoardingTxids = {};

  /// Initialize the service by loading persisted data
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load known boarding transactions
      final boardingJson = prefs.getString(_boardingTxKey);
      if (boardingJson != null && boardingJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(boardingJson);
        _knownBoardingTxs = decoded.map((k, v) => MapEntry(k, v as int));
      }

      // Load settled boarding txids
      final settledJson = prefs.getString(_settledOnchainKey);
      if (settledJson != null && settledJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(settledJson);
        _settledBoardingTxids = decoded.cast<String>().toSet();
      }

      logger.i(
          'BoardingTrackingService initialized: ${_knownBoardingTxs.length} boarding txs, ${_settledBoardingTxids.length} settled');
    } catch (e) {
      logger.e('Error initializing BoardingTrackingService: $e');
    }
  }

  /// Process a list of transactions to track boarding->round conversions.
  /// Call this whenever transactions are fetched.
  static Future<void> processTransactions(
      List<Transaction> transactions) async {
    try {
      // Extract current boarding transactions
      final currentBoardingTxs = <String, int>{};
      final currentRoundTxs = <String, int>{};

      for (final tx in transactions) {
        tx.map(
          boarding: (t) {
            currentBoardingTxs[t.txid] = t.amountSats.toInt();
          },
          round: (t) {
            // Only track positive (incoming) round transactions
            final amount = t.amountSats.toInt();
            if (amount > 0) {
              currentRoundTxs[t.txid] = amount;
            }
          },
          redeem: (_) {},
          offboard: (_) {},
        );
      }

      // Find NEW boarding transactions (not seen before)
      for (final entry in currentBoardingTxs.entries) {
        if (!_knownBoardingTxs.containsKey(entry.key)) {
          // New boarding transaction - save it as onchain receive
          logger
              .i('New boarding tx detected: ${entry.key}, ${entry.value} sats');
          await RecipientStorageService.saveOnchainReceive(
            txid: entry.key,
            amountSats: entry.value,
            label: 'Onchain deposit',
          );
        }
      }

      // Find boarding transactions that have DISAPPEARED (settled)
      // and try to match them to new round transactions
      for (final entry in _knownBoardingTxs.entries) {
        final boardingTxid = entry.key;
        final boardingAmount = entry.value;

        // Skip if still present as boarding or already processed
        if (currentBoardingTxs.containsKey(boardingTxid)) continue;
        if (_settledBoardingTxids.contains(boardingTxid)) continue;

        // This boarding tx has settled - find matching round tx
        // Look for a round tx with similar amount (within 1% tolerance for fees)
        final tolerance = (boardingAmount * 0.01).round();

        for (final roundEntry in currentRoundTxs.entries) {
          final roundTxid = roundEntry.key;
          final roundAmount = roundEntry.value;

          // Check if amounts match (within tolerance)
          if ((roundAmount - boardingAmount).abs() <= tolerance) {
            // Found a match! Save this round txid as onchain too
            logger
                .i('Boarding tx $boardingTxid settled to round tx $roundTxid');
            await RecipientStorageService.saveOnchainReceive(
              txid: roundTxid,
              amountSats: roundAmount,
              label: 'Onchain deposit (settled)',
            );

            // Mark this boarding as settled
            _settledBoardingTxids.add(boardingTxid);
            break;
          }
        }
      }

      // Update known boarding txs
      _knownBoardingTxs = currentBoardingTxs;

      // Persist state
      await _saveState();
    } catch (e) {
      logger.e('Error processing transactions for boarding tracking: $e');
    }
  }

  /// Check if a txid originated from an onchain boarding transaction
  static Future<bool> isOnchainOrigin(String txid) async {
    // Check if it's a current boarding tx
    if (_knownBoardingTxs.containsKey(txid)) return true;

    // Check stored recipients
    final recipient = await RecipientStorageService.getByTxid(txid);
    return recipient?.isOnchain ?? false;
  }

  /// Save state to persistent storage
  static Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save known boarding txs
      await prefs.setString(_boardingTxKey, jsonEncode(_knownBoardingTxs));

      // Save settled boarding txids (limit to last 100 to prevent unbounded growth)
      final settledList = _settledBoardingTxids.toList();
      if (settledList.length > 100) {
        _settledBoardingTxids =
            settledList.sublist(settledList.length - 100).toSet();
      }
      await prefs.setString(
          _settledOnchainKey, jsonEncode(_settledBoardingTxids.toList()));
    } catch (e) {
      logger.e('Error saving boarding tracking state: $e');
    }
  }

  /// Clear all tracking data (useful for wallet reset)
  static Future<void> clear() async {
    _knownBoardingTxs.clear();
    _settledBoardingTxids.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_boardingTxKey);
      await prefs.remove(_settledOnchainKey);
    } catch (e) {
      logger.e('Error clearing boarding tracking: $e');
    }
  }
}
