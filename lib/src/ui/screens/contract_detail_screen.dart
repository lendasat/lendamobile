import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart' show LendaSwapService;
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/ui/screens/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Screen to view contract details and perform actions.
class ContractDetailScreen extends StatefulWidget {
  final String contractId;

  const ContractDetailScreen({
    super.key,
    required this.contractId,
  });

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final LendasatService _lendasatService = LendasatService();
  final LendaSwapService _swapService = LendaSwapService();

  Contract? _contract;
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isRepaying = false;
  bool _isMarkingPaid = false;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contract = await _lendasatService.getContract(widget.contractId);
      if (mounted) {
        setState(() {
          _contract = contract;
          _isLoading = false;
        });

        // Start polling if contract is in a pending state
        _startPollingIfNeeded();
      }
    } catch (e) {
      logger.e('Error loading contract: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startPollingIfNeeded() {
    _pollTimer?.cancel();

    if (_contract != null && !_contract!.isClosed) {
      // Poll every 30 seconds for updates
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _refreshContract();
      });
    }
  }

  Future<void> _refreshContract() async {
    try {
      final contract = await _lendasatService.getContract(widget.contractId);
      if (mounted) {
        setState(() => _contract = contract);

        // Stop polling if contract is closed
        if (contract.isClosed) {
          _pollTimer?.cancel();
        }
      }
    } catch (e) {
      logger.e('Error refreshing contract: $e');
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cancelContract() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Contract'),
        content: const Text(
          'Are you sure you want to cancel this loan request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await _lendasatService.cancelContract(widget.contractId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contract cancelled'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e('Error cancelling contract: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _showClaimSheet() async {
    if (_contract == null) return;

    setState(() => _isActionLoading = true);

    try {
      if (_contract!.isArkCollateral) {
        // Ark collateral claim - no fee rate needed (offchain)
        final txid = await _lendasatService.claimArkCollateral(
          contractId: widget.contractId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collateral claimed! TXID: ${txid.substring(0, 16)}...'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _refreshContract();
        }
      } else {
        // Standard Bitcoin claim - need fee rate for on-chain tx
        final feeRate = await _showFeeRateDialog();
        if (feeRate == null) {
          setState(() => _isActionLoading = false);
          return;
        }

        final txid = await _lendasatService.claimCollateral(
          contractId: widget.contractId,
          feeRate: feeRate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collateral claimed! TXID: ${txid.substring(0, 16)}...'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _refreshContract();
        }
      }
    } catch (e) {
      logger.e('Error claiming collateral: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _showRecoverSheet() async {
    if (_contract == null) return;

    // Get fee rate first
    final feeRate = await _showFeeRateDialog();
    if (feeRate == null) return;

    setState(() => _isActionLoading = true);

    try {
      // Use automatic signing and broadcasting
      final txid = await _lendasatService.recoverCollateral(
        contractId: widget.contractId,
        feeRate: feeRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collateral recovered! TXID: ${txid.substring(0, 16)}...'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _refreshContract();
      }
    } catch (e) {
      logger.e('Error recovering collateral: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  /// Pay collateral for an approved contract that's awaiting deposit.
  Future<void> _payCollateral() async {
    if (_contract == null) return;

    // Verify contract is ready for collateral (use effectiveCollateralSats which has initialCollateralSats fallback)
    if (_contract!.contractAddress == null || _contract!.effectiveCollateralSats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract not ready for collateral yet. Please wait.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Confirm with user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay Collateral'),
        content: Text(
          'Send ${_contract!.effectiveCollateralBtc.toStringAsFixed(6)} BTC as collateral for this loan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    // Suppress payment notifications during collateral send
    PaymentOverlayService().startSuppression();

    try {
      final collateralSats = BigInt.from(_contract!.effectiveCollateralSats);
      final collateralAddress = _contract!.contractAddress!;

      logger.i('[Loan] Sending $collateralSats sats to $collateralAddress');

      final txid = await ark_api.send(
        address: collateralAddress,
        amountSats: collateralSats,
      );

      logger.i('[Loan] Collateral sent! TXID: $txid');

      // Track analytics
      await AnalyticsService().trackLoanTransaction(
        amountSats: _contract!.effectiveCollateralSats,
        type: 'borrow',
        loanId: _contract!.id,
        interestRate: _contract!.interestRate,
        durationDays: _contract!.durationDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collateral sent! Loan is being processed.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _refreshContract();
      }
    } catch (e) {
      logger.e('[Loan] Error sending collateral: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
      Future.delayed(const Duration(seconds: 5), () {
        PaymentOverlayService().stopSuppression();
      });
    }
  }

  /// Repay the loan using Lendaswap - swaps BTC to stablecoin and sends to repayment address.
  Future<void> _repayWithLendaswap() async {
    if (_contract == null || !_contract!.canRepayWithLendaswap) return;

    final targetToken = _contract!.repaymentSwapToken!;
    final repaymentAddress = _contract!.loanRepaymentAddress!;
    final amountToRepay = _contract!.balanceOutstanding;

    // Confirm with user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repay with Lendaswap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repay \$${amountToRepay.toStringAsFixed(2)} using Lendaswap?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'This will swap BTC from your wallet to ${targetToken.symbol} '
              'and send it to the lender\'s repayment address.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Powered by Lendaswap',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRepaying = true);
    PaymentOverlayService().startSuppression();

    try {
      // Initialize swap service if needed
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }

      // Check wallet balance
      final walletBalance = await ark_api.balance();
      final availableSats = walletBalance.offchain.totalSats;

      logger.i('[LoanRepay] Repaying \$${amountToRepay.toStringAsFixed(2)} to $repaymentAddress');

      // Create the swap - BTC to stablecoin, sent to repayment address
      final result = await _swapService.createSellBtcSwap(
        targetEvmAddress: repaymentAddress,
        targetAmountUsd: amountToRepay,
        targetToken: targetToken.tokenId,
        targetChain: targetToken.chainId,
      );

      logger.i('[LoanRepay] Swap created: ${result.swapId}, sending ${result.satsToSend} sats to ${result.arkadeHtlcAddress}');

      // Check if we have enough balance
      final satsToSend = BigInt.from(result.satsToSend);
      if (availableSats < satsToSend) {
        throw Exception(
          'Insufficient balance. Available: $availableSats sats, Required: ${result.satsToSend} sats',
        );
      }

      // Fund the swap by sending BTC to the HTLC address
      final fundingTxid = await ark_api.send(
        address: result.arkadeHtlcAddress,
        amountSats: satsToSend,
      );

      logger.i('[LoanRepay] Swap funded! TXID: $fundingTxid');

      // Track analytics - using loan transaction with repay type
      await AnalyticsService().trackLoanTransaction(
        amountSats: result.satsToSend,
        type: 'repay',
        loanId: _contract!.id,
        interestRate: _contract!.interestRate,
        durationDays: _contract!.durationDays,
      );

      if (mounted) {
        // Calculate BTC amount from sats for display
        final btcAmount = (result.satsToSend / 100000000).toStringAsFixed(8);

        // Navigate to swap processing screen to monitor the swap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SwapProcessingScreen(
              swapId: result.swapId,
              sourceToken: SwapToken.bitcoin,
              targetToken: targetToken,
              sourceAmount: btcAmount,
              targetAmount: amountToRepay.toStringAsFixed(2),
            ),
          ),
        ).then((_) {
          // Refresh contract status when returning
          _refreshContract();
        });
      }
    } catch (e) {
      logger.e('[LoanRepay] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repayment failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRepaying = false);
      }
      Future.delayed(const Duration(seconds: 5), () {
        PaymentOverlayService().stopSuppression();
      });
    }
  }

  /// Show dialog to mark an installment as already paid with transaction ID.
  Future<void> _showMarkAsPaidDialog() async {
    if (_contract == null) return;

    // Get unpaid installments
    final unpaidInstallments = _contract!.installments
        .where((i) =>
            i.status != InstallmentStatus.paid &&
            i.status != InstallmentStatus.confirmed)
        .toList();

    if (unpaidInstallments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All installments are already paid.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      return;
    }

    // Default to first unpaid installment
    Installment selectedInstallment = unpaidInstallments.first;
    final txidController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Enter the transaction ID of your payment to confirm repayment.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Installment selector (if multiple)
              if (unpaidInstallments.length > 1) ...[
                Text(
                  'Select Installment',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<Installment>(
                    value: selectedInstallment,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: unpaidInstallments.map((i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text(
                          '\$${i.totalPayment.toStringAsFixed(2)} - Due ${_formatDate(i.dueDate)}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedInstallment = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '\$${selectedInstallment.totalPayment.toStringAsFixed(2)} due ${_formatDate(selectedInstallment.dueDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Transaction ID input
              Text(
                'Transaction ID',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: txidController,
                decoration: const InputDecoration(
                  hintText: 'Enter transaction ID or hash',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                maxLines: 2,
              ),
            ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (txidController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a transaction ID'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isMarkingPaid = true);

    try {
      await _lendasatService.markInstallmentPaid(
        contractId: _contract!.id,
        installmentId: selectedInstallment.id,
        paymentTxid: txidController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment confirmed! Refreshing contract...'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _refreshContract();
      }
    } catch (e) {
      logger.e('Error marking installment paid: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingPaid = false);
      }
    }
  }

  Future<int?> _showFeeRateDialog() async {
    final controller = TextEditingController(text: '10');

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Fee Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter fee rate in sat/vB:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffix: Text('sat/vB'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final rate = int.tryParse(controller.text);
              if (rate != null && rate > 0) {
                Navigator.pop(context, rate);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      appBar: ArkAppBar(
        context: context,
        text: 'Loan Details',
        onTap: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadContract,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _contract == null
                  ? _buildNotFoundView()
                  : _buildContractDetails(),
    );
  }

  Widget _buildErrorView() {
    // Extract user-friendly error message
    String displayMessage = _errorMessage ?? 'Unknown error';
    if (displayMessage.contains('401 Unauthorized') || displayMessage.contains('Invalid token')) {
      displayMessage = 'Session expired. Please go back and try again.';
    } else if (displayMessage.contains('AnyhowException')) {
      // Clean up Rust error format
      final match = RegExp(r'AnyhowException\(([^)]+)').firstMatch(displayMessage);
      if (match != null) {
        displayMessage = match.group(1) ?? displayMessage;
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              'Error Loading Contract',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: 'Retry',
              buttonType: ButtonType.secondary,
              onTap: _loadContract,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          Text(
            'Contract Not Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetails() {
    return RefreshIndicator(
      onRefresh: _loadContract,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            _buildStatusHeader(),
            const SizedBox(height: AppTheme.cardPadding),

            // NOTE: Deposit card removed - collateral is now auto-sent from loan_offer_detail_screen

            // Loan details
            _buildLoanDetails(),
            const SizedBox(height: AppTheme.cardPadding),

            // Collateral details
            _buildCollateralDetails(),
            const SizedBox(height: AppTheme.cardPadding),

            // Repayment schedule (if active loan or has installments)
            if (_contract!.isActiveLoan || _contract!.installments.isNotEmpty) ...[
              _buildRepaymentSchedule(),
              const SizedBox(height: AppTheme.cardPadding),
            ],

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract ID row
          Row(
            children: [
              Text(
                'Contract',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const Spacer(),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _contract!.id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(_contract!.id, 'Contract ID'),
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
          // Loan amount and lender
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${_contract!.loanAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'from ${_contract!.lender.name}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar for active loans
          if (_contract!.isActiveLoan) ...[
            const SizedBox(height: AppTheme.cardPadding),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _contract!.repaymentProgress,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.successColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_contract!.repaymentProgress * 100).toStringAsFixed(0)}% repaid',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;

    if (_contract!.isClosed) {
      badgeColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    } else if (_contract!.hasIssue) {
      badgeColor = AppTheme.errorColor;
    } else if (_contract!.canClaim || _contract!.canRecover) {
      badgeColor = AppTheme.successColor;
    } else if (_contract!.isAwaitingDeposit) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _contract!.statusText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLoanDetails() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.cardPadding),
          _buildDetailRow('Principal', '\$${_contract!.loanAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Interest', '\$${_contract!.interest.toStringAsFixed(2)}'),
          _buildDetailRow(
            'Interest Rate',
            '${(_contract!.interestRate * 100).toStringAsFixed(2)}%',
          ),
          _buildDetailRow('Duration', '${_contract!.durationDays} days'),
          _buildDetailRow(
            'Total Repayment',
            '\$${_contract!.totalRepayment.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Outstanding',
            '\$${_contract!.remainingBalance.toStringAsFixed(2)}',
          ),
          _buildDetailRow('Expires', _formatDate(_contract!.expiry)),
        ],
      ),
    );
  }

  Widget _buildCollateralDetails() {
    // Use deposited amount if available, otherwise fall back to effective collateral
    final collateralBtc = _contract!.depositedBtc > 0
        ? _contract!.depositedBtc
        : _contract!.effectiveCollateralBtc;
    final collateralSats = collateralBtc * 100000000;

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collateral',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.cardPadding),
          _buildDetailRow(
            'Amount',
            '${collateralSats.toStringAsFixed(0)} sats',
          ),
          _buildDetailRow(
            '',
            '${collateralBtc.toStringAsFixed(8)} BTC',
          ),
          _buildDetailRow(
            'LTV',
            '${(_contract!.initialLtv * 100).toStringAsFixed(1)}%',
          ),
          _buildDetailRow(
            'Liquidation Price',
            '\$${_contract!.liquidationPrice.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Type',
            _contract!.isArkCollateral ? 'Arkade (Instant)' : 'On-chain',
          ),
          if (_contract!.contractAddress != null) ...[
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              'Contract Address',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _contract!.contractAddress!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _copyToClipboard(
                    _contract!.contractAddress!,
                    'Contract Address',
                  ),
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepaymentSchedule() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repayment Schedule',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Repayment summary for active loans
          if (_contract!.isActiveLoan) ...[
            _buildDetailRow(
              'Total Repayment',
              '\$${_contract!.totalRepayment.toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Amount Paid',
              '\$${(_contract!.totalRepayment - _contract!.balanceOutstanding).toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Outstanding',
              '\$${_contract!.balanceOutstanding.toStringAsFixed(2)}',
            ),
            // Show BTC repayment address for manual payments
            if (_contract!.btcLoanRepaymentAddress != null &&
                _contract!.btcLoanRepaymentAddress!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.elementSpacing),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BTC Repayment Address',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _contract!.btcLoanRepaymentAddress!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyToClipboard(
                            _contract!.btcLoanRepaymentAddress!,
                            'BTC Repayment Address',
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.copy,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.cardPadding),
            Divider(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
          ],

          // Installments list
          ..._contract!.installments.map((installment) => _buildInstallmentRow(installment)),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow(Installment installment) {
    final isPaid = installment.status == InstallmentStatus.paid ||
        installment.status == InstallmentStatus.confirmed;
    final isOverdue = installment.isOverdue;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      child: Row(
        children: [
          Icon(
            isPaid
                ? Icons.check_circle
                : isOverdue
                    ? Icons.warning
                    : Icons.schedule,
            size: 20,
            color: isPaid
                ? AppTheme.successColor
                : isOverdue
                    ? AppTheme.errorColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${installment.totalPayment.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      ),
                ),
                Text(
                  'Due: ${_formatDate(installment.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? AppTheme.errorColor
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          Text(
            installment.statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPaid
                      ? AppTheme.successColor
                      : isOverdue
                          ? AppTheme.errorColor
                          : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canCancel = _contract!.status == ContractStatus.requested;
    // Can pay collateral if approved and has collateral info (use effectiveCollateralSats for fallback)
    final canPayCollateral = _contract!.status == ContractStatus.approved &&
        _contract!.contractAddress != null &&
        _contract!.effectiveCollateralSats > 0;
    // Full width for buttons
    final buttonWidth = MediaQuery.of(context).size.width - AppTheme.cardPadding * 2;

    return Column(
      children: [
        // Pay Collateral button for approved contracts awaiting deposit
        if (canPayCollateral)
          LongButtonWidget(
            title: _isActionLoading
                ? 'Sending...'
                : 'Pay Collateral (${_contract!.effectiveCollateralBtc.toStringAsFixed(6)} BTC)',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _payCollateral,
          ),
        // Repay with Lendaswap button for active loans
        if (_contract!.canRepayWithLendaswap) ...[
          if (canPayCollateral) const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isRepaying
                ? 'Processing...'
                : 'Repay \$${_contract!.balanceOutstanding.toStringAsFixed(2)} with Lendaswap',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            buttonGradient: const LinearGradient(
              colors: [Color(0xFF8247E5), Color(0xFF6C3DC1)], // Lendaswap purple gradient
            ),
            onTap: _isRepaying || _isActionLoading ? null : _repayWithLendaswap,
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Powered by Lendaswap',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ),
        ],
        // "I Already Paid" button for active loans with outstanding balance
        if (_contract!.isActiveLoan && _contract!.balanceOutstanding > 0) ...[
          const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isMarkingPaid ? 'Confirming...' : 'I Already Paid',
            buttonType: ButtonType.secondary,
            customWidth: buttonWidth,
            onTap: _isMarkingPaid || _isActionLoading || _isRepaying
                ? null
                : _showMarkAsPaidDialog,
          ),
        ],
        if (_contract!.canClaim) ...[
          if (canPayCollateral || _contract!.canRepayWithLendaswap) const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isActionLoading ? 'Loading...' : 'Claim Collateral',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _showClaimSheet,
          ),
        ],
        if (_contract!.canRecover) ...[
          const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isActionLoading ? 'Loading...' : 'Recover Collateral',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _showRecoverSheet,
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isActionLoading ? 'Loading...' : 'Cancel Request',
            buttonType: ButtonType.secondary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _cancelContract,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {String? copyValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyValue != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(copyValue, label),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

}
