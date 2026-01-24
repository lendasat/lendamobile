import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart'
    show CurrencyType;
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/swap/token_selector_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Swap amount input card - Uniswap style
class SwapAmountCard extends StatelessWidget {
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
  final BigInt? balanceSats;
  final String? label;
  final bool isTopCard;
  final CurrencyType btcUnit;
  final VoidCallback? onMaxTap;

  const SwapAmountCard({
    super.key,
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
    this.balanceSats,
    this.label,
    this.isTopCard = true,
    this.btcUnit = CurrencyType.sats,
    this.onMaxTap,
  });

  void _showTokenSelector(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    arkBottomSheet(
      context: context,
      height: screenHeight * 0.75,
      child: TokenSelectorSheet(
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
      return btcUnit == CurrencyType.sats ? '0' : '0.00000000';
    }
    return '0.00';
  }

  String _formatBalance(BigInt sats) {
    final value = sats.toInt();
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      final formatted = value.toString();
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
    return value.toString();
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
              vertical: AppTheme.cardPadding * 0.75,
            ),
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => focusNode?.requestFocus(),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dollar sign prefix
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
                        // Sats/BTC icon prefix
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
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              isDense: false,
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
                  ),
                ),
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                // Conversion text row with optional Max button
                Row(
                  children: [
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
                    // Max button
                    if (onMaxTap != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onMaxTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall),
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          child: Text(
                            'Max',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppTheme.white60
                                  : AppTheme.black60,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                      color:
                          isDarkMode ? const Color(0xFF3D3D3D) : Colors.white,
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
                if (showBalance && token.isBtc && balanceSats != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppTheme.satoshiIcon,
                          size: 12,
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatBalance(balanceSats!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                        ),
                      ],
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
