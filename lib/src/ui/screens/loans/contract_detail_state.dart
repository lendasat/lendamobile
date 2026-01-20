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
      availableBalanceSats: availableBalanceSats ?? this.availableBalanceSats,
      bitcoinPriceData: bitcoinPriceData ?? this.bitcoinPriceData,
    );
  }
}
