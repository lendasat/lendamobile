import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust;
import 'package:ark_flutter/src/rust/models/exchange_rates.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangeCurrency extends StatefulWidget {
  const ChangeCurrency({super.key});

  @override
  State<ChangeCurrency> createState() => _ChangeCurrencyState();
}

class _ChangeCurrencyState extends State<ChangeCurrency> {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<SettingsController>();
    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: ArkAppBar(
        text: AppLocalizations.of(context)!.currency,
        context: context,
        hasBackButton: true,
        onTap: () => controller.switchTab('main'),
      ),
      body: const _CurrencyPickerBody(),
    );
  }
}

class _CurrencyPickerBody extends StatefulWidget {
  const _CurrencyPickerBody();

  @override
  State<_CurrencyPickerBody> createState() => _CurrencyPickerBodyState();
}

class _CurrencyPickerBodyState extends State<_CurrencyPickerBody> {
  String _searchText = '';

  String _getCurrencyName(FiatCurrency currency) {
    switch (currency) {
      case FiatCurrency.usd:
        return 'US Dollar';
      case FiatCurrency.eur:
        return 'Euro';
      case FiatCurrency.gbp:
        return 'British Pound';
      case FiatCurrency.jpy:
        return 'Japanese Yen';
      case FiatCurrency.cad:
        return 'Canadian Dollar';
      case FiatCurrency.aud:
        return 'Australian Dollar';
      case FiatCurrency.chf:
        return 'Swiss Franc';
      case FiatCurrency.cny:
        return 'Chinese Yuan';
      case FiatCurrency.inr:
        return 'Indian Rupee';
      case FiatCurrency.brl:
        return 'Brazilian Real';
      case FiatCurrency.mxn:
        return 'Mexican Peso';
      case FiatCurrency.krw:
        return 'South Korean Won';
    }
  }

  String _getCurrencySymbol(FiatCurrency currency) {
    switch (currency) {
      case FiatCurrency.usd:
        return '\$';
      case FiatCurrency.eur:
        return '€';
      case FiatCurrency.gbp:
        return '£';
      case FiatCurrency.jpy:
        return '¥';
      case FiatCurrency.cad:
        return 'C\$';
      case FiatCurrency.aud:
        return 'A\$';
      case FiatCurrency.chf:
        return 'CHF';
      case FiatCurrency.cny:
        return '¥';
      case FiatCurrency.inr:
        return '₹';
      case FiatCurrency.brl:
        return 'R\$';
      case FiatCurrency.mxn:
        return 'MX\$';
      case FiatCurrency.krw:
        return '₩';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final selectedCurrency = currencyService.currentCurrency;
    final currencies = rust.getSupportedCurrencies();

    return ArkScaffold(
      context: context,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.elementSpacing),
              SearchFieldWidget(
                hintText: AppLocalizations.of(context)!.search,
                isSearchEnabled: true,
                onChanged: (val) {
                  setState(() {
                    _searchText = val;
                  });
                },
                handleSearch: (dynamic) {},
              ),
              _buildCurrencyList(currencies, selectedCurrency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyList(
      List<FiatCurrency> currencies, FiatCurrency selectedCurrency) {
    return SizedBox(
      width: double.infinity,
      child: ListView.builder(
        itemCount: currencies.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final currency = currencies[index];
          final currencyName = _getCurrencyName(currency);

          if (_searchText.isNotEmpty &&
              !currencyName.toLowerCase().startsWith(_searchText.toLowerCase())) {
            return const SizedBox.shrink();
          }

          return _buildCurrencyTile(currency, currencyName, selectedCurrency);
        },
      ),
    );
  }

  Widget _buildCurrencyTile(
      FiatCurrency currency, String currencyName, FiatCurrency selectedCurrency) {
    final currencyService = context.read<CurrencyPreferenceService>();
    final currencySymbol = _getCurrencySymbol(currency);

    return ArkListTile(
      leading: Text(
        currencyName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: Text(
        currencySymbol,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      selected: currency == selectedCurrency,
      onTap: () async {
        await currencyService.setCurrency(currency);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.currencyUpdatedSuccessfully),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
