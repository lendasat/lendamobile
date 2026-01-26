import 'dart:async';

import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart' as lendaswap_api;
import 'package:ark_flutter/src/services/amount_widget_service.dart'
    show CurrencyType;
import 'package:ark_flutter/src/services/bitcoin_price_service.dart'
    show fetchBitcoinPriceData;
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart'
    show TimeRange;
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/lendaswap_price_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/swap_monitoring_service.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_config.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_state.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';

/// Result of a swap execution.
sealed class SwapResult {
  const SwapResult();
}

/// Swap initiated successfully - can auto-claim (Polygon/gasless)
class SwapSuccess extends SwapResult {
  const SwapSuccess(this.swapId);
  final String swapId;
}

/// Swap initiated - requires WalletConnect to claim (Ethereum)
/// Navigate user to processing screen to complete the claim flow
class SwapSuccessRequiresClaiming extends SwapResult {
  const SwapSuccessRequiresClaiming({
    required this.swapId,
    required this.sourceToken,
    required this.targetToken,
    required this.sourceAmount,
    required this.targetAmount,
  });
  final String swapId;
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;
}

class SwapNavigateToFunding extends SwapResult {
  const SwapNavigateToFunding();
}

class SwapError extends SwapResult {
  const SwapError(this.message);
  final String message;
}

class SwapInsufficientLiquidity extends SwapResult {
  const SwapInsufficientLiquidity();
}

/// Controller for swap screen business logic and state management.
class SwapController extends ChangeNotifier {
  SwapController() {
    _init();
  }

  SwapState _state = SwapState.initial();
  SwapState get state => _state;

  final LendaSwapService _swapService = LendaSwapService();
  final LendaswapPriceFeedService _priceFeed = LendaswapPriceFeedService();
  Timer? _quoteDebounceTimer;
  StreamSubscription<PriceUpdateMessage>? _priceSubscription;
  StreamSubscription<Map<String, double>>? _coinGeckoSubscription;

  // Text controllers for UI binding
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController targetController = TextEditingController();
  final FocusNode sourceFocusNode = FocusNode();
  final FocusNode targetFocusNode = FocusNode();

  void _init() {
    _loadBitcoinPrice();
    _loadBalance();
    _connectPriceFeed();
  }

  /// Connect to the LendaSwap price feed for real-time prices.
  void _connectPriceFeed() {
    _priceFeed.connect();
    _priceSubscription = _priceFeed.priceUpdates.listen(_onPriceUpdate);
    _coinGeckoSubscription =
        _priceFeed.coinGeckoPriceUpdates.listen(_onCoinGeckoUpdate);
  }

  /// Handle WebSocket price updates from the price feed.
  void _onPriceUpdate(PriceUpdateMessage update) {
    logger.d('[SwapController] Received WebSocket price update');
  }

  /// Handle CoinGecko price updates.
  void _onCoinGeckoUpdate(Map<String, double> prices) {
    logger.d('[SwapController] Received CoinGecko price update: $prices');

    final xautPrice = prices['xaut_eth'];
    if (xautPrice != null) {
      _updateState(_state.copyWith(xautUsdPrice: xautPrice));
      logger.i(
          '[SwapController] Updated XAUT price from CoinGecko: \$${xautPrice.toStringAsFixed(2)}');
    }
  }

  @override
  void dispose() {
    _quoteDebounceTimer?.cancel();
    _priceSubscription?.cancel();
    _coinGeckoSubscription?.cancel();
    sourceController.dispose();
    targetController.dispose();
    sourceFocusNode.dispose();
    targetFocusNode.dispose();
    super.dispose();
  }

  /// Unfocus all inputs and cancel pending operations
  void unfocus() {
    sourceFocusNode.unfocus();
    targetFocusNode.unfocus();
    _quoteDebounceTimer?.cancel();
  }

  /// Refresh balance - call when screen becomes visible
  void refreshBalance() => _loadBalance();

  // ============================================================
  // State Updates
  // ============================================================

  void _updateState(SwapState newState) {
    _state = newState;
    notifyListeners();
  }

  // ============================================================
  // Data Loading
  // ============================================================

  Future<void> _loadBitcoinPrice() async {
    try {
      final priceData = await fetchBitcoinPriceData(TimeRange.day);
      if (priceData.isNotEmpty) {
        _updateState(_state.copyWith(btcUsdPrice: priceData.last.price));
      }
    } catch (e) {
      // Use fallback price
    }
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await ark_api.balance();
      _updateState(_state.copyWith(
        availableBalanceSats: balance.offchain.totalSats,
        spendableBalanceSats:
            balance.offchain.confirmedSats + balance.offchain.pendingSats,
        isLoadingBalance: false,
      ));
    } catch (e) {
      _updateState(_state.copyWith(isLoadingBalance: false));
    }
  }

  // ============================================================
  // Quote Fetching
  // ============================================================

  void _fetchQuoteDebounced() {
    _quoteDebounceTimer?.cancel();
    _quoteDebounceTimer = Timer(
      const Duration(milliseconds: SwapConfig.quoteDebounceMs),
      _fetchQuote,
    );
  }

  Future<void> _fetchQuote() async {
    final btc = _state.btcValue;
    if (btc <= 0) {
      _updateState(_state.copyWith(clearQuote: true, isLoadingQuote: false));
      return;
    }

    _updateState(_state.copyWith(isLoadingQuote: true));

    try {
      final sats = SwapConfig.btcToSats(btc);
      final quote = await lendaswap_api.lendaswapGetQuote(
        fromToken: _state.sourceToken.tokenId,
        toToken: _state.targetToken.tokenId,
        amountSats: BigInt.from(sats),
      );
      _updateState(_state.copyWith(quote: quote, isLoadingQuote: false));
    } catch (e) {
      logger.e('Failed to fetch quote: $e');
      _updateState(_state.copyWith(clearQuote: true, isLoadingQuote: false));
    }
  }

  // ============================================================
  // Amount Handling
  // ============================================================

  void onSourceAmountChanged(String value) {
    final newState = _calculateAmountsFromSource(value);
    _updateState(newState);
    _syncTargetController();
    _fetchQuoteDebounced();
  }

  void onTargetAmountChanged(String value) {
    final newState = _calculateAmountsFromTarget(value);
    _updateState(newState);
    _syncSourceController();
    _fetchQuoteDebounced();
  }

  SwapState _calculateAmountsFromSource(String value) {
    final source = _state.sourceToken;

    if (source.isBtc) {
      return _calculateFromBtcSource(value);
    } else if (source.isStablecoin) {
      return _calculateFromStablecoinSource(value);
    } else {
      return _calculateFromTokenSource(value);
    }
  }

  SwapState _calculateFromBtcSource(String value) {
    // Helper to calculate tokenAmount for gold target tokens
    String? calcTokenAmount(double usd) {
      if (_state.targetToken.isGold && usd > 0) {
        final price = _state.getTokenUsdPrice(_state.targetToken);
        if (price == null || price <= 0) return null;
        final tokens = usd / price;
        return tokens.toStringAsFixed(6);
      }
      return null;
    }

    if (_state.sourceShowUsd) {
      // User entered USD
      final usd = double.tryParse(value) ?? 0;
      final btc = usd > 0 ? usd / _state.btcUsdPrice : 0.0;
      final sats = SwapConfig.btcToSats(btc);
      final tokenAmt = calcTokenAmount(usd);
      return _state.copyWith(
        usdAmount: value,
        btcAmount: btc > 0 ? _formatBtc(btc) : '',
        satsAmount: sats > 0 ? sats.toString() : '',
        tokenAmount: tokenAmt ?? _state.tokenAmount,
      );
    } else if (_state.sourceBtcUnit == CurrencyType.sats) {
      // User entered sats
      final sats = double.tryParse(value) ?? 0;
      final btc = sats / BitcoinConstants.satsPerBtc;
      final usd = btc * _state.btcUsdPrice;
      final tokenAmt = calcTokenAmount(usd);

      var newState = _state.copyWith(
        satsAmount: value,
        btcAmount: sats > 0 ? btc.toString() : '',
        usdAmount: sats > 0 ? _formatUsd(usd) : '',
        tokenAmount: tokenAmt ?? _state.tokenAmount,
      );

      // Check for auto-switch to BTC
      if (sats >= SwapConfig.satsToBtcThreshold) {
        newState = newState.copyWith(sourceBtcUnit: CurrencyType.bitcoin);
        _scheduleControllerUpdate(sourceController, _formatBtc(btc));
      }
      return newState;
    } else {
      // User entered BTC
      final btc = double.tryParse(value) ?? 0;
      final sats = SwapConfig.btcToSats(btc);
      final usd = btc * _state.btcUsdPrice;
      final tokenAmt = calcTokenAmount(usd);

      var newState = _state.copyWith(
        btcAmount: value,
        satsAmount: sats > 0 ? sats.toString() : '',
        usdAmount: btc > 0 ? _formatUsd(usd) : '',
        tokenAmount: tokenAmt ?? _state.tokenAmount,
      );

      // Check for auto-switch to sats
      if (btc > 0 && btc < SwapConfig.btcToSatsThreshold) {
        newState = newState.copyWith(sourceBtcUnit: CurrencyType.sats);
        _scheduleControllerUpdate(sourceController, sats.toString());
      }
      return newState;
    }
  }

  SwapState _calculateFromStablecoinSource(String value) {
    final usd = double.tryParse(value) ?? 0;
    final btc = usd > 0 ? usd / _state.btcUsdPrice : 0.0;
    final sats = SwapConfig.btcToSats(btc);
    return _state.copyWith(
      usdAmount: value,
      tokenAmount: value,
      btcAmount: btc > 0 ? _formatBtc(btc) : '',
      satsAmount: sats > 0 ? sats.toString() : '',
    );
  }

  SwapState _calculateFromTokenSource(String value) {
    final tokens = double.tryParse(value) ?? 0;
    final price = _state.getTokenUsdPrice(_state.sourceToken);
    if (price == null || price <= 0) {
      // Price not available - clear amounts
      return _state.copyWith(
        tokenAmount: value,
        usdAmount: '',
        btcAmount: '',
        satsAmount: '',
      );
    }
    final usd = tokens * price;
    final btc = usd > 0 ? usd / _state.btcUsdPrice : 0.0;
    final sats = SwapConfig.btcToSats(btc);
    return _state.copyWith(
      tokenAmount: value,
      usdAmount: usd > 0 ? _formatUsd(usd) : '',
      btcAmount: btc > 0 ? _formatBtc(btc) : '',
      satsAmount: sats > 0 ? sats.toString() : '',
    );
  }

  SwapState _calculateAmountsFromTarget(String value) {
    final target = _state.targetToken;

    if (target.isBtc) {
      return _calculateFromBtcTarget(value);
    } else if (target.isStablecoin) {
      return _calculateFromStablecoinTarget(value);
    } else {
      return _calculateFromTokenTarget(value);
    }
  }

  SwapState _calculateFromBtcTarget(String value) {
    // Helper to calculate tokenAmount for gold source tokens
    String? calcTokenAmount(double usd) {
      if (_state.sourceToken.isGold && usd > 0) {
        final price = _state.getTokenUsdPrice(_state.sourceToken);
        if (price == null || price <= 0) return null;
        final tokens = usd / price;
        return tokens.toStringAsFixed(6);
      }
      return null;
    }

    if (_state.targetShowUsd) {
      final usd = double.tryParse(value) ?? 0;
      final btc = usd > 0 ? usd / _state.btcUsdPrice : 0.0;
      final sats = SwapConfig.btcToSats(btc);
      final tokenAmt = calcTokenAmount(usd);
      return _state.copyWith(
        usdAmount: value,
        btcAmount: btc > 0 ? _formatBtc(btc) : '',
        satsAmount: sats > 0 ? sats.toString() : '',
        tokenAmount: tokenAmt ?? _state.tokenAmount,
      );
    } else if (_state.targetBtcUnit == CurrencyType.sats) {
      final sats = double.tryParse(value) ?? 0;
      final btc = sats / BitcoinConstants.satsPerBtc;
      final usd = btc * _state.btcUsdPrice;
      final tokenAmt = calcTokenAmount(usd);

      var newState = _state.copyWith(
        satsAmount: value,
        btcAmount: sats > 0 ? btc.toString() : '',
        usdAmount: sats > 0 ? _formatUsd(usd) : '',
        tokenAmount: tokenAmt ?? _state.tokenAmount,
      );

      if (sats >= SwapConfig.satsToBtcThreshold) {
        newState = newState.copyWith(targetBtcUnit: CurrencyType.bitcoin);
        _scheduleControllerUpdate(targetController, _formatBtc(btc));
      }
      return newState;
    } else {
      final btc = double.tryParse(value) ?? 0;
      final sats = SwapConfig.btcToSats(btc);
      final usd = btc * _state.btcUsdPrice;
      final tokenAmt = calcTokenAmount(usd);

      var newState = _state.copyWith(
        btcAmount: value,
        satsAmount: sats > 0 ? sats.toString() : '',
        usdAmount: btc > 0 ? _formatUsd(usd) : '',
        tokenAmount: tokenAmt ?? _state.tokenAmount,
      );

      if (btc > 0 && btc < SwapConfig.btcToSatsThreshold) {
        newState = newState.copyWith(targetBtcUnit: CurrencyType.sats);
        _scheduleControllerUpdate(targetController, sats.toString());
      }
      return newState;
    }
  }

  SwapState _calculateFromStablecoinTarget(String value) {
    final usd = double.tryParse(value) ?? 0;
    final btc = usd > 0 ? usd / _state.btcUsdPrice : 0.0;
    final sats = SwapConfig.btcToSats(btc);
    return _state.copyWith(
      usdAmount: value,
      tokenAmount: value,
      btcAmount: btc > 0 ? _formatBtc(btc) : '',
      satsAmount: sats > 0 ? sats.toString() : '',
    );
  }

  SwapState _calculateFromTokenTarget(String value) {
    final tokens = double.tryParse(value) ?? 0;
    final price = _state.getTokenUsdPrice(_state.targetToken);
    if (price == null || price <= 0) {
      // Price not available - clear amounts
      return _state.copyWith(
        tokenAmount: value,
        usdAmount: '',
        btcAmount: '',
        satsAmount: '',
      );
    }
    final usd = tokens * price;
    final btc = usd > 0 ? usd / _state.btcUsdPrice : 0.0;
    final sats = SwapConfig.btcToSats(btc);
    return _state.copyWith(
      tokenAmount: value,
      usdAmount: usd > 0 ? _formatUsd(usd) : '',
      btcAmount: btc > 0 ? _formatBtc(btc) : '',
      satsAmount: sats > 0 ? sats.toString() : '',
    );
  }

  void _syncSourceController() {
    final source = _state.sourceToken;
    if (source.isBtc) {
      sourceController.text = _state.sourceShowUsd
          ? _state.usdAmount
          : (_state.sourceBtcUnit == CurrencyType.sats
              ? _state.satsAmount
              : _state.btcAmount);
    } else if (source.isStablecoin) {
      sourceController.text = _state.usdAmount;
    } else {
      sourceController.text = _state.tokenAmount;
    }
  }

  void _syncTargetController() {
    final target = _state.targetToken;
    if (target.isBtc) {
      targetController.text = _state.targetShowUsd
          ? _state.usdAmount
          : (_state.targetBtcUnit == CurrencyType.sats
              ? _state.satsAmount
              : _state.btcAmount);
    } else if (target.isStablecoin) {
      targetController.text = _state.usdAmount;
    } else {
      final usd = double.tryParse(_state.usdAmount) ?? 0;
      final price = _state.getTokenUsdPrice(target);
      if (usd > 0 && price != null && price > 0) {
        final tokens = usd / price;
        targetController.text = tokens.toStringAsFixed(6);
      } else {
        targetController.text = '';
      }
    }
  }

  void _scheduleControllerUpdate(
      TextEditingController controller, String value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.text = value;
    });
  }

  // ============================================================
  // Token Switching
  // ============================================================

  void swapTokens() {
    // Before swapping, calculate tokenAmount if target was a non-stablecoin token
    // (like XAUT) since its value is calculated on-the-fly and not stored
    String tokenAmount = _state.tokenAmount;
    if (_state.targetToken.isGold) {
      final usd = double.tryParse(_state.usdAmount) ?? 0;
      final price = _state.getTokenUsdPrice(_state.targetToken);
      if (usd > 0 && price != null && price > 0) {
        final tokens = usd / price;
        tokenAmount = tokens.toStringAsFixed(6);
      }
    }

    _updateState(_state.copyWith(
      sourceToken: _state.targetToken,
      targetToken: _state.sourceToken,
      sourceShowUsd: _state.targetShowUsd,
      targetShowUsd: _state.sourceShowUsd,
      sourceBtcUnit: _state.targetBtcUnit,
      targetBtcUnit: _state.sourceBtcUnit,
      tokenAmount: tokenAmount,
    ));
    _syncSourceController();
    _syncTargetController();
    _fetchQuoteDebounced();
  }

  void onSourceTokenChanged(SwapToken token) {
    var newState = _state.copyWith(
      sourceToken: token,
      sourceShowUsd: !token.isBtc,
    );

    // Ensure tokens are different types
    if (token.isBtc == newState.targetToken.isBtc) {
      newState = newState.copyWith(
        targetToken: token.isBtc ? SwapToken.usdcPolygon : SwapToken.bitcoin,
        targetShowUsd: token.isBtc,
      );
    }

    // Recalculate tokenAmount when changing to gold token
    if (token.isGold) {
      final usd = double.tryParse(_state.usdAmount) ?? 0;
      final price = newState.getTokenUsdPrice(token);
      if (usd > 0 && price != null && price > 0) {
        final tokens = usd / price;
        newState = newState.copyWith(tokenAmount: tokens.toStringAsFixed(6));
      }
    }

    _updateState(newState);
    _syncSourceController();
    _syncTargetController();
    _fetchQuoteDebounced();
  }

  void onTargetTokenChanged(SwapToken token) {
    var newState = _state.copyWith(
      targetToken: token,
      targetShowUsd: !token.isBtc,
    );

    if (token.isBtc == newState.sourceToken.isBtc) {
      newState = newState.copyWith(
        sourceToken: token.isBtc ? SwapToken.usdcPolygon : SwapToken.bitcoin,
        sourceShowUsd: token.isBtc,
      );
    }

    // Recalculate tokenAmount when changing to gold token
    if (token.isGold) {
      final usd = double.tryParse(_state.usdAmount) ?? 0;
      final price = newState.getTokenUsdPrice(token);
      if (usd > 0 && price != null && price > 0) {
        final tokens = usd / price;
        newState = newState.copyWith(tokenAmount: tokens.toStringAsFixed(6));
      }
    }

    _updateState(newState);
    _syncSourceController();
    _syncTargetController();
    _fetchQuoteDebounced();
  }

  void toggleSourceMode() {
    _updateState(_state.copyWith(sourceShowUsd: !_state.sourceShowUsd));
    _syncSourceController();
  }

  void toggleTargetMode() {
    _updateState(_state.copyWith(targetShowUsd: !_state.targetShowUsd));
    _syncTargetController();
  }

  // ============================================================
  // Max Amount
  // ============================================================

  Future<void> setMaxAmount() async {
    if (!_state.sourceToken.isBtc || _state.isLoadingBalance) return;

    final availableSats = _state.spendableBalanceSats.toInt();
    if (availableSats <= 0) {
      _setAmount(0);
      return;
    }

    // Fetch quote if needed for fee calculation
    if (_state.quote == null) {
      try {
        final quote = await lendaswap_api.lendaswapGetQuote(
          fromToken: _state.sourceToken.tokenId,
          toToken: _state.targetToken.tokenId,
          amountSats: BigInt.from(availableSats),
        );
        _updateState(_state.copyWith(quote: quote));
      } catch (e) {
        logger.e('Failed to fetch quote for max calculation: $e');
        OverlayService().showError('Failed to calculate fees');
        return;
      }
    }

    final protocolPercent = _state.quote!.protocolFeePercent;
    final networkFee = _state.quote!.networkFeeSats.toInt();

    // Calculate max: balance = amount + fees
    final maxSats = protocolPercent > 0
        ? ((availableSats - networkFee) / (1 + protocolPercent / 100))
            .floor()
            .clamp(0, availableSats)
        : (availableSats - networkFee).clamp(0, availableSats);

    _setAmount(maxSats);
    _fetchQuoteDebounced();
  }

  void _setAmount(int sats) {
    final btc = SwapConfig.satsToBtc(sats);
    final usd = btc * _state.btcUsdPrice;

    _updateState(_state.copyWith(
      satsAmount: sats.toString(),
      btcAmount: btc.toStringAsFixed(8),
      usdAmount: usd.toStringAsFixed(2),
    ));

    // Update controller based on current mode
    if (_state.sourceShowUsd) {
      sourceController.text = _state.usdAmount;
    } else if (_state.sourceBtcUnit == CurrencyType.sats) {
      sourceController.text = _state.satsAmount;
    } else {
      sourceController.text = _state.btcAmount;
    }

    _syncTargetController();
  }

  // ============================================================
  // Swap Execution
  // ============================================================

  Future<SwapResult> executeSwap({String? targetEvmAddress}) async {
    if (!_state.canExecute) {
      return const SwapError('Invalid swap state');
    }

    _updateState(_state.copyWith(isExecuting: true));
    PaymentOverlayService().startSuppression();

    try {
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }

      if (_state.isBtcToEvm) {
        if (targetEvmAddress == null) {
          return const SwapError('EVM address required');
        }
        return await _executeBtcToEvmSwap(targetEvmAddress);
      } else {
        return const SwapNavigateToFunding();
      }
    } catch (e) {
      logger.e('Swap failed: $e');
      final errorStr = e.toString().toLowerCase();
      // Check for liquidity errors
      if (errorStr.contains('insufficient') &&
          (errorStr.contains('liquidity') || errorStr.contains('wbtc'))) {
        return const SwapInsufficientLiquidity();
      }
      return SwapError(parseSwapError(e.toString()));
    } finally {
      _updateState(_state.copyWith(isExecuting: false));
      Future.delayed(AppTimeouts.mediumDelay, () {
        PaymentOverlayService().stopSuppression();
      });
    }
  }

  Future<SwapResult> _executeBtcToEvmSwap(String targetEvmAddress) async {
    final balance = await ark_api.balance();
    final availableSats = balance.offchain.totalSats;
    final requiredSats = BigInt.from(_state.satsValue);

    if (availableSats < requiredSats) {
      return SwapError('Insufficient balance. Available: $availableSats sats');
    }

    final targetAmount = _state.targetToken.isStablecoin
        ? _state.usdValue
        : (double.tryParse(_state.tokenAmount) ?? 0);

    final result = await _swapService.createSellBtcSwap(
      targetEvmAddress: targetEvmAddress,
      targetAmount: targetAmount,
      targetToken: _state.targetToken.tokenId,
      targetChain: _state.targetToken.chainId,
    );

    SwapMonitoringService().startMonitoringSwap(result.swapId);

    // Fund the swap
    final satsToSend = BigInt.from(result.satsToSend);
    if (availableSats >= satsToSend) {
      try {
        await ark_api.send(
            address: result.arkadeHtlcAddress, amountSats: satsToSend);
        logger.i('Swap funded: ${result.swapId}');
      } catch (e) {
        logger.e('Failed to fund swap: $e');
        return SwapError(
            'Failed to send funds: ${parseSwapError(e.toString())}');
      }
    }

    // Ethereum swaps require WalletConnect to claim - keep user in flow
    // Polygon swaps use gasless Gelato claiming - can go to wallet
    if (_state.targetToken.isEthereum) {
      final sourceAmountBtc =
          (_state.satsValue / BitcoinConstants.satsPerBtc).toStringAsFixed(8);
      final targetAmountStr = _state.targetToken.isStablecoin
          ? targetAmount.toStringAsFixed(2)
          : targetAmount.toStringAsFixed(6);

      return SwapSuccessRequiresClaiming(
        swapId: result.swapId,
        sourceToken: _state.sourceToken,
        targetToken: _state.targetToken,
        sourceAmount: sourceAmountBtc,
        targetAmount: targetAmountStr,
      );
    }

    return SwapSuccess(result.swapId);
  }

  void onSwapSuccess() {
    clearAmounts();
    PaymentMonitoringService().switchToWalletTab();
    OverlayService().showSuccess('Swap initiated! Processing in background...');
  }

  /// Clear all swap amounts and reset controllers
  void clearAmounts() {
    _updateState(_state.clearAmounts());
    sourceController.clear();
    targetController.clear();
  }

  // ============================================================
  // Display Helpers
  // ============================================================

  String getSourceConversionText() {
    if (_state.sourceToken.isBtc) {
      if (_state.sourceShowUsd) {
        return _state.sourceBtcUnit == CurrencyType.sats
            ? '${_state.satsAmount.isNotEmpty ? _state.satsAmount : "0"} sats'
            : '${_state.btcAmount.isNotEmpty ? _state.btcAmount : "0"} BTC';
      }
      return '\$${_state.usdAmount.isNotEmpty ? _state.usdAmount : "0.00"}';
    }
    return _state.sourceBtcUnit == CurrencyType.sats
        ? '${_state.satsAmount.isNotEmpty ? _state.satsAmount : "0"} sats'
        : '${_state.btcAmount.isNotEmpty ? _state.btcAmount : "0"} BTC';
  }

  String getTargetConversionText() {
    if (_state.targetToken.isBtc) {
      if (_state.targetShowUsd) {
        return _state.targetBtcUnit == CurrencyType.sats
            ? '${_state.satsAmount.isNotEmpty ? _state.satsAmount : "0"} sats'
            : '${_state.btcAmount.isNotEmpty ? _state.btcAmount : "0"} BTC';
      }
      return '\$${_state.usdAmount.isNotEmpty ? _state.usdAmount : "0.00"}';
    }
    return _state.targetBtcUnit == CurrencyType.sats
        ? '${_state.satsAmount.isNotEmpty ? _state.satsAmount : "0"} sats'
        : '${_state.btcAmount.isNotEmpty ? _state.btcAmount : "0"} BTC';
  }

  List<SwapToken> getAvailableSourceTokens() => SwapToken.allTokens;

  List<SwapToken> getAvailableTargetTokens() => SwapToken.allTokens;

  /// Data for navigating to EVM funding screen
  ({
    SwapToken sourceToken,
    SwapToken targetToken,
    String sourceAmount,
    String targetAmount,
    double usdAmount,
  }) getEvmFundingData() {
    return (
      sourceToken: _state.sourceToken,
      targetToken: _state.targetToken,
      sourceAmount: _state.sourceToken.isStablecoin
          ? _state.usdAmount
          : _state.tokenAmount,
      targetAmount: _state.btcAmount,
      usdAmount: _state.sourceToken.isStablecoin
          ? _state.usdValue
          : (double.tryParse(_state.tokenAmount) ?? 0),
    );
  }

  // ============================================================
  // Formatting Utilities
  // ============================================================

  String _formatBtc(double btc) {
    if (btc == 0) return '0';
    if (btc < 0.00001) return btc.toStringAsFixed(8);
    if (btc < 0.001) return btc.toStringAsFixed(6);
    if (btc < 1) return btc.toStringAsFixed(5);
    return btc.toStringAsFixed(4);
  }

  String _formatUsd(double usd) => usd.toStringAsFixed(2);

  /// Parse swap error into user-friendly message
  static String parseSwapError(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('min amount')) {
      return 'Amount too small. Minimum is 1,000 sats.';
    }
    if (errorLower.contains('max amount')) {
      return 'Amount too large. Please try a smaller amount.';
    }
    if (errorLower.contains('insufficient') ||
        errorLower.contains('not enough')) {
      return 'Insufficient balance for this swap.';
    }
    if (errorLower.contains('network error') ||
        errorLower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Clean up error
    var clean = error;
    if (clean.contains('AnyhowException(')) {
      clean = clean.replaceAll('AnyhowException(', '').replaceAll(')', '');
    }
    if (clean.contains('Stack backtrace:')) {
      clean = clean.split('Stack backtrace:')[0].trim();
    }
    if (clean.contains('API error:')) {
      clean = clean.split('API error:').last.trim();
    }

    return clean.length > 100
        ? '${clean.substring(0, 97)}...'
        : (clean.isEmpty ? 'Swap failed' : clean);
  }
}
