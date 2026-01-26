import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/screens/swap/evm_swap_funding_screen.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_controller.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_amount_card.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_confirmation_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/fee_breakdown_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/evm_address_input_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/insufficient_liquidity_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  SwapScreenState createState() => SwapScreenState();
}

class SwapScreenState extends State<SwapScreen>
    with SingleTickerProviderStateMixin {
  late final SwapController _controller;
  late final AnimationController _swapButtonController;
  late final Animation<double> _swapButtonAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = SwapController()..addListener(_onStateChanged);
    _initSwapButtonAnimation();
  }

  void _initSwapButtonAnimation() {
    _swapButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _swapButtonAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _swapButtonController, curve: Curves.easeInOut),
    );
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    _swapButtonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Public method to refresh balance when tab becomes visible
  void refreshBalance() => _controller.refreshBalance();

  /// Unfocus all inputs when screen becomes invisible
  void unfocusAll() => _controller.unfocus();

  // ============================================================
  // Swap Flow
  // ============================================================

  void _initiateSwap() {
    FocusManager.instance.primaryFocus?.unfocus();

    final state = _controller.state;
    if (state.usdValue <= 0) {
      OverlayService().showError('Please enter a valid amount');
      return;
    }

    if (state.isBtcToEvm) {
      _showEvmAddressInput();
    } else if (state.isEvmToBtc) {
      _showConfirmation();
    } else {
      OverlayService().showError('Invalid swap pair');
    }
  }

  void _showEvmAddressInput() {
    final state = _controller.state;
    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      child: EvmAddressInputSheet(
        tokenSymbol: state.targetToken.symbol,
        network: state.targetToken.network,
        onAddressConfirmed: (address) =>
            _showConfirmation(targetEvmAddress: address),
      ),
    );
  }

  void _showConfirmation({String? targetEvmAddress}) {
    final state = _controller.state;
    final sourceAmount = state.sourceToken.isBtc
        ? state.btcAmount
        : (state.sourceToken.isStablecoin
            ? state.usdAmount
            : state.tokenAmount);
    final targetAmount = state.targetToken.isBtc
        ? state.btcAmount
        : (state.targetToken.isStablecoin
            ? state.usdAmount
            : state.tokenAmount);

    arkBottomSheet(
      context: context,
      child: SwapConfirmationSheet(
        sourceToken: state.sourceToken,
        targetToken: state.targetToken,
        sourceAmount: sourceAmount,
        targetAmount: targetAmount,
        sourceAmountUsd: state.usdAmount,
        targetAmountUsd: state.usdAmount,
        exchangeRate: state.btcUsdPrice,
        networkFeeSats: state.quote?.networkFeeSats.toInt() ?? 0,
        protocolFeeSats: state.quote?.protocolFeeSats.toInt() ?? 0,
        protocolFeePercent: state.quote?.protocolFeePercent ?? 0.0,
        sourceAmountSats: state.satsValue,
        targetAddress: targetEvmAddress,
        isLoading: state.isExecuting,
        onConfirm: () => _executeSwap(targetEvmAddress: targetEvmAddress),
      ),
    );
  }

  Future<void> _executeSwap({String? targetEvmAddress}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context); // Close confirmation sheet

    final result =
        await _controller.executeSwap(targetEvmAddress: targetEvmAddress);

    switch (result) {
      case SwapSuccess():
        _controller.onSwapSuccess();
      case SwapSuccessRequiresClaiming():
        // Ethereum swaps require WalletConnect to claim
        // Navigate to processing screen to complete the flow
        _navigateToProcessingScreen(result);
      case SwapNavigateToFunding():
        _navigateToFundingScreen();
      case SwapInsufficientLiquidity():
        _showInsufficientLiquiditySheet();
      case SwapError(:final message):
        OverlayService().showError(message);
    }
  }

  void _navigateToProcessingScreen(SwapSuccessRequiresClaiming result) {
    // Navigate to processing screen where user can claim via WalletConnect
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SwapProcessingScreen(
          swapId: result.swapId,
          sourceToken: result.sourceToken,
          targetToken: result.targetToken,
          sourceAmount: result.sourceAmount,
          targetAmount: result.targetAmount,
        ),
      ),
    ).then((_) {
      // Clear swap inputs when returning from processing screen
      _controller.clearAmounts();
    });
  }

  void _showInsufficientLiquiditySheet() {
    arkBottomSheet(
      context: context,
      child: const InsufficientLiquiditySheet(),
    );
  }

  void _navigateToFundingScreen() {
    final data = _controller.getEvmFundingData();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvmSwapFundingScreen(
          sourceToken: data.sourceToken,
          targetToken: data.targetToken,
          sourceAmount: data.sourceAmount,
          targetAmount: data.targetAmount,
          usdAmount: data.usdAmount,
        ),
      ),
    );
  }

  void _showFeeInfoSheet() {
    final state = _controller.state;
    final networkFeeSats = state.quote?.networkFeeSats.toInt() ?? 0;
    final protocolFeeSats = state.quote?.protocolFeeSats.toInt() ?? 0;
    final protocolFeePercent = state.quote?.protocolFeePercent ?? 0.0;

    arkBottomSheet(
      context: context,
      child: FeeBreakdownSheet(
        networkFeeSats: networkFeeSats,
        protocolFeeSats: protocolFeeSats,
        protocolFeePercent: protocolFeePercent,
        networkFeeUsd: _satsToUsd(networkFeeSats),
        protocolFeeUsd: _satsToUsd(protocolFeeSats),
        isLoading: state.isLoadingQuote,
        hasQuote: state.quote != null,
      ),
    );
  }

  double _satsToUsd(int sats) {
    return (sats / BitcoinConstants.satsPerBtc) * _controller.state.btcUsdPrice;
  }

  // ============================================================
  // Swap Button Animation
  // ============================================================

  void _onSwapButtonTapDown(TapDownDetails _) =>
      _swapButtonController.forward();

  void _onSwapButtonTapUp(TapUpDetails _) {
    _swapButtonController
        .forward()
        .then((_) => _swapButtonController.reverse());
  }

  void _onSwapButtonTapCancel() => _swapButtonController.reverse();

  void _swapTokens() {
    HapticFeedback.lightImpact();
    _controller.swapTokens();
  }

  // ============================================================
  // Build
  // ============================================================

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
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) unfocusAll();
          },
          child: Stack(
            children: [
              _buildContent(),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.cardPadding * 3.5),
          _buildSwapCards(),
          const SizedBox(height: AppTheme.cardPadding),
          _buildRateInfo(),
          const SizedBox(height: AppTheme.cardPadding * 5.5),
        ],
      ),
    );
  }

  Widget _buildSwapCards() {
    final state = _controller.state;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Stack(
        children: [
          Column(
            children: [
              // Source card (You Sell)
              SwapAmountCard(
                token: state.sourceToken,
                cardTitle: 'Sell',
                controller: _controller.sourceController,
                focusNode: _controller.sourceFocusNode,
                showUsdMode: state.sourceShowUsd,
                conversionText: _controller.getSourceConversionText(),
                onAmountChanged: _controller.onSourceAmountChanged,
                onToggleMode: state.sourceToken.isBtc
                    ? _controller.toggleSourceMode
                    : null,
                availableTokens: _controller.getAvailableSourceTokens(),
                onTokenChanged: _controller.onSourceTokenChanged,
                showBalance: state.sourceToken.isBtc,
                balanceSats:
                    state.sourceToken.isBtc ? state.availableBalanceSats : null,
                label: 'sell',
                isTopCard: true,
                btcUnit: state.sourceBtcUnit,
                onMaxTap:
                    state.sourceToken.isBtc ? _controller.setMaxAmount : null,
              ),
              const SizedBox(height: 4),
              // Target card (You Buy)
              SwapAmountCard(
                token: state.targetToken,
                cardTitle: 'Buy',
                controller: _controller.targetController,
                focusNode: _controller.targetFocusNode,
                showUsdMode: state.targetShowUsd,
                conversionText: _controller.getTargetConversionText(),
                onAmountChanged: _controller.onTargetAmountChanged,
                onToggleMode: state.targetToken.isBtc
                    ? _controller.toggleTargetMode
                    : null,
                availableTokens: _controller.getAvailableTargetTokens(),
                onTokenChanged: _controller.onTargetTokenChanged,
                showBalance: false,
                label: 'buy',
                isTopCard: false,
                btcUnit: state.targetBtcUnit,
              ),
            ],
          ),
          _buildSwapDirectionButton(),
        ],
      ),
    );
  }

  Widget _buildSwapDirectionButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
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
                color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
                borderRadius: BorderRadius.circular(44 / 3),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 4,
                ),
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRateInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.white60 : AppTheme.black60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '1 BTC \u2248 \$${_formatPrice(_controller.state.btcUsdPrice)}',
          style: TextStyle(fontSize: 13, color: textColor),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showFeeInfoSheet,
          child: Icon(Icons.info_outline_rounded, size: 16, color: textColor),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final state = _controller.state;

    return Positioned(
      left: 0,
      right: 0,
      bottom: AppTheme.cardPadding,
      child: Center(
        child: LongButtonWidget(
          title: state.buttonTitle,
          customWidth:
              MediaQuery.of(context).size.width - AppTheme.cardPadding * 2,
          buttonType:
              state.isAmountValid ? ButtonType.solid : ButtonType.transparent,
          state: (state.isExecuting || state.isLoadingQuote)
              ? ButtonState.loading
              : (state.isAmountTooSmall || state.hasInsufficientFunds)
                  ? ButtonState.disabled
                  : ButtonState.idle,
          onTap: state.canExecute ? _initiateSwap : null,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price < 1000) return price.toStringAsFixed(2);

    final formatted = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    final length = formatted.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) buffer.write(',');
      buffer.write(formatted[i]);
    }
    return buffer.toString();
  }
}
