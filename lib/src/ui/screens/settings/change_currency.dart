import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
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
    return ArkScaffoldUnsafe(
      context: context,
      appBar: BitNetAppBar(
        text: AppLocalizations.of(context)!.currency,
        context: context,
        hasBackButton: true,
        transparent: false,
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
  late List<FiatCurrency> _allCurrencies;
  List<FiatCurrency> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _allCurrencies = rust.getSupportedCurrencies();
    _filteredCurrencies = _allCurrencies;
  }

  void _filterCurrencies(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredCurrencies = _allCurrencies;
      } else {
        final searchLower = searchText.toLowerCase();
        _filteredCurrencies = _allCurrencies.where((currency) {
          final name = _getCurrencyName(currency).toLowerCase();
          final code = currency.name.toLowerCase();
          return name.contains(searchLower) || code.startsWith(searchLower);
        }).toList();
      }
    });
  }

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

    return ArkScaffoldUnsafe(
      context: context,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.elementSpacing),
            // Fixed search bar at top
            SearchFieldWidget(
              hintText: AppLocalizations.of(context)!.search,
              isSearchEnabled: true,
              onChanged: _filterCurrencies,
              handleSearch: (dynamic) {},
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Scrollable list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCurrencies.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  return _buildCurrencyTile(
                    currency,
                    _getCurrencyName(currency),
                    selectedCurrency,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(FiatCurrency currency, String currencyName,
      FiatCurrency selectedCurrency) {
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
          OverlayService().showSuccess(
            AppLocalizations.of(context)!.currencyUpdatedSuccessfully,
          );
        }
      },
    );
  }
}
