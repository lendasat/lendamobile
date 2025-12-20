import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Currency {
  final String code;

  final String name;

  final Image icon;

  Currency({required this.code, required this.name, required this.icon});
}

enum BitcoinUnits { BTC, SAT }

class CryptoInfoItem extends StatefulWidget {
  final Currency currency;

  final BuildContext context;

  final VoidCallback onTap;

  final String balance;

  final BitcoinUnits defaultUnit;

  final double? bitcoinPrice;

  const CryptoInfoItem({
    super.key,
    required this.currency,
    required this.context,
    required this.onTap,
    required this.balance,
    required this.defaultUnit,
    this.bitcoinPrice,
  });

  @override
  State<CryptoInfoItem> createState() => _CryptoInfoItemState();
}

class _CryptoInfoItemState extends State<CryptoInfoItem> {
  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final userPrefs = context.watch<UserPreferencesService>();

    // Parse the balance and calculate the fiat equivalent.
    // (Assuming balance is in satoshis)
    final double balanceValue = double.tryParse(widget.balance) ?? 0.0;
    final bitcoinPrice = widget.bitcoinPrice ?? 0;
    final currencyEquivalent =
        (balanceValue / 100000000 * bitcoinPrice).toStringAsFixed(2);

    return GlassContainer(
      height: AppTheme.cardPadding * 2.75,
      borderRadius: AppTheme.cardPadding * 2.75 / 3,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.elementSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon and Currency Name
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: SizedBox(
                          height: AppTheme.cardPadding * 1.75,
                          width: AppTheme.cardPadding * 1.75,
                          child: ClipOval(child: widget.currency.icon),
                        ),
                      ),
                      SizedBox(width: AppTheme.elementSpacing / 1.5),
                      Text(
                        widget.currency.name,
                        style: Theme.of(widget.context).textTheme.titleSmall!
                            .copyWith(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.white90
                                  : AppTheme.black90,
                            ),
                      ),
                    ],
                  ),
                ),
                // Main Balance – apply the currency switch logic with conditional icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        !userPrefs.balancesVisible
                            ? Text(
                                "******",
                                style: Theme.of(
                                  widget.context,
                                ).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                currencyService.showCoinBalance
                                    ? widget.balance
                                    : "${currencyService.symbol}$currencyEquivalent",
                                style: Theme.of(
                                  widget.context,
                                ).textTheme.titleMedium,
                              ),
                        currencyService.showCoinBalance
                            ? Icon(
                                AppTheme.satoshiIcon,
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tap Interaction
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: widget.onTap),
          ),
        ],
      ),
    );
  }
}
