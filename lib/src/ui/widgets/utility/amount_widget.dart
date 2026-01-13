import 'dart:async';

import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:provider/provider.dart';

class AmountWidget extends StatefulWidget {
  final bool Function()? enabled;
  final TextEditingController btcController;
  final TextEditingController currController;
  final TextEditingController satController;
  final FocusNode focusNode;
  final CurrencyType bitcoinUnit;
  final bool swapped;
  final int? lowerBound;
  final int? upperBound;
  final CurrencyType? boundType;
  final Function()? init;
  final Function(String currencyType, String text)? onAmountChange;
  final bool autoConvert;
  final bool Function()? preventConversion;
  final Function(double currentVal)? underBoundFunc;
  final Function(double currentVal)? inBoundFunc;
  final Function(double currentVal)? overBoundFunc;
  final Function(String inputState)? onInputStateChange;
  final double? bitcoinPrice;

  const AmountWidget({
    super.key,
    required this.enabled,
    required this.btcController,
    required this.satController,
    required this.currController,
    required this.focusNode,
    this.bitcoinUnit = CurrencyType.sats,
    this.swapped = true,
    this.lowerBound,
    this.upperBound,
    this.boundType,
    required this.autoConvert,
    this.onAmountChange,
    this.init,
    this.preventConversion,
    this.underBoundFunc,
    this.inBoundFunc,
    this.overBoundFunc,
    this.onInputStateChange,
    this.bitcoinPrice,
  });

  @override
  State<AmountWidget> createState() => _AmountWidgetState();
}

class _AmountWidgetState extends State<AmountWidget>
    with WidgetsBindingObserver {
  late AmountWidgetService _service;
  bool _wasKeyboardVisible = false;
  Timer? _keyboardDebounceTimer;

  // Cached input formatters - created once, updated when needed
  List<TextInputFormatter>? _cachedFormatters;
  bool _formattersNeedUpdate = true;

  // Cache for display values to avoid rebuilds
  String _displayFiat = "";
  String _displayBtc = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.init?.call();

    _service = AmountWidgetService();

    // Determine initial swapped state based on user's display preference
    // showCoinBalance = true means user prefers BTC/sats (swapped = false)
    // showCoinBalance = false means user prefers fiat (swapped = true)
    final currencyService = context.read<CurrencyPreferenceService>();
    final initialSwapped = !currencyService.showCoinBalance;

    _service.initialize(
      btcController: widget.btcController,
      satController: widget.satController,
      currController: widget.currController,
      initialSwapped: initialSwapped,
      preventConversionValue: widget.preventConversion?.call() ?? false,
      enabledValue: widget.enabled?.call() ?? true,
      initialUnit: widget.bitcoinUnit,
      onInputStateChange: widget.onInputStateChange,
    );

    // Call the callback with initial state - only once
    if (widget.onInputStateChange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onInputStateChange!(
          initialSwapped ? "currency" : _service.currentUnit.name.toLowerCase(),
        );
      });
    }

    // Initial conversion calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateConversions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardDebounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mark formatters for update if relevant props changed
    if (oldWidget.boundType != widget.boundType ||
        oldWidget.lowerBound != widget.lowerBound ||
        oldWidget.upperBound != widget.upperBound ||
        oldWidget.bitcoinPrice != widget.bitcoinPrice) {
      _formattersNeedUpdate = true;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Debounce keyboard detection to avoid 60+ calls during animation
    _keyboardDebounceTimer?.cancel();
    _keyboardDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (_wasKeyboardVisible && !keyboardVisible) {
        // Keyboard was just dismissed - unfocus amount field
        widget.focusNode.unfocus();
      }
      _wasKeyboardVisible = keyboardVisible;
    });
  }

  /// Get fiat rate from currency service
  double? _getFiatRate(CurrencyPreferenceService currencyService) {
    final exchangeRates = currencyService.exchangeRates;
    return exchangeRates?.rates[currencyService.code];
  }

  /// Update conversions when input changes - called from onChanged, NOT build
  void _updateConversions() {
    final currencyService = context.read<CurrencyPreferenceService>();
    final fiatRate = _getFiatRate(currencyService);

    _service.onInputChanged(
      bitcoinPrice: widget.bitcoinPrice,
      fiatRate: fiatRate,
    );

    // Update cached display values
    _displayFiat = _service.cachedFiatDisplay;
    _displayBtc = _service.cachedBtcDisplay;

    // Handle auto-convert if enabled
    if (widget.autoConvert && !_service.swapped) {
      final amount = _service.currentUnit == CurrencyType.bitcoin
          ? double.tryParse(widget.btcController.text.isEmpty
                  ? "0"
                  : widget.btcController.text) ??
              0.0
          : double.tryParse(widget.satController.text.isEmpty
                  ? "0"
                  : widget.satController.text) ??
              0.0;

      final unitEquivalent =
          _service.convertToBitcoinUnit(amount, _service.currentUnit);
      _service.processAutoConvert(unitEquivalent);
    }
  }

  /// Handle text input changes
  void _handleInputChange(String text) {
    _updateConversions();

    // Notify parent of amount change
    if (widget.onAmountChange != null) {
      final currencyService = context.read<CurrencyPreferenceService>();
      final currencyType =
          _service.swapped ? currencyService.code : _service.currentUnit.name;
      widget.onAmountChange!(
        currencyType,
        widget.btcController.text.isEmpty ? '0' : widget.btcController.text,
      );
    }

    // Trigger rebuild to update display
    setState(() {});
  }

  /// Get or create cached input formatters
  List<TextInputFormatter> _getInputFormatters(double? bitcoinPrice) {
    if (!_formattersNeedUpdate && _cachedFormatters != null) {
      return _cachedFormatters!;
    }

    List<TextInputFormatter> formatters = [];

    // Add bound input formatter if boundType exists
    if (widget.boundType != null && bitcoinPrice != null) {
      formatters.add(
        BoundInputFormatter(
          swapped: _service.swapped,
          lowerBound: widget.lowerBound ?? 0,
          upperBound: widget.upperBound ?? 999999999999999,
          boundType: widget.boundType!,
          valueType: _service.currentUnit,
          bitcoinPrice: bitcoinPrice,
          overBound: widget.overBoundFunc,
          underBound: widget.underBoundFunc,
          inBound: widget.inBoundFunc,
        ),
      );
    }

    // Add filtering formatter based on unit and swapped state
    if (_service.currentUnit == CurrencyType.sats && !_service.swapped) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'(^\d+)')));
    } else {
      formatters.add(const CommaToDecimalFormatter());
      formatters.add(
        FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)')),
      );
    }

    // Add numerical range formatter
    formatters.add(
      NumericalRangeFormatter(
        min: 0,
        max: (widget.upperBound != null && widget.upperBound! > 99999999999)
            ? widget.upperBound!.toDouble()
            : 99999999999,
      ),
    );

    _cachedFormatters = formatters;
    _formattersNeedUpdate = false;
    return formatters;
  }

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final bitcoinPrice = widget.bitcoinPrice;
    // Use read instead of watch - we update display via setState in _handleInputChange
    final currencyService = context.read<CurrencyPreferenceService>();

    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        // Mark formatters for update when service state changes (swapped/unit)
        _formattersNeedUpdate = true;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input field
              TextField(
                enabled: _service.enabled,
                focusNode: widget.focusNode,
                onTapOutside: (_) {
                  if (widget.focusNode.hasFocus) {
                    widget.focusNode.unfocus();
                  }
                },
                textAlign: TextAlign.left,
                onChanged: _handleInputChange,
                maxLength: widget.lowerBound != null ? 20 : 10,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _getInputFormatters(bitcoinPrice),
                decoration: InputDecoration(
                  suffixIcon: _service.swapped
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currencyService.symbol,
                              style: TextStyle(
                                fontSize: 24,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        )
                      : _getCurrencyIcon(
                          context,
                          _service.currentUnit,
                          size: 24.0,
                        ),
                  border: InputBorder.none,
                  counterText: "",
                  hintText: "0",
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)),
                ),
                controller: _service.getCurrentController(),
                autofocus: false,
                style: materialTheme.textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8.0),
              // Conversion display - tap to swap
              GestureDetector(
                onTap: () {
                  final fiatRate = _getFiatRate(currencyService);
                  _service.toggleSwapped(bitcoinPrice, fiatRate);
                  widget.focusNode.unfocus();

                  // Update display values after swap
                  _displayFiat = _service.cachedFiatDisplay;
                  _displayBtc = _service.cachedBtcDisplay;

                  if (widget.onAmountChange != null) {
                    widget.onAmountChange!(
                      _service.currentUnit.name,
                      widget.btcController.text,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: !_service.swapped
                    ? _buildBitcoinToMoneyDisplay(
                        context, bitcoinPrice, currencyService)
                    : _buildMoneyToBitcoinDisplay(context, currencyService),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Display fiat equivalent - NO conversions here, just display cached value
  Widget _buildBitcoinToMoneyDisplay(
    BuildContext context,
    double? bitcoinPrice,
    CurrencyPreferenceService currencyService,
  ) {
    final materialTheme = Theme.of(context);
    final textColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    // Show placeholder if no value or no price
    if (_displayFiat.isEmpty || bitcoinPrice == null) {
      return Text(
        "\u2248 ${currencyService.symbol}0",
        style: materialTheme.textTheme.bodyLarge?.copyWith(color: textColor),
      );
    }

    // Parse the cached fiat display for formatting
    final fiatValue = double.tryParse(_displayFiat) ?? 0.0;
    // Convert back from local currency rate for formatAmount (which applies rate internally)
    final exchangeRates = currencyService.exchangeRates;
    final fiatRate = exchangeRates?.rates[currencyService.code] ?? 1.0;
    final usdValue = fiatValue / fiatRate;

    return Text(
      "\u2248 ${currencyService.formatAmount(usdValue)}",
      style: materialTheme.textTheme.bodyLarge?.copyWith(color: textColor),
    );
  }

  /// Display bitcoin equivalent - NO conversions here, just display cached value
  Widget _buildMoneyToBitcoinDisplay(
    BuildContext context,
    CurrencyPreferenceService currencyService,
  ) {
    final materialTheme = Theme.of(context);
    final textColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    // Show placeholder if no value
    final displayValue = _displayBtc.isEmpty ? "0" : _displayBtc;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "\u2248 $displayValue",
          style: materialTheme.textTheme.bodyLarge?.copyWith(color: textColor),
        ),
        const SizedBox(width: 4),
        _getCurrencyIcon(context, _service.currentUnit),
      ],
    );
  }

  Widget _getCurrencyIcon(BuildContext context, CurrencyType type,
      {double? size}) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    switch (type) {
      case CurrencyType.bitcoin:
        return Icon(
          Icons.currency_bitcoin,
          color: color,
          size: size,
        );
      case CurrencyType.sats:
        return Text("sat", style: TextStyle(fontSize: size, color: color));
      case CurrencyType.usd:
        return Icon(Icons.attach_money, color: color, size: size);
    }
  }
}
