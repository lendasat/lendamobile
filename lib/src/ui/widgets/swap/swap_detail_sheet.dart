import 'dart:async';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet widget for displaying swap details.
class SwapDetailSheet extends StatefulWidget {
  final String swapId;
  final SwapActivityItem? initialSwapItem;

  const SwapDetailSheet({
    super.key,
    required this.swapId,
    this.initialSwapItem,
  });

  @override
  State<SwapDetailSheet> createState() => _SwapDetailSheetState();
}

class _SwapDetailSheetState extends State<SwapDetailSheet> {
  final LendaSwapService _swapService = LendaSwapService();
  SwapInfo? _swapInfo;
  bool _isLoading = true;
  bool _isRefunding = false;
  bool _isClaiming = false;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialSwapItem != null) {
      _swapInfo = widget.initialSwapItem!.swap;
      _isLoading = false;
    }
    _loadSwapInfo();
    _startPollingIfNeeded();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPollingIfNeeded() {
    if (_swapInfo != null) {
      final status = _swapInfo!.status;
      if (status == SwapStatusSimple.waitingForDeposit ||
          status == SwapStatusSimple.processing) {
        _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          _loadSwapInfo();
        });
      }
    }
  }

  Future<void> _loadSwapInfo() async {
    try {
      if (!_swapService.isInitialized) {
        await _swapService.initialize();
      }
      final swap = await _swapService.getSwap(widget.swapId);
      if (mounted) {
        setState(() {
          _swapInfo = swap;
          _isLoading = false;
          _errorMessage = null;
        });

        if (swap.status == SwapStatusSimple.completed ||
            swap.status == SwapStatusSimple.failed ||
            swap.status == SwapStatusSimple.refunded ||
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

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      OverlayService().showSuccess('Copied to clipboard');
    }
  }

  Future<void> _handleRefund() async {
    if (_swapInfo == null) return;

    final refundAddress = await _showRefundAddressSheet();
    if (refundAddress == null || refundAddress.isEmpty) return;

    setState(() => _isRefunding = true);

    try {
      final txid = await _swapService.refundVhtlc(widget.swapId, refundAddress);
      if (mounted) {
        OverlayService().showSuccess('Refund initiated: ${_truncateId(txid)}');
        await _loadSwapInfo();
      }
    } catch (e) {
      logger.e('Refund failed: $e');
      if (mounted) {
        OverlayService().showError('Refund failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefunding = false);
      }
    }
  }

  Future<void> _handleClaim() async {
    if (_swapInfo == null) return;

    setState(() => _isClaiming = true);

    try {
      if (_swapInfo!.canClaimGelato) {
        logger.i('Claiming BTC→EVM swap via Gelato');
        await _swapService.claimGelato(widget.swapId);
        if (mounted) {
          OverlayService()
              .showSuccess('Claim submitted! Funds will arrive shortly.');
        }
      } else if (_swapInfo!.canClaimVhtlc) {
        logger.i('Claiming EVM→BTC swap via VHTLC');
        final txid = await _swapService.claimVhtlc(widget.swapId);
        if (mounted) {
          OverlayService().showSuccess('Claimed! TXID: ${_truncateId(txid)}');
        }
      }
      await _loadSwapInfo();
    } catch (e) {
      logger.e('Claim failed: $e');
      if (mounted) {
        OverlayService().showError('Claim failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  Future<String?> _showRefundAddressSheet() async {
    final controller = TextEditingController();
    String? result;

    await arkBottomSheet(
      context: context,
      child: _RefundAddressSheet(
        controller: controller,
        onConfirm: (address) {
          result = address;
          Navigator.pop(context);
        },
      ),
    );

    return result;
  }

  SwapToken _getSourceToken() {
    if (_swapInfo == null) return SwapToken.bitcoin;
    final token = _swapInfo!.sourceToken.toLowerCase();
    if (token.contains('btc')) return SwapToken.bitcoin;
    if (token.contains('xaut')) return SwapToken.xautEthereum;
    if (token.contains('usdc') && token.contains('pol')) {
      return SwapToken.usdcPolygon;
    }
    if (token.contains('usdt') && token.contains('pol')) {
      return SwapToken.usdtPolygon;
    }
    if (token.contains('usdc') && token.contains('eth')) {
      return SwapToken.usdcEthereum;
    }
    if (token.contains('usdt') && token.contains('eth')) {
      return SwapToken.usdtEthereum;
    }
    return SwapToken.bitcoin;
  }

  SwapToken _getTargetToken() {
    if (_swapInfo == null) return SwapToken.usdcPolygon;
    final token = _swapInfo!.targetToken.toLowerCase();
    if (token.contains('btc')) return SwapToken.bitcoin;
    if (token.contains('xaut')) return SwapToken.xautEthereum;
    if (token.contains('usdc') && token.contains('pol')) {
      return SwapToken.usdcPolygon;
    }
    if (token.contains('usdt') && token.contains('pol')) {
      return SwapToken.usdtPolygon;
    }
    if (token.contains('usdc') && token.contains('eth')) {
      return SwapToken.usdcEthereum;
    }
    if (token.contains('usdt') && token.contains('eth')) {
      return SwapToken.usdtEthereum;
    }
    return SwapToken.usdcPolygon;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Swap Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.cardPadding * 2),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMessage != null && _swapInfo == null
                    ? _buildErrorState(context)
                    : _buildContent(context, isDark),
          ),
        ],
      ),
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

  Widget _buildContent(BuildContext context, bool isDark) {
    final sourceToken = _getSourceToken();
    final targetToken = _getTargetToken();
    final status = _swapInfo?.status ?? SwapStatusSimple.waitingForDeposit;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Column(
        children: [
          // Status header
          _buildStatusHeader(context, status, isDark),
          const SizedBox(height: AppTheme.cardPadding),
          // Swap summary
          _buildSwapSummary(context, sourceToken, targetToken, isDark),
          const SizedBox(height: AppTheme.cardPadding),
          // Swap details
          _buildSwapDetails(context, isDark),
          const SizedBox(height: AppTheme.cardPadding),
          // Action buttons
          _buildActionButtons(context, status),
          SafeArea(
            top: false,
            child: const SizedBox(height: AppTheme.cardPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(
      BuildContext context, SwapStatusSimple status, bool isDark) {
    final statusInfo = _getStatusInfo(status);

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: statusInfo.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(statusInfo.icon, size: 32, color: statusInfo.color),
        ),
        const SizedBox(height: AppTheme.elementSpacing),
        Text(
          statusInfo.text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusInfo.color,
              ),
        ),
        if (statusInfo.description != null) ...[
          const SizedBox(height: 4),
          Text(
            statusInfo.description!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
        ],
      ],
    );
  }

  _StatusInfo _getStatusInfo(SwapStatusSimple status) {
    switch (status) {
      case SwapStatusSimple.waitingForDeposit:
        return _StatusInfo(
          icon: Icons.hourglass_empty_rounded,
          color: Colors.orange,
          text: 'Waiting for Deposit',
          description: 'Send funds to complete the swap',
        );
      case SwapStatusSimple.processing:
        return _StatusInfo(
          icon: Icons.sync_rounded,
          color: AppTheme.colorBitcoin,
          text: 'Processing',
          description: 'Your swap is being processed',
        );
      case SwapStatusSimple.completed:
        return _StatusInfo(
          icon: Icons.check_circle_rounded,
          color: AppTheme.successColor,
          text: 'Completed',
          description: 'Swap completed successfully',
        );
      case SwapStatusSimple.expired:
        return _StatusInfo(
          icon: Icons.timer_off_rounded,
          color: AppTheme.errorColor,
          text: 'Expired',
          description: 'This swap has expired',
        );
      case SwapStatusSimple.refundable:
        return _StatusInfo(
          icon: Icons.replay_rounded,
          color: Colors.orange,
          text: 'Refundable',
          description: 'You can claim a refund for this swap',
        );
      case SwapStatusSimple.refunded:
        return _StatusInfo(
          icon: Icons.undo_rounded,
          color: AppTheme.white60,
          text: 'Refunded',
          description: 'Funds have been refunded',
        );
      case SwapStatusSimple.failed:
        return _StatusInfo(
          icon: Icons.error_rounded,
          color: AppTheme.errorColor,
          text: 'Failed',
          description: 'This swap failed to complete',
        );
    }
  }

  Widget _buildSwapSummary(BuildContext context, SwapToken sourceToken,
      SwapToken targetToken, bool isDark) {
    final btcAmount = _swapInfo != null
        ? ((_swapInfo!.sourceAmountSats.toInt()) / BitcoinConstants.satsPerBtc)
            .toStringAsFixed(8)
        : '0';
    final tokenAmount = _swapInfo?.targetAmountUsd.toStringAsFixed(
            sourceToken.isStablecoin || targetToken.isStablecoin ? 2 : 6) ??
        '0.00';

    String formatTokenAmount(SwapToken token, String amount) {
      if (token.isBtc) {
        return '$btcAmount BTC';
      } else if (token.isStablecoin) {
        return '\$$amount';
      } else {
        return '$amount ${token.symbol}';
      }
    }

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          children: [
            // From
            Row(
              children: [
                TokenIcon(token: sourceToken, size: 40),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sent',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  isDark ? AppTheme.white60 : AppTheme.black60,
                            ),
                      ),
                      Text(
                        formatTokenAmount(sourceToken, tokenAmount),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Arrow
            Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: isDark ? AppTheme.white60 : AppTheme.black60,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // To
            Row(
              children: [
                TokenIcon(token: targetToken, size: 40),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Received',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  isDark ? AppTheme.white60 : AppTheme.black60,
                            ),
                      ),
                      Text(
                        formatTokenAmount(targetToken, tokenAmount),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _swapInfo?.status ==
                                          SwapStatusSimple.completed
                                      ? AppTheme.successColor
                                      : null,
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
    );
  }

  Widget _buildSwapDetails(BuildContext context, bool isDark) {
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
              isDark,
              onTap: () => _copyToClipboard(widget.swapId),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            _buildDetailRow(
              context,
              'Direction',
              _swapInfo!.direction == 'btc_to_evm'
                  ? 'BTC → ${_getTargetToken().symbol}'
                  : '${_getSourceToken().symbol} → BTC',
              isDark,
            ),
            if (_swapInfo!.evmHtlcClaimTxid != null &&
                _swapInfo!.direction == 'btc_to_evm') ...[
              const SizedBox(height: AppTheme.elementSpacing),
              _buildDetailRow(
                context,
                'Transaction',
                _truncateId(_swapInfo!.evmHtlcClaimTxid!),
                isDark,
                onTap: () => _copyToClipboard(_swapInfo!.evmHtlcClaimTxid!),
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
    bool isDark, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.white60 : AppTheme.black60,
            fontSize: 14,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.copy_rounded,
                size: 14,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
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

  void _navigateToDeposit() {
    if (_swapInfo == null) return;

    final sourceToken = _getSourceToken();
    final targetToken = _getTargetToken();
    final btcAmount =
        (_swapInfo!.sourceAmountSats.toInt() / BitcoinConstants.satsPerBtc)
            .toStringAsFixed(8);
    final tokenAmount = _swapInfo!.targetAmountUsd.toStringAsFixed(
        sourceToken.isStablecoin || targetToken.isStablecoin ? 2 : 6);

    Navigator.pop(context); // Close bottom sheet first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SwapProcessingScreen(
          swapId: widget.swapId,
          sourceToken: sourceToken,
          targetToken: targetToken,
          sourceAmount: sourceToken.isBtc ? btcAmount : tokenAmount,
          targetAmount: targetToken.isBtc ? btcAmount : tokenAmount,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SwapStatusSimple status) {
    final canClaim =
        _swapInfo?.canClaimGelato == true || _swapInfo?.canClaimVhtlc == true;
    final canRefund = _swapInfo?.canRefund == true;
    final isWaitingForDeposit = status == SwapStatusSimple.waitingForDeposit;
    final showDepositButton = isWaitingForDeposit &&
        _swapInfo?.direction == 'evm_to_btc' &&
        _swapInfo?.depositAddress != null;

    if (!canClaim && !canRefund && !showDepositButton) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (showDepositButton) ...[
          LongButtonWidget(
            title: 'Deposit',
            customWidth: double.infinity,
            onTap: _navigateToDeposit,
          ),
          const SizedBox(height: AppTheme.cardPadding),
        ],
        if (canClaim) ...[
          LongButtonWidget(
            title: _swapInfo!.canClaimGelato
                ? 'Claim ${_getTargetToken().symbol}'
                : 'Claim BTC',
            customWidth: double.infinity,
            state: _isClaiming ? ButtonState.loading : ButtonState.idle,
            onTap: _isClaiming ? null : _handleClaim,
          ),
        ],
        if (canRefund) ...[
          if (canClaim) const SizedBox(height: AppTheme.elementSpacing),
          LongButtonWidget(
            title: 'Claim Refund',
            customWidth: double.infinity,
            state: _isRefunding ? ButtonState.loading : ButtonState.idle,
            buttonType: ButtonType.secondary,
            onTap: _isRefunding ? null : _handleRefund,
          ),
        ],
      ],
    );
  }

  String _truncateId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String text;
  final String? description;

  const _StatusInfo({
    required this.icon,
    required this.color,
    required this.text,
    this.description,
  });
}

/// Sheet for entering refund address.
class _RefundAddressSheet extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onConfirm;

  const _RefundAddressSheet({
    required this.controller,
    required this.onConfirm,
  });

  @override
  State<_RefundAddressSheet> createState() => _RefundAddressSheetState();
}

class _RefundAddressSheetState extends State<_RefundAddressSheet> {
  String? _errorText;
  bool _isValid = false;

  bool _validateAddress(String address) {
    if (address.isEmpty) return false;
    if (address.startsWith('ark1') || address.startsWith('tark1')) {
      return address.length >= 20;
    }
    if (address.startsWith('bc1') || address.startsWith('tb1')) {
      return address.length >= 26;
    }
    if (address.startsWith('1') ||
        address.startsWith('3') ||
        address.startsWith('m') ||
        address.startsWith('n') ||
        address.startsWith('2')) {
      return address.length >= 26 && address.length <= 35;
    }
    return false;
  }

  void _onAddressChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = null;
        _isValid = false;
      } else if (!_validateAddress(value)) {
        _errorText = 'Invalid Bitcoin/Ark address';
        _isValid = false;
      } else {
        _errorText = null;
        _isValid = true;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      widget.controller.text = data!.text!.trim();
      _onAddressChanged(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Address',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          Text(
            'Enter the Bitcoin or Ark address where you want to receive your refund.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      onChanged: _onAddressChanged,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'ark1... or bc1...',
                        hintStyle: TextStyle(
                          color:
                              isDark ? AppTheme.white60 : AppTheme.black60,
                        ),
                        border: InputBorder.none,
                        errorText: _errorText,
                        errorStyle: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    icon: Icon(
                      Icons.paste_rounded,
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                      size: 20,
                    ),
                    tooltip: 'Paste',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Make sure this is your address. Refunds cannot be reversed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
          LongButtonWidget(
            title: 'Confirm Refund',
            customWidth: double.infinity,
            state: _isValid ? ButtonState.idle : ButtonState.disabled,
            onTap: _isValid
                ? () => widget.onConfirm(widget.controller.text)
                : null,
          ),
          SafeArea(
            top: false,
            child: const SizedBox(height: AppTheme.cardPadding),
          ),
        ],
      ),
    );
  }
}
