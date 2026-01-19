import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

import 'wallet_balance_display.dart';

/// Displays the locked collateral amount (from LendaSat loans)
class WalletLockedCollateral extends StatelessWidget {
  final int lockedCollateralSats;
  final double btcPrice;
  final VoidCallback? onTap;

  const WalletLockedCollateral({
    super.key,
    required this.lockedCollateralSats,
    required this.btcPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    final formattedSats =
        WalletBalanceDisplay.formatSatsAmount(lockedCollateralSats);
    final lockedBtc = lockedCollateralSats / BitcoinConstants.satsPerBtc;
    // formatAmount handles currency conversion internally
    final lockedFiatAmount = lockedBtc * btcPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: PostHogMaskWidget(
        child: GestureDetector(
          onTap: onTap ?? currencyService.toggleShowCoinBalance,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.lock,
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
                        : currencyService.formatAmount(lockedFiatAmount))
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
                'locked',
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
