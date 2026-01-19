import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/price_widgets.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'wallet_balance_display.dart';

/// Displays price/balance change indicators with percent and absolute change
class WalletPriceIndicators extends StatelessWidget {
  final double percentChange;
  final bool isPositive;
  final double balanceChangeInFiat;
  final double btcPrice;
  final VoidCallback? onTap;

  const WalletPriceIndicators({
    super.key,
    required this.percentChange,
    required this.isPositive,
    required this.balanceChangeInFiat,
    required this.btcPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();
    final isObscured = !userPrefs.balancesVisible;

    // Balance change in BTC
    final balanceChange = btcPrice > 0 ? balanceChangeInFiat / btcPrice : 0.0;

    // Convert balance change to sats
    final balanceChangeInSats =
        (balanceChange.abs() * BitcoinConstants.satsPerBtc).round();

    return GestureDetector(
      onTap: onTap ?? currencyService.toggleShowCoinBalance,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show sats with satoshi icon when in coin mode
            currencyService.showCoinBalance
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: isPositive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 16,
                      ),
                      Text(
                        isObscured
                            ? '****'
                            : WalletBalanceDisplay.formatSatsAmount(
                                balanceChangeInSats),
                        style: TextStyle(
                          color: isPositive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isObscured) ...[
                        const SizedBox(width: 2),
                        Icon(
                          AppTheme.satoshiIcon,
                          size: 14,
                          color: isPositive
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ],
                    ],
                  )
                : ColoredPriceWidget(
                    price:
                        currencyService.formatAmount(balanceChangeInFiat.abs()),
                    isPositive: isPositive,
                    shouldHideAmount: isObscured,
                  ),
            const SizedBox(width: 8),
            BitNetPercentWidget(
              priceChange: percentChange.isInfinite
                  ? '+∞%'
                  : '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
              shouldHideAmount: isObscured,
            ),
          ],
        ),
      ),
    );
  }
}
