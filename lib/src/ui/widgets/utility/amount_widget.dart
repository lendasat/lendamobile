import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:flutter/material.dart';
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

class _AmountWidgetState extends State<AmountWidget> {
  late AmountWidgetService _service;

  @override
  void initState() {
    super.initState();
    widget.init?.call();

    _service = AmountWidgetService();

    _service.initialize(
      btcController: widget.btcController,
      satController: widget.satController,
      currController: widget.currController,
      initialSwapped: widget.swapped,
      preventConversionValue: widget.preventConversion?.call() ?? false,
      enabledValue: widget.enabled?.call() ?? true,
      initialUnit: widget.bitcoinUnit,
      onInputStateChange: widget.onInputStateChange,
    );

    // Call the callback with initial state
    if (widget.onInputStateChange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInputStateChange!(
          _service.swapped
              ? "currency"
              : _service.currentUnit.name.toLowerCase(),
        );
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final bitcoinPrice = widget.bitcoinPrice;
    final currencyService = context.watch<CurrencyPreferenceService>();

    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final currencyType =
            _service.swapped ? currencyService.code : _service.currentUnit.name;

        return Column(
          children: [
            Row(
              children: [
                // Swap button
                IconButton(
                  icon: Icon(Icons.swap_vert,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () {
                    _service.toggleSwapped(bitcoinPrice);
                    widget.focusNode.unfocus();
                    if (widget.onAmountChange != null) {
                      widget.onAmountChange!(
                        _service.currentUnit.name,
                        widget.btcController.text,
                      );
                    }
                  },
                ),
                // Input field
                Expanded(
                  child: TextField(
                    enabled: _service.enabled,
                    focusNode: widget.focusNode,
                    onTapOutside: (_) {
                      if (widget.focusNode.hasFocus) {
                        widget.focusNode.unfocus();
                      }
                    },
                    textAlign: TextAlign.center,
                    onChanged: (text) {
                      if (!_service.swapped) {
                        if (_service.currentUnit == CurrencyType.sats) {
                          widget.btcController.text = (double.tryParse(
                                    widget.satController.text,
                                  ) ??
                                  0 / BitcoinConstants.satsPerBtc)
                              .toStringAsFixed(8);
                        } else {
                          widget.satController.text =
                              ((double.tryParse(widget.btcController.text) ??
                                          0) *
                                      BitcoinConstants.satsPerBtc)
                                  .toInt()
                                  .toString();
                        }
                      }
                      if (widget.onAmountChange != null && !_service.swapped) {
                        widget.onAmountChange!(
                          currencyType,
                          widget.btcController.text.isEmpty
                              ? '0'
                              : widget.btcController.text,
                        );
                      }
                    },
                    maxLength: widget.lowerBound != null ? 20 : 10,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _service.getInputFormatters(
                      hasBoundType: widget.boundType != null,
                      context: context,
                      bitcoinPrice: bitcoinPrice,
                      lowerBound: widget.lowerBound,
                      upperBound: widget.upperBound,
                      boundType: widget.boundType,
                      overBoundCallback: widget.overBoundFunc,
                      underBoundCallback: widget.underBoundFunc,
                      inBoundCallback: widget.inBoundFunc,
                    ),
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
                      hintText: "0.0",
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
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            // Conversion display
            Center(
              child: !_service.swapped
                  ? _buildBitcoinToMoneyWidget(
                      context, bitcoinPrice, currencyService)
                  : _buildMoneyToBitcoinWidget(
                      context, bitcoinPrice, currencyService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBitcoinToMoneyWidget(
    BuildContext context,
    double? bitcoinPrice,
    CurrencyPreferenceService currencyService,
  ) {
    final materialTheme = Theme.of(context);

    if (bitcoinPrice == null) {
      return Text(
        "≈ ${currencyService.formatAmount(0.0)}",
        style: materialTheme.textTheme.bodyLarge?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
      );
    }

    final amount = _service.currentUnit == CurrencyType.bitcoin
        ? double.tryParse(
              widget.btcController.text.isEmpty
                  ? "0.0"
                  : widget.btcController.text,
            ) ??
            0.0
        : double.tryParse(
              widget.satController.text.isEmpty
                  ? "0"
                  : widget.satController.text,
            ) ??
            0.0;

    double btcAmount =
        _service.currentUnit == CurrencyType.sats ? amount / BitcoinConstants.satsPerBtc : amount;
    double usdAmount = btcAmount * bitcoinPrice;

    if (!_service.preventConversion) {
      widget.currController.text = usdAmount.toStringAsFixed(2);
    }

    if (widget.autoConvert) {
      final unitEquivalent = _service.convertToBitcoinUnit(
        amount,
        _service.currentUnit,
      );
      _service.processAutoConvert(unitEquivalent);
    }

    return Text(
      "≈ ${currencyService.formatAmount(usdAmount)}",
      style: materialTheme.textTheme.bodyLarge?.copyWith(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
    );
  }

  Widget _buildMoneyToBitcoinWidget(
    BuildContext context,
    double? bitcoinPrice,
    CurrencyPreferenceService currencyService,
  ) {
    final materialTheme = Theme.of(context);

    if (bitcoinPrice == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "≈ 0.00",
            style: materialTheme.textTheme.bodyLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          _getCurrencyIcon(context, _service.currentUnit),
        ],
      );
    }

    final currAmount = double.tryParse(
          widget.currController.text.isEmpty
              ? "0.0"
              : widget.currController.text,
        ) ??
        0.0;
    final btcAmount = currAmount / bitcoinPrice;
    final satAmount = (btcAmount * BitcoinConstants.satsPerBtc).round();

    if (!_service.preventConversion) {
      widget.btcController.text = btcAmount.toString();
      widget.satController.text = satAmount.toString();
    }

    if (widget.autoConvert) {
      final amount = _service.currentUnit == CurrencyType.bitcoin
          ? double.tryParse(
                widget.btcController.text.isEmpty
                    ? "0.0"
                    : widget.btcController.text,
              ) ??
              0.0
          : double.tryParse(
                widget.satController.text.isEmpty
                    ? "0"
                    : widget.satController.text,
              ) ??
              0.0;

      final unitEquivalent = _service.convertToBitcoinUnit(
        amount,
        _service.currentUnit,
      );
      _service.processAutoConvert(unitEquivalent);
    }

    if (widget.onAmountChange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAmountChange!(
          _service.swapped ? currencyService.code : _service.currentUnit.name,
          widget.btcController.text.isEmpty ? '0' : widget.btcController.text,
        );
      });
    }

    final displayAmount = _service.currentUnit == CurrencyType.bitcoin
        ? widget.btcController.text
        : widget.satController.text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "≈ $displayAmount",
          style: materialTheme.textTheme.bodyLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7)),
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
