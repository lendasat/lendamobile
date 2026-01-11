import 'dart:async';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart'
    show LendaSwapService;
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _showAddressCopied = false;
  BigInt _availableBalanceSats = BigInt.zero;

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

      // Fetch wallet balance for collateral check
      // Use cached balance first for instant display, then fetch fresh balance
      try {
        final cachedBalance = await SettingsService().getCachedBalance();
        if (cachedBalance != null) {
          _availableBalanceSats = BigInt.from(
              (cachedBalance.total * BitcoinConstants.satsPerBtc).round());
        }
        // Also fetch fresh balance for accuracy
        final walletBalance = await ark_api.balance();
        _availableBalanceSats = walletBalance.offchain.totalSats;
      } catch (e) {
        logger.w('Error fetching balance for collateral check: $e');
        // Keep cached balance if fresh fetch fails
        if (_availableBalanceSats == BigInt.zero) {
          _availableBalanceSats = BigInt.zero;
        }
      }

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
      // Poll every 3 seconds for updates (matches iframe implementation)
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _refreshContract();
      });
    }
  }

  Future<void> _refreshContract() async {
    try {
      final contract = await _lendasatService.getContract(widget.contractId);

      // Also refresh balance if contract is awaiting deposit
      if (contract.status == ContractStatus.approved) {
        try {
          // Try cached balance first, then fresh
          final cachedBalance = await SettingsService().getCachedBalance();
          if (cachedBalance != null) {
            _availableBalanceSats = BigInt.from(
                (cachedBalance.total * BitcoinConstants.satsPerBtc).round());
          }
          final walletBalance = await ark_api.balance();
          _availableBalanceSats = walletBalance.offchain.totalSats;
        } catch (e) {
          // Ignore balance fetch errors during refresh
        }
      }

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
      OverlayService().showOverlay('$label copied to clipboard');
    }
  }

  void _copyContractAddress() {
    if (_contract?.contractAddress == null) return;
    Clipboard.setData(ClipboardData(text: _contract!.contractAddress!));
    HapticFeedback.lightImpact();

    setState(() {
      _showAddressCopied = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAddressCopied = false;
        });
      }
    });
  }

  Future<void> _openSupportDiscord() async {
    final uri = Uri.parse('https://discord.com/invite/a5MP7yZDpQ');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          OverlayService().showError('Could not open Discord');
        }
      }
    } catch (e) {
      logger.e('Error opening Discord: $e');
      if (mounted) {
        OverlayService().showError('Could not open Discord');
      }
    }
  }

  Future<void> _cancelContract() async {
    await arkBottomSheet(
      context: context,
      child: _ConfirmationSheet(
        title: AppLocalizations.of(context)?.cancel ?? 'Cancel',
        message:
            'Are you sure you want to cancel this loan request? This action cannot be undone.',
        confirmText: 'Cancel Request',
        confirmColor: AppTheme.errorColor,
        cancelText: 'Keep',
        onConfirm: () async {
          Navigator.pop(context);
          setState(() => _isActionLoading = true);

          try {
            await _lendasatService.cancelContract(widget.contractId);
            if (mounted) {
              OverlayService().showSuccess('Contract cancelled');
              Navigator.pop(context);
            }
          } catch (e) {
            logger.e('Error cancelling contract: $e');
            if (mounted) {
              OverlayService().showError('Failed to cancel: ${e.toString()}');
            }
          } finally {
            if (mounted) {
              setState(() => _isActionLoading = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _showClaimSheet() async {
    if (_contract == null) return;

    setState(() => _isActionLoading = true);

    try {
      // All collateral is Ark-based (offchain) - no fee rate needed
      final txid = await _lendasatService.claimArkCollateral(
        contractId: widget.contractId,
      );

      if (mounted) {
        OverlayService().showSuccess(
            'Collateral claimed! TXID: ${txid.substring(0, 16)}...');
        await _refreshContract();
      }
    } catch (e) {
      logger.e('Error claiming collateral: $e');
      if (mounted) {
        OverlayService().showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _showRecoverSheet() async {
    if (_contract == null) return;

    setState(() => _isActionLoading = true);

    try {
      // All collateral is Ark-based (offchain) - uses same claim flow
      // claimArkCollateral handles both regular claims and recovery via settlement
      final txid = await _lendasatService.claimArkCollateral(
        contractId: widget.contractId,
      );

      if (mounted) {
        OverlayService().showSuccess(
            'Collateral recovered! TXID: ${txid.substring(0, 16)}...');
        await _refreshContract();
      }
    } catch (e) {
      logger.e('Error recovering collateral: $e');
      if (mounted) {
        OverlayService().showError('Error: ${e.toString()}');
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
    if (_contract!.contractAddress == null ||
        _contract!.effectiveCollateralSats <= 0) {
      OverlayService()
          .showError('Contract not ready for collateral yet. Please wait.');
      return;
    }

    await arkBottomSheet(
      context: context,
      child: _ConfirmationSheet(
        title: 'Pay Collateral',
        message:
            'Send ${_contract!.effectiveCollateralBtc.toStringAsFixed(6)} BTC as collateral for this loan?',
        confirmText: 'Pay',
        cancelText: 'Cancel',
        onConfirm: () async {
          Navigator.pop(context);
          setState(() => _isActionLoading = true);

          // Suppress payment notifications during collateral send
          PaymentOverlayService().startSuppression();

          try {
            final collateralSats =
                BigInt.from(_contract!.effectiveCollateralSats);
            final collateralAddress = _contract!.contractAddress!;

            logger
                .i('[Loan] Sending $collateralSats sats to $collateralAddress');

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
              OverlayService()
                  .showSuccess('Collateral sent! Loan is being processed.');
              await _refreshContract();
            }
          } catch (e) {
            logger.e('[Loan] Error sending collateral: $e');
            if (mounted) {
              OverlayService().showError('Failed: ${e.toString()}');
            }
          } finally {
            if (mounted) {
              setState(() => _isActionLoading = false);
            }
            Future.delayed(const Duration(seconds: 5), () {
              PaymentOverlayService().stopSuppression();
            });
          }
        },
      ),
    );
  }

  /// Repay the loan using Lendaswap - swaps BTC to stablecoin and sends to repayment address.
  Future<void> _repayWithLendaswap() async {
    if (_contract == null || !_contract!.canRepayWithLendaswap) return;

    final targetToken = _contract!.repaymentSwapToken!;
    final repaymentAddress = _contract!.loanRepaymentAddress!;
    final amountToRepay = _contract!.balanceOutstanding;

    await arkBottomSheet(
      context: context,
      child: _RepayConfirmationSheet(
        amountToRepay: amountToRepay,
        targetTokenSymbol: targetToken.symbol,
        onConfirm: () async {
          Navigator.pop(context);
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

            logger.i(
                '[LoanRepay] Repaying \$${amountToRepay.toStringAsFixed(2)} to $repaymentAddress');

            // Create the swap - BTC to stablecoin, sent to repayment address
            // For loan repayment, amount is in USD which equals token amount for stablecoins
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
              final btcAmount =
                  (result.satsToSend / BitcoinConstants.satsPerBtc)
                      .toStringAsFixed(8);

              // Get the first unpaid installment for marking as paid after swap
              final unpaidInstallments = _contract!.installments
                  .where((i) =>
                      i.status != InstallmentStatus.paid &&
                      i.status != InstallmentStatus.confirmed)
                  .toList();
              final installmentId = unpaidInstallments.isNotEmpty
                  ? unpaidInstallments.first.id
                  : null;

              // Navigate to swap processing screen to monitor the swap
              // Pass loan info so it can automatically mark payment when swap completes
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SwapProcessingScreen(
                    swapId: result.swapId,
                    sourceToken: SwapToken.bitcoin,
                    targetToken: targetToken,
                    sourceAmount: btcAmount,
                    targetAmount: amountToRepay.toStringAsFixed(2),
                    loanContractId: _contract!.id,
                    loanInstallmentId: installmentId,
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
              OverlayService().showError('Repayment failed: ${e.toString()}');
            }
          } finally {
            if (mounted) {
              setState(() => _isRepaying = false);
            }
            Future.delayed(const Duration(seconds: 5), () {
              PaymentOverlayService().stopSuppression();
            });
          }
        },
      ),
    );
  }

  /// Show bottom sheet to mark an installment as already paid with transaction ID.
  Future<void> _showMarkAsPaidDialog() async {
    if (_contract == null) return;

    // Get unpaid installments
    final unpaidInstallments = _contract!.installments
        .where((i) =>
            i.status != InstallmentStatus.paid &&
            i.status != InstallmentStatus.confirmed)
        .toList();

    if (unpaidInstallments.isEmpty) {
      OverlayService().showSuccess('All installments are already paid.');
      return;
    }

    await arkBottomSheet(
      context: context,
      child: _MarkAsPaidSheet(
        unpaidInstallments: unpaidInstallments,
        formatDate: _formatDate,
        onConfirm: (installment, txid) async {
          Navigator.pop(context);
          setState(() => _isMarkingPaid = true);

          try {
            await _lendasatService.markInstallmentPaid(
              contractId: _contract!.id,
              installmentId: installment.id,
              paymentTxid: txid,
            );

            if (mounted) {
              OverlayService()
                  .showSuccess('Payment confirmed! Refreshing contract...');
              await _refreshContract();
            }
          } catch (e) {
            logger.e('Error marking installment paid: $e');
            if (mounted) {
              OverlayService().showError('Failed: ${e.toString()}');
            }
          } finally {
            if (mounted) {
              setState(() => _isMarkingPaid = false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: 'Contract Details',
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
    if (displayMessage.contains('401 Unauthorized') ||
        displayMessage.contains('Invalid token')) {
      displayMessage = 'Session expired. Please go back and try again.';
    } else if (displayMessage.contains('AnyhowException')) {
      // Clean up Rust error format
      final match =
          RegExp(r'AnyhowException\(([^)]+)').firstMatch(displayMessage);
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
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.errorColor),
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
              title: AppLocalizations.of(context)?.retry ?? 'Retry',
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
        padding: const EdgeInsets.only(
          top: AppTheme.cardPadding * 3,
          left: AppTheme.cardPadding,
          right: AppTheme.cardPadding,
          bottom: AppTheme.cardPadding,
        ),
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
            if (_contract!.isActiveLoan ||
                _contract!.installments.isNotEmpty) ...[
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusBadgeColor();

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract ID row
          Row(
            children: [
              GestureDetector(
                onTap: () => _copyToClipboard(_contract!.id, 'Contract ID'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ID: ${_contract!.id.substring(0, 8).toUpperCase()}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.copy,
                        size: 14,
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildStatusBadge(statusColor)),
            ],
          ),
          const SizedBox(height: 20),
          // Loan amount and lender
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOAN AMOUNT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_contract!.loanAmount.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LENDER',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _contract!.lender.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // Progress bar for active loans
          if (_contract!.isActiveLoan) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REPAYMENT PROGRESS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                ),
                Text(
                  '${(_contract!.repaymentProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _contract!.repaymentProgress,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Text(
          _contract!.statusText.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Color _getStatusBadgeColor() {
    if (_contract!.isClosed) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    } else if (_contract!.hasIssue) {
      return AppTheme.errorColor;
    } else if (_contract!.canClaim || _contract!.canRecover) {
      return AppTheme.successColor;
    } else if (_contract!.isAwaitingDeposit) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildLoanDetails() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded,
                  size: 18, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Loan Details',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
              'PRINCIPAL', '\$${_contract!.loanAmount.toStringAsFixed(2)}'),
          _buildDetailRow(
              'INTEREST', '\$${_contract!.interest.toStringAsFixed(2)}'),
          _buildDetailRow(
            'INTEREST RATE',
            '${(_contract!.interestRate * 100).toStringAsFixed(2)}% APY',
          ),
          _buildDetailRow('DURATION', '${_contract!.durationDays} days'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          ),
          _buildDetailRow(
            'TOTAL REPAYMENT',
            '\$${_contract!.totalRepayment.toStringAsFixed(2)}',
            isBold: true,
          ),
          _buildDetailRow(
            'EXPIRES',
            _formatDate(_contract!.expiry),
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralDetails() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final collateralBtc = _contract!.depositedBtc > 0
        ? _contract!.depositedBtc
        : _contract!.effectiveCollateralBtc;
    final collateralSats = collateralBtc * BitcoinConstants.satsPerBtc;

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded,
                  size: 18, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Collateral Info',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'AMOUNT',
            '${collateralSats.toStringAsFixed(0)} sats',
            subtext: '${collateralBtc.toStringAsFixed(8)} BTC',
          ),
          _buildDetailRow(
            'INITIAL LTV',
            '${(_contract!.initialLtv * 100).toStringAsFixed(1)}%',
          ),
          _buildDetailRow(
            'LIQUIDATION PRICE',
            '\$${_contract!.liquidationPrice.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'NETWORK TYPE',
            _contract!.isArkCollateral ? 'Arkade (Instant)' : 'On-chain',
          ),
          if (_contract!.contractAddress != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _copyContractAddress,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTRACT ADDRESS',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isDarkMode
                                      ? AppTheme.white60
                                      : AppTheme.black60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _contract!.contractAddress!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: isDarkMode
                                  ? AppTheme.white90
                                  : AppTheme.black90,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _showAddressCopied
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check,
                                color: AppTheme.successColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copied',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepaymentSchedule() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded,
                  size: 18, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Repayment Schedule',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_contract!.isActiveLoan) ...[
            _buildDetailRow('TOTAL REPAYMENT',
                '\$${_contract!.totalRepayment.toStringAsFixed(2)}'),
            _buildDetailRow(
              'REMAINING BALANCE',
              '\$${_contract!.balanceOutstanding.toStringAsFixed(2)}',
              isBold: true,
            ),
            if (_contract!.btcLoanRepaymentAddress != null &&
                _contract!.btcLoanRepaymentAddress!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _copyToClipboard(
                    _contract!.btcLoanRepaymentAddress!, 'BTC Address'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.colorBitcoin.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_bitcoin_rounded,
                          size: 16, color: AppTheme.colorBitcoin),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BTC REPAYMENT ADDRESS',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.colorBitcoin
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              _contract!.btcLoanRepaymentAddress!,
                              style: const TextStyle(
                                  fontSize: 10, fontFamily: 'monospace'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.copy_rounded,
                          size: 14,
                          color: AppTheme.colorBitcoin.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
          ],
          ..._contract!.installments
              .map((installment) => _buildInstallmentRow(installment)),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow(Installment installment) {
    final isPaid = installment.status == InstallmentStatus.paid ||
        installment.status == InstallmentStatus.confirmed;
    final isOverdue = installment.isOverdue;
    final color = isPaid
        ? AppTheme.successColor
        : (isOverdue
            ? AppTheme.errorColor
            : Theme.of(context).colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid
                  ? Icons.check_rounded
                  : (isOverdue
                      ? Icons.priority_high_rounded
                      : Icons.pending_rounded),
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${installment.totalPayment.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      ),
                ),
                Text(
                  isPaid
                      ? 'Paid on ${_formatDate(installment.dueDate)}'
                      : 'Due ${_formatDate(installment.dueDate)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              installment.statusText.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canCancel = _contract!.status == ContractStatus.requested;
    final canPayCollateral = _contract!.status == ContractStatus.approved &&
        _contract!.contractAddress != null &&
        _contract!.effectiveCollateralSats > 0;
    final buttonWidth =
        MediaQuery.of(context).size.width - AppTheme.cardPadding * 2;
    final isPayingCollateral = _isActionLoading;

    // Check if user has enough balance for collateral
    final requiredSats = BigInt.from(_contract!.effectiveCollateralSats);
    final hasInsufficientBalance =
        canPayCollateral && _availableBalanceSats < requiredSats;

    return Column(
      children: [
        if (canPayCollateral)
          LongButtonWidget(
            title: isPayingCollateral
                ? 'ADDING COLLATERAL...'
                : hasInsufficientBalance
                    ? 'BALANCE TOO LOW'
                    : 'PAY COLLATERAL',
            buttonType:
                hasInsufficientBalance ? ButtonType.secondary : ButtonType.primary,
            customWidth: buttonWidth,
            isLoading: isPayingCollateral,
            onTap:
                isPayingCollateral || hasInsufficientBalance ? null : _payCollateral,
          ),
        if (hasInsufficientBalance)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.elementSpacing),
            child: Text(
              'You need ${(_contract!.effectiveCollateralSats / 100000000).toStringAsFixed(8)} BTC to fund this contract',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        if (_contract!.canRepayWithLendaswap) ...[
          if (canPayCollateral) const SizedBox(height: 12),
          LongButtonWidget(
            title: _isRepaying ? 'SWAPPING...' : 'REPAY',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            buttonGradient: const LinearGradient(
              colors: [Color(0xFF8247E5), Color(0xFF6C3DC1)],
            ),
            onTap: _isRepaying || _isActionLoading ? null : _repayWithLendaswap,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on_rounded,
                  size: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                'Powered by Lendaswap',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ],
        // Show "I already paid" only if loan is active AND repayment not already sent
        if (_contract!.isActiveLoan &&
            _contract!.balanceOutstanding > 0 &&
            !_contract!.isAwaitingRepaymentConfirmation) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: _isMarkingPaid ? 'CONFIRMING...' : 'I ALREADY PAID',
            buttonType: ButtonType.secondary,
            customWidth: buttonWidth,
            onTap: _isMarkingPaid || _isActionLoading || _isRepaying
                ? null
                : _showMarkAsPaidDialog,
          ),
        ],
        // Show waiting message when repayment is sent but not yet confirmed
        if (_contract!.isAwaitingRepaymentConfirmation) ...[
          const SizedBox(height: 12),
          Container(
            width: buttonWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.successColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Repayment sent! Waiting for lender confirmation...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'If you entered the wrong transaction ID, contact support to update it.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'CONTACT SUPPORT',
            buttonType: ButtonType.secondary,
            customWidth: buttonWidth,
            onTap: _openSupportDiscord,
          ),
        ],
        if (_contract!.canClaim) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'CLAIM COLLATERAL',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _showClaimSheet,
          ),
        ],
        if (_contract!.canRecover) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'RECOVER COLLATERAL',
            buttonType: ButtonType.primary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _showRecoverSheet,
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'CANCEL REQUEST',
            buttonType: ButtonType.secondary,
            customWidth: buttonWidth,
            onTap: _isActionLoading ? null : _cancelContract,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {String? subtext, bool isBold = false, bool highlight = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 9,
                ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                      color: highlight ? AppTheme.colorBitcoin : null,
                    ),
              ),
              if (subtext != null)
                Text(
                  subtext,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        fontSize: 10,
                      ),
                ),
            ],
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

/// Bottom sheet for marking an installment as paid with transaction ID.
class _MarkAsPaidSheet extends StatefulWidget {
  final List<Installment> unpaidInstallments;
  final String Function(String) formatDate;
  final Future<void> Function(Installment installment, String txid) onConfirm;

  const _MarkAsPaidSheet({
    required this.unpaidInstallments,
    required this.formatDate,
    required this.onConfirm,
  });

  @override
  State<_MarkAsPaidSheet> createState() => _MarkAsPaidSheetState();
}

class _MarkAsPaidSheetState extends State<_MarkAsPaidSheet> {
  late Installment _selectedInstallment;
  final TextEditingController _txidController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _selectedInstallment = widget.unpaidInstallments.first;
  }

  @override
  void dispose() {
    _txidController.dispose();
    super.dispose();
  }

  void _onTxidChanged(String value) {
    setState(() {
      _isValid = value.trim().isNotEmpty;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _txidController.text = data!.text!.trim();
      _onTxidChanged(_txidController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Confirm Payment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Info text
          Text(
            'Enter the transaction ID of your payment to confirm repayment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Installment selector (if multiple)
          if (widget.unpaidInstallments.length > 1) ...[
            Text(
              'SELECT INSTALLMENT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<Installment>(
                  value: _selectedInstallment,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: widget.unpaidInstallments.map((i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        '\$${i.totalPayment.toStringAsFixed(2)} - Due ${widget.formatDate(i.dueDate)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedInstallment = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ] else ...[
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${_selectedInstallment.totalPayment.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Due ${widget.formatDate(_selectedInstallment.dueDate)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDarkMode
                                          ? AppTheme.white60
                                          : AppTheme.black60,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ],

          // Transaction ID input
          Text(
            'TRANSACTION ID',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 8),
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _txidController,
                      onChanged: _onTxidChanged,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter transaction ID or hash',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  // Paste button
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    icon: Icon(
                      Icons.paste_rounded,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      size: 20,
                    ),
                    tooltip: 'Paste',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Confirm button
          LongButtonWidget(
            title: 'Confirm Payment',
            customWidth: double.infinity,
            state: _isValid ? ButtonState.idle : ButtonState.disabled,
            onTap: _isValid
                ? () => widget.onConfirm(
                      _selectedInstallment,
                      _txidController.text.trim(),
                    )
                : null,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
        ],
      ),
    );
  }
}

/// Generic confirmation bottom sheet for simple yes/no actions.
class _ConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmationSheet({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Message
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding * 1.5),
          // Buttons
          Row(
            children: [
              Expanded(
                child: LongButtonWidget(
                  title: cancelText,
                  buttonType: ButtonType.secondary,
                  customWidth: double.infinity,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppTheme.elementSpacing),
              Expanded(
                child: LongButtonWidget(
                  title: confirmText,
                  buttonType: ButtonType.primary,
                  customWidth: double.infinity,
                  buttonGradient: confirmColor != null
                      ? LinearGradient(colors: [confirmColor!, confirmColor!])
                      : null,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
        ],
      ),
    );
  }
}

/// Confirmation sheet for loan repayment with Lendaswap.
class _RepayConfirmationSheet extends StatelessWidget {
  final double amountToRepay;
  final String targetTokenSymbol;
  final VoidCallback onConfirm;

  const _RepayConfirmationSheet({
    required this.amountToRepay,
    required this.targetTokenSymbol,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Repay with Lendaswap',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          // Amount card
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount to repay',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDarkMode
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                  ),
                        ),
                        Text(
                          '\$${amountToRepay.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          // Info text
          Text(
            'This will swap BTC from your wallet to $targetTokenSymbol '
            'and send it to the lender\'s repayment address.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Lendaswap badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
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
          const SizedBox(height: AppTheme.cardPadding * 1.5),
          // Buttons
          Row(
            children: [
              Expanded(
                child: LongButtonWidget(
                  title: AppLocalizations.of(context)?.cancel ?? 'Cancel',
                  buttonType: ButtonType.secondary,
                  customWidth: double.infinity,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppTheme.elementSpacing),
              Expanded(
                child: LongButtonWidget(
                  title: 'Repay',
                  buttonType: ButtonType.primary,
                  customWidth: double.infinity,
                  buttonGradient: const LinearGradient(
                    colors: [Color(0xFF8247E5), Color(0xFF6C3DC1)],
                  ),
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
        ],
      ),
    );
  }
}
