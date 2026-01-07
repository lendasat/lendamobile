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
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/swap/evm_address_input_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_confirmation_sheet.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/screens/swap/evm_swap_funding_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  SwapScreenState createState() => SwapScreenState();
}

class SwapScreenState extends State<SwapScreen> {
  // Selected tokens
  SwapToken sourceToken = SwapToken.bitcoin;
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

  void _swapTokens() {
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
    return sats > 0 && sats < _minSwapSats;
  }

  /// Check if amount is valid for swap
  bool get _isAmountValid {
    final btc = double.tryParse(btcAmount) ?? 0;
    final sats = (btc * BitcoinConstants.satsPerBtc).round();
    return sats >= _minSwapSats;
  }

  String _getButtonTitle() {
    if (_isAmountTooSmall) {
      return "Amount too small (min 1,000 sats)";
    }
    return "Swap ${sourceToken.symbol} to ${targetToken.symbol}";
  }

  List<SwapToken> _getAvailableSourceTokens() {
    // For first release, only Bitcoin is supported as source
    return SwapToken.btcTokens;
  }

  List<SwapToken> _getAvailableTargetTokens() {
    return SwapToken.getValidTargets(sourceToken);
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
      height: MediaQuery.of(context).size.height * 0.7,
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
        protocolFeePercent: _quote?.protocolFeePercent ?? 0.0,
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

      // Navigate to processing screen
      if (mounted) {
        // For display, use the correct amount based on token type
        String displaySourceAmount;
        String displayTargetAmount;

        if (sourceToken.isBtc) {
          displaySourceAmount = btcAmount;
        } else if (sourceToken.isStablecoin) {
          displaySourceAmount = usdAmount;
        } else {
          displaySourceAmount = tokenAmount; // XAUT and other non-stablecoins
        }

        if (targetToken.isBtc) {
          displayTargetAmount = btcAmount;
        } else if (targetToken.isStablecoin) {
          displayTargetAmount = usdAmount;
        } else {
          displayTargetAmount = tokenAmount; // XAUT and other non-stablecoins
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SwapProcessingScreen(
              swapId: swapId,
              sourceToken: sourceToken,
              targetToken: targetToken,
              sourceAmount: displaySourceAmount,
              targetAmount: displayTargetAmount,
            ),
          ),
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
      child: ArkScaffold(
        context: context,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        appBar: BitNetAppBar(
          text: "Swap",
          context: context,
          hasBackButton: false,
        ),
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
                    const SizedBox(height: AppTheme.cardPadding * 2),
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
                              _SwapAmountCard(
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
                                showBalance: true,
                                label: 'sell',
                                isTopCard: true,
                                btcUnit: _sourceBtcUnit,
                              ),
                              const SizedBox(height: 4),
                              // TARGET CARD (You Buy)
                              _SwapAmountCard(
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
                          // SWAP BUTTON - Hidden for first release as only one direction is supported
                          /*
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: _swapTokens,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1B1B1B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                size: 20,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      */
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
                    buttonType: _isAmountValid
                        ? ButtonType.solid
                        : ButtonType.transparent,
                    state: isLoading
                        ? ButtonState.loading
                        : (_isAmountTooSmall
                            ? ButtonState.disabled
                            : ButtonState.idle),
                    onTap: _isAmountValid ? _initiateSwap : null,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use quote data if available, otherwise show placeholder
    final networkFeeSats = _quote?.networkFeeSats.toInt() ?? 0;
    final protocolFeeSats = _quote?.protocolFeeSats.toInt() ?? 0;
    final protocolFeePercent = _quote?.protocolFeePercent ?? 0.0;
    final totalFeeSats = networkFeeSats + protocolFeeSats;

    final networkFeeUsd =
        btcToUsd(networkFeeSats / BitcoinConstants.satsPerBtc);
    final protocolFeeUsd =
        btcToUsd(protocolFeeSats / BitcoinConstants.satsPerBtc);
    final totalFeeUsd = networkFeeUsd + protocolFeeUsd;

    arkBottomSheet(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            if (_quote == null && !_isLoadingQuote)
              Text(
                'Enter an amount to see fee breakdown',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
              )
            else if (_isLoadingQuote)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.cardPadding),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _FeeInfoRow(
                label: 'Network Fee',
                value: '~\$${networkFeeUsd.toStringAsFixed(2)}',
                subtitle: '${formatSats(networkFeeSats)} sats',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              _FeeInfoRow(
                label: 'Protocol Fee',
                value: '~\$${protocolFeeUsd.toStringAsFixed(2)}',
                subtitle: '${protocolFeePercent.toStringAsFixed(2)}%',
                isDarkMode: isDarkMode,
              ),
              const Divider(height: AppTheme.cardPadding * 2),
              _FeeInfoRow(
                label: 'Total Fees',
                value: '~\$${totalFeeUsd.toStringAsFixed(2)}',
                subtitle: '${formatSats(totalFeeSats)} sats',
                isDarkMode: isDarkMode,
                isBold: true,
              ),
            ],
            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      ),
    );
  }
}

/// Swap amount input card - Uniswap style
class _SwapAmountCard extends StatelessWidget {
  final SwapToken token;
  final String cardTitle;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool showUsdMode;
  final String conversionText;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onToggleMode;
  final List<SwapToken> availableTokens;
  final ValueChanged<SwapToken> onTokenChanged;
  final bool showBalance;
  final String? label;
  final bool isTopCard;
  final CurrencyType btcUnit; // Current BTC unit (sats or bitcoin)

  const _SwapAmountCard({
    required this.token,
    required this.cardTitle,
    required this.controller,
    this.focusNode,
    required this.showUsdMode,
    required this.conversionText,
    required this.onAmountChanged,
    this.onToggleMode,
    required this.availableTokens,
    required this.onTokenChanged,
    required this.showBalance,
    this.label,
    this.isTopCard = true,
    this.btcUnit = CurrencyType.sats,
  });

  void _showTokenSelector(BuildContext context) {
    arkBottomSheet(
      context: context,
      child: _TokenSelectorSheet(
        selectedToken: token,
        availableTokens: availableTokens,
        onTokenSelected: (selectedToken) {
          onTokenChanged(selectedToken);
          Navigator.pop(context);
        },
        label: label,
      ),
    );
  }

  String _getPlaceholder() {
    if (token.isBtc && !showUsdMode) {
      // Sats use integer placeholder, BTC uses decimal
      return btcUnit == CurrencyType.sats ? '0' : '0.00000000';
    }
    return '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final showDollarPrefix = showUsdMode || !token.isBtc;
    final showBtcPrefix = token.isBtc && !showUsdMode;

    return GlassContainer(
      borderRadius: AppTheme.borderRadiusMid,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card title
                Text(
                  cardTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                // Amount input row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dollar sign prefix (if showing USD)
                    if (showDollarPrefix)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          "\$",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    // Sats/BTC icon prefix (switches based on btcUnit)
                    if (showBtcPrefix)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          btcUnit == CurrencyType.sats
                              ? AppTheme.satoshiIcon
                              : Icons.currency_bitcoin,
                          size: 32,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    // Amount input
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: !(token.isBtc &&
                              !showUsdMode &&
                              btcUnit == CurrencyType.sats),
                        ),
                        inputFormatters: [
                          // Use digits only for sats, decimals for BTC/USD
                          if (token.isBtc &&
                              !showUsdMode &&
                              btcUnit == CurrencyType.sats)
                            FilteringTextInputFormatter.digitsOnly
                          else
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,8}$'),
                            ),
                        ],
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintText: _getPlaceholder(),
                          hintStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? AppTheme.white60.withValues(alpha: 0.3)
                                : AppTheme.black60.withValues(alpha: 0.3),
                          ),
                        ),
                        onChanged: onAmountChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                // Conversion text (clickable if toggle is available)
                GestureDetector(
                  onTap: onToggleMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show Bitcoin icon if conversion text shows BTC
                        if (conversionText.endsWith('BTC')) ...[
                          Icon(
                            Icons.currency_bitcoin,
                            size: 14,
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            conversionText.replaceAll(' BTC', ''),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                          ),
                        ] else if (conversionText.endsWith('sats')) ...[
                          // Show Satoshi icon for sats
                          Icon(
                            AppTheme.satoshiIcon,
                            size: 14,
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            conversionText.replaceAll(' sats', ''),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                          ),
                        ] else
                          Text(
                            conversionText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                          ),
                        if (onToggleMode != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_vert,
                            size: 14,
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Token selector on right
          Positioned(
            right: AppTheme.cardPadding * 0.75,
            top: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _showTokenSelector(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(
                              0xFF3D3D3D) // Lighter grey for dark mode
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMid),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TokenIconWithNetwork(
                          token: token,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          token.symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
                if (showBalance) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      token.isBtc ? '1,000,000 sats' : '~\$500.00',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for token selection with search
class _TokenSelectorSheet extends StatefulWidget {
  final SwapToken selectedToken;
  final List<SwapToken> availableTokens;
  final ValueChanged<SwapToken> onTokenSelected;
  final String? label;

  const _TokenSelectorSheet({
    required this.selectedToken,
    required this.availableTokens,
    required this.onTokenSelected,
    this.label,
  });

  @override
  State<_TokenSelectorSheet> createState() => _TokenSelectorSheetState();
}

class _TokenSelectorSheetState extends State<_TokenSelectorSheet> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SwapToken> get _filteredTokens {
    if (_searchQuery.isEmpty) {
      return widget.availableTokens;
    }
    final query = _searchQuery.toLowerCase();
    return widget.availableTokens.where((token) {
      return token.symbol.toLowerCase().contains(query) ||
          token.network.toLowerCase().contains(query) ||
          token.displayName.toLowerCase().contains(query) ||
          token.tokenId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final title = widget.label == 'sell'
        ? 'Select token to sell'
        : widget.label == 'buy'
            ? 'Select token to buy'
            : 'Select token';

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: title,
        hasBackButton: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppTheme.cardPadding * 2),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
            ),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or network...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding,
                    vertical: AppTheme.elementSpacing,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Token list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
              ),
              itemCount: _filteredTokens.length,
              itemBuilder: (context, index) {
                final token = _filteredTokens[index];
                final isSelected = token == widget.selectedToken;

                return _TokenListItem(
                  token: token,
                  isSelected: isSelected,
                  onTap: () => widget.onTokenSelected(token),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// List item for a token in the selector
class _TokenListItem extends StatelessWidget {
  final SwapToken token;
  final bool isSelected;
  final VoidCallback onTap;

  const _TokenListItem({
    required this.token,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing * 0.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            opacity: isSelected ? 0.3 : 0.15,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.elementSpacing),
              child: Row(
                children: [
                  // Token icon with network badge
                  TokenIconWithNetwork(token: token, size: 44),
                  const SizedBox(width: AppTheme.elementSpacing),
                  // Token info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.symbol,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          token.network,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Selected indicator
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row widget for fee breakdown display
class _FeeInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final bool isDarkMode;
  final bool isBold;

  const _FeeInfoRow({
    required this.label,
    required this.value,
    this.subtitle,
    required this.isDarkMode,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
