import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ark_flutter/src/rust/api.dart' as rust;
import 'package:ark_flutter/src/rust/models/exchange_rates.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Service for managing user's preferred display currency
class CurrencyPreferenceService extends ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  static const String _showCoinBalanceKey = 'show_coin_balance';

  FiatCurrency _currentCurrency = FiatCurrency.usd;
  ExchangeRates? _exchangeRates;
  DateTime? _lastFetch;
  bool _showCoinBalance = true;

  FiatCurrency get currentCurrency => _currentCurrency;
  ExchangeRates? get exchangeRates => _exchangeRates;
  bool get showCoinBalance => _showCoinBalance;

  Future<void> loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString(_currencyKey);

    if (currencyCode != null) {
      try {
        final currencies = rust.getSupportedCurrencies();
        _currentCurrency = currencies.firstWhere(
          (c) => rust.currencyCode(currency: c) == currencyCode,
          orElse: () => FiatCurrency.usd,
        );
      } catch (e) {
        _currentCurrency = FiatCurrency.usd;
      }
    }

    _showCoinBalance = prefs.getBool(_showCoinBalanceKey) ?? true;

    notifyListeners();
    await fetchExchangeRates();
  }

  Future<void> toggleShowCoinBalance() async {
    _showCoinBalance = !_showCoinBalance;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCoinBalanceKey, _showCoinBalance);

    notifyListeners();
  }

  Future<void> setShowCoinBalance(bool value) async {
    _showCoinBalance = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCoinBalanceKey, _showCoinBalance);

    notifyListeners();
  }

  Future<void> setCurrency(FiatCurrency currency) async {
    _currentCurrency = currency;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, rust.currencyCode(currency: currency));

    notifyListeners();
  }

  Future<void> fetchExchangeRates() async {
    try {
      // Only fetch if we haven't fetched in the last hour
      if (_lastFetch != null &&
          DateTime.now().difference(_lastFetch!).inHours < 1) {
        return;
      }

      _exchangeRates = await rust.fetchExchangeRates();
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _logger.w('Failed to fetch exchange rates: $e');
    }
  }

  double convertFromUsd(double usdAmount) {
    if (_exchangeRates == null) {
      return usdAmount;
    }

    final currencyCode = rust.currencyCode(currency: _currentCurrency);
    final rate = _exchangeRates!.rates[currencyCode];

    if (rate == null) {
      return usdAmount;
    }

    return usdAmount * rate;
  }

  String get symbol {
    switch (_currentCurrency) {
      case FiatCurrency.usd:
        return '\$';
      case FiatCurrency.eur:
        return '€';
      case FiatCurrency.gbp:
        return '£';
      case FiatCurrency.jpy:
        return '¥';
      case FiatCurrency.cad:
        return 'CA\$';
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

  String get code => rust.currencyCode(currency: _currentCurrency);

  String get fullName {
    switch (_currentCurrency) {
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

  String get flag {
    switch (_currentCurrency) {
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

  int get decimalPlaces {
    switch (_currentCurrency) {
      case FiatCurrency.jpy:
      case FiatCurrency.krw:
        return 0;
      default:
        return 2;
    }
  }

  /// Get the locale string for the current currency.
  /// This determines the number formatting (thousand/decimal separators).
  String get _localeForCurrency {
    switch (_currentCurrency) {
      case FiatCurrency.usd:
        return 'en_US';
      case FiatCurrency.eur:
        return 'de_DE'; // German/European format: 1.234,56
      case FiatCurrency.gbp:
        return 'en_GB';
      case FiatCurrency.jpy:
        return 'ja_JP';
      case FiatCurrency.cad:
        return 'en_CA';
      case FiatCurrency.aud:
        return 'en_AU';
      case FiatCurrency.chf:
        return 'de_CH'; // Swiss format: 1'234.56 or 1.234,56
      case FiatCurrency.cny:
        return 'zh_CN';
      case FiatCurrency.inr:
        return 'en_IN';
      case FiatCurrency.brl:
        return 'pt_BR'; // Brazilian format: 1.234,56
      case FiatCurrency.mxn:
        return 'es_MX';
      case FiatCurrency.krw:
        return 'ko_KR';
    }
  }

  /// Format amount in selected currency with proper thousand separators.
  String formatAmount(double usdAmount) {
    final convertedAmount = convertFromUsd(usdAmount);

    // Use NumberFormat for locale-aware formatting with thousand separators
    final formatter = NumberFormat.decimalPatternDigits(
      locale: _localeForCurrency,
      decimalDigits: decimalPlaces,
    );

    final formatted = formatter.format(convertedAmount);

    // Some currencies put symbol after amount
    switch (_currentCurrency) {
      case FiatCurrency.eur:
      case FiatCurrency.chf:
        return '$formatted $symbol';
      default:
        return '$symbol$formatted';
    }
  }
}
