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

  bool _swapped = false;
  bool _preventConversion = false;
  bool _enabled = true;
  CurrencyType _currentUnit = CurrencyType.sats;

  Function(String)? _onInputStateChange;

  // Cached converted values - updated on input change, not during build
  String _cachedFiatDisplay = "";
  String _cachedBtcDisplay = "";

  bool get swapped => _swapped;
  bool get preventConversion => _preventConversion;
  bool get enabled => _enabled;
  CurrencyType get currentUnit => _currentUnit;
  String get cachedFiatDisplay => _cachedFiatDisplay;
  String get cachedBtcDisplay => _cachedBtcDisplay;

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

    // NO LISTENERS - we handle updates explicitly via onInputChanged
  }

  /// Called when user types in the input field - handles all conversions
  void onInputChanged({
    required double? bitcoinPrice,
    required double? fiatRate,
  }) {
    if (_btcController == null ||
        _satController == null ||
        _currController == null) {
      return;
    }

    if (_swapped) {
      // User is typing in fiat - convert to BTC/sats
      _updateBitcoinFromFiat(bitcoinPrice, fiatRate);
    } else {
      // User is typing in BTC/sats - sync controllers and update fiat display
      _syncBitcoinControllers();
      _updateFiatFromBitcoin(bitcoinPrice, fiatRate);
    }
  }

  /// Sync btc and sat controllers when user types in bitcoin mode
  void _syncBitcoinControllers() {
    if (_currentUnit == CurrencyType.sats) {
      final sats = double.tryParse(_satController!.text) ?? 0;
      _btcController!.text =
          (sats / BitcoinConstants.satsPerBtc).toStringAsFixed(8);
    } else {
      final btc = double.tryParse(_btcController!.text) ?? 0;
      _satController!.text =
          (btc * BitcoinConstants.satsPerBtc).toInt().toString();
    }
  }

  /// Update fiat display value from current bitcoin amount
  void _updateFiatFromBitcoin(double? bitcoinPrice, double? fiatRate) {
    // Check if there's actual input
    final hasSourceContent = _currentUnit == CurrencyType.bitcoin
        ? _btcController!.text.isNotEmpty
        : _satController!.text.isNotEmpty;

    if (!hasSourceContent || bitcoinPrice == null) {
      _cachedFiatDisplay = "";
      return;
    }

    final amount = _currentUnit == CurrencyType.bitcoin
        ? double.tryParse(_btcController!.text) ?? 0.0
        : double.tryParse(_satController!.text) ?? 0.0;

    final btcAmount = _currentUnit == CurrencyType.sats
        ? amount / BitcoinConstants.satsPerBtc
        : amount;
    final fiatAmount = btcAmount * bitcoinPrice * (fiatRate ?? 1.0);

    _cachedFiatDisplay = fiatAmount.toStringAsFixed(2);

    // Update currency controller for when user swaps
    if (!_preventConversion) {
      _currController!.text = _cachedFiatDisplay;
    }
  }

  /// Update bitcoin display value from current fiat amount
  void _updateBitcoinFromFiat(double? bitcoinPrice, double? fiatRate) {
    // Check if there's actual input
    if (_currController!.text.isEmpty ||
        bitcoinPrice == null ||
        fiatRate == null) {
      _cachedBtcDisplay = "";
      return;
    }

    final currAmount = double.tryParse(_currController!.text) ?? 0.0;

    final btcAmount = currAmount / (bitcoinPrice * fiatRate);
    final satAmount = (btcAmount * BitcoinConstants.satsPerBtc).round();

    // Update controllers for when user swaps back
    if (!_preventConversion) {
      _btcController!.text = btcAmount.toStringAsFixed(8);
      _satController!.text = satAmount.toString();
    }

    _cachedBtcDisplay = _currentUnit == CurrencyType.bitcoin
        ? btcAmount.toStringAsFixed(8)
        : satAmount.toString();
  }

  /// Toggle between currency and bitcoin unit input
  void toggleSwapped(double? bitcoinPrice, double? fiatRate) {
    _swapped = !_swapped;

    if (_btcController == null ||
        _satController == null ||
        _currController == null) {
      return;
    }

    if (_swapped) {
      // Switching to fiat mode - convert bitcoin to fiat
      final hasSourceContent = _currentUnit == CurrencyType.bitcoin
          ? _btcController!.text.isNotEmpty
          : _satController!.text.isNotEmpty;

      if (hasSourceContent && bitcoinPrice != null) {
        _updateFiatFromBitcoin(bitcoinPrice, fiatRate);
      } else {
        _currController!.text = '';
      }
    } else {
      // Switching to bitcoin mode - convert fiat to bitcoin
      if (_currController!.text.isNotEmpty && bitcoinPrice != null) {
        _updateBitcoinFromFiat(bitcoinPrice, fiatRate);
      } else {
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
        _btcController!.text = unitEquivalent.amount.toStringAsFixed(8);
      } else {
        _satController!.text = unitEquivalent.amount.toInt().toString();
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

  /// Get current amount in the active unit
  double getCurrentAmount() {
    if (_swapped) {
      return double.tryParse(_currController?.text ?? '0') ?? 0.0;
    }
    if (_currentUnit == CurrencyType.bitcoin) {
      return double.tryParse(_btcController?.text ?? '0') ?? 0.0;
    }
    return double.tryParse(_satController?.text ?? '0') ?? 0.0;
  }

  @override
  void dispose() {
    // No listeners to remove anymore
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
          convertedNewValue = convertedNewValue *
              BitcoinConstants.satsPerBtc; // Convert to sats
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

/// Input formatter that converts comma to dot for decimal input
/// This allows users with European/Apple keyboards to use comma as decimal separator
class CommaToDecimalFormatter extends TextInputFormatter {
  const CommaToDecimalFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Replace comma with dot
    final newText = newValue.text.replaceAll(',', '.');

    if (newText == newValue.text) {
      return newValue;
    }

    // Adjust cursor position if text changed
    return TextEditingValue(
      text: newText,
      selection: newValue.selection,
    );
  }
}

// Enums and utility classes needed by AmountWidget
enum CurrencyType { bitcoin, sats, usd }
