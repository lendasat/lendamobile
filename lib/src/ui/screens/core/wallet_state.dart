import 'package:ark_flutter/src/rust/api/ark_api.dart' show Transaction;
import 'package:ark_flutter/src/rust/lendaswap.dart' show SwapInfo;
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart'
    show PriceData;
import 'package:flutter/material.dart';
import 'package:ark_flutter/theme.dart';

/// Immutable state for the wallet screen.
class WalletState {
  // Loading states
  final bool isBalanceLoading;
  final bool isTransactionFetching;
  final bool isSettling;

  // Balance values
  final double pendingBalance;
  final double confirmedBalance;
  final double totalBalance;

  // Additional balances
  final int lockedCollateralSats;
  final int boardingBalanceSats;
  final int recoverableSats;
  final int expiredSats;

  // Auto-settle state
  final bool skipAutoSettle;
  final DateTime? lastSettleAttempt;

  // Data lists
  final List<Transaction> transactions;
  final List<SwapInfo> swaps;
  final List<PriceData> bitcoinPriceData;

  // UI state
  final Color gradientTopColor;
  final Color gradientBottomColor;
  final bool wordRecoverySet;

  WalletState({
    this.isBalanceLoading = true,
    this.isTransactionFetching = true,
    this.isSettling = false,
    this.pendingBalance = 0.0,
    this.confirmedBalance = 0.0,
    this.totalBalance = 0.0,
    this.lockedCollateralSats = 0,
    this.boardingBalanceSats = 0,
    this.recoverableSats = 0,
    this.expiredSats = 0,
    this.skipAutoSettle = false,
    this.lastSettleAttempt,
    this.transactions = const [],
    this.swaps = const [],
    this.bitcoinPriceData = const [],
    Color? gradientTopColor,
    Color? gradientBottomColor,
    this.wordRecoverySet = false,
  })  : gradientTopColor =
            gradientTopColor ?? AppTheme.successColor.withValues(alpha: 0.3),
        gradientBottomColor = gradientBottomColor ??
            AppTheme.successColorGradient.withValues(alpha: 0.15);

  /// Initial loading state.
  factory WalletState.initial() => WalletState();

  /// Current BTC price from price data.
  double get currentBtcPrice {
    if (bitcoinPriceData.isEmpty) return 0;
    return bitcoinPriceData.last.price;
  }

  /// Whether there are any transactions or swaps.
  bool get hasTransactions => transactions.isNotEmpty || swaps.isNotEmpty;

  /// Whether boarding balance can be settled.
  bool get canSettle => boardingBalanceSats > 0 && !isSettling;

  /// Whether there are recoverable VTXOs.
  bool get hasRecoverableVtxos => recoverableSats > 0 || expiredSats > 0;

  WalletState copyWith({
    bool? isBalanceLoading,
    bool? isTransactionFetching,
    bool? isSettling,
    double? pendingBalance,
    double? confirmedBalance,
    double? totalBalance,
    int? lockedCollateralSats,
    int? boardingBalanceSats,
    int? recoverableSats,
    int? expiredSats,
    bool? skipAutoSettle,
    DateTime? lastSettleAttempt,
    bool clearLastSettleAttempt = false,
    List<Transaction>? transactions,
    List<SwapInfo>? swaps,
    List<PriceData>? bitcoinPriceData,
    Color? gradientTopColor,
    Color? gradientBottomColor,
    bool? wordRecoverySet,
  }) {
    return WalletState(
      isBalanceLoading: isBalanceLoading ?? this.isBalanceLoading,
      isTransactionFetching:
          isTransactionFetching ?? this.isTransactionFetching,
      isSettling: isSettling ?? this.isSettling,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      confirmedBalance: confirmedBalance ?? this.confirmedBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      lockedCollateralSats: lockedCollateralSats ?? this.lockedCollateralSats,
      boardingBalanceSats: boardingBalanceSats ?? this.boardingBalanceSats,
      recoverableSats: recoverableSats ?? this.recoverableSats,
      expiredSats: expiredSats ?? this.expiredSats,
      skipAutoSettle: skipAutoSettle ?? this.skipAutoSettle,
      lastSettleAttempt: clearLastSettleAttempt
          ? null
          : (lastSettleAttempt ?? this.lastSettleAttempt),
      transactions: transactions ?? this.transactions,
      swaps: swaps ?? this.swaps,
      bitcoinPriceData: bitcoinPriceData ?? this.bitcoinPriceData,
      gradientTopColor: gradientTopColor ?? this.gradientTopColor,
      gradientBottomColor: gradientBottomColor ?? this.gradientBottomColor,
      wordRecoverySet: wordRecoverySet ?? this.wordRecoverySet,
    );
  }
}
