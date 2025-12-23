import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/screens/swap_detail_screen.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen shown when a swap completes successfully.
class SwapSuccessScreen extends StatefulWidget {
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;
  final String swapId;
  final String? txHash;

  const SwapSuccessScreen({
    super.key,
    required this.sourceToken,
    required this.targetToken,
    required this.sourceAmount,
    required this.targetAmount,
    required this.swapId,
    this.txHash,
  });

  @override
  State<SwapSuccessScreen> createState() => _SwapSuccessScreenState();
}

class _SwapSuccessScreenState extends State<SwapSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _trackSwap();
  }

  Future<void> _trackSwap() async {
    // Parse amount to sats (BTC amount * 100_000_000)
    int amountSats = 0;
    try {
      if (widget.sourceToken.isBtc) {
        amountSats = (double.parse(widget.sourceAmount) * BitcoinConstants.satsPerBtc).toInt();
      } else if (widget.targetToken.isBtc) {
        amountSats = (double.parse(widget.targetAmount) * BitcoinConstants.satsPerBtc).toInt();
      }
    } catch (e) {
      logger.w('Failed to parse swap amount for analytics: $e');
    }

    await AnalyticsService().trackSwapTransaction(
      amountSats: amountSats,
      fromAsset: widget.sourceToken.symbol,
      toAsset: widget.targetToken.symbol,
      swapId: widget.swapId,
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      OverlayService().showSuccess('Copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  (AppTheme.cardPadding * 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: AppTheme.cardPadding),
                // Main content
                Column(
                  children: [
                    // Success animation/icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                    // Title
                    Text(
                      'Swap Complete!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your swap has been executed successfully',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode
                                ? AppTheme.white60
                                : AppTheme.black60,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.cardPadding * 2),
                    // Swap summary
                    GlassContainer(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMid),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.cardPadding),
                        child: Column(
                          children: [
                            // From
                            Row(
                              children: [
                                TokenIcon(token: widget.sourceToken, size: 40),
                                const SizedBox(width: AppTheme.elementSpacing),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sent',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isDarkMode
                                                  ? AppTheme.white60
                                                  : AppTheme.black60,
                                            ),
                                      ),
                                      Text(
                                        widget.sourceToken.isBtc
                                            ? '${widget.sourceAmount} BTC'
                                            : '\$${widget.sourceAmount} ${widget.sourceToken.symbol}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.cardPadding),
                            // Divider with arrow
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 18,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.cardPadding),
                            // To
                            Row(
                              children: [
                                TokenIcon(token: widget.targetToken, size: 40),
                                const SizedBox(width: AppTheme.elementSpacing),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Received',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isDarkMode
                                                  ? AppTheme.white60
                                                  : AppTheme.black60,
                                            ),
                                      ),
                                      Text(
                                        widget.targetToken.isBtc
                                            ? '${widget.targetAmount} BTC'
                                            : '\$${widget.targetAmount} ${widget.targetToken.symbol}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.successColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                    // Transaction details
                    GlassContainer(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMid),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.cardPadding),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              context,
                              'Swap ID',
                              _truncateId(widget.swapId),
                              isDarkMode,
                              onTap: () =>
                                  _copyToClipboard(context, widget.swapId),
                            ),
                            if (widget.txHash != null) ...[
                              const SizedBox(height: AppTheme.elementSpacing),
                              _buildDetailRow(
                                context,
                                'Transaction',
                                _truncateId(widget.txHash!),
                                isDarkMode,
                                onTap: () =>
                                    _copyToClipboard(context, widget.txHash!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.cardPadding),
                // Bottom buttons
                Column(
                  children: [
                    // Done button
                    LongButtonWidget(
                      title: 'Done',
                      customWidth: double.infinity,
                      onTap: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    // View details button
                    TextButton(
                      onPressed: () {
                        // Navigate to swap detail screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                SwapDetailScreen(swapId: widget.swapId),
                          ),
                        );
                      },
                      child: Text(
                        'View Swap Details',
                        style: TextStyle(
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            fontSize: 14,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.copy_rounded,
                size: 14,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }

  String _truncateId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }
}
