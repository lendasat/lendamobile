import 'dart:async';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart'
    show CurrencyType;
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart' as lendaswap_api;
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/evm_address_input_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_amount_card.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_confirmation_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/fee_breakdown_sheet.dart';
import 'package:ark_flutter/src/ui/screens/swap/evm_swap_funding_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/swap_monitoring_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  SwapScreenState createState() => SwapScreenState();
}

class SwapScreenState extends State<SwapScreen>
    with SingleTickerProviderStateMixin {
  // Selected tokens
  SwapToken sourceToken = SwapToken.bitcoin;

  // Swap button animation
  late AnimationController _swapButtonController;
  late Animation<double> _swapButtonAnimation;
  SwapToken targetToken = SwapToken.usdcPolygon;

  // Amount values (stored as strings for precise decimal handling)
  String btcAmount = '';
  String usdAmount = '';
  String satsAmount = ''; // Sats amount (parallel to btcAmount)
  String tokenAmount = ''; // For non-stablecoin tokens like XAUT

  // Input mode: true = show USD as main input, false = show native token
  bool sourceShowUsd = false;
  bool targetShowUsd = true; // Target defaults to USD for stablecoins

  // BTC unit tracking for auto-switching between sats and BTC
  CurrencyType _sourceBtcUnit = CurrencyType.sats;
  CurrencyType _targetBtcUnit = CurrencyType.sats;

  // Approximate XAUt (gold) price - 1 XAUt ≈ 1 oz gold
  static const double xautUsdPrice = 2650.0;

  // Bitcoin price data
  List<PriceData> _bitcoinPriceData = [];

  // Get current BTC price from fetched data
  double get btcUsdPrice {
    if (_bitcoinPriceData.isEmpty) return 104000.0; // Fallback
    return _bitcoinPriceData.last.price;
  }

  // Scroll controller
  final ScrollController scrollController = ScrollController();

  // Loading state
  bool isLoading = false;

  // Quote state
  lendaswap_api.SwapQuote? _quote;
  bool _isLoadingQuote = false;
  Timer? _quoteDebounceTimer;

  // Balance state (for insufficient funds checking)
  BigInt _availableBalanceSats = BigInt.zero;
  BigInt _spendableBalanceSats =
      BigInt.zero; // Confirmed + pending for max button
  bool _isLoadingBalance = true;

  // Swap service
  final LendaSwapService _swapService = LendaSwapService();

  // Text controllers and focus nodes
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _targetFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBitcoinPrice();
    _loadBalance();

    // Initialize swap button animation
    _swapButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _swapButtonAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _swapButtonController, curve: Curves.easeInOut),
    );
  }

  /// Load wallet balance for insufficient funds checking
  Future<void> _loadBalance() async {
    try {
      final balance = await ark_api.balance();
      if (mounted) {
        setState(() {
          _availableBalanceSats = balance.offchain.totalSats;
          _spendableBalanceSats =
              balance.offchain.confirmedSats + balance.offchain.pendingSats;
          _isLoadingBalance = false;
        });
        logger.d(
            "Swap screen balance loaded: $_availableBalanceSats sats (spendable: $_spendableBalanceSats)");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  /// Public method to refresh balance - called when tab becomes visible
  void refreshBalance() {
    _loadBalance();
  }

  Future<void> _loadBitcoinPrice() async {
    try {
      final priceData = await fetchBitcoinPriceData(TimeRange.day);
      if (mounted && priceData.isNotEmpty) {
        setState(() {
          _bitcoinPriceData = priceData;
        });
      }
    } catch (e) {
      // Silently fail - will use fallback price
    }
  }

  @override
  void dispose() {
    _quoteDebounceTimer?.cancel();
    _sourceController.dispose();
    _targetController.dispose();
    _sourceFocusNode.dispose();
    _targetFocusNode.dispose();
    scrollController.dispose();
    _swapButtonController.dispose();
    super.dispose();
  }

  /// Unfocus all text fields and cancel pending operations
  /// Called when screen becomes invisible (tab switch)
  void unfocusAll() {
    _sourceFocusNode.unfocus();
    _targetFocusNode.unfocus();
    // Cancel any pending quote fetch to prevent callbacks after tab switch
    _quoteDebounceTimer?.cancel();
  }

  /// Fetch quote from LendaSwap API with debouncing
  void _fetchQuoteDebounced() {
    _quoteDebounceTimer?.cancel();
    _quoteDebounceTimer = Timer(AppTimeouts.quoteDebounce, () {
      _fetchQuote();
    });
  }

  /// Fetch quote from LendaSwap API
  Future<void> _fetchQuote() async {
    // Parse BTC amount
    final btc = double.tryParse(btcAmount) ?? 0;
    if (btc <= 0) {
      setState(() {
        _quote = null;
        _isLoadingQuote = false;
      });
      return;
    }

    setState(() => _isLoadingQuote = true);

    try {
      final sats = (btc * BitcoinConstants.satsPerBtc).round();
      final quote = await lendaswap_api.lendaswapGetQuote(
        fromToken: sourceToken.tokenId,
        toToken: targetToken.tokenId,
        amountSats: BigInt.from(sats),
      );

      if (mounted) {
        setState(() {
          _quote = quote;
          _isLoadingQuote = false;
        });
      }
    } catch (e) {
      logger.e('Failed to fetch quote: $e');
      if (mounted) {
        setState(() {
          _quote = null;
          _isLoadingQuote = false;
        });
      }
    }
  }

  /// Convert BTC to USD
  double btcToUsd(double btc) => btc * btcUsdPrice;

  /// Convert USD to BTC
  double usdToBtc(double usd) => usd / btcUsdPrice;

  /// Format BTC amount (up to 8 decimals)
  String formatBtc(double btc) {
    if (btc == 0) return '0';
    if (btc < 0.00001) return btc.toStringAsFixed(8);
    if (btc < 0.001) return btc.toStringAsFixed(6);
    if (btc < 1) return btc.toStringAsFixed(5);
    return btc.toStringAsFixed(4);
  }

  /// Format USD amount (2 decimals)
  String formatUsd(double usd) {
    return usd.toStringAsFixed(2);
  }

  /// Format sats amount
  String formatSats(int sats) {
    if (sats >= 1000000) {
      return '${(sats / 1000000).toStringAsFixed(2)}M';
    } else if (sats >= 1000) {
      return '${(sats / 1000).toStringAsFixed(1)}k';
    }
    return sats.toString();
  }

  /// Check if BTC unit should switch based on amount thresholds
  /// Returns (newUnit, convertedAmount)
  /// Thresholds: >= 100M sats -> BTC, < 0.001 BTC -> sats
  (CurrencyType, String) _checkBtcUnitThreshold(
      double amount, CurrencyType currentUnit) {
    if (currentUnit == CurrencyType.sats) {
      // If sats >= 1 BTC (100,000,000), switch to BTC
      if (amount >= BitcoinConstants.satsPerBtc) {
        return (
          CurrencyType.bitcoin,
          formatBtc(amount / BitcoinConstants.satsPerBtc)
        );
      }
      return (CurrencyType.sats, amount.toInt().toString());
    } else {
      // If BTC < 0.001 (100,000 sats), switch to sats
      if (amount < 0.001 && amount > 0) {
        return (
          CurrencyType.sats,
          (amount * BitcoinConstants.satsPerBtc).round().toString()
        );
      }
      return (CurrencyType.bitcoin, formatBtc(amount));
    }
  }

  void _onSourceAmountChanged(String value) {
    setState(() {
      if (sourceToken.isBtc) {
        if (sourceShowUsd) {
          // User entered USD, convert to BTC and sats
          usdAmount = value;
          final usd = double.tryParse(value) ?? 0;
          final btc = usd > 0 ? usdToBtc(usd) : 0.0;
          btcAmount = btc > 0 ? formatBtc(btc) : '';
          satsAmount = btc > 0
              ? (btc * BitcoinConstants.satsPerBtc).round().toString()
              : '';
        } else {
          // User entering sats or BTC based on current unit
          if (_sourceBtcUnit == CurrencyType.sats) {
            // User entering sats (integers)
            satsAmount = value;
            final sats = double.tryParse(value) ?? 0;
            final btc = sats / BitcoinConstants.satsPerBtc;
            btcAmount = sats > 0 ? btc.toString() : '';
            usdAmount = sats > 0 ? formatUsd(btcToUsd(btc)) : '';

            // Check for auto-switch to BTC
            if (sats > 0) {
              final (newUnit, newAmount) =
                  _checkBtcUnitThreshold(sats, CurrencyType.sats);
              if (newUnit != _sourceBtcUnit) {
                _sourceBtcUnit = newUnit;
                // Update controller text after setState completes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _sourceController.text = newAmount;
                });
              }
            }
          } else {
            // User entering BTC (decimals)
            btcAmount = value;
            final btc = double.tryParse(value) ?? 0;
            satsAmount = btc > 0
                ? (btc * BitcoinConstants.satsPerBtc).round().toString()
                : '';
            usdAmount = btc > 0 ? formatUsd(btcToUsd(btc)) : '';

            // Check for auto-switch to sats
            if (btc > 0) {
              final (newUnit, newAmount) =
                  _checkBtcUnitThreshold(btc, CurrencyType.bitcoin);
              if (newUnit != _sourceBtcUnit) {
                _sourceBtcUnit = newUnit;
                // Update controller text after setState completes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _sourceController.text = newAmount;
                });
              }
            }
          }
        }
      } else if (sourceToken.isStablecoin) {
        // Source is stablecoin (1 token = $1)
        usdAmount = value;
        tokenAmount = value;
        final usd = double.tryParse(value) ?? 0;
        final btc = usd > 0 ? usdToBtc(usd) : 0.0;
        btcAmount = btc > 0 ? formatBtc(btc) : '';
        satsAmount = btc > 0
            ? (btc * BitcoinConstants.satsPerBtc).round().toString()
            : '';
      } else {
        // Source is non-stablecoin (e.g., XAUT)
        // User enters token amount, we convert to USD
        tokenAmount = value;
        final tokens = double.tryParse(value) ?? 0;
        final usd = tokens * xautUsdPrice;
        final btc = usd > 0 ? usdToBtc(usd) : 0.0;
        usdAmount = usd > 0 ? formatUsd(usd) : '';
        btcAmount = btc > 0 ? formatBtc(btc) : '';
        satsAmount = btc > 0
            ? (btc * BitcoinConstants.satsPerBtc).round().toString()
            : '';
      }

      // Update target amount
      _updateTargetAmount();
    });

    // Fetch quote with debouncing
    _fetchQuoteDebounced();
  }

  void _onTargetAmountChanged(String value) {
    setState(() {
      if (targetToken.isBtc) {
        if (targetShowUsd) {
          // User entered USD, convert to BTC and sats
          usdAmount = value;
          final usd = double.tryParse(value) ?? 0;
          final btc = usd > 0 ? usdToBtc(usd) : 0.0;
          btcAmount = btc > 0 ? formatBtc(btc) : '';
          satsAmount = btc > 0
              ? (btc * BitcoinConstants.satsPerBtc).round().toString()
              : '';
        } else {
          // User entering sats or BTC based on current unit
          if (_targetBtcUnit == CurrencyType.sats) {
            // User entering sats (integers)
            satsAmount = value;
            final sats = double.tryParse(value) ?? 0;
            final btc = sats / BitcoinConstants.satsPerBtc;
            btcAmount = sats > 0 ? btc.toString() : '';
            usdAmount = sats > 0 ? formatUsd(btcToUsd(btc)) : '';

            // Check for auto-switch to BTC
            if (sats > 0) {
              final (newUnit, newAmount) =
                  _checkBtcUnitThreshold(sats, CurrencyType.sats);
              if (newUnit != _targetBtcUnit) {
                _targetBtcUnit = newUnit;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _targetController.text = newAmount;
                });
              }
            }
          } else {
            // User entering BTC (decimals)
            btcAmount = value;
            final btc = double.tryParse(value) ?? 0;
            satsAmount = btc > 0
                ? (btc * BitcoinConstants.satsPerBtc).round().toString()
                : '';
            usdAmount = btc > 0 ? formatUsd(btcToUsd(btc)) : '';

            // Check for auto-switch to sats
            if (btc > 0) {
              final (newUnit, newAmount) =
                  _checkBtcUnitThreshold(btc, CurrencyType.bitcoin);
              if (newUnit != _targetBtcUnit) {
                _targetBtcUnit = newUnit;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _targetController.text = newAmount;
                });
              }
            }
          }
        }
      } else if (targetToken.isStablecoin) {
        // Target is stablecoin (1 token = $1)
        usdAmount = value;
        tokenAmount = value;
        final usd = double.tryParse(value) ?? 0;
        final btc = usd > 0 ? usdToBtc(usd) : 0.0;
        btcAmount = btc > 0 ? formatBtc(btc) : '';
        satsAmount = btc > 0
            ? (btc * BitcoinConstants.satsPerBtc).round().toString()
            : '';
      } else {
        // Target is non-stablecoin (e.g., XAUT)
        // User enters token amount, we convert to USD
        tokenAmount = value;
        final tokens = double.tryParse(value) ?? 0;
        final usd = tokens * xautUsdPrice;
        final btc = usd > 0 ? usdToBtc(usd) : 0.0;
        usdAmount = usd > 0 ? formatUsd(usd) : '';
        btcAmount = btc > 0 ? formatBtc(btc) : '';
        satsAmount = btc > 0
            ? (btc * BitcoinConstants.satsPerBtc).round().toString()
            : '';
      }

      // Update source amount
      _updateSourceAmount();
    });

    // Fetch quote with debouncing
    _fetchQuoteDebounced();
  }

  void _updateTargetAmount() {
    if (targetToken.isBtc) {
      if (targetShowUsd) {
        _targetController.text = usdAmount;
      } else {
        // Show sats or BTC based on current unit
        _targetController.text =
            _targetBtcUnit == CurrencyType.sats ? satsAmount : btcAmount;
      }
    } else if (targetToken.isStablecoin) {
      // Target is stablecoin - show USD amount (1:1 with token)
      _targetController.text = usdAmount;
      tokenAmount = usdAmount; // For stablecoins, token amount = USD amount
    } else {
      // Target is non-stablecoin (e.g., XAUT) - convert USD to token amount
      final usd = double.tryParse(usdAmount) ?? 0;
      if (usd > 0) {
        final tokens = usd / xautUsdPrice;
        tokenAmount = tokens.toStringAsFixed(6);
        _targetController.text = tokenAmount;
      } else {
        tokenAmount = '';
        _targetController.text = '';
      }
    }
  }

  void _updateSourceAmount() {
    if (sourceToken.isBtc) {
      if (sourceShowUsd) {
        _sourceController.text = usdAmount;
      } else {
        // Show sats or BTC based on current unit
        _sourceController.text =
            _sourceBtcUnit == CurrencyType.sats ? satsAmount : btcAmount;
      }
    } else if (sourceToken.isStablecoin) {
      // Source is stablecoin - show USD amount (1:1 with token)
      _sourceController.text = usdAmount;
      tokenAmount = usdAmount;
    } else {
      // Source is non-stablecoin (e.g., XAUT) - convert USD to token amount
      final usd = double.tryParse(usdAmount) ?? 0;
      if (usd > 0) {
        final tokens = usd / xautUsdPrice;
        tokenAmount = tokens.toStringAsFixed(6);
        _sourceController.text = tokenAmount;
      } else {
        tokenAmount = '';
        _sourceController.text = '';
      }
    }
  }

  void _toggleSourceMode() {
    setState(() {
      sourceShowUsd = !sourceShowUsd;
      if (sourceToken.isBtc) {
        if (sourceShowUsd) {
          _sourceController.text = usdAmount;
        } else {
          _sourceController.text =
              _sourceBtcUnit == CurrencyType.sats ? satsAmount : btcAmount;
        }
      }
    });
  }

  void _toggleTargetMode() {
    setState(() {
      targetShowUsd = !targetShowUsd;
      if (targetToken.isBtc) {
        if (targetShowUsd) {
          _targetController.text = usdAmount;
        } else {
          _targetController.text =
              _targetBtcUnit == CurrencyType.sats ? satsAmount : btcAmount;
        }
      }
    });
  }

  void _onSwapButtonTapDown(TapDownDetails details) {
    _swapButtonController.forward();
  }

  void _onSwapButtonTapUp(TapUpDetails details) {
    // Ensure forward completes before reversing (for quick taps)
    _swapButtonController
        .forward()
        .then((_) => _swapButtonController.reverse());
  }

  void _onSwapButtonTapCancel() {
    _swapButtonController.reverse();
  }

  void _swapTokens() {
    HapticFeedback.lightImpact();
    setState(() {
      // Swap the tokens
      final temp = sourceToken;
      sourceToken = targetToken;
      targetToken = temp;

      // Swap modes
      final tempMode = sourceShowUsd;
      sourceShowUsd = targetShowUsd;
      targetShowUsd = tempMode;

      // Update controllers
      _updateSourceAmount();
      _updateTargetAmount();
    });

    // Fetch new quote for swapped tokens
    _fetchQuoteDebounced();
  }

  void _onSourceTokenChanged(SwapToken token) {
    setState(() {
      sourceToken = token;
      // Reset to appropriate input mode
      sourceShowUsd = !token.isBtc; // Show USD for stablecoins

      if (token.isBtc == targetToken.isBtc) {
        if (token.isBtc) {
          targetToken = SwapToken.usdcPolygon;
          targetShowUsd = true;
        } else {
          targetToken = SwapToken.bitcoin;
          targetShowUsd = false;
        }
      }
      _updateSourceAmount();
      _updateTargetAmount();
    });

    // Fetch new quote for changed token
    _fetchQuoteDebounced();
  }

  void _onTargetTokenChanged(SwapToken token) {
    setState(() {
      targetToken = token;
      targetShowUsd = !token.isBtc;

      if (token.isBtc == sourceToken.isBtc) {
        if (token.isBtc) {
          sourceToken = SwapToken.usdcPolygon;
          sourceShowUsd = true;
        } else {
          sourceToken = SwapToken.bitcoin;
          sourceShowUsd = false;
        }
      }
      _updateSourceAmount();
      _updateTargetAmount();
    });

    // Fetch new quote for changed token
    _fetchQuoteDebounced();
  }

  /// Minimum swap amount in sats
  static const int _minSwapSats = 1000;

  /// Check if current amount is below minimum
  bool get _isAmountTooSmall {
    final btc = double.tryParse(btcAmount) ?? 0;
    final sats = (btc * BitcoinConstants.satsPerBtc).round();
    // Show "too small" if user has entered something (including 0) and it's below minimum
    final hasInput = _sourceController.text.isNotEmpty;
    return hasInput && sats < _minSwapSats;
  }

  /// Get total sats required including fees (from quote)
  int get _totalRequiredSats {
    final btc = double.tryParse(btcAmount) ?? 0;
    final inputSats = (btc * BitcoinConstants.satsPerBtc).round();
    if (_quote != null) {
      // Use actual fees from quote
      final networkFee = _quote!.networkFeeSats.toInt();
      final protocolFee = _quote!.protocolFeeSats.toInt();
      return inputSats + networkFee + protocolFee;
    }
    // Estimate fees if no quote yet (~0.5% for protocol + ~250 sats network)
    return inputSats + (inputSats * 0.005).round() + 250;
  }

  /// Check if user has insufficient funds for the swap including fees
  bool get _hasInsufficientFunds {
    if (_isLoadingBalance || !sourceToken.isBtc) return false;
    final btc = double.tryParse(btcAmount) ?? 0;
    if (btc <= 0) return false;
    return BigInt.from(_totalRequiredSats) > _availableBalanceSats;
  }

  /// Check if amount is valid for swap
  bool get _isAmountValid {
    final btc = double.tryParse(btcAmount) ?? 0;
    final sats = (btc * BitcoinConstants.satsPerBtc).round();
    return sats >= _minSwapSats && !_hasInsufficientFunds;
  }

  /// Check if swap can actually be executed (amount valid and not loading)
  /// Note: We don't include _isLoadingQuote here to prevent button flickering
  /// while quotes are being fetched in the background
  bool get _canSwap {
    return _isAmountValid && !isLoading;
  }

  String _getButtonTitle() {
    if (_hasInsufficientFunds) {
      return "Not enough funds";
    }
    if (_isAmountTooSmall) {
      return "Amount too small (min 1,000 sats)";
    }
    return "Swap ${sourceToken.symbol} to ${targetToken.symbol}";
  }

  /// Set the maximum swappable amount (balance minus fees from quote)
  void _setMaxAmount() async {
    logger.i(
        "Max tapped - isBtc: ${sourceToken.isBtc}, isLoadingBalance: $_isLoadingBalance, spendable: $_spendableBalanceSats");

    if (!sourceToken.isBtc || _isLoadingBalance) {
      logger.w(
          "Max button early return - isBtc: ${sourceToken.isBtc}, isLoadingBalance: $_isLoadingBalance");
      return;
    }

    // Use spendable balance (confirmed + pending) for max calculation
    final availableSats = _spendableBalanceSats.toInt();
    if (availableSats <= 0) {
      logger.w("Max button - balance is 0, setting amount to 0");
      // Set amount to 0 so user sees feedback instead of nothing happening
      setState(() {
        satsAmount = '0';
        btcAmount = '0';
        usdAmount = '0';
        _sourceController.text = '0';
      });
      _updateTargetAmount();
      return;
    }

    // If no quote exists yet, fetch one first to get accurate fee info
    if (_quote == null) {
      logger.i("No quote available, fetching quote for fee calculation...");

      // Fetch a quote for the full balance to get fee percentages
      try {
        final quote = await lendaswap_api.lendaswapGetQuote(
          fromToken: sourceToken.tokenId,
          toToken: targetToken.tokenId,
          amountSats: BigInt.from(availableSats),
        );
        if (mounted) {
          setState(() {
            _quote = quote;
          });
          // Now that we have a quote, call setMaxAmount again
          _setMaxAmount();
        }
      } catch (e) {
        logger.e("Failed to fetch quote for max calculation: $e");
        OverlayService().showError('Failed to calculate fees');
      }
      return;
    }

    // Use actual fee values from the quote API
    // Protocol fee is a percentage, network fee is fixed sats
    final protocolFeePercent = _quote!.protocolFeePercent;
    final networkFeeSats = _quote!.networkFeeSats.toInt();

    // Calculate max amount: balance - fees
    // Protocol fee formula: maxAmount * (protocolFeePercent / 100) = protocolFee
    // So: maxAmount + maxAmount * (protocolFeePercent / 100) + networkFee = availableSats
    // Therefore: maxAmount = (availableSats - networkFee) / (1 + protocolFeePercent / 100)
    final maxSwapSats = protocolFeePercent > 0
        ? ((availableSats - networkFeeSats) / (1 + protocolFeePercent / 100))
            .floor()
            .clamp(0, availableSats)
        : (availableSats - networkFeeSats).clamp(0, availableSats);

    final calculatedProtocolFee =
        (maxSwapSats * protocolFeePercent / 100).round();
    final totalFees = calculatedProtocolFee + networkFeeSats;

    logger.i(
        "Max calculation - balance: $availableSats, fees: $totalFees (protocol: $calculatedProtocolFee @ ${protocolFeePercent}%, network: $networkFeeSats), max: $maxSwapSats");

    // Always set the max amount, even if below minimum
    // The button will show "Amount too small" if below minimum
    setState(() {
      // Set sats amount
      satsAmount = maxSwapSats.toString();
      // Convert to BTC
      final btcValue = maxSwapSats / BitcoinConstants.satsPerBtc;
      btcAmount = btcValue.toStringAsFixed(8);
      // Convert to USD
      final usdValue = btcValue * btcUsdPrice;
      usdAmount = usdValue.toStringAsFixed(2);

      // Update the source controller based on current display mode
      if (sourceShowUsd) {
        _sourceController.text = usdAmount;
      } else if (_sourceBtcUnit == CurrencyType.sats) {
        _sourceController.text = satsAmount;
      } else {
        _sourceController.text = btcAmount;
      }

      logger.i(
          "Max set - sats: $satsAmount, btc: $btcAmount, usd: $usdAmount, controller: ${_sourceController.text}");
    });

    // Update target and fetch new quote
    _updateTargetAmount();
    _fetchQuoteDebounced();
  }

  List<SwapToken> _getAvailableSourceTokens() {
    // Bitcoin and Polygon stablecoins (USDC, USDT) are available as source
    return [
      ...SwapToken.btcTokens,
      ...SwapToken.polygonTokens,
    ];
  }

  List<SwapToken> _getAvailableTargetTokens() {
    // Show all available tokens as target options
    return [
      ...SwapToken.btcTokens,
      ...SwapToken.polygonTokens,
    ];
  }

  /// Get the conversion display text for source
  String _getSourceConversionText() {
    if (sourceToken.isBtc) {
      if (sourceShowUsd) {
        // Showing USD, display sats/BTC equivalent based on unit
        if (_sourceBtcUnit == CurrencyType.sats) {
          return satsAmount.isNotEmpty ? '≈ $satsAmount sats' : '≈ 0 sats';
        }
        return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
      } else {
        // Showing sats/BTC, display USD equivalent
        return usdAmount.isNotEmpty ? '≈ \$$usdAmount' : '≈ \$0.00';
      }
    } else {
      // Stablecoin - show sats/BTC equivalent based on unit
      if (_sourceBtcUnit == CurrencyType.sats) {
        return satsAmount.isNotEmpty ? '≈ $satsAmount sats' : '≈ 0 sats';
      }
      return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
    }
  }

  /// Get the conversion display text for target
  String _getTargetConversionText() {
    if (targetToken.isBtc) {
      if (targetShowUsd) {
        // Showing USD, display sats/BTC equivalent based on unit
        if (_targetBtcUnit == CurrencyType.sats) {
          return satsAmount.isNotEmpty ? '≈ $satsAmount sats' : '≈ 0 sats';
        }
        return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
      } else {
        // Showing sats/BTC, display USD equivalent
        return usdAmount.isNotEmpty ? '≈ \$$usdAmount' : '≈ \$0.00';
      }
    } else {
      // Stablecoin - show sats/BTC equivalent based on unit
      if (_targetBtcUnit == CurrencyType.sats) {
        return satsAmount.isNotEmpty ? '≈ $satsAmount sats' : '≈ 0 sats';
      }
      return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
    }
  }

  /// Initiate the swap flow
  void _initiateSwap() {
    // Dismiss keyboard immediately when starting swap flow
    FocusManager.instance.primaryFocus?.unfocus();

    // Validate amounts
    final usd = double.tryParse(usdAmount);
    if (usd == null || usd <= 0) {
      OverlayService().showError('Please enter a valid amount');
      return;
    }

    // Check swap direction
    if (sourceToken.isBtc && targetToken.isEvm) {
      // BTC -> EVM: Need to get EVM address (where to receive stablecoins)
      _showEvmAddressInput();
    } else if (sourceToken.isEvm && targetToken.isBtc) {
      // EVM -> BTC: Go directly to confirmation
      // User will send from their external wallet (MetaMask, etc.)
      // BTC will be received to wallet's Arkade address automatically
      _showConfirmation();
    } else {
      OverlayService().showError('Invalid swap pair');
    }
  }

  /// Show EVM address input sheet (for BTC -> EVM swaps)
  void _showEvmAddressInput() {
    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      child: EvmAddressInputSheet(
        tokenSymbol: targetToken.symbol,
        network: targetToken.network,
        onAddressConfirmed: (address) {
          _showConfirmation(targetEvmAddress: address);
        },
      ),
    );
  }

  // NOTE: _showEvmToBtcAddressInput was removed - for EVM → BTC swaps,
  // we no longer ask for the user's EVM address since they send from their
  // external wallet (MetaMask, etc.). The swap is created with a placeholder
  // address, and the processing screen shows the deposit address.

  /// Show swap confirmation sheet
  void _showConfirmation({
    String? targetEvmAddress,
  }) {
    // Determine which address to display in confirmation
    // For EVM→BTC, no address to show (user sends from external wallet)
    final displayAddress = targetEvmAddress;

    // Determine display amounts based on token type
    String displaySourceAmount;
    String displayTargetAmount;

    if (sourceToken.isBtc) {
      displaySourceAmount = btcAmount;
    } else if (sourceToken.isStablecoin) {
      displaySourceAmount = usdAmount;
    } else {
      displaySourceAmount = tokenAmount; // XAUT
    }

    if (targetToken.isBtc) {
      displayTargetAmount = btcAmount;
    } else if (targetToken.isStablecoin) {
      displayTargetAmount = usdAmount;
    } else {
      displayTargetAmount = tokenAmount; // XAUT
    }

    // Calculate source amount in sats for total from balance display
    final btc = double.tryParse(btcAmount) ?? 0;
    final sourceAmountSats = (btc * BitcoinConstants.satsPerBtc).round();

    arkBottomSheet(
      context: context,
      child: SwapConfirmationSheet(
        sourceToken: sourceToken,
        targetToken: targetToken,
        sourceAmount: displaySourceAmount,
        targetAmount: displayTargetAmount,
        sourceAmountUsd: usdAmount,
        targetAmountUsd: usdAmount,
        exchangeRate: btcUsdPrice,
        networkFeeSats: _quote?.networkFeeSats.toInt() ?? 0,
        protocolFeeSats: _quote?.protocolFeeSats.toInt() ?? 0,
        protocolFeePercent: _quote?.protocolFeePercent ?? 0.0,
        sourceAmountSats: sourceAmountSats,
        targetAddress: displayAddress,
        isLoading: isLoading,
        onConfirm: () => _executeSwap(targetEvmAddress: targetEvmAddress),
      ),
    );
  }

  /// Execute the swap
  Future<void> _executeSwap({
    String? targetEvmAddress,
  }) async {
    // Dismiss keyboard first to prevent it from reopening after sheet closes
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => isLoading = true);
    Navigator.pop(context); // Close confirmation sheet

    // Suppress payment notifications during swap to avoid showing "payment received"
    // when change from the outgoing transaction is detected
    PaymentOverlayService().startSuppression();

    try {
      // Initialize swap service if needed
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }

      final usd = double.tryParse(usdAmount) ?? 0;
      String swapId;

      if (sourceToken.isBtc && targetToken.isEvm) {
        // BTC -> EVM swap: Create swap and automatically fund from wallet

        // Step 1: Check wallet balance before creating swap
        final walletBalance = await ark_api.balance();
        final availableSats = walletBalance.offchain.totalSats;

        // Parse BTC amount to sats for balance check
        final btcValue = double.tryParse(btcAmount) ?? 0;
        final estimatedSats = (btcValue * BitcoinConstants.satsPerBtc).toInt();

        if (availableSats < BigInt.from(estimatedSats)) {
          throw Exception(
            'Insufficient balance. Available: $availableSats sats, Required: ~$estimatedSats sats',
          );
        }

        // Step 2: Create the swap
        // For stablecoins, token amount = usd amount (1:1)
        // For non-stablecoins (e.g., XAUT), use the calculated token amount
        final targetAmountValue = targetToken.isStablecoin
            ? usd
            : (double.tryParse(tokenAmount) ?? 0);

        final result = await _swapService.createSellBtcSwap(
          targetEvmAddress: targetEvmAddress!,
          targetAmount: targetAmountValue,
          targetToken: targetToken.tokenId,
          targetChain: targetToken.chainId,
        );
        swapId = result.swapId;

        // Start monitoring this swap for auto-claim
        SwapMonitoringService().startMonitoringSwap(swapId);

        // Step 3: Automatically fund the swap by sending BTC to HTLC address
        final satsToSend = result.satsToSend;
        final htlcAddress = result.arkadeHtlcAddress;

        logger.i(
            'Auto-funding swap $swapId: sending $satsToSend sats to $htlcAddress');

        // Verify we have enough for the actual amount (may differ slightly from estimate)
        // satsToSend is PlatformInt64 (int on native, BigInt on web), convert to BigInt for comparison
        final satsToSendBigInt = BigInt.from(satsToSend);
        if (availableSats < satsToSendBigInt) {
          // Swap was created but we can't fund it - still navigate to show status
          logger.e(
              'Insufficient balance for funding. Swap created but not funded.');
          if (mounted) {
            OverlayService().showError(
              'Swap created but insufficient balance to fund. '
              'Need $satsToSend sats, have $availableSats sats.',
            );
          }
          // Continue to navigate to processing screen - swap will show as waiting
        } else {
          // Send the BTC to fund the HTLC
          try {
            final fundingTxid = await ark_api.send(
              address: htlcAddress,
              amountSats: satsToSendBigInt,
            );
            logger.i('Swap funded successfully. TXID: $fundingTxid');
          } catch (fundingError) {
            // Funding failed but swap was created - still navigate to show status
            logger.e('Failed to fund swap: $fundingError');
            if (mounted) {
              OverlayService().showError(
                  'Failed to send funds: ${fundingError.toString()}');
            }
            // Continue to navigate - user can see swap status and potentially retry
          }
        }
      } else {
        // EVM -> BTC swap: Navigate to funding screen with WalletConnect
        // The funding screen handles wallet connection, swap creation, and HTLC funding
        logger.i('EVM to BTC swap: navigating to funding screen');

        // For stablecoins, token amount = usd amount (1:1)
        // For non-stablecoins (e.g., XAUT), use the calculated token amount
        final sourceAmountValue = sourceToken.isStablecoin
            ? usd
            : (double.tryParse(tokenAmount) ?? 0);

        // For display, use the correct amount based on token type
        String displaySourceAmount;
        String displayTargetAmount;

        if (sourceToken.isStablecoin) {
          displaySourceAmount = usdAmount;
        } else {
          displaySourceAmount = tokenAmount;
        }
        displayTargetAmount = btcAmount;

        // Stop suppression before navigating
        PaymentOverlayService().stopSuppression();
        setState(() => isLoading = false);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvmSwapFundingScreen(
                sourceToken: sourceToken,
                targetToken: targetToken,
                sourceAmount: displaySourceAmount,
                targetAmount: displayTargetAmount,
                usdAmount: sourceAmountValue,
              ),
            ),
          );
        }
        return; // Exit early - funding screen handles the rest
      }

      // Navigate back to wallet and show success message
      // Swap processing happens in the background
      if (mounted) {
        // Clear the input fields
        _sourceController.clear();
        _targetController.clear();
        setState(() {
          btcAmount = '';
          usdAmount = '';
          satsAmount = '';
          tokenAmount = '';
          _quote = null;
        });

        // Switch to wallet tab (this also refreshes wallet data)
        PaymentMonitoringService().switchToWalletTab();

        // Show success message
        OverlayService().showSuccess(
          'Swap initiated! Processing in background...',
        );
      }
    } catch (e) {
      logger.e('Swap failed: $e');
      if (mounted) {
        final errorMessage = _parseSwapError(e.toString());
        OverlayService().showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
      // Stop suppression after a delay to allow change transaction to settle
      // without showing a "payment received" notification
      Future.delayed(AppTimeouts.mediumDelay, () {
        PaymentOverlayService().stopSuppression();
      });
    }
  }

  /// Parse swap error messages and return user-friendly text
  String _parseSwapError(String error) {
    final errorLower = error.toLowerCase();

    // Check for minimum amount error
    if (errorLower.contains('min amount')) {
      // Try to extract the minimum amount from the error
      final minAmountMatch =
          RegExp(r'min amount is [₿B]?\s*([\d.,\s]+)', caseSensitive: false)
              .firstMatch(error);
      if (minAmountMatch != null) {
        final minAmount =
            minAmountMatch.group(1)?.replaceAll(' ', '') ?? '0.00001';
        return 'Amount too small. Minimum is ₿$minAmount (1,000 sats)';
      }
      return 'Amount too small. Minimum swap amount is 1,000 sats.';
    }

    // Check for maximum amount error
    if (errorLower.contains('max amount')) {
      return 'Amount too large. Please try a smaller amount.';
    }

    // Check for insufficient balance
    if (errorLower.contains('insufficient') ||
        errorLower.contains('not enough')) {
      return 'Insufficient balance for this swap.';
    }

    // Check for network errors
    if (errorLower.contains('network error') ||
        errorLower.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Check for timeout
    if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Default: clean up the error message
    // Remove "AnyhowException", stack traces, etc.
    String cleanError = error;
    if (cleanError.contains('AnyhowException(')) {
      cleanError =
          cleanError.replaceAll('AnyhowException(', '').replaceAll(')', '');
    }
    if (cleanError.contains('Stack backtrace:')) {
      cleanError = cleanError.split('Stack backtrace:')[0].trim();
    }
    if (cleanError.contains('API error:')) {
      cleanError = cleanError.split('API error:').last.trim();
    }

    // Limit length
    if (cleanError.length > 100) {
      cleanError = '${cleanError.substring(0, 97)}...';
    }

    return cleanError.isEmpty ? 'Swap failed. Please try again.' : cleanError;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ArkScaffoldUnsafe(
        context: context,
        resizeToAvoidBottomInset: true,
        body: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              unfocusAll();
            }
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.cardPadding * 3.5),
                    // Uniswap-style card stack with connected border
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.cardPadding,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // SOURCE CARD (You Sell)
                              SwapAmountCard(
                                token: sourceToken,
                                cardTitle: "Sell",
                                controller: _sourceController,
                                focusNode: _sourceFocusNode,
                                showUsdMode: sourceShowUsd,
                                conversionText: _getSourceConversionText(),
                                onAmountChanged: _onSourceAmountChanged,
                                onToggleMode: sourceToken.isBtc
                                    ? _toggleSourceMode
                                    : null,
                                availableTokens: _getAvailableSourceTokens(),
                                onTokenChanged: _onSourceTokenChanged,
                                // Only show balance for BTC (we know the user's balance)
                                // For EVM tokens, user sends from external wallet
                                showBalance: sourceToken.isBtc,
                                balanceSats: sourceToken.isBtc
                                    ? _availableBalanceSats
                                    : null,
                                label: 'sell',
                                isTopCard: true,
                                btcUnit: _sourceBtcUnit,
                                onMaxTap:
                                    sourceToken.isBtc ? _setMaxAmount : null,
                              ),
                              const SizedBox(height: 4),
                              // TARGET CARD (You Buy)
                              SwapAmountCard(
                                token: targetToken,
                                cardTitle: "Buy",
                                controller: _targetController,
                                focusNode: _targetFocusNode,
                                showUsdMode: targetShowUsd,
                                conversionText: _getTargetConversionText(),
                                onAmountChanged: _onTargetAmountChanged,
                                onToggleMode: targetToken.isBtc
                                    ? _toggleTargetMode
                                    : null,
                                availableTokens: _getAvailableTargetTokens(),
                                onTokenChanged: _onTargetTokenChanged,
                                showBalance: false,
                                label: 'buy',
                                isTopCard: false,
                                btcUnit: _targetBtcUnit,
                              ),
                            ],
                          ),
                          // SWAP BUTTON - Allows changing swap direction
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTapDown: _onSwapButtonTapDown,
                                onTapUp: _onSwapButtonTapUp,
                                onTapCancel: _onSwapButtonTapCancel,
                                onTap: _swapTokens,
                                child: AnimatedBuilder(
                                  animation: _swapButtonAnimation,
                                  builder: (context, child) => Transform.scale(
                                    scale: _swapButtonAnimation.value,
                                    child: child,
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF1B1B1B)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(44 / 3),
                                      border: Border.all(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                                .withValues(alpha: 0.1)
                                            : Colors.black
                                                .withValues(alpha: 0.08),
                                        width: 4,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 20,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                    // Minimal rate info
                    _buildRateInfo(context),
                    const SizedBox(height: AppTheme.cardPadding * 5.5),
                  ],
                ),
              ),
              // Bottom button
              Positioned(
                left: 0,
                right: 0,
                bottom: AppTheme.cardPadding,
                child: Center(
                  child: LongButtonWidget(
                    title: _getButtonTitle(),
                    customWidth: MediaQuery.of(context).size.width -
                        AppTheme.cardPadding * 2,
                    // Don't change button type based on loading state to prevent flicker
                    buttonType: (_isAmountValid &&
                            !_isAmountTooSmall &&
                            !_hasInsufficientFunds)
                        ? ButtonType.solid
                        : ButtonType.transparent,
                    state: (isLoading || _isLoadingQuote)
                        ? ButtonState.loading
                        : ((_isAmountTooSmall || _hasInsufficientFunds)
                            ? ButtonState.disabled
                            : ButtonState.idle),
                    onTap: _canSwap ? _initiateSwap : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimal rate display with info icon
  Widget _buildRateInfo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '1 BTC ≈ \$${_formatPrice(btcUsdPrice)}',
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _showFeeInfoSheet(context),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
          ),
        ),
      ],
    );
  }

  /// Format price with thousands separator
  String _formatPrice(double price) {
    if (price >= 1000) {
      final formatted = price.toStringAsFixed(0);
      final result = StringBuffer();
      final length = formatted.length;
      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          result.write(',');
        }
        result.write(formatted[i]);
      }
      return result.toString();
    }
    return price.toStringAsFixed(2);
  }

  /// Show fee breakdown sheet when user taps info icon
  void _showFeeInfoSheet(BuildContext context) {
    // Use quote data if available, otherwise show placeholder
    final networkFeeSats = _quote?.networkFeeSats.toInt() ?? 0;
    final protocolFeeSats = _quote?.protocolFeeSats.toInt() ?? 0;
    final protocolFeePercent = _quote?.protocolFeePercent ?? 0.0;

    final networkFeeUsd =
        btcToUsd(networkFeeSats / BitcoinConstants.satsPerBtc);
    final protocolFeeUsd =
        btcToUsd(protocolFeeSats / BitcoinConstants.satsPerBtc);

    arkBottomSheet(
      context: context,
      child: FeeBreakdownSheet(
        networkFeeSats: networkFeeSats,
        protocolFeeSats: protocolFeeSats,
        protocolFeePercent: protocolFeePercent,
        networkFeeUsd: networkFeeUsd,
        protocolFeeUsd: protocolFeeUsd,
        isLoading: _isLoadingQuote,
        hasQuote: _quote != null,
      ),
    );
  }
}
