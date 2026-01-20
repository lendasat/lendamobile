import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'contract_detail_config.dart';
import 'contract_detail_state.dart';

/// Result of a swap repayment operation.
class RepaymentResult {
  final String swapId;
  final int satsToSend;
  final String arkadeHtlcAddress;
  final String btcAmount;
  final SwapToken targetToken;
  final double targetAmount;
  final String? installmentId;

  const RepaymentResult({
    required this.swapId,
    required this.satsToSend,
    required this.arkadeHtlcAddress,
    required this.btcAmount,
    required this.targetToken,
    required this.targetAmount,
    this.installmentId,
  });
}

/// Controller for contract detail screen business logic.
class ContractDetailController extends ChangeNotifier {
  final String contractId;
  final LendasatService _lendasatService;
  final LendaSwapService _swapService;

  ContractDetailState _state = ContractDetailState.initial();
  Timer? _pollTimer;

  ContractDetailController({
    required this.contractId,
    LendasatService? lendasatService,
    LendaSwapService? swapService,
  })  : _lendasatService = lendasatService ?? LendasatService(),
        _swapService = swapService ?? LendaSwapService();

  /// Current state.
  ContractDetailState get state => _state;

  /// Initialize controller and load data.
  Future<void> initialize() async {
    await Future.wait([
      loadContract(),
      _loadBitcoinPrice(),
    ]);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Load contract data and wallet balance.
  Future<void> loadContract() async {
    _updateState(_state.copyWith(isLoading: true, clearError: true));

    try {
      final contract = await _lendasatService.getContract(contractId);
      final balance = await _fetchWalletBalance();

      _updateState(_state.copyWith(
        contract: contract,
        isLoading: false,
        availableBalanceSats: balance,
      ));

      _startPollingIfNeeded();
    } catch (e) {
      logger.e('Error loading contract: $e');
      _updateState(_state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _loadBitcoinPrice() async {
    try {
      final priceData = await fetchBitcoinPriceData(TimeRange.day);
      if (priceData.isNotEmpty) {
        _updateState(_state.copyWith(bitcoinPriceData: priceData));
      }
    } catch (e) {
      // Silently fail - will use fallback
    }
  }

  Future<BigInt> _fetchWalletBalance() async {
    BigInt balance = BigInt.zero;
    try {
      // Use cached balance first for instant display
      final cachedBalance = await SettingsService().getCachedBalance();
      if (cachedBalance != null) {
        balance = BigInt.from(
            (cachedBalance.total * BitcoinConstants.satsPerBtc).round());
      }
      // Also fetch fresh balance for accuracy
      final walletBalance = await ark_api.balance();
      balance = walletBalance.offchain.totalSats;
    } catch (e) {
      logger.w('Error fetching balance for collateral check: $e');
    }
    return balance;
  }

  void _startPollingIfNeeded() {
    _pollTimer?.cancel();

    if (_state.contract != null && !_state.contract!.isClosed) {
      _pollTimer = Timer.periodic(
        Duration(seconds: ContractDetailConfig.pollingIntervalSeconds),
        (_) => _refreshContract(),
      );
    }
  }

  Future<void> _refreshContract() async {
    try {
      final contract = await _lendasatService.getContract(contractId);

      // Also refresh balance if contract is awaiting deposit
      BigInt? balance;
      if (contract.status == ContractStatus.approved) {
        balance = await _fetchWalletBalance();
      }

      _updateState(_state.copyWith(
        contract: contract,
        availableBalanceSats: balance,
      ));

      // Stop polling if contract is closed
      if (contract.isClosed) {
        _pollTimer?.cancel();
      }
    } catch (e) {
      logger.e('Error refreshing contract: $e');
    }
  }

  /// Copy text to clipboard with feedback.
  Future<void> copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    OverlayService().showOverlay('$label copied to clipboard');
  }

  /// Copy contract address with visual feedback.
  void copyContractAddress() {
    if (_state.contract?.contractAddress == null) return;
    Clipboard.setData(ClipboardData(text: _state.contract!.contractAddress!));
    HapticFeedback.lightImpact();

    _updateState(_state.copyWith(showAddressCopied: true));

    Future.delayed(
      Duration(seconds: ContractDetailConfig.copyFeedbackSeconds),
      () => _updateState(_state.copyWith(showAddressCopied: false)),
    );
  }

  /// Copy BTC repayment address with visual feedback.
  void copyBtcAddress() {
    if (_state.contract?.btcLoanRepaymentAddress == null) return;
    Clipboard.setData(
        ClipboardData(text: _state.contract!.btcLoanRepaymentAddress!));
    HapticFeedback.lightImpact();

    _updateState(_state.copyWith(showBtcAddressCopied: true));

    Future.delayed(
      Duration(seconds: ContractDetailConfig.copyFeedbackSeconds),
      () => _updateState(_state.copyWith(showBtcAddressCopied: false)),
    );
  }

  /// Open Discord support channel.
  Future<void> openSupportDiscord() async {
    final uri = Uri.parse(ContractDetailConfig.discordSupportUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        OverlayService().showError('Could not open Discord');
      }
    } catch (e) {
      logger.e('Error opening Discord: $e');
      OverlayService().showError('Could not open Discord');
    }
  }

  /// Cancel the contract.
  Future<void> cancelContract() async {
    _updateState(_state.copyWith(isActionLoading: true));

    try {
      await _lendasatService.cancelContract(contractId);
      OverlayService().showSuccess('Contract cancelled');
    } catch (e) {
      logger.e('Error cancelling contract: $e');
      OverlayService().showError('Failed to cancel: ${e.toString()}');
      rethrow;
    } finally {
      _updateState(_state.copyWith(isActionLoading: false));
    }
  }

  /// Claim collateral for a completed/defaulted contract.
  Future<void> claimCollateral() async {
    if (_state.contract == null) return;

    _updateState(_state.copyWith(isActionLoading: true));

    try {
      final txid = await _lendasatService.claimArkCollateral(
        contractId: contractId,
      );
      OverlayService()
          .showSuccess('Collateral claimed! TXID: ${txid.substring(0, 16)}...');
      await _refreshContract();
    } catch (e) {
      logger.e('Error claiming collateral: $e');
      OverlayService().showError('Error: ${e.toString()}');
    } finally {
      _updateState(_state.copyWith(isActionLoading: false));
    }
  }

  /// Recover collateral from a cancelled/expired contract.
  Future<void> recoverCollateral() async {
    if (_state.contract == null) return;

    _updateState(_state.copyWith(isActionLoading: true));

    try {
      final txid = await _lendasatService.claimArkCollateral(
        contractId: contractId,
      );
      OverlayService().showSuccess(
          'Collateral recovered! TXID: ${txid.substring(0, 16)}...');
      await _refreshContract();
    } catch (e) {
      logger.e('Error recovering collateral: $e');
      OverlayService().showError('Error: ${e.toString()}');
    } finally {
      _updateState(_state.copyWith(isActionLoading: false));
    }
  }

  /// Pay collateral for an approved contract.
  Future<void> payCollateral() async {
    if (_state.contract == null) return;

    // Verify contract is ready for collateral
    if (_state.contract!.contractAddress == null ||
        _state.contract!.effectiveCollateralSats <= 0) {
      OverlayService()
          .showError('Contract not ready for collateral yet. Please wait.');
      return;
    }

    _updateState(_state.copyWith(isActionLoading: true));
    PaymentOverlayService().startSuppression();

    try {
      final collateralSats =
          BigInt.from(_state.contract!.effectiveCollateralSats);
      final collateralAddress = _state.contract!.contractAddress!;

      logger.i('[Loan] Sending $collateralSats sats to $collateralAddress');

      final txid = await ark_api.send(
        address: collateralAddress,
        amountSats: collateralSats,
      );

      logger.i('[Loan] Collateral sent! TXID: $txid');

      // Track analytics
      await AnalyticsService().trackLoanTransaction(
        amountSats: _state.contract!.effectiveCollateralSats,
        type: 'borrow',
        loanId: _state.contract!.id,
        interestRate: _state.contract!.interestRate,
        durationDays: _state.contract!.durationDays,
      );

      OverlayService().showSuccess('Collateral sent! Loan is being processed.');
      await _refreshContract();
    } catch (e) {
      logger.e('[Loan] Error sending collateral: $e');
      OverlayService().showError('Failed: ${e.toString()}');
    } finally {
      _updateState(_state.copyWith(isActionLoading: false));
      Future.delayed(
        Duration(seconds: ContractDetailConfig.paymentSuppressionDelaySeconds),
        () => PaymentOverlayService().stopSuppression(),
      );
    }
  }

  /// Repay the loan using Lendaswap.
  /// Returns swap details for navigation, or null if failed.
  Future<RepaymentResult?> repayWithLendaswap() async {
    if (_state.contract == null || !_state.contract!.canRepayWithLendaswap) {
      return null;
    }

    final targetToken = _state.contract!.repaymentSwapToken!;
    final repaymentAddress = _state.contract!.loanRepaymentAddress!;
    final amountToRepay = _state.contract!.balanceOutstanding;

    _updateState(_state.copyWith(isRepaying: true));
    PaymentOverlayService().startSuppression();

    try {
      // Initialize swap service if needed
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }

      // Check wallet balance
      final walletBalance = await ark_api.balance();
      final availableSats = walletBalance.offchain.totalSats;

      logger.i(
          '[LoanRepay] Repaying \$${amountToRepay.toStringAsFixed(2)} to $repaymentAddress');

      // Create the swap
      final result = await _swapService.createSellBtcSwap(
        targetEvmAddress: repaymentAddress,
        targetAmount: amountToRepay,
        targetToken: targetToken.tokenId,
        targetChain: targetToken.chainId,
      );

      logger.i(
          '[LoanRepay] Swap created: ${result.swapId}, sending ${result.satsToSend} sats to ${result.arkadeHtlcAddress}');

      // Check if we have enough balance
      final satsToSend = BigInt.from(result.satsToSend);
      if (availableSats < satsToSend) {
        throw Exception(
          'Insufficient balance. Available: $availableSats sats, Required: ${result.satsToSend} sats',
        );
      }

      // Fund the swap
      final fundingTxid = await ark_api.send(
        address: result.arkadeHtlcAddress,
        amountSats: satsToSend,
      );

      logger.i('[LoanRepay] Swap funded! TXID: $fundingTxid');

      // Track analytics
      await AnalyticsService().trackLoanTransaction(
        amountSats: result.satsToSend,
        type: 'repay',
        loanId: _state.contract!.id,
        interestRate: _state.contract!.interestRate,
        durationDays: _state.contract!.durationDays,
      );

      // Get first unpaid installment
      final unpaidInstallments = _state.contract!.installments
          .where((i) =>
              i.status != InstallmentStatus.paid &&
              i.status != InstallmentStatus.confirmed)
          .toList();
      final installmentId =
          unpaidInstallments.isNotEmpty ? unpaidInstallments.first.id : null;

      final btcAmount =
          (result.satsToSend / BitcoinConstants.satsPerBtc).toStringAsFixed(8);

      return RepaymentResult(
        swapId: result.swapId,
        satsToSend: result.satsToSend,
        arkadeHtlcAddress: result.arkadeHtlcAddress,
        btcAmount: btcAmount,
        targetToken: targetToken,
        targetAmount: amountToRepay,
        installmentId: installmentId,
      );
    } catch (e) {
      logger.e('[LoanRepay] Error: $e');
      OverlayService().showError('Repayment failed: ${e.toString()}');
      return null;
    } finally {
      _updateState(_state.copyWith(isRepaying: false));
      Future.delayed(
        Duration(seconds: ContractDetailConfig.paymentSuppressionDelaySeconds),
        () => PaymentOverlayService().stopSuppression(),
      );
    }
  }

  /// Mark an installment as paid.
  Future<void> markInstallmentPaid({
    required String installmentId,
    required String paymentTxid,
  }) async {
    if (_state.contract == null) return;

    _updateState(_state.copyWith(isMarkingPaid: true));

    try {
      await _lendasatService.markInstallmentPaid(
        contractId: _state.contract!.id,
        installmentId: installmentId,
        paymentTxid: paymentTxid,
      );

      OverlayService().showSuccess('Payment confirmed! Refreshing contract...');
      await _refreshContract();
    } catch (e) {
      logger.e('Error marking installment paid: $e');
      OverlayService().showError('Failed: ${e.toString()}');
    } finally {
      _updateState(_state.copyWith(isMarkingPaid: false));
    }
  }

  /// Refresh contract after returning from swap screen.
  Future<void> refreshAfterSwap() async {
    await _refreshContract();
  }

  /// Get unpaid installments for marking as paid.
  List<Installment> get unpaidInstallments {
    if (_state.contract == null) return [];
    return _state.contract!.installments
        .where((i) =>
            i.status != InstallmentStatus.paid &&
            i.status != InstallmentStatus.confirmed)
        .toList();
  }

  /// Format a date string for display.
  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Get user-friendly error message.
  String? get displayErrorMessage {
    if (_state.errorMessage == null) return null;

    String message = _state.errorMessage!;
    if (message.contains('401 Unauthorized') ||
        message.contains('Invalid token')) {
      return 'Session expired. Please go back and try again.';
    } else if (message.contains('AnyhowException')) {
      final match = RegExp(r'AnyhowException\(([^)]+)').firstMatch(message);
      if (match != null) {
        return match.group(1) ?? message;
      }
    }
    return message;
  }

  void _updateState(ContractDetailState newState) {
    _state = newState;
    notifyListeners();
  }
}
