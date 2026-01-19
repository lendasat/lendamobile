import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

import 'wallet_balance_display.dart';

/// Displays the boarding balance (funds waiting to be settled into Ark)
class WalletBoardingBalance extends StatelessWidget {
  final int boardingBalanceSats;
  final double btcPrice;
  final bool isSettling;
  final bool skipAutoSettle;
  final VoidCallback? onTap;

  const WalletBoardingBalance({
    super.key,
    required this.boardingBalanceSats,
    required this.btcPrice,
    required this.isSettling,
    required this.skipAutoSettle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    final formattedSats =
        WalletBalanceDisplay.formatSatsAmount(boardingBalanceSats);
    final boardingBtc = boardingBalanceSats / BitcoinConstants.satsPerBtc;
    // formatAmount handles currency conversion internally
    final boardingFiatAmount = boardingBtc * btcPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: PostHogMaskWidget(
        child: GestureDetector(
          onTap: isSettling ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSettling)
                dotProgress(context, size: 14.0)
              else
                Icon(
                  FontAwesomeIcons.arrowDown,
                  size: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              const SizedBox(width: 6),
              Text(
                userPrefs.balancesVisible
                    ? (currencyService.showCoinBalance
                        ? '$formattedSats sats'
                        : currencyService.formatAmount(boardingFiatAmount))
                    : '****',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                isSettling
                    ? 'settling...'
                    : skipAutoSettle
                        ? 'confirming...'
                        : 'incoming',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
