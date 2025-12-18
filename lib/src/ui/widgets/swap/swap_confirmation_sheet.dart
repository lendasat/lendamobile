import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';

/// Confirmation sheet shown before executing a swap.
/// Displays all swap details for user review with collapsible fee breakdown.
class SwapConfirmationSheet extends StatefulWidget {
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;
  final String sourceAmountUsd;
  final String targetAmountUsd;
  final double exchangeRate;
  final int networkFeeSats;
  final double protocolFeePercent;
  final String? targetAddress;
  final VoidCallback onConfirm;
  final bool isLoading;

  const SwapConfirmationSheet({
    super.key,
    required this.sourceToken,
    required this.targetToken,
    required this.sourceAmount,
    required this.targetAmount,
    required this.sourceAmountUsd,
    required this.targetAmountUsd,
    required this.exchangeRate,
    required this.networkFeeSats,
    required this.protocolFeePercent,
    this.targetAddress,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  State<SwapConfirmationSheet> createState() => _SwapConfirmationSheetState();
}

class _SwapConfirmationSheetState extends State<SwapConfirmationSheet> {
  bool _feesExpanded = false;

  /// Calculate network fee in USD
  double get _networkFeeUsd {
    return (widget.networkFeeSats / 100000000) * widget.exchangeRate;
  }

  /// Calculate protocol fee in USD
  double get _protocolFeeUsd {
    final usd = double.tryParse(widget.sourceAmountUsd) ?? 0;
    return usd * widget.protocolFeePercent / 100;
  }

  /// Total fees in USD
  double get _totalFeesUsd => _networkFeeUsd + _protocolFeeUsd;

  /// Net amount after fees (what user actually receives)
  double get _netReceiveUsd {
    final gross = double.tryParse(widget.targetAmountUsd) ?? 0;
    return gross - _totalFeesUsd;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: 'Confirm Swap',
        hasBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.cardPadding * 2),
                    // You pay card
                    _buildPayCard(context, isDarkMode),
                    const SizedBox(height: AppTheme.elementSpacing),
                    // Arrow
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    // You receive card (with net amount after fees)
                    _buildReceiveCard(context, isDarkMode),
                    const SizedBox(height: AppTheme.cardPadding),
                    // Collapsible fees section
                    _buildFeesSection(context, isDarkMode),
                    // Receiving address (if applicable)
                    if (widget.targetAddress != null) ...[
                      const SizedBox(height: AppTheme.elementSpacing),
                      _buildAddressRow(context, isDarkMode),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // Confirm button
            LongButtonWidget(
              title: 'Confirm Swap',
              customWidth: double.infinity,
              state: widget.isLoading ? ButtonState.loading : ButtonState.idle,
              onTap: widget.isLoading ? null : widget.onConfirm,
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildPayCard(BuildContext context, bool isDarkMode) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You pay',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sourceToken.isBtc
                        ? '${widget.sourceAmount} BTC'
                        : '\$${widget.sourceAmount}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    widget.sourceToken.isBtc
                        ? '≈ \$${widget.sourceAmountUsd}'
                        : '≈ ${widget.sourceAmount} ${widget.sourceToken.symbol}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ],
              ),
            ),
            TokenIconWithNetwork(token: widget.sourceToken, size: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiveCard(BuildContext context, bool isDarkMode) {
    final netAmount = _netReceiveUsd.toStringAsFixed(2);
    final grossAmount = widget.targetAmountUsd;

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You receive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Net amount (after fees) - prominent
                  Text(
                    widget.targetToken.isBtc
                        ? '${widget.targetAmount} BTC'
                        : '\$$netAmount ${widget.targetToken.symbol}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                  ),
                  // Gross amount (before fees) - secondary
                  if (!widget.targetToken.isBtc && _totalFeesUsd > 0.01)
                    Text(
                      'before fees: \$$grossAmount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                          ),
                    ),
                ],
              ),
            ),
            TokenIconWithNetwork(token: widget.targetToken, size: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesSection(BuildContext context, bool isDarkMode) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Column(
        children: [
          // Collapsible header
          InkWell(
            onTap: () => setState(() => _feesExpanded = !_feesExpanded),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total fees',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '~\$${_totalFeesUsd.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _feesExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expandable details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.cardPadding,
                right: AppTheme.cardPadding,
                bottom: AppTheme.cardPadding,
              ),
              child: Column(
                children: [
                  Divider(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  _buildFeeRow(
                    context,
                    'Network',
                    '~\$${_networkFeeUsd.toStringAsFixed(2)}',
                    isDarkMode,
                  ),
                  const SizedBox(height: AppTheme.elementSpacing * 0.5),
                  _buildFeeRow(
                    context,
                    'Protocol (${widget.protocolFeePercent}%)',
                    '~\$${_protocolFeeUsd.toStringAsFixed(2)}',
                    isDarkMode,
                  ),
                ],
              ),
            ),
            crossFadeState: _feesExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(BuildContext context, bool isDarkMode) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Receiving address',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
            Text(
              _truncateAddress(widget.targetAddress!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }
}
