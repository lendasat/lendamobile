import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header widget displaying transaction amount with status pill.
/// Toggles between sats/BTC and fiat display on tap.
class TransactionAmountHeader extends StatelessWidget {
  final int amountSats;
  final bool isSent;
  final bool isConfirmed;
  final String networkType;
  final CurrencyPreferenceService currencyService;
  final double bitcoinPrice;

  const TransactionAmountHeader({
    super.key,
    required this.amountSats,
    required this.isSent,
    required this.isConfirmed,
    required this.networkType,
    required this.currencyService,
    required this.bitcoinPrice,
  });

  /// Format amount with auto sats/BTC switching based on threshold
  (String, String, bool) _formatAmountWithUnit(int sats) {
    final absAmount = sats.abs();
    if (absAmount >= BitcoinConstants.satsPerBtc) {
      final btc = absAmount / BitcoinConstants.satsPerBtc;
      return (btc.toStringAsFixed(8), 'BTC', false);
    } else {
      final formatter = NumberFormat('#,###');
      return (formatter.format(absAmount), 'sats', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showCoinBalance = currencyService.showCoinBalance;
    final (formattedAmount, unit, isSatsUnit) =
        _formatAmountWithUnit(amountSats);

    // Calculate fiat value
    final btcAmount = amountSats.abs() / BitcoinConstants.satsPerBtc;
    final fiatAmount = btcAmount * bitcoinPrice;

    return GestureDetector(
      onTap: () => currencyService.toggleShowCoinBalance(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppTheme.cardPadding * 1.5,
        ),
        child: Column(
          children: [
            // Status pill
            _buildStatusPill(context, l10n),
            const SizedBox(height: AppTheme.cardPadding),
            // Large amount - toggles between sats/BTC and fiat
            if (showCoinBalance)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${isSent ? '-' : '+'}$formattedAmount',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(width: 4),
                  if (isSatsUnit)
                    Icon(
                      AppTheme.satoshiIcon,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface,
                    )
                  else
                    Text(
                      unit,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                ],
              )
            else
              Text(
                '${isSent ? '-' : '+'}${currencyService.formatAmount(fiatAmount)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build status pill - shows "Incoming" (orange) if pending, otherwise Sent/Received
  Widget _buildStatusPill(BuildContext context, AppLocalizations l10n) {
    final isPending = !isConfirmed && networkType != 'Arkade';

    final Color pillColor = isPending
        ? AppTheme.colorBitcoin
        : (isSent ? AppTheme.errorColor : AppTheme.successColor);
    final IconData pillIcon = isPending
        ? Icons.schedule_rounded
        : (isSent ? Icons.north_east_rounded : Icons.south_west_rounded);
    final String pillText =
        isPending ? l10n.pending : (isSent ? l10n.sent : l10n.received);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding * 0.75,
        vertical: AppTheme.elementSpacing * 0.4,
      ),
      decoration: BoxDecoration(
        color: pillColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pillIcon,
            size: 14,
            color: pillColor,
          ),
          const SizedBox(width: 4),
          Text(
            pillText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: pillColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
