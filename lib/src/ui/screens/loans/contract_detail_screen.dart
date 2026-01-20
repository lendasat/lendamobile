import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart'
    show Contract, Installment;
import 'package:ark_flutter/src/services/lendasat_service.dart'
    show ContractExtension, InstallmentExtension;
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bottom_action_buttons.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/loans/loan_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_detail_controller.dart';
import 'contract_detail_state.dart';

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
  late final ContractDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ContractDetailController(contractId: widget.contractId);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

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
                onPressed: state.isLoading ? null : _controller.loadContract,
              ),
            ],
          ),
          body: state.isLoading
              ? dotProgress(context)
              : state.errorMessage != null
                  ? _ErrorView(
                      errorMessage: _controller.displayErrorMessage,
                      onRetry: _controller.loadContract,
                    )
                  : state.contract == null
                      ? const _NotFoundView()
                      : _ContractDetailsBody(
                          controller: _controller,
                          state: state,
                        ),
        );
      },
    );
  }
}

/// Error view with retry button.
class _ErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: AppLocalizations.of(context)?.retry ?? 'Retry',
              buttonType: ButtonType.secondary,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Not found view.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
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
}

/// Main contract details body.
class _ContractDetailsBody extends StatelessWidget {
  final ContractDetailController controller;
  final ContractDetailState state;

  const _ContractDetailsBody({
    required this.controller,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final contract = state.contract!;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: controller.loadContract,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: AppTheme.cardPadding * 3,
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: state.hasActionButtons
                  ? AppTheme.cardPadding * 10
                  : AppTheme.cardPadding * 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusHeader(contract: contract, controller: controller),
                const SizedBox(height: AppTheme.cardPadding),
                _LoanDetails(contract: contract),
                const SizedBox(height: AppTheme.cardPadding),
                _CollateralDetails(
                  contract: contract,
                  state: state,
                  controller: controller,
                ),
                const SizedBox(height: AppTheme.cardPadding),
                if (contract.isActiveLoan || contract.installments.isNotEmpty)
                  _RepaymentSchedule(
                    contract: contract,
                    state: state,
                    controller: controller,
                  ),
              ],
            ),
          ),
        ),
        if (state.hasActionButtons)
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomActionContainer(
              child: _ActionButtons(
                controller: controller,
                state: state,
                context: context,
              ),
            ),
          ),
      ],
    );
  }
}

/// Status header with contract ID and status badge.
class _StatusHeader extends StatelessWidget {
  final Contract contract;
  final ContractDetailController controller;

  const _StatusHeader({
    required this.contract,
    required this.controller,
  });

  Color _getStatusBadgeColor(BuildContext context) {
    if (contract.isClosed) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    } else if (contract.hasIssue) {
      return AppTheme.errorColor;
    } else if (contract.canClaim || contract.canRecover) {
      return AppTheme.successColor;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusBadgeColor(context);

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    controller.copyToClipboard(contract.id, 'Contract ID'),
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
                        'ID: ${contract.id.substring(0, 8).toUpperCase()}',
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
              Flexible(
                  child: _StatusBadge(contract: contract, color: statusColor)),
            ],
          ),
          const SizedBox(height: 20),
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
                      '\$${contract.loanAmount.toStringAsFixed(2)}',
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
                    contract.lender.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          if (contract.isActiveLoan) ...[
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
                  '${(contract.repaymentProgress * 100).toStringAsFixed(0)}%',
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
                value: contract.repaymentProgress,
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
}

/// Status badge widget.
class _StatusBadge extends StatelessWidget {
  final Contract contract;
  final Color color;

  const _StatusBadge({required this.contract, required this.color});

  @override
  Widget build(BuildContext context) {
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
          contract.statusText.toUpperCase(),
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
}

/// Loan details section.
class _LoanDetails extends StatelessWidget {
  final Contract contract;

  const _LoanDetails({required this.contract});

  @override
  Widget build(BuildContext context) {
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
          _DetailRow(
              label: 'PRINCIPAL',
              value: '\$${contract.loanAmount.toStringAsFixed(2)}'),
          _DetailRow(
              label: 'INTEREST',
              value: '\$${contract.interest.toStringAsFixed(2)}'),
          _DetailRow(
            label: 'INTEREST RATE',
            value: '${(contract.interestRate * 100).toStringAsFixed(2)}% APY',
          ),
          _DetailRow(label: 'DURATION', value: '${contract.durationDays} days'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          ),
          _DetailRow(
            label: 'TOTAL REPAYMENT',
            value: '\$${contract.totalRepayment.toStringAsFixed(2)}',
            isBold: true,
          ),
          _DetailRow(
            label: 'EXPIRES',
            value: _formatDate(contract.expiry),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

/// Collateral details section.
class _CollateralDetails extends StatelessWidget {
  final Contract contract;
  final ContractDetailState state;
  final ContractDetailController controller;

  const _CollateralDetails({
    required this.contract,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final btcPrice = state.currentBtcPrice;
    final showCoinBalance = currencyService.showCoinBalance;

    final collateralBtc = contract.depositedBtc > 0
        ? contract.depositedBtc
        : contract.effectiveCollateralBtc;
    final collateralSats = collateralBtc * BitcoinConstants.satsPerBtc;
    final collateralUsd = collateralBtc * btcPrice;

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
          const SizedBox(height: AppTheme.elementSpacing),
          ArkListTile(
            contentPadding: EdgeInsets.zero,
            text: 'Amount',
            onTap: () => currencyService.toggleShowCoinBalance(),
            trailing: showCoinBalance
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${collateralSats.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        AppTheme.satoshiIcon,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  )
                : Text(
                    currencyService.formatAmount(collateralUsd),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
          ),
          ArkListTile(
            contentPadding: EdgeInsets.zero,
            text: 'Initial LTV',
            trailing: Text(
              '${(contract.initialLtv * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ArkListTile(
            contentPadding: EdgeInsets.zero,
            text: 'Liquidation Price',
            trailing: Text(
              '\$${contract.liquidationPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (contract.contractAddress != null)
            _ContractAddressTile(
              contract: contract,
              state: state,
              controller: controller,
            ),
        ],
      ),
    );
  }
}

/// Contract address tile with copy functionality.
class _ContractAddressTile extends StatelessWidget {
  final Contract contract;
  final ContractDetailState state;
  final ContractDetailController controller;

  const _ContractAddressTile({
    required this.contract,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkListTile(
      contentPadding: EdgeInsets.zero,
      text: 'Contract Address',
      onTap: controller.copyContractAddress,
      trailing: SizedBox(
        width: AppTheme.cardPadding * 6,
        child: state.showAddressCopied
            ? Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.check,
                    color: AppTheme.successColor,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  const Text(
                    'Copied',
                    style: TextStyle(color: AppTheme.successColor),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      contract.contractAddress!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  Icon(
                    Icons.copy,
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Repayment schedule section.
class _RepaymentSchedule extends StatelessWidget {
  final Contract contract;
  final ContractDetailState state;
  final ContractDetailController controller;

  const _RepaymentSchedule({
    required this.contract,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
          if (contract.isActiveLoan) ...[
            _DetailRow(
              label: 'TOTAL REPAYMENT',
              value: '\$${contract.totalRepayment.toStringAsFixed(2)}',
            ),
            _DetailRow(
              label: 'REMAINING BALANCE',
              value: '\$${contract.balanceOutstanding.toStringAsFixed(2)}',
              isBold: true,
            ),
            if (contract.btcLoanRepaymentAddress != null &&
                contract.btcLoanRepaymentAddress!.isNotEmpty)
              _BtcAddressTile(
                contract: contract,
                state: state,
                controller: controller,
              ),
            if (contract.loanRepaymentAddress != null &&
                contract.loanRepaymentAddress!.isNotEmpty)
              _StablecoinAddressTile(
                contract: contract,
                state: state,
                controller: controller,
              ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
          ],
          ...contract.installments.map<Widget>(
            (installment) => _InstallmentRow(
              installment: installment,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

/// BTC repayment address tile.
class _BtcAddressTile extends StatelessWidget {
  final Contract contract;
  final ContractDetailState state;
  final ContractDetailController controller;

  const _BtcAddressTile({
    required this.contract,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ArkListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.currency_bitcoin_rounded,
        size: 20,
        color: AppTheme.colorBitcoin,
      ),
      text: 'BTC Repayment Address',
      onTap: controller.copyBtcAddress,
      trailing: SizedBox(
        width: AppTheme.cardPadding * 6,
        child: state.showBtcAddressCopied
            ? Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.check,
                    color: AppTheme.successColor,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  const Text(
                    'Copied',
                    style: TextStyle(color: AppTheme.successColor),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      contract.btcLoanRepaymentAddress!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  Icon(
                    Icons.copy,
                    color: AppTheme.colorBitcoin.withValues(alpha: 0.7),
                    size: AppTheme.cardPadding * 0.75,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Stablecoin repayment address tile.
class _StablecoinAddressTile extends StatelessWidget {
  final Contract contract;
  final ContractDetailState state;
  final ContractDetailController controller;

  const _StablecoinAddressTile({
    required this.contract,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Purple color for stablecoins (matches the repay button gradient)
    const stablecoinColor = Color(0xFF8247E5);

    return ArkListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.attach_money_rounded,
        size: 20,
        color: stablecoinColor,
      ),
      text: '${contract.loanAssetDisplayName} Address',
      onTap: controller.copyStablecoinAddress,
      trailing: SizedBox(
        width: AppTheme.cardPadding * 6,
        child: state.showStablecoinAddressCopied
            ? Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.check,
                    color: AppTheme.successColor,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  const Text(
                    'Copied',
                    style: TextStyle(color: AppTheme.successColor),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      contract.loanRepaymentAddress!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  Icon(
                    Icons.copy,
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Installment row widget.
class _InstallmentRow extends StatelessWidget {
  final Installment installment;
  final ContractDetailController controller;

  const _InstallmentRow({
    required this.installment,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = installment.status.toString().contains('paid') ||
        installment.status.toString().contains('confirmed');
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
                      ? 'Paid on ${controller.formatDate(installment.dueDate)}'
                      : 'Due ${controller.formatDate(installment.dueDate)}',
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
}

/// Detail row for key-value display.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Action buttons section.
class _ActionButtons extends StatelessWidget {
  final ContractDetailController controller;
  final ContractDetailState state;
  final BuildContext context;

  const _ActionButtons({
    required this.controller,
    required this.state,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final contract = state.contract!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.canPayCollateral)
          LongButtonWidget(
            title: state.isActionLoading
                ? 'ADDING COLLATERAL...'
                : state.hasInsufficientBalance
                    ? 'BALANCE TOO LOW'
                    : 'PAY COLLATERAL',
            buttonType: state.hasInsufficientBalance
                ? ButtonType.secondary
                : ButtonType.primary,
            customWidth: double.infinity,
            isLoading: state.isActionLoading,
            onTap: state.isActionLoading || state.hasInsufficientBalance
                ? null
                : () => _showPayCollateralConfirmation(context),
          ),
        if (state.hasInsufficientBalance)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.elementSpacing),
            child: Text(
              'You need ${(contract.effectiveCollateralSats / 100000000).toStringAsFixed(8)} BTC to fund this contract',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        if (contract.canRepayWithLendaswap) ...[
          if (state.canPayCollateral) const SizedBox(height: 12),
          LongButtonWidget(
            title: state.isRepaying
                ? 'SWAPPING...'
                : state.hasInsufficientRepaymentBalance
                    ? 'NOT ENOUGH FUNDS'
                    : 'REPAY',
            buttonType: state.hasInsufficientRepaymentBalance
                ? ButtonType.secondary
                : ButtonType.primary,
            customWidth: double.infinity,
            buttonGradient: state.hasInsufficientRepaymentBalance
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF8247E5), Color(0xFF6C3DC1)],
                  ),
            onTap: state.isRepaying ||
                    state.isActionLoading ||
                    state.hasInsufficientRepaymentBalance
                ? null
                : () => _showRepayConfirmation(context),
          ),
          if (state.hasInsufficientRepaymentBalance)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.elementSpacing),
              child: Text(
                'You need approximately ${(state.estimatedRepaymentSats / BitcoinConstants.satsPerBtc).toStringAsFixed(6)} BTC to repay this loan',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                textAlign: TextAlign.center,
              ),
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
        if (contract.isActiveLoan &&
            contract.balanceOutstanding > 0 &&
            !contract.isAwaitingRepaymentConfirmation) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: state.isMarkingPaid ? 'CONFIRMING...' : 'I ALREADY PAID',
            buttonType: ButtonType.secondary,
            customWidth: double.infinity,
            onTap:
                state.isMarkingPaid || state.isActionLoading || state.isRepaying
                    ? null
                    : () => _showMarkAsPaidDialog(context),
          ),
        ],
        if (contract.isAwaitingRepaymentConfirmation) ...[
          const SizedBox(height: 12),
          _AwaitingConfirmationBanner(controller: controller),
        ],
        if (contract.canClaim) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'CLAIM COLLATERAL',
            buttonType: ButtonType.primary,
            customWidth: double.infinity,
            onTap: state.isActionLoading ? null : controller.claimCollateral,
          ),
        ],
        if (contract.canRecover) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'RECOVER COLLATERAL',
            buttonType: ButtonType.primary,
            customWidth: double.infinity,
            onTap: state.isActionLoading ? null : controller.recoverCollateral,
          ),
        ],
        if (state.canCancel) ...[
          const SizedBox(height: 12),
          LongButtonWidget(
            title: 'CANCEL REQUEST',
            buttonType: ButtonType.secondary,
            customWidth: double.infinity,
            onTap: state.isActionLoading
                ? null
                : () => _showCancelConfirmation(context),
          ),
        ],
      ],
    );
  }

  Future<void> _showPayCollateralConfirmation(BuildContext context) async {
    final contract = state.contract!;
    await arkBottomSheet(
      context: context,
      child: ConfirmationSheet(
        title: 'Pay Collateral',
        message:
            'Send ${contract.effectiveCollateralBtc.toStringAsFixed(6)} BTC as collateral for this loan?',
        confirmText: 'Pay',
        cancelText: 'Cancel',
        onConfirm: () async {
          Navigator.pop(context);
          await controller.payCollateral();
        },
      ),
    );
  }

  Future<void> _showRepayConfirmation(BuildContext context) async {
    final contract = state.contract!;
    await arkBottomSheet(
      context: context,
      child: RepayConfirmationSheet(
        amountToRepay: contract.balanceOutstanding,
        targetTokenSymbol: contract.repaymentSwapToken!.symbol,
        onConfirm: () async {
          Navigator.pop(context);
          final result = await controller.repayWithLendaswap();
          if (result != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SwapProcessingScreen(
                  swapId: result.swapId,
                  sourceToken: SwapToken.bitcoin,
                  targetToken: result.targetToken,
                  sourceAmount: result.btcAmount,
                  targetAmount: result.targetAmount.toStringAsFixed(2),
                  loanContractId: contract.id,
                  loanInstallmentId: result.installmentId,
                ),
              ),
            ).then((_) => controller.refreshAfterSwap());
          }
        },
      ),
    );
  }

  Future<void> _showMarkAsPaidDialog(BuildContext context) async {
    final unpaidInstallments = controller.unpaidInstallments;
    if (unpaidInstallments.isEmpty) return;

    await arkBottomSheet(
      context: context,
      child: MarkAsPaidSheet(
        unpaidInstallments: unpaidInstallments,
        formatDate: controller.formatDate,
        onConfirm: (installment, txid) async {
          Navigator.pop(context);
          await controller.markInstallmentPaid(
            installmentId: installment.id,
            paymentTxid: txid,
          );
        },
      ),
    );
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    await arkBottomSheet(
      context: context,
      child: ConfirmationSheet(
        title: AppLocalizations.of(context)?.cancel ?? 'Cancel',
        message:
            'Are you sure you want to cancel this loan request? This action cannot be undone.',
        confirmText: 'Cancel Request',
        confirmColor: AppTheme.errorColor,
        cancelText: 'Keep',
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await controller.cancelContract();
            if (context.mounted) {
              Navigator.pop(context);
            }
          } catch (_) {
            // Error already shown by controller
          }
        },
      ),
    );
  }
}

/// Awaiting repayment confirmation banner.
class _AwaitingConfirmationBanner extends StatelessWidget {
  final ContractDetailController controller;

  const _AwaitingConfirmationBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
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
                  dotProgress(context, size: 14.0),
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
          customWidth: double.infinity,
          onTap: controller.openSupportDiscord,
        ),
      ],
    );
  }
}
