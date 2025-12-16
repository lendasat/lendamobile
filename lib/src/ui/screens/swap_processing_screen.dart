import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/swap_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen that shows the processing status of an ongoing swap.
class SwapProcessingScreen extends StatefulWidget {
  final String swapId;
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;

  const SwapProcessingScreen({
    super.key,
    required this.swapId,
    required this.sourceToken,
    required this.targetToken,
    required this.sourceAmount,
    required this.targetAmount,
  });

  @override
  State<SwapProcessingScreen> createState() => _SwapProcessingScreenState();
}

class _SwapProcessingScreenState extends State<SwapProcessingScreen> {
  final LendaSwapService _swapService = LendaSwapService();
  SwapInfo? _swapInfo;
  Timer? _pollTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSwapInfo();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadSwapInfo();
    });
  }

  Future<void> _loadSwapInfo() async {
    try {
      final swap = await _swapService.getSwap(widget.swapId);
      if (mounted) {
        setState(() {
          _swapInfo = swap;
          _isLoading = false;
        });

        // Check if completed or failed
        if (swap.isCompleted) {
          _pollTimer?.cancel();
          _navigateToSuccess();
        } else if (swap.status == SwapStatusSimple.failed ||
            swap.status == SwapStatusSimple.expired) {
          _pollTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SwapSuccessScreen(
          sourceToken: widget.sourceToken,
          targetToken: widget.targetToken,
          sourceAmount: widget.sourceAmount,
          targetAmount: widget.targetAmount,
          swapId: widget.swapId,
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: 'Swap in Progress',
        hasBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(context)
              : _buildProcessingState(context, isDarkMode),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              'Error loading swap',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.white60,
                  ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: 'Retry',
              onTap: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadSwapInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context, bool isDarkMode) {
    final status = _swapInfo?.status ?? SwapStatusSimple.waitingForDeposit;

    // Only show deposit info for EVM → BTC swaps (user needs to deposit EVM tokens)
    // For BTC → EVM swaps, Arkade handles payment automatically
    final showDepositInfo = status == SwapStatusSimple.waitingForDeposit &&
        _swapInfo?.depositAddress != null &&
        widget.sourceToken.isEvm; // Only for EVM source (buying BTC)

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.cardPadding * 2),
          // Status indicator
          _buildStatusIndicator(context, status, isDarkMode),
          const SizedBox(height: AppTheme.cardPadding * 2),
          // Swap summary
          _buildSwapSummary(context, isDarkMode),
          const SizedBox(height: AppTheme.cardPadding),
          // Deposit info only for EVM → BTC swaps
          if (showDepositInfo) _buildDepositInfo(context, isDarkMode),
          const SizedBox(height: AppTheme.cardPadding),
          // Status details
          _buildStatusDetails(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
      BuildContext context, SwapStatusSimple status, bool isDarkMode) {
    IconData icon;
    Color color;
    String statusText;
    bool showSpinner = false;

    // For BTC → EVM swaps, "Waiting for Deposit" should show as "Processing"
    // since Arkade handles the payment automatically
    final effectiveStatus = status == SwapStatusSimple.waitingForDeposit &&
            widget.sourceToken.isBtc
        ? SwapStatusSimple.processing
        : status;

    switch (effectiveStatus) {
      case SwapStatusSimple.waitingForDeposit:
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange;
        statusText = 'Waiting for Deposit';
        showSpinner = true;
        break;
      case SwapStatusSimple.processing:
        icon = Icons.sync_rounded;
        color = AppTheme.colorBitcoin;
        statusText = 'Processing';
        showSpinner = true;
        break;
      case SwapStatusSimple.completed:
        icon = Icons.check_circle_rounded;
        color = AppTheme.successColor;
        statusText = 'Completed';
        break;
      case SwapStatusSimple.expired:
        icon = Icons.timer_off_rounded;
        color = AppTheme.errorColor;
        statusText = 'Expired';
        break;
      case SwapStatusSimple.refundable:
        icon = Icons.replay_rounded;
        color = Colors.orange;
        statusText = 'Refundable';
        break;
      case SwapStatusSimple.refunded:
        icon = Icons.undo_rounded;
        color = AppTheme.white60;
        statusText = 'Refunded';
        break;
      case SwapStatusSimple.failed:
        icon = Icons.error_rounded;
        color = AppTheme.errorColor;
        statusText = 'Failed';
        break;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (showSpinner)
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withValues(alpha: 0.3),
                  ),
                ),
              ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.cardPadding),
        Text(
          statusText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildSwapSummary(BuildContext context, bool isDarkMode) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          children: [
            // From
            Expanded(
              child: Column(
                children: [
                  TokenIcon(token: widget.sourceToken, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    widget.sourceToken.isBtc
                        ? '${widget.sourceAmount} BTC'
                        : '\$${widget.sourceAmount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    widget.sourceToken.symbol,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ],
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
            // To
            Expanded(
              child: Column(
                children: [
                  TokenIcon(token: widget.targetToken, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    widget.targetToken.isBtc
                        ? '${widget.targetAmount} BTC'
                        : '\$${widget.targetAmount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    widget.targetToken.symbol,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositInfo(BuildContext context, bool isDarkMode) {
    final depositAddress = _swapInfo!.depositAddress!;
    final isLightningInvoice = depositAddress.startsWith('ln');

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLightningInvoice ? Icons.bolt_rounded : Icons.account_balance_wallet_rounded,
                  color: AppTheme.colorBitcoin,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isLightningInvoice ? 'Pay Lightning Invoice' : 'Send to Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Address/Invoice
            GestureDetector(
              onTap: () => _copyToClipboard(depositAddress),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.elementSpacing),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLightningInvoice
                            ? '${depositAddress.substring(0, 20)}...${depositAddress.substring(depositAddress.length - 10)}'
                            : depositAddress,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              isLightningInvoice
                  ? 'Scan or pay this Lightning invoice to continue the swap'
                  : 'Send the exact amount to this address to continue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDetails(BuildContext context, bool isDarkMode) {
    if (_swapInfo == null) return const SizedBox.shrink();

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              'Swap ID',
              _truncateId(widget.swapId),
              isDarkMode,
              onTap: () => _copyToClipboard(widget.swapId),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            _buildDetailRow(
              context,
              'Direction',
              _swapInfo!.isBtcToEvm ? 'BTC → Stablecoin' : 'Stablecoin → BTC',
              isDarkMode,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            _buildDetailRow(
              context,
              'Created',
              _formatTimestamp(_swapInfo!.createdAt),
              isDarkMode,
            ),
            if (_swapInfo!.canRefund) ...[
              const SizedBox(height: AppTheme.cardPadding),
              LongButtonWidget(
                title: 'Refund',
                buttonType: ButtonType.secondary,
                onTap: () {
                  // TODO: Implement refund flow
                },
              ),
            ],
          ],
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

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
