import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart'
    show PriceData;
import 'package:ark_flutter/src/ui/widgets/wallet/wallet_mini_chart.dart';

/// Calculator for wallet balance history and chart data
class BalanceChartCalculator {
  final List<Transaction> transactions;
  final List<PriceData> priceData;
  final double currentBalance;

  // Cache for computed chart data
  List<WalletChartData>? _cachedChartData;
  int _lastTransactionCount = 0;
  int _lastPriceDataCount = 0;
  double _lastBalance = 0;

  BalanceChartCalculator({
    required this.transactions,
    required this.priceData,
    required this.currentBalance,
  });

  /// Calculate the user's BTC balance at a specific point in time
  /// by working backwards from current balance using transaction history.
  double getBalanceAtTimestamp(int timestampMs) {
    final timestampSec = timestampMs ~/ 1000;

    // Sum all transaction amounts that occurred AFTER the target timestamp
    double amountAfterTimestamp = 0.0;

    // Process regular transactions from the rust backend
    // These include all boarding, round, and redeem transactions
    for (final tx in transactions) {
      final txTimestamp = tx.map(
        boarding: (t) =>
            (t.confirmedAt is BigInt
                ? (t.confirmedAt as BigInt).toInt()
                : t.confirmedAt) ??
            (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        round: (t) => t.createdAt is BigInt
            ? (t.createdAt as BigInt).toInt()
            : t.createdAt,
        redeem: (t) => t.createdAt is BigInt
            ? (t.createdAt as BigInt).toInt()
            : t.createdAt,
        offboard: (t) =>
            (t.confirmedAt is BigInt
                ? (t.confirmedAt as BigInt).toInt()
                : t.confirmedAt) ??
            (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );

      // Only count transactions that happened AFTER our target point
      if (txTimestamp > timestampSec) {
        final amountSats = tx.map(
          boarding: (t) => t.amountSats.toInt(),
          round: (t) => t.amountSats is BigInt
              ? (t.amountSats as BigInt).toInt()
              : t.amountSats,
          // Redeem transactions already have the correct sign from the backend (negative for outgoing)
          redeem: (t) => t.amountSats is BigInt
              ? (t.amountSats as BigInt).toInt()
              : t.amountSats,
          offboard: (t) => t.amountSats.toInt(),
        );
        amountAfterTimestamp += amountSats / BitcoinConstants.satsPerBtc;
      }
    }

    // NOTE: Swaps are NOT processed here because they result in boarding/round transactions
    // which are already captured in the transactions list. Processing them again results in double-counting.

    // Balance at timestamp = current balance - changes that happened after
    // Current: 100. Received: 50. Before: 100 - 50 = 50.
    // Current: 50. Sent: 50. Before: 50 - (-50) = 100.
    return (currentBalance - amountAfterTimestamp).clamp(0.0, double.infinity);
  }

  /// Get cached balance chart data or compute if cache is invalid
  /// This avoids expensive getBalanceAtTimestamp calculations on every rebuild
  List<WalletChartData> getChartData() {
    // Check if cache is valid
    final needsRecompute = _cachedChartData == null ||
        transactions.length != _lastTransactionCount ||
        priceData.length != _lastPriceDataCount ||
        currentBalance != _lastBalance;

    if (needsRecompute) {
      // Compute chart data - this is the expensive operation
      _cachedChartData = priceData.map((data) {
        final balanceAtTime = getBalanceAtTimestamp(data.time);
        return WalletChartData(
          time: data.time.toDouble(),
          value: data.price * balanceAtTime,
        );
      }).toList();

      // Update cache keys
      _lastTransactionCount = transactions.length;
      _lastPriceDataCount = priceData.length;
      _lastBalance = currentBalance;
    }

    // Always append current state as the final point for immediate visual updates
    // This is cheap to compute and ensures the chart reflects the current balance
    final result = List<WalletChartData>.from(_cachedChartData!);
    final currentPrice = priceData.isNotEmpty ? priceData.last.price : 0.0;
    result.add(WalletChartData(
      time: DateTime.now().millisecondsSinceEpoch.toDouble(),
      value: currentPrice * currentBalance,
    ));

    return result;
  }

  /// Determines if a balance change should be considered positive (green) or negative (red).
  /// Uses balance-aware logic to properly handle edge cases:
  /// - Both balances zero: neutral (green) - new user or always empty
  /// - Had balance, now zero: loss (red) - user withdrew/spent everything
  /// - Had zero, now have balance: gain (green) - user received first deposit
  /// - Otherwise: compare portfolio values
  static bool isBalanceChangePositive(double firstBalance, double lastBalance,
      double firstValue, double lastValue) {
    // 1 satoshi threshold for "essentially zero" (handles floating point precision)
    const satoshiThreshold = 0.00000001;

    // Case 1: Both balances essentially zero - neutral state, show green
    if (firstBalance < satoshiThreshold && lastBalance < satoshiThreshold) {
      return true;
    }

    // Case 2: Had balance, now zero - definite loss (-100%), show red
    if (firstBalance >= satoshiThreshold && lastBalance < satoshiThreshold) {
      return false;
    }

    // Case 3: Had zero, now have balance - definite gain, show green
    if (firstBalance < satoshiThreshold && lastBalance >= satoshiThreshold) {
      return true;
    }

    // Case 4: Normal portfolio value comparison
    return lastValue >= firstValue;
  }

  /// Check if the overall price/balance change is positive
  bool isPriceChangePositive(double currentPrice) {
    if (priceData.isEmpty) return true;

    // Calculate portfolio value change (balance at time × price)
    final firstData = priceData.first;

    // Compare first point with the ACTUAL current state (not the last price point which might be stale)
    final firstBalance = getBalanceAtTimestamp(firstData.time);

    final firstValue = firstData.price * firstBalance;
    final currentValue = currentPrice * currentBalance;

    return isBalanceChangePositive(
        firstBalance, currentBalance, firstValue, currentValue);
  }

  /// Calculate the percent change over the time period
  /// Returns (percentChange, isPositive, balanceChangeInFiat)
  (double percentChange, bool isPositive, double balanceChangeInFiat)
      calculatePriceChangeMetrics(double currentPrice) {
    if (priceData.isEmpty) {
      return (0.0, true, 0.0);
    }

    final firstData = priceData.first;
    final firstBalance = getBalanceAtTimestamp(firstData.time);

    final firstValue = firstData.price * firstBalance;
    final currentValue = currentPrice * currentBalance;
    final valueDiff = currentValue - firstValue;

    final isPositive = isBalanceChangePositive(
        firstBalance, currentBalance, firstValue, currentValue);

    // Calculate percent change with proper edge case handling
    double percentChange;
    const satoshiThreshold = 0.00000001;

    if (firstBalance < satoshiThreshold && currentBalance < satoshiThreshold) {
      percentChange = 0.0;
    } else if (firstBalance >= satoshiThreshold &&
        currentBalance < satoshiThreshold) {
      percentChange = -100.0;
    } else if (firstBalance < satoshiThreshold &&
        currentBalance >= satoshiThreshold) {
      percentChange = double.infinity;
    } else if (firstValue != 0) {
      percentChange = (valueDiff / firstValue) * 100;
    } else {
      percentChange = 0.0;
    }

    return (percentChange, isPositive, valueDiff);
  }
}
