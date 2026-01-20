import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart'
    show ContractExtension;
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart'
    show PriceData;

/// Immutable state for the contract detail screen.
class ContractDetailState {
  final Contract? contract;
  final bool isLoading;
  final bool isActionLoading;
  final bool isRepaying;
  final bool isMarkingPaid;
  final String? errorMessage;
  final bool showAddressCopied;
  final bool showBtcAddressCopied;
  final bool showStablecoinAddressCopied;
  final BigInt availableBalanceSats;
  final List<PriceData> bitcoinPriceData;

  ContractDetailState({
    this.contract,
    this.isLoading = true,
    this.isActionLoading = false,
    this.isRepaying = false,
    this.isMarkingPaid = false,
    this.errorMessage,
    this.showAddressCopied = false,
    this.showBtcAddressCopied = false,
    this.showStablecoinAddressCopied = false,
    BigInt? availableBalanceSats,
    this.bitcoinPriceData = const [],
  }) : availableBalanceSats = availableBalanceSats ?? BigInt.zero;

  /// Initial loading state.
  factory ContractDetailState.initial() => ContractDetailState();

  /// Current BTC price from price data.
  double get currentBtcPrice {
    if (bitcoinPriceData.isEmpty) return 0;
    return bitcoinPriceData.last.price;
  }

  /// Whether there are any action buttons to display.
  bool get hasActionButtons {
    if (contract == null) return false;

    final canCancel = contract!.status == ContractStatus.requested;
    final canPayCollateral = contract!.status == ContractStatus.approved &&
        contract!.contractAddress != null &&
        contract!.effectiveCollateralSats > 0;

    return canCancel ||
        canPayCollateral ||
        contract!.canRepayWithLendaswap ||
        contract!.canClaim ||
        contract!.canRecover ||
        (contract!.isActiveLoan &&
            contract!.balanceOutstanding > 0 &&
            !contract!.isAwaitingRepaymentConfirmation) ||
        contract!.isAwaitingRepaymentConfirmation;
  }

  /// Whether user can cancel the contract.
  bool get canCancel => contract?.status == ContractStatus.requested;

  /// Whether user can pay collateral.
  bool get canPayCollateral =>
      contract?.status == ContractStatus.approved &&
      contract?.contractAddress != null &&
      (contract?.effectiveCollateralSats ?? 0) > 0;

  /// Whether user has insufficient balance for collateral.
  bool get hasInsufficientBalance {
    if (!canPayCollateral || contract == null) return false;
    final requiredSats = BigInt.from(contract!.effectiveCollateralSats);
    return availableBalanceSats < requiredSats;
  }

  /// Estimated sats needed for loan repayment (with 5% buffer for fees).
  /// Returns 0 if cannot be calculated (no price data or no repayment needed).
  int get estimatedRepaymentSats {
    if (contract == null || currentBtcPrice <= 0) return 0;
    if (!contract!.canRepayWithLendaswap) return 0;

    final amountToRepay = contract!.balanceOutstanding;
    if (amountToRepay <= 0) return 0;

    // Convert USD to BTC, then to sats, with 5% buffer for swap fees
    final btcNeeded = amountToRepay / currentBtcPrice;
    final satsNeeded = btcNeeded * BitcoinConstants.satsPerBtc;
    final satsWithBuffer = satsNeeded * 1.05; // 5% buffer for fees

    return satsWithBuffer.ceil();
  }

  /// Whether user has insufficient balance for loan repayment.
  bool get hasInsufficientRepaymentBalance {
    if (contract == null || !contract!.canRepayWithLendaswap) return false;
    if (currentBtcPrice <= 0) return false; // Can't estimate without price

    final requiredSats = BigInt.from(estimatedRepaymentSats);
    return availableBalanceSats < requiredSats;
  }

  ContractDetailState copyWith({
    Contract? contract,
    bool? isLoading,
    bool? isActionLoading,
    bool? isRepaying,
    bool? isMarkingPaid,
    String? errorMessage,
    bool clearError = false,
    bool? showAddressCopied,
    bool? showBtcAddressCopied,
    bool? showStablecoinAddressCopied,
    BigInt? availableBalanceSats,
    List<PriceData>? bitcoinPriceData,
  }) {
    return ContractDetailState(
      contract: contract ?? this.contract,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      isRepaying: isRepaying ?? this.isRepaying,
      isMarkingPaid: isMarkingPaid ?? this.isMarkingPaid,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      showAddressCopied: showAddressCopied ?? this.showAddressCopied,
      showBtcAddressCopied: showBtcAddressCopied ?? this.showBtcAddressCopied,
      showStablecoinAddressCopied:
          showStablecoinAddressCopied ?? this.showStablecoinAddressCopied,
      availableBalanceSats: availableBalanceSats ?? this.availableBalanceSats,
      bitcoinPriceData: bitcoinPriceData ?? this.bitcoinPriceData,
    );
  }
}
