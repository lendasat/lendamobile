import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
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
  final int protocolFeeSats; // Protocol fee in sats for total calculation
  final double protocolFeePercent;
  final int sourceAmountSats; // Input amount in sats for total calculation
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
    required this.protocolFeeSats,
    required this.protocolFeePercent,
    required this.sourceAmountSats,
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
    return (widget.networkFeeSats / BitcoinConstants.satsPerBtc) *
        widget.exchangeRate;
  }

  /// Calculate protocol fee in USD
  double get _protocolFeeUsd {
    return (widget.protocolFeeSats / BitcoinConstants.satsPerBtc) *
        widget.exchangeRate;
  }

  /// Total fees in sats
  int get _totalFeesSats => widget.networkFeeSats + widget.protocolFeeSats;

  /// Total fees in USD
  double get _totalFeesUsd => _networkFeeUsd + _protocolFeeUsd;

  /// Total amount deducted from balance (input + fees) in sats
  int get _totalFromBalanceSats => widget.sourceAmountSats + _totalFeesSats;

  /// Total amount deducted from balance in USD
  double get _totalFromBalanceUsd {
    return (_totalFromBalanceSats / BitcoinConstants.satsPerBtc) *
        widget.exchangeRate;
  }

  /// Net amount after fees (what user actually receives)
  double get _netReceiveUsd {
    final gross = double.tryParse(widget.targetAmountUsd) ?? 0;
    return gross - _totalFeesUsd;
  }

  /// Format sats with thousands separator
  String _formatSats(int sats) {
    return sats.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: AppLocalizations.of(context)?.confirmSwap ?? 'Confirm Swap',
        hasBackButton: false,
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - (AppTheme.cardPadding * 2),
        child: LongButtonWidget(
          title: AppLocalizations.of(context)?.confirmSwap ?? 'Confirm Swap',
          customWidth: double.infinity,
          state: widget.isLoading ? ButtonState.loading : ButtonState.idle,
          onTap: widget.isLoading ? null : widget.onConfirm,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
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
            // Extra space at bottom for floating button
            const SizedBox(height: AppTheme.cardPadding * 5),
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
                    AppLocalizations.of(context)?.youPay ?? 'You pay',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                    AppLocalizations.of(context)?.youReceive ?? 'You receive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                      '${AppLocalizations.of(context)?.beforeFees ?? 'before fees'}: \$$grossAmount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
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
    // Only show for BTC source (where we deduct from balance)
    final showTotalFromBalance = widget.sourceToken.isBtc;

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
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)?.totalFeesLabel ??
                          'Total fees',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${_formatSats(_totalFeesSats)} sats (~\$${_totalFeesUsd.toStringAsFixed(2)})',
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
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                    AppLocalizations.of(context)?.networkFee ?? 'Network fee',
                    '${_formatSats(widget.networkFeeSats)} sats',
                    isDarkMode,
                  ),
                  const SizedBox(height: AppTheme.elementSpacing * 0.5),
                  _buildFeeRow(
                    context,
                    '${AppLocalizations.of(context)?.protocolFee ?? 'Protocol fee'} (${widget.protocolFeePercent.toStringAsFixed(1)}%)',
                    '${_formatSats(widget.protocolFeeSats)} sats',
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
          // Total from balance (always visible, outside collapsible)
          if (showTotalFromBalance) ...[
            Divider(
              height: 1,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total from balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatSats(_totalFromBalanceSats)} sats',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '~\$${_totalFromBalanceUsd.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
            Flexible(
              child: Text(
                AppLocalizations.of(context)?.receivingAddress ??
                    'Receiving address',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
