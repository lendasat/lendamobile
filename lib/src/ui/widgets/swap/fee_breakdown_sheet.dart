import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';

/// Bottom sheet content for fee breakdown with collapsible details.
/// Used in swap screen to show network and protocol fees.
class FeeBreakdownSheet extends StatefulWidget {
  final int networkFeeSats;
  final int protocolFeeSats;
  final double protocolFeePercent;
  final double networkFeeUsd;
  final double protocolFeeUsd;
  final bool isLoading;
  final bool hasQuote;

  const FeeBreakdownSheet({
    super.key,
    required this.networkFeeSats,
    required this.protocolFeeSats,
    required this.protocolFeePercent,
    required this.networkFeeUsd,
    required this.protocolFeeUsd,
    required this.isLoading,
    required this.hasQuote,
  });

  @override
  State<FeeBreakdownSheet> createState() => _FeeBreakdownSheetState();
}

class _FeeBreakdownSheetState extends State<FeeBreakdownSheet> {
  bool _feesExpanded = false;

  int get _totalFeeSats => widget.networkFeeSats + widget.protocolFeeSats;
  double get _totalFeeUsd => widget.networkFeeUsd + widget.protocolFeeUsd;

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

    return Container(
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
          if (!widget.hasQuote && !widget.isLoading)
            Text(
              'Enter an amount to see fee breakdown',
              style: TextStyle(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
              ),
            )
          else if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: dotProgress(context),
            )
          else
            GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: Column(
                children: [
                  // Collapsible header
                  InkWell(
                    onTap: () => setState(() => _feesExpanded = !_feesExpanded),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMid),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.cardPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Total fees',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_formatSats(_totalFeeSats)} sats (~\$${_totalFeeUsd.toStringAsFixed(2)})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _feesExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: isDarkMode
                                      ? AppTheme.white60
                                      : AppTheme.black60,
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
                            'Network fee',
                            '${_formatSats(widget.networkFeeSats)} sats',
                            '~\$${widget.networkFeeUsd.toStringAsFixed(2)}',
                            isDarkMode,
                          ),
                          const SizedBox(height: AppTheme.elementSpacing * 0.5),
                          _buildFeeRow(
                            'Protocol fee (${widget.protocolFeePercent.toStringAsFixed(1)}%)',
                            '${_formatSats(widget.protocolFeeSats)} sats',
                            '~\$${widget.protocolFeeUsd.toStringAsFixed(2)}',
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
            ),
          const SizedBox(height: AppTheme.cardPadding),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    String satsValue,
    String usdValue,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              satsValue,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              usdValue,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
