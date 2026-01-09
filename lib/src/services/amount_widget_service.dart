import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BitcoinUnitModel {
  final CurrencyType bitcoinUnit;
  final double amount;

  BitcoinUnitModel({required this.bitcoinUnit, required this.amount});
}

class AmountWidgetService extends ChangeNotifier {
  TextEditingController? _btcController;
  TextEditingController? _satController;
  TextEditingController? _currController;

  VoidCallback? _btcListener;
  VoidCallback? _satListener;
  VoidCallback? _currListener;

  bool _swapped = false;
  bool _preventConversion = false;
  bool _enabled = true;
  CurrencyType _currentUnit = CurrencyType.sats;

  Function(String)? _onInputStateChange;

  bool get swapped => _swapped;
  bool get preventConversion => _preventConversion;
  bool get enabled => _enabled;
  CurrencyType get currentUnit => _currentUnit;

  void initialize({
    required TextEditingController btcController,
    required TextEditingController satController,
    required TextEditingController currController,
    bool initialSwapped = false,
    bool preventConversionValue = false,
    bool enabledValue = true,
    CurrencyType initialUnit = CurrencyType.sats,
    Function(String)? onInputStateChange,
  }) {
    _btcController = btcController;
    _satController = satController;
    _currController = currController;

    _swapped = initialSwapped;
    _preventConversion = preventConversionValue;
    _enabled = enabledValue;
    _currentUnit = initialUnit;
    _onInputStateChange = onInputStateChange;

    // Set up listeners
    _btcListener = () => notifyListeners();
    _satListener = () => notifyListeners();
    _currListener = () => notifyListeners();

    btcController.addListener(_btcListener!);
    satController.addListener(_satListener!);
    currController.addListener(_currListener!);
  }

  /// Toggle between currency and bitcoin unit input
  void toggleSwapped(double? bitcoinPrice) {
    _swapped = !_swapped;

    if (_btcController == null ||
        _satController == null ||
        _currController == null) {
      return;
    }

    if (_swapped) {
      // Switching to fiat mode - check if source has content
      final hasSourceContent = _currentUnit == CurrencyType.bitcoin
          ? _btcController!.text.isNotEmpty
          : _satController!.text.isNotEmpty;

      if (hasSourceContent && bitcoinPrice != null) {
        final btcAmount = _currentUnit == CurrencyType.bitcoin
            ? double.tryParse(_btcController!.text) ?? 0.0
            : (int.tryParse(_satController!.text) ?? 0).toDouble();

        final currencyEquivalent = _convertCurrency(
          _currentUnit,
          btcAmount,
          CurrencyType.usd,
          bitcoinPrice,
          fixed: false,
        );
        _currController!.text = double.parse(
          currencyEquivalent,
        ).toStringAsFixed(2);
      } else {
        // Keep fiat controller empty if source was empty
        _currController!.text = '';
      }
    } else {
      // Switching to bitcoin mode - check if fiat has content
      if (_currController!.text.isNotEmpty && bitcoinPrice != null) {
        final currAmount = double.tryParse(_currController!.text) ?? 0.0;

        final btcEquivalent = _convertCurrency(
          CurrencyType.usd,
          currAmount,
          _currentUnit,
          bitcoinPrice,
        );
        _btcController!.text = btcEquivalent;
      } else {
        // Keep bitcoin controller empty if fiat was empty
        _btcController!.text = '';
        _satController!.text = '';
      }
    }

    _onInputStateChange?.call(
      _swapped ? "currency" : _currentUnit.name.toLowerCase(),
    );
    notifyListeners();
  }

  TextEditingController? getCurrentController() {
    if (_swapped) {
      return _currController;
    } else {
      return _currentUnit == CurrencyType.bitcoin
          ? _btcController
          : _satController;
    }
  }

  void processAutoConvert(BitcoinUnitModel unitEquivalent) {
    if (_btcController == null || _satController == null) return;

    if (unitEquivalent.bitcoinUnit != _currentUnit) {
      _currentUnit = unitEquivalent.bitcoinUnit;

      if (_currentUnit == CurrencyType.bitcoin) {
        _btcController!.text = unitEquivalent.amount.toString();
      } else {
        _satController!.text = unitEquivalent.amount.toString();
      }

      if (_onInputStateChange != null && !_swapped) {
        _onInputStateChange!(_currentUnit.name.toLowerCase());
      }

      notifyListeners();
    }
  }

  /// Convert between bitcoin units
  BitcoinUnitModel convertToBitcoinUnit(
    double amount,
    CurrencyType currentUnit,
  ) {
    if (currentUnit == CurrencyType.sats) {
      // If sats, check if amount is large enough to display as BTC
      if (amount >= BitcoinConstants.satsPerBtc) {
        return BitcoinUnitModel(
          bitcoinUnit: CurrencyType.bitcoin,
          amount: amount / BitcoinConstants.satsPerBtc,
        );
      }
      return BitcoinUnitModel(bitcoinUnit: CurrencyType.sats, amount: amount);
    } else {
      // If BTC, check if amount is small enough to display as sats
      if (amount < 0.001) {
        return BitcoinUnitModel(
          bitcoinUnit: CurrencyType.sats,
          amount: (amount * BitcoinConstants.satsPerBtc).round().toDouble(),
        );
      }
      return BitcoinUnitModel(
        bitcoinUnit: CurrencyType.bitcoin,
        amount: amount,
      );
    }
  }

  /// Convert currency amounts
  String _convertCurrency(
    CurrencyType from,
    double amount,
    CurrencyType to,
    double bitcoinPrice, {
    bool fixed = true,
  }) {
    if (from == to) return amount.toString();

    // Convert to BTC first
    double btcAmount;
    switch (from) {
      case CurrencyType.bitcoin:
        btcAmount = amount;
        break;
      case CurrencyType.sats:
        btcAmount = amount / BitcoinConstants.satsPerBtc;
        break;
      case CurrencyType.usd:
        btcAmount = amount / bitcoinPrice;
        break;
    }

    // Convert from BTC to target
    double result;
    switch (to) {
      case CurrencyType.bitcoin:
        result = btcAmount;
        break;
      case CurrencyType.sats:
        result = btcAmount * BitcoinConstants.satsPerBtc;
        break;
      case CurrencyType.usd:
        result = btcAmount * bitcoinPrice;
        break;
    }

    return fixed ? result.toStringAsFixed(8) : result.toString();
  }

  /// Get input formatters for text field
  List<TextInputFormatter> getInputFormatters({
    required bool hasBoundType,
    required BuildContext context,
    required double? bitcoinPrice,
    int? lowerBound,
    int? upperBound,
    CurrencyType? boundType,
    Function(double)? overBoundCallback,
    Function(double)? underBoundCallback,
    Function(double)? inBoundCallback,
  }) {
    List<TextInputFormatter> formatters = [];

    // Add bound input formatter if boundType exists
    if (hasBoundType && boundType != null && bitcoinPrice != null) {
      formatters.add(
        BoundInputFormatter(
          swapped: _swapped,
          lowerBound: lowerBound ?? 0,
          upperBound: upperBound ?? 999999999999999,
          boundType: boundType,
          valueType: _currentUnit,
          bitcoinPrice: bitcoinPrice,
          overBound: overBoundCallback,
          underBound: underBoundCallback,
          inBound: inBoundCallback,
        ),
      );
    }

    // Add filtering formatter based on unit and swapped state
    if (_currentUnit == CurrencyType.sats && !_swapped) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'(^\d+)')));
    } else {
      formatters.add(
        FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)')),
      );
    }

    // Add numerical range formatter
    formatters.add(
      NumericalRangeFormatter(
        min: 0,
        max: (upperBound != null && upperBound > 99999999999)
            ? upperBound.toDouble()
            : 99999999999,
      ),
    );

    return formatters;
  }

  @override
  void dispose() {
    if (_btcController != null && _btcListener != null) {
      _btcController!.removeListener(_btcListener!);
    }
    if (_satController != null && _satListener != null) {
      _satController!.removeListener(_satListener!);
    }
    if (_currController != null && _currListener != null) {
      _currController!.removeListener(_currListener!);
    }
    super.dispose();
  }
}

/// Input formatter to enforce bounds
class BoundInputFormatter extends TextInputFormatter {
  final bool swapped;
  final int lowerBound;
  final int upperBound;
  final double bitcoinPrice;
  final CurrencyType boundType;
  final CurrencyType valueType;
  final Function(double)? overBound;
  final Function(double)? underBound;
  final Function(double)? inBound;

  BoundInputFormatter({
    required this.swapped,
    required this.lowerBound,
    required this.upperBound,
    required this.boundType,
    required this.valueType,
    required this.bitcoinPrice,
    this.overBound,
    this.underBound,
    this.inBound,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    double convertedNewValue = double.tryParse(newValue.text) ?? 0;

    if (!swapped) {
      if (valueType != boundType) {
        if (valueType == CurrencyType.sats) {
          convertedNewValue =
              convertedNewValue / BitcoinConstants.satsPerBtc; // Convert to BTC
        } else {
          convertedNewValue =
              convertedNewValue * BitcoinConstants.satsPerBtc; // Convert to sats
        }
      }

      if (convertedNewValue < lowerBound) {
        underBound?.call(convertedNewValue);
      } else if (convertedNewValue > upperBound) {
        overBound?.call(convertedNewValue);
      } else {
        inBound?.call(convertedNewValue);
      }
    } else {
      // Convert USD to bound type for comparison
      convertedNewValue = (convertedNewValue / bitcoinPrice) *
          (boundType == CurrencyType.sats ? BitcoinConstants.satsPerBtc : 1);

      if (convertedNewValue < lowerBound) {
        underBound?.call(convertedNewValue);
      } else if (convertedNewValue > upperBound) {
        overBound?.call(convertedNewValue);
      } else {
        inBound?.call(convertedNewValue);
      }
    }

    return newValue;
  }
}

/// Input formatter to enforce numerical range
class NumericalRangeFormatter extends TextInputFormatter {
  final double min;
  final double max;

  NumericalRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = double.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}

// Enums and utility classes needed by AmountWidget
enum CurrencyType { bitcoin, sats, usd }
