import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
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

  Contract? _contract;
  bool _isLoading = true;
  bool _isActionLoading = false;
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

    // Get fee rate first
    final feeRate = await _showFeeRateDialog();
    if (feeRate == null) return;

    setState(() => _isActionLoading = true);

    try {
      if (_contract!.isArkCollateral) {
        // Ark collateral claim - use automatic signing
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
        // Standard Bitcoin claim - use automatic signing
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
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
              _errorMessage!,
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

            // Repayment schedule (if active)
            if (_contract!.installments.isNotEmpty) ...[
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
              _buildStatusBadge(),
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
          if (_contract!.loanRepaymentAddress != null)
            _buildDetailRow(
              'Repayment Address',
              _truncateAddress(_contract!.loanRepaymentAddress!),
              copyValue: _contract!.loanRepaymentAddress,
            ),
        ],
      ),
    );
  }

  Widget _buildCollateralDetails() {
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
            'Required',
            '${_contract!.collateralBtc.toStringAsFixed(6)} BTC',
          ),
          _buildDetailRow(
            'Deposited',
            '${_contract!.depositedBtc.toStringAsFixed(6)} BTC',
          ),
          _buildDetailRow(
            'Initial LTV',
            '${(_contract!.initialLtv * 100).toStringAsFixed(0)}%',
          ),
          _buildDetailRow(
            'Liquidation Price',
            '\$${_contract!.liquidationPrice.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Type',
            _contract!.isArkCollateral ? 'Arkade (Instant)' : 'On-chain',
          ),
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

    return Column(
      children: [
        if (_contract!.canClaim)
          LongButtonWidget(
            title: _isActionLoading ? 'Loading...' : 'Claim Collateral',
            buttonType: ButtonType.primary,
            onTap: _isActionLoading ? null : _showClaimSheet,
          ),
        if (_contract!.canRecover) ...[
          const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isActionLoading ? 'Loading...' : 'Recover Collateral',
            buttonType: ButtonType.primary,
            onTap: _isActionLoading ? null : _showRecoverSheet,
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: _isActionLoading ? 'Loading...' : 'Cancel Request',
            buttonType: ButtonType.secondary,
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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

  String _truncateAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }
}
