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
/// Displays all swap details for user review.
class SwapConfirmationSheet extends StatelessWidget {
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;
  final String sourceAmountUsd;
  final String targetAmountUsd;
  final double exchangeRate;
  final int networkFeeSats;
  final double protocolFeePercent;
  final String? targetAddress; // EVM address for BTC->EVM swaps
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

  String _formatSats(int sats) {
    if (sats >= 1000000) {
      return '${(sats / 1000000).toStringAsFixed(2)}M';
    } else if (sats >= 1000) {
      return '${(sats / 1000).toStringAsFixed(1)}k';
    }
    return sats.toString();
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
            const SizedBox(height: AppTheme.cardPadding * 2),
            // Swap summary card
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: Column(
                  children: [
                    // From
                    _SwapAmountRow(
                      label: 'You pay',
                      token: sourceToken,
                      amount: sourceAmount,
                      amountUsd: sourceAmountUsd,
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                    // Arrow
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                    // To
                    _SwapAmountRow(
                      label: 'You receive',
                      token: targetToken,
                      amount: targetAmount,
                      amountUsd: targetAmountUsd,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // Details card
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Exchange Rate',
                      value: '1 BTC = \$${exchangeRate.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    _DetailRow(
                      label: 'Network Fee',
                      value: '${_formatSats(networkFeeSats)} sats',
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    _DetailRow(
                      label: 'Protocol Fee',
                      value: '$protocolFeePercent%',
                    ),
                    if (targetAddress != null) ...[
                      const SizedBox(height: AppTheme.elementSpacing),
                      const Divider(),
                      const SizedBox(height: AppTheme.elementSpacing),
                      _DetailRow(
                        label: 'Receiving Address',
                        value: _truncateAddress(targetAddress!),
                        isMonospace: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Warning text
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swaps are atomic and non-reversible. Please review all details carefully.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // Confirm button
            LongButtonWidget(
              title: 'Confirm Swap',
              customWidth: double.infinity,
              state: isLoading ? ButtonState.loading : ButtonState.idle,
              onTap: isLoading ? null : onConfirm,
            ),
            const SizedBox(height: AppTheme.cardPadding),
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

class _SwapAmountRow extends StatelessWidget {
  final String label;
  final SwapToken token;
  final String amount;
  final String amountUsd;

  const _SwapAmountRow({
    required this.label,
    required this.token,
    required this.amount,
    required this.amountUsd,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                token.isBtc ? '$amount BTC' : '\$$amount',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                token.isBtc ? '≈ \$$amountUsd' : '≈ $amountUsd BTC',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
              ),
            ],
          ),
        ),
        TokenIconWithNetwork(token: token, size: 48),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
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
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
