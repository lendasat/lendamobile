import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/swap/evm_address_input_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/evm_to_btc_address_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/swap_confirmation_sheet.dart';
import 'package:ark_flutter/src/ui/screens/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_price_chart.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  // Selected tokens
  SwapToken sourceToken = SwapToken.btcArkade;
  SwapToken targetToken = SwapToken.usdcPolygon;

  // Amount values (stored as strings for precise decimal handling)
  String btcAmount = '';
  String usdAmount = '';

  // Input mode: true = show USD as main input, false = show native token
  bool sourceShowUsd = false;
  bool targetShowUsd = true; // Target defaults to USD for stablecoins

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

  // Swap service
  final LendaSwapService _swapService = LendaSwapService();


  // Text controllers
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

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
    _sourceController.dispose();
    _targetController.dispose();
    scrollController.dispose();
    super.dispose();
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

  void _onSourceAmountChanged(String value) {
    setState(() {
      if (sourceToken.isBtc) {
        if (sourceShowUsd) {
          // User entered USD, convert to BTC
          usdAmount = value;
          final usd = double.tryParse(value) ?? 0;
          btcAmount = usd > 0 ? formatBtc(usdToBtc(usd)) : '';
        } else {
          // User entered BTC
          btcAmount = value;
          final btc = double.tryParse(value) ?? 0;
          usdAmount = btc > 0 ? formatUsd(btcToUsd(btc)) : '';
        }
      } else {
        // Source is stablecoin (USD)
        usdAmount = value;
        final usd = double.tryParse(value) ?? 0;
        btcAmount = usd > 0 ? formatBtc(usdToBtc(usd)) : '';
      }

      // Update target amount
      _updateTargetAmount();
    });
  }

  void _onTargetAmountChanged(String value) {
    setState(() {
      if (targetToken.isBtc) {
        if (targetShowUsd) {
          usdAmount = value;
          final usd = double.tryParse(value) ?? 0;
          btcAmount = usd > 0 ? formatBtc(usdToBtc(usd)) : '';
        } else {
          btcAmount = value;
          final btc = double.tryParse(value) ?? 0;
          usdAmount = btc > 0 ? formatUsd(btcToUsd(btc)) : '';
        }
      } else {
        // Target is stablecoin
        usdAmount = value;
        final usd = double.tryParse(value) ?? 0;
        btcAmount = usd > 0 ? formatBtc(usdToBtc(usd)) : '';
      }

      // Update source amount
      _updateSourceAmount();
    });
  }

  void _updateTargetAmount() {
    if (targetToken.isBtc) {
      _targetController.text = targetShowUsd ? usdAmount : btcAmount;
    } else {
      // Target is stablecoin - show USD amount
      _targetController.text = usdAmount;
    }
  }

  void _updateSourceAmount() {
    if (sourceToken.isBtc) {
      _sourceController.text = sourceShowUsd ? usdAmount : btcAmount;
    } else {
      _sourceController.text = usdAmount;
    }
  }

  void _toggleSourceMode() {
    setState(() {
      sourceShowUsd = !sourceShowUsd;
      if (sourceToken.isBtc) {
        _sourceController.text = sourceShowUsd ? usdAmount : btcAmount;
      }
    });
  }

  void _toggleTargetMode() {
    setState(() {
      targetShowUsd = !targetShowUsd;
      if (targetToken.isBtc) {
        _targetController.text = targetShowUsd ? usdAmount : btcAmount;
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
          targetToken = SwapToken.btcArkade;
          targetShowUsd = false;
        }
      }
      _updateSourceAmount();
      _updateTargetAmount();
    });
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
          sourceToken = SwapToken.btcArkade;
          sourceShowUsd = false;
        }
      }
      _updateSourceAmount();
      _updateTargetAmount();
    });
  }

  String _getButtonTitle() {
    return "Swap ${sourceToken.symbol} to ${targetToken.symbol}";
  }

  List<SwapToken> _getAvailableSourceTokens() {
    return SwapToken.values;
  }

  List<SwapToken> _getAvailableTargetTokens() {
    return SwapTokenExtension.getValidTargets(sourceToken);
  }

  /// Get the conversion display text for source
  String _getSourceConversionText() {
    if (sourceToken.isBtc) {
      if (sourceShowUsd) {
        // Showing USD, display BTC equivalent
        return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
      } else {
        // Showing BTC, display USD equivalent
        return usdAmount.isNotEmpty ? '≈ \$$usdAmount' : '≈ \$0.00';
      }
    } else {
      // Stablecoin - always show BTC equivalent
      return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
    }
  }

  /// Get the conversion display text for target
  String _getTargetConversionText() {
    if (targetToken.isBtc) {
      if (targetShowUsd) {
        return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
      } else {
        return usdAmount.isNotEmpty ? '≈ \$$usdAmount' : '≈ \$0.00';
      }
    } else {
      return btcAmount.isNotEmpty ? '≈ $btcAmount BTC' : '≈ 0 BTC';
    }
  }

  /// Initiate the swap flow
  void _initiateSwap() {
    // Validate amounts
    final usd = double.tryParse(usdAmount);
    if (usd == null || usd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Check swap direction
    if (sourceToken.isBtc && targetToken.isEvm) {
      // BTC -> EVM: Need to get EVM address (where to receive stablecoins)
      _showEvmAddressInput();
    } else if (sourceToken.isEvm && targetToken.isBtc) {
      // EVM -> BTC: Need to get both EVM address (source) and BTC address (target)
      _showEvmToBtcAddressInput();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid swap pair')),
      );
    }
  }

  /// Show EVM address input sheet (for BTC -> EVM swaps)
  void _showEvmAddressInput() {
    arkBottomSheet(
      context: context,
      child: EvmAddressInputSheet(
        tokenSymbol: targetToken.symbol,
        network: targetToken.network,
        onAddressConfirmed: (address) {
          _showConfirmation(
            targetEvmAddress: address,
            sourceEvmAddress: null,
            targetBtcAddress: null,
          );
        },
      ),
    );
  }

  /// Show EVM to BTC address input sheet (for EVM -> BTC swaps)
  void _showEvmToBtcAddressInput() {
    arkBottomSheet(
      context: context,
      child: EvmToBtcAddressSheet(
        sourceTokenSymbol: sourceToken.symbol,
        sourceNetwork: sourceToken.network,
        onAddressesConfirmed: (evmAddress, btcAddress) {
          _showConfirmation(
            targetEvmAddress: null,
            sourceEvmAddress: evmAddress,
            targetBtcAddress: btcAddress,
          );
        },
      ),
    );
  }

  /// Show swap confirmation sheet
  void _showConfirmation({
    String? targetEvmAddress,
    String? sourceEvmAddress,
    String? targetBtcAddress,
  }) {
    // Determine which address to display in confirmation
    final displayAddress = targetEvmAddress ?? targetBtcAddress;

    arkBottomSheet(
      context: context,
      child: SwapConfirmationSheet(
        sourceToken: sourceToken,
        targetToken: targetToken,
        sourceAmount: sourceToken.isBtc ? btcAmount : usdAmount,
        targetAmount: targetToken.isBtc ? btcAmount : usdAmount,
        sourceAmountUsd: usdAmount,
        targetAmountUsd: usdAmount,
        exchangeRate: btcUsdPrice,
        networkFeeSats: 1500,
        protocolFeePercent: 0.25,
        targetAddress: displayAddress,
        isLoading: isLoading,
        onConfirm: () => _executeSwap(
          targetEvmAddress: targetEvmAddress,
          sourceEvmAddress: sourceEvmAddress,
          targetBtcAddress: targetBtcAddress,
        ),
      ),
    );
  }

  /// Execute the swap
  Future<void> _executeSwap({
    String? targetEvmAddress,
    String? sourceEvmAddress,
    String? targetBtcAddress,
  }) async {
    setState(() => isLoading = true);
    Navigator.pop(context); // Close confirmation sheet

    try {
      // Initialize swap service if needed
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }

      final usd = double.tryParse(usdAmount) ?? 0;
      String swapId;

      if (sourceToken.isBtc && targetToken.isEvm) {
        // BTC -> EVM swap
        final result = await _swapService.createSellBtcSwap(
          targetEvmAddress: targetEvmAddress!,
          targetAmountUsd: usd,
          targetToken: targetToken.symbol.toLowerCase(),
          targetChain: targetToken.network.toLowerCase(),
        );
        swapId = result.swapId;
      } else {
        // EVM -> BTC swap
        final result = await _swapService.createBuyBtcSwap(
          targetArkAddress: targetBtcAddress!,
          userEvmAddress: sourceEvmAddress!,
          sourceAmountUsd: usd,
          sourceToken: sourceToken.symbol.toLowerCase(),
          sourceChain: sourceToken.network.toLowerCase(),
        );
        swapId = result.swapId;
      }

      // Navigate to processing screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SwapProcessingScreen(
              swapId: swapId,
              sourceToken: sourceToken,
              targetToken: targetToken,
              sourceAmount: sourceToken.isBtc ? btcAmount : usdAmount,
              targetAmount: targetToken.isBtc ? btcAmount : usdAmount,
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('Swap failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Swap failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: ArkAppBar(
        text: "Swap",
        context: context,
        hasBackButton: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.cardPadding * 2),
                SizedBox(
                  height: AppTheme.cardPadding * (7.0 * 2 + 0.5),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // SOURCE CARD (You Sell)
                          Container(
                            height: AppTheme.cardPadding * 7.0,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.cardPadding,
                            ),
                            child: _SwapAmountCard(
                              token: sourceToken,
                              cardTitle: "Sell",
                              controller: _sourceController,
                              showUsdMode: sourceShowUsd,
                              conversionText: _getSourceConversionText(),
                              onAmountChanged: _onSourceAmountChanged,
                              onToggleMode: sourceToken.isBtc ? _toggleSourceMode : null,
                              availableTokens: _getAvailableSourceTokens(),
                              onTokenChanged: _onSourceTokenChanged,
                              showBalance: true,
                              label: 'sell',
                            ),
                          ),
                          Container(height: AppTheme.cardPadding * 0.5),
                          // TARGET CARD (You Buy)
                          Container(
                            height: AppTheme.cardPadding * 7.0,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.cardPadding,
                            ),
                            child: _SwapAmountCard(
                              token: targetToken,
                              cardTitle: "Buy",
                              controller: _targetController,
                              showUsdMode: targetShowUsd,
                              conversionText: _getTargetConversionText(),
                              onAmountChanged: _onTargetAmountChanged,
                              onToggleMode: targetToken.isBtc ? _toggleTargetMode : null,
                              availableTokens: _getAvailableTargetTokens(),
                              onTokenChanged: _onTargetTokenChanged,
                              showBalance: false,
                              label: 'buy',
                            ),
                          ),
                        ],
                      ),
                      // SWAP BUTTON IN THE MIDDLE
                      Align(
                        alignment: Alignment.center,
                        child: Material(
                          color: AppTheme.colorBitcoin,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                          child: InkWell(
                            onTap: _swapTokens,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusSmall,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.swap_vert,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.cardPadding),
                // Quote info section
                _buildQuoteInfo(context),
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
                state: isLoading ? ButtonState.loading : ButtonState.idle,
                onTap: _initiateSwap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteInfo(BuildContext context) {
    final usd = double.tryParse(usdAmount) ?? 0;

    // Calculate fees (mock - in production get from quote API)
    const networkFeeSats = 1500;
    const protocolFeePercent = 0.25;
    final protocolFeeSats = (usd * protocolFeePercent / 100 * 100000000 / btcUsdPrice).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            children: [
              _buildQuoteRow(
                context,
                'Rate',
                '1 BTC = \$${formatUsd(btcUsdPrice)}',
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              _buildQuoteRow(
                context,
                'Network Fee',
                '${formatSats(networkFeeSats)} sats (~\$${formatUsd(btcToUsd(networkFeeSats / 100000000))})',
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              _buildQuoteRow(
                context,
                'Protocol Fee',
                '$protocolFeePercent%${protocolFeeSats > 0 ? ' (${formatSats(protocolFeeSats)} sats)' : ''}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteRow(BuildContext context, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Swap amount input card
class _SwapAmountCard extends StatelessWidget {
  final SwapToken token;
  final String cardTitle;
  final TextEditingController controller;
  final bool showUsdMode;
  final String conversionText;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onToggleMode;
  final List<SwapToken> availableTokens;
  final ValueChanged<SwapToken> onTokenChanged;
  final bool showBalance;
  final String? label;

  const _SwapAmountCard({
    required this.token,
    required this.cardTitle,
    required this.controller,
    required this.showUsdMode,
    required this.conversionText,
    required this.onAmountChanged,
    this.onToggleMode,
    required this.availableTokens,
    required this.onTokenChanged,
    required this.showBalance,
    this.label,
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
      return '0';
    }
    return '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final showDollarPrefix = showUsdMode || !token.isBtc;

    return GlassContainer(
      borderRadius: BorderRadius.circular(24),
      boxShadow: isDarkMode
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      ),
                ),
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                // Amount input row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dollar sign prefix (if showing USD)
                    if (showDollarPrefix)
                      Text(
                        "\$",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    // Amount input
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,8}$'),
                          ),
                        ],
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintText: _getPlaceholder(),
                          hintStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? AppTheme.white60.withValues(alpha: 0.5)
                                : AppTheme.black60.withValues(alpha: 0.5),
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
                      borderRadius: BorderRadius.circular(8),
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          conversionText,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                          ),
                        ),
                        if (onToggleMode != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_vert,
                            size: 14,
                            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(500),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.elementSpacing * 0.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: AppTheme.elementSpacing * 0.5),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: AppTheme.elementSpacing * 0.5),
                          TokenIconWithNetwork(
                            token: token,
                            size: AppTheme.cardPadding * 1.25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showBalance) ...[
                  const SizedBox(height: 6),
                  Text(
                    token.isBtc ? '1,000,000 sats' : '~\$500.00',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
      appBar: ArkAppBar(
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          token.network,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
