import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card widget displaying a loan contract summary.
class ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback onTap;

  const ContractCard({
    super.key,
    required this.contract,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(contract.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        borderRadius: AppTheme.cardRadiusSmall,
      ),
      child: GlassContainer(
        borderRadius: AppTheme.cardRadiusSmall,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.cardRadiusSmall,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${contract.loanAmount.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                        ),
                        Text(
                          'from ${contract.lender.name}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isDarkMode
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(context, statusColor),
                  ],
                ),
                const SizedBox(height: AppTheme.cardPadding),

                // Time remaining indicator
                if (!contract.isClosed) ...[
                  _buildTimeRemaining(context),
                  const SizedBox(height: AppTheme.elementSpacing),
                ],

                // Mini stats
                Row(
                  children: [
                    _buildMiniInfo(
                        context,
                        AppLocalizations.of(context)?.interest ?? 'Interest',
                        '${(contract.interestRate * 100).toStringAsFixed(1)}% APY'),
                    const SizedBox(width: 16),
                    _buildMiniInfo(
                        context,
                        AppLocalizations.of(context)?.due ?? 'Due',
                        _formatDate(DateTime.parse(contract.expiry))),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }

  Widget _buildMiniInfo(BuildContext context, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTimeRemaining(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final expiryDate = DateTime.parse(contract.expiry);
    final now = DateTime.now();
    final remaining = expiryDate.difference(now);

    String timeText;
    Color timeColor;

    // Check if contract is in a completed/closed state - not overdue anymore
    final isRepaymentConfirmed =
        contract.status == ContractStatus.repaymentConfirmed;
    final isClosed = contract.status == ContractStatus.closed ||
        contract.status == ContractStatus.closing ||
        contract.status == ContractStatus.closingByClaim;
    final isCompleted = isRepaymentConfirmed || isClosed;

    if (remaining.isNegative && !isCompleted) {
      timeText = AppLocalizations.of(context)?.overdue ?? 'Overdue';
      timeColor = AppTheme.errorColor;
    } else if (isRepaymentConfirmed) {
      timeText = 'Claim Collateral';
      timeColor = AppTheme.colorBitcoin;
    } else if (isClosed) {
      timeText = 'Completed';
      timeColor = AppTheme.successColor;
    } else if (remaining.inDays > 0) {
      timeText =
          '${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'} left';
      timeColor = remaining.inDays <= 3
          ? Colors.orange
          : (isDarkMode ? AppTheme.white70 : AppTheme.black70);
    } else if (remaining.inHours > 0) {
      timeText =
          '${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'} left';
      timeColor = Colors.orange;
    } else {
      timeText = '${remaining.inMinutes} min left';
      timeColor = AppTheme.errorColor;
    }

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: timeColor,
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: timeColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Color _getStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.principalGiven:
      case ContractStatus.repaymentProvided:
      case ContractStatus.repaymentConfirmed:
        return AppTheme.successColor;
      case ContractStatus.requested:
      case ContractStatus.approved:
        return Colors.orange;
      case ContractStatus.collateralSeen:
      case ContractStatus.collateralConfirmed:
        return Colors.orange;
      case ContractStatus.closed:
      case ContractStatus.closedByLiquidation:
      case ContractStatus.closedByDefaulting:
      case ContractStatus.closedByRecovery:
        return Colors.grey;
      case ContractStatus.defaulted:
      case ContractStatus.rejected:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
