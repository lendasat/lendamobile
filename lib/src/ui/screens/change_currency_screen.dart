import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust;
import 'package:ark_flutter/src/rust/models/exchange_rates.dart';
import '../../../services/currency_preference_service.dart';

class ChangeCurrencyScreen extends StatefulWidget {
  const ChangeCurrencyScreen({super.key});

  @override
  State<ChangeCurrencyScreen> createState() => _ChangeCurrencyScreenState();
}

class _ChangeCurrencyScreenState extends State<ChangeCurrencyScreen> {
  FiatCurrency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final currencyService = context.read<CurrencyPreferenceService>();
    _selectedCurrency = currencyService.currentCurrency;
  }

  void _applyCurrency() async {
    if (_selectedCurrency == null) return;

    final currencyService = context.read<CurrencyPreferenceService>();
    await currencyService.setCurrency(_selectedCurrency!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.currencyUpdatedSuccessfully),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
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

  String _getCurrencyFlag(FiatCurrency currency) {
    switch (currency) {
      case FiatCurrency.usd:
        return '🇺🇸';
      case FiatCurrency.eur:
        return '🇪🇺';
      case FiatCurrency.gbp:
        return '🇬🇧';
      case FiatCurrency.jpy:
        return '🇯🇵';
      case FiatCurrency.cad:
        return '🇨🇦';
      case FiatCurrency.aud:
        return '🇦🇺';
      case FiatCurrency.chf:
        return '🇨🇭';
      case FiatCurrency.cny:
        return '🇨🇳';
      case FiatCurrency.inr:
        return '🇮🇳';
      case FiatCurrency.brl:
        return '🇧🇷';
      case FiatCurrency.mxn:
        return '🇲🇽';
      case FiatCurrency.krw:
        return '🇰🇷';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final currencies = rust.getSupportedCurrencies();

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.changeCurrency,
            style: TextStyle(color: theme.primaryWhite)),
        iconTheme: IconThemeData(color: theme.primaryWhite),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final currencyName = _getCurrencyName(currency);
                final currencyCode = rust.currencyCode(currency: currency);
                final flag = _getCurrencyFlag(currency);

                return RadioListTile<FiatCurrency>(
                  title: Text('$flag $currencyName'),
                  subtitle: Text(currencyCode),
                  value: currency,
                  groupValue: _selectedCurrency,
                  onChanged: (FiatCurrency? value) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyCurrency,
                child: Text(AppLocalizations.of(context)!.apply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
