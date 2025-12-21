import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';

/// Unified activity item that can represent either a transaction or a swap.
/// Used for displaying mixed history in the wallet activity list.
sealed class WalletActivityItem {
  int get timestamp;
  String get id;
  bool get isSwap;
}

/// A regular Ark transaction (boarding, round, or redeem).
class TransactionActivityItem implements WalletActivityItem {
  final Transaction transaction;

  const TransactionActivityItem(this.transaction);

  @override
  int get timestamp => transaction.map(
        boarding: (tx) {
          // Boarding transactions use confirmedAt if available
          if (tx.confirmedAt != null) {
            return tx.confirmedAt is BigInt
                ? (tx.confirmedAt as BigInt).toInt()
                : tx.confirmedAt as int;
          }
          // Unconfirmed boarding txs should be at the TOP of the history
          return (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1;
        },
        round: (tx) => tx.createdAt is BigInt ? (tx.createdAt as BigInt).toInt() : tx.createdAt as int,
        redeem: (tx) => tx.createdAt is BigInt ? (tx.createdAt as BigInt).toInt() : tx.createdAt as int,
      );

  @override
  String get id => transaction.map(
        boarding: (tx) => tx.txid,
        round: (tx) => tx.txid,
        redeem: (tx) => tx.txid,
      );

  @override
  bool get isSwap => false;

  int get amountSats => transaction.map(
        boarding: (tx) => tx.amountSats.toInt(),
        round: (tx) => tx.amountSats is BigInt ? (tx.amountSats as BigInt).toInt() : tx.amountSats as int,
        redeem: (tx) => tx.amountSats is BigInt ? (tx.amountSats as BigInt).toInt() : tx.amountSats as int,
      );

  bool get isSettled => transaction.map(
        boarding: (tx) => tx.confirmedAt != null,
        round: (tx) => true,
        redeem: (tx) => tx.isSettled,
      );
}

/// A LendaSwap swap (BTC <-> Stablecoin).
class SwapActivityItem implements WalletActivityItem {
  final SwapInfo swap;

  const SwapActivityItem(this.swap);

  @override
  int get timestamp {
    try {
      // Handle format like "2025-12-21 19:04:15.0 +00:00:00"
      String dateStr = swap.createdAt;

      // Remove the unusual timezone format (+00:00:00 or -00:00:00)
      if (dateStr.contains(' +') || dateStr.contains(' -')) {
        final parts = dateStr.split(RegExp(r' [+-]'));
        if (parts.isNotEmpty) {
          dateStr = parts[0].trim();
        }
      }

      // Replace space between date and time with 'T' for ISO format
      dateStr = dateStr.replaceFirst(' ', 'T');

      // Add Z suffix if no timezone indicator
      if (!dateStr.contains('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }

      final date = DateTime.parse(dateStr);
      return date.millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      // If parsing fails for an OLD swap, don't pin it to the top.
      // 0 will put it at the bottom where it's less confusing than the very tip.
      return 0;
    }
  }

  @override
  String get id => swap.id;

  @override
  bool get isSwap => true;

  /// Check if this is a BTC to stablecoin swap.
  bool get isBtcToEvm => swap.direction == 'btc_to_evm';

  /// Get the amount in satoshis (positive for receiving BTC, negative for sending).
  int get amountSats {
    final sats = swap.sourceAmountSats.toInt();
    // Negative when selling BTC, positive when buying BTC
    return isBtcToEvm ? -sats : sats;
  }

  /// Get USD amount for the swap.
  double get usdAmount => swap.targetAmountUsd;

  /// Get the EVM token symbol (e.g., "USDC", "USDT").
  /// For BTC → EVM swaps, this is the target token.
  /// For EVM → BTC swaps, this is the source token.
  String get tokenSymbol {
    // Always show the EVM token (the non-BTC token in the swap)
    final token = isBtcToEvm ? swap.targetToken : swap.sourceToken;
    if (token.contains('usdc')) return 'USDC';
    if (token.contains('usdt')) return 'USDT';
    if (token.contains('xaut')) return 'XAUt';
    if (token.contains('btc')) return 'BTC';
    return token.toUpperCase();
  }

  /// Get the network name (e.g., "Polygon", "Ethereum").
  String get networkName {
    final token = isBtcToEvm ? swap.targetToken : swap.sourceToken;
    if (token.contains('pol')) return 'Polygon';
    if (token.contains('eth')) return 'Ethereum';
    return 'Unknown';
  }

  /// Get status color based on swap status.
  SwapDisplayStatus get displayStatus {
    switch (swap.status) {
      case SwapStatusSimple.waitingForDeposit:
        return SwapDisplayStatus.pending;
      case SwapStatusSimple.processing:
        return SwapDisplayStatus.processing;
      case SwapStatusSimple.completed:
        return SwapDisplayStatus.completed;
      case SwapStatusSimple.expired:
        return SwapDisplayStatus.expired;
      case SwapStatusSimple.refundable:
        return SwapDisplayStatus.refundable;
      case SwapStatusSimple.refunded:
        return SwapDisplayStatus.refunded;
      case SwapStatusSimple.failed:
        return SwapDisplayStatus.failed;
    }
  }

  /// Check if refund is available.
  bool get canRefund => swap.status == SwapStatusSimple.refundable;

  /// Check if swap is completed.
  bool get isCompleted => swap.status == SwapStatusSimple.completed;

  /// Check if swap failed or expired.
  bool get isFailed =>
      swap.status == SwapStatusSimple.failed ||
      swap.status == SwapStatusSimple.expired;
}

/// Display status for swaps in the UI.
enum SwapDisplayStatus {
  pending,
  processing,
  completed,
  expired,
  refundable,
  refunded,
  failed,
}

/// Extension to help with sorting and filtering.
extension WalletActivityItemListExtension on List<WalletActivityItem> {
  /// Sort by timestamp, newest first.
  List<WalletActivityItem> sortedByTime() {
    final sorted = List<WalletActivityItem>.from(this);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  /// Filter to only swaps.
  List<SwapActivityItem> get swapsOnly =>
      whereType<SwapActivityItem>().toList();

  /// Filter to only transactions.
  List<TransactionActivityItem> get transactionsOnly =>
      whereType<TransactionActivityItem>().toList();
}

/// Combine transactions and swaps into a unified list.
List<WalletActivityItem> combineActivity(
  List<Transaction> transactions,
  List<SwapInfo> swaps,
) {
  final List<WalletActivityItem> items = [];

  for (final tx in transactions) {
    items.add(TransactionActivityItem(tx));
  }

  for (final swap in swaps) {
    items.add(SwapActivityItem(swap));
  }

  return items.sortedByTime();
}
