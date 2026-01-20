import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart'
    show ContractExtension;
import 'package:ark_flutter/src/ui/screens/loans/loan_filter_screen.dart';

/// Immutable state for the loans screen.
class LoansState {
  // Loading states
  final bool isLoading;
  final bool isRegistering;
  final String? errorMessage;

  // Data
  final List<LoanOffer> offers;
  final List<Contract> contracts;

  // Filter state
  final String searchQuery;
  final LoanFilterOptions filterOptions;

  // Debug info
  final String? debugPubkey;
  final String? debugDerivationPath;
  final bool showDebugInfo;

  // Auth state
  final bool isAuthenticated;

  const LoansState({
    this.isLoading = true,
    this.isRegistering = false,
    this.errorMessage,
    this.offers = const [],
    this.contracts = const [],
    this.searchQuery = '',
    this.filterOptions = const LoanFilterOptions(),
    this.debugPubkey,
    this.debugDerivationPath,
    this.showDebugInfo = false,
    this.isAuthenticated = false,
  });

  /// Initial loading state.
  factory LoansState.initial() => const LoansState();

  /// Filter offers to only show Arkade collateral.
  List<LoanOffer> get arkadeOffers => offers
      .where((o) => o.collateralAsset == CollateralAsset.arkadeBtc)
      .toList();

  /// Whether there are any active filters.
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty || filterOptions.hasFilter;

  /// Filter contracts by search query and status filter.
  List<Contract> get filteredContracts {
    if (!hasActiveFilters) return contracts;

    return contracts.where((contract) {
      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        final lenderName = contract.lender.name.toLowerCase();
        final amount = contract.loanAmount.toStringAsFixed(2);
        final statusText = contract.statusText.toLowerCase();
        final matchesSearch = lenderName.contains(lowerQuery) ||
            amount.contains(lowerQuery) ||
            statusText.contains(lowerQuery);
        if (!matchesSearch) return false;
      }

      // Apply status filter
      if (filterOptions.hasFilter) {
        final status = contract.status;
        final expiryDate = DateTime.parse(contract.expiry);
        final isOverdue = DateTime.now().isAfter(expiryDate) &&
            status != ContractStatus.repaymentConfirmed &&
            status != ContractStatus.closed &&
            status != ContractStatus.closing &&
            status != ContractStatus.closingByClaim;

        bool matchesStatus = false;
        for (final filter in filterOptions.selectedStatuses) {
          switch (filter) {
            case 'Active':
              if (status == ContractStatus.principalGiven ||
                  status == ContractStatus.extended) {
                matchesStatus = true;
              }
              break;
            case 'Pending':
              if (status == ContractStatus.requested ||
                  status == ContractStatus.approved ||
                  status == ContractStatus.collateralSeen ||
                  status == ContractStatus.collateralConfirmed) {
                matchesStatus = true;
              }
              break;
            case 'Repayment Confirmed':
              if (status == ContractStatus.repaymentConfirmed) {
                matchesStatus = true;
              }
              break;
            case 'Closed':
              if (status == ContractStatus.closed ||
                  status == ContractStatus.closing ||
                  status == ContractStatus.closingByClaim) {
                matchesStatus = true;
              }
              break;
            case 'Overdue':
              if (isOverdue) {
                matchesStatus = true;
              }
              break;
          }
          if (matchesStatus) break;
        }
        if (!matchesStatus) return false;
      }

      return true;
    }).toList();
  }

  LoansState copyWith({
    bool? isLoading,
    bool? isRegistering,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<LoanOffer>? offers,
    List<Contract>? contracts,
    String? searchQuery,
    LoanFilterOptions? filterOptions,
    String? debugPubkey,
    String? debugDerivationPath,
    bool? showDebugInfo,
    bool? isAuthenticated,
  }) {
    return LoansState(
      isLoading: isLoading ?? this.isLoading,
      isRegistering: isRegistering ?? this.isRegistering,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      offers: offers ?? this.offers,
      contracts: contracts ?? this.contracts,
      searchQuery: searchQuery ?? this.searchQuery,
      filterOptions: filterOptions ?? this.filterOptions,
      debugPubkey: debugPubkey ?? this.debugPubkey,
      debugDerivationPath: debugDerivationPath ?? this.debugDerivationPath,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
