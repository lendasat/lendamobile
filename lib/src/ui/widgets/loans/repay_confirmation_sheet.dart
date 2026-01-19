import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';

/// Confirmation sheet for loan repayment with Lendaswap.
/// Shows amount to repay and explains the swap process.
class RepayConfirmationSheet extends StatelessWidget {
  final double amountToRepay;
  final String targetTokenSymbol;
  final VoidCallback onConfirm;

  const RepayConfirmationSheet({
    super.key,
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
