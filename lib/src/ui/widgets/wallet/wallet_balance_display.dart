import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

/// Displays the main wallet balance with tap-to-toggle currency
class WalletBalanceDisplay extends StatelessWidget {
  final double balanceBtc;
  final double btcPrice;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WalletBalanceDisplay({
    super.key,
    required this.balanceBtc,
    required this.btcPrice,
    this.onTap,
    this.onLongPress,
  });

  /// Format satoshi amount with thousand separators
  static String formatSatsAmount(int sats) {
    final formatted = sats.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    // Convert BTC to satoshis for display
    final balanceInSats = (balanceBtc * BitcoinConstants.satsPerBtc).round();
    final formattedSats = formatSatsAmount(balanceInSats);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Balance display masked for PostHog session replay
          PostHogMaskWidget(
            child: GestureDetector(
              onTap: onTap ?? currencyService.toggleShowCoinBalance,
              onLongPress: onLongPress ?? userPrefs.toggleBalancesVisible,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: double.infinity,
                child: currencyService.showCoinBalance
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userPrefs.balancesVisible ? formattedSats : '****',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Icon(
                            AppTheme.satoshiIcon,
                            size: 58,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          userPrefs.balancesVisible
                              ? currencyService
                                  .formatAmount(balanceBtc * btcPrice)
                              : '${currencyService.symbol}****',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
