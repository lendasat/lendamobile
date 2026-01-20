import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart' as lendaswap_api;
import 'package:ark_flutter/src/services/amount_widget_service.dart'
    show CurrencyType;

/// Immutable state for the swap screen.
class SwapState {
  SwapState({
    this.sourceToken = SwapToken.bitcoin,
    this.targetToken = SwapToken.usdcPolygon,
    this.btcAmount = '',
    this.usdAmount = '',
    this.satsAmount = '',
    this.tokenAmount = '',
    this.sourceShowUsd = false,
    this.targetShowUsd = true,
    this.sourceBtcUnit = CurrencyType.sats,
    this.targetBtcUnit = CurrencyType.sats,
    this.quote,
    this.isLoadingQuote = false,
    this.isExecuting = false,
    BigInt? availableBalanceSats,
    BigInt? spendableBalanceSats,
    this.isLoadingBalance = true,
    this.btcUsdPrice = 104000.0,
  })  : availableBalanceSats = availableBalanceSats ?? BigInt.zero,
        spendableBalanceSats = spendableBalanceSats ?? BigInt.zero;

  // Token selection
  final SwapToken sourceToken;
  final SwapToken targetToken;

  // Amount values (stored as strings for precise decimal handling)
  final String btcAmount;
  final String usdAmount;
  final String satsAmount;
  final String tokenAmount;

  // Display modes
  final bool sourceShowUsd;
  final bool targetShowUsd;
  final CurrencyType sourceBtcUnit;
  final CurrencyType targetBtcUnit;

  // Quote
  final lendaswap_api.SwapQuote? quote;
  final bool isLoadingQuote;

  // Execution state
  final bool isExecuting;

  // Balance
  final BigInt availableBalanceSats;
  final BigInt spendableBalanceSats;
  final bool isLoadingBalance;

  // Price
  final double btcUsdPrice;

  /// Create initial state
  factory SwapState.initial() => SwapState();

  /// Check if swap direction is BTC to EVM
  bool get isBtcToEvm => sourceToken.isBtc && targetToken.isEvm;

  /// Check if swap direction is EVM to BTC
  bool get isEvmToBtc => sourceToken.isEvm && targetToken.isBtc;

  /// Get BTC amount as double
  double get btcValue => double.tryParse(btcAmount) ?? 0;

  /// Get USD amount as double
  double get usdValue => double.tryParse(usdAmount) ?? 0;

  /// Get sats amount as int
  int get satsValue => int.tryParse(satsAmount) ?? 0;

  /// Check if amount is too small
  bool get isAmountTooSmall {
    if (btcAmount.isEmpty && satsAmount.isEmpty) return false;
    return satsValue < 1000;
  }

  /// Check if user has insufficient funds (only for BTC source)
  bool get hasInsufficientFunds {
    if (isLoadingBalance || !sourceToken.isBtc) return false;
    if (btcValue <= 0) return false;
    return BigInt.from(totalRequiredSats) > availableBalanceSats;
  }

  /// Get total sats required including fees
  int get totalRequiredSats {
    final inputSats = satsValue;
    if (quote != null) {
      return inputSats +
          quote!.networkFeeSats.toInt() +
          quote!.protocolFeeSats.toInt();
    }
    // Estimate: ~0.5% protocol + ~250 network
    return inputSats + (inputSats * 0.005).round() + 250;
  }

  /// Check if amount is valid for swap
  bool get isAmountValid => satsValue >= 1000 && !hasInsufficientFunds;

  /// Check if swap can be executed
  bool get canExecute => isAmountValid && !isExecuting;

  /// Get button title based on state
  String get buttonTitle {
    if (hasInsufficientFunds) return 'Not enough funds';
    if (isAmountTooSmall) return 'Amount too small (min 1,000 sats)';
    return 'Swap ${sourceToken.symbol} to ${targetToken.symbol}';
  }

  /// Copy with new values
  SwapState copyWith({
    SwapToken? sourceToken,
    SwapToken? targetToken,
    String? btcAmount,
    String? usdAmount,
    String? satsAmount,
    String? tokenAmount,
    bool? sourceShowUsd,
    bool? targetShowUsd,
    CurrencyType? sourceBtcUnit,
    CurrencyType? targetBtcUnit,
    lendaswap_api.SwapQuote? quote,
    bool clearQuote = false,
    bool? isLoadingQuote,
    bool? isExecuting,
    BigInt? availableBalanceSats,
    BigInt? spendableBalanceSats,
    bool? isLoadingBalance,
    double? btcUsdPrice,
  }) {
    return SwapState(
      sourceToken: sourceToken ?? this.sourceToken,
      targetToken: targetToken ?? this.targetToken,
      btcAmount: btcAmount ?? this.btcAmount,
      usdAmount: usdAmount ?? this.usdAmount,
      satsAmount: satsAmount ?? this.satsAmount,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      sourceShowUsd: sourceShowUsd ?? this.sourceShowUsd,
      targetShowUsd: targetShowUsd ?? this.targetShowUsd,
      sourceBtcUnit: sourceBtcUnit ?? this.sourceBtcUnit,
      targetBtcUnit: targetBtcUnit ?? this.targetBtcUnit,
      quote: clearQuote ? null : (quote ?? this.quote),
      isLoadingQuote: isLoadingQuote ?? this.isLoadingQuote,
      isExecuting: isExecuting ?? this.isExecuting,
      availableBalanceSats: availableBalanceSats ?? this.availableBalanceSats,
      spendableBalanceSats: spendableBalanceSats ?? this.spendableBalanceSats,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      btcUsdPrice: btcUsdPrice ?? this.btcUsdPrice,
    );
  }

  /// Clear all amounts
  SwapState clearAmounts() {
    return copyWith(
      btcAmount: '',
      usdAmount: '',
      satsAmount: '',
      tokenAmount: '',
      clearQuote: true,
    );
  }
}
